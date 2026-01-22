// entry/src/main/ets/view/home/SearchBar.ets
/**
 * 顶部搜索组件
 */
import { BarData } from '../../component/ScrollContainer'
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import promptAction from '@ohos.promptAction'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import { geoLocationManager } from '@kit.LocationKit'
import { resolveCityFromLocation } from '../../common/utils/LocationHelper'

interface DialogButton {
  text: string
  color: string
}

// 兼容 showDialog 返回值（常见字段：index）
interface DialogResult {
  index: number
}

@Component
export struct SearchBar {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0

  @Prop barData: BarData

  @StorageLink('hasUnreadMessage')
  hasUnreadMessage: boolean = false

  // 当前城市（全局）
  @StorageLink('currentCityName')
  currentCityName: string = '北京'

  // （后面手动选地区会写这几个）
  @StorageLink('currentProvinceCode') currentProvinceCode: string = ''
  @StorageLink('currentCityCode') currentCityCode: string = ''
  @StorageLink('currentDistrictCode') currentDistrictCode: string = ''

  private goSelectRegion(): void {
    // 你的 main_pages 里注册的是 view/home/RegionSelect
    router.pushUrl({ url: 'view/home/RegionSelect' })
  }

  private async showGoSelectDialog(title: string, message: string): Promise<void> {
    const buttons: DialogButton[] = [
      { text: '取消', color: '#666666' },
      { text: '去选择', color: '#0A59F7' }
    ]
    const res = await promptAction.showDialog({ title, message, buttons }) as DialogResult
    if (res.index === 1) {
      this.goSelectRegion()
    }
  }

  /**
   * 点击定位图标
   */
  private async onClickLocate(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext()

      // 请求定位权限
      const atManager = abilityAccessCtrl.createAtManager()
      await atManager.requestPermissionsFromUser(context, [
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION'
      ])

      // 获取当前位置
      const loc = await geoLocationManager.getCurrentLocation()
      const latitude = loc.latitude ?? 0
      const longitude = loc.longitude ?? 0

      // 逆地理解析城市
      const res = await resolveCityFromLocation(latitude, longitude)
      const cityName = (res.cityName || '').replace('市', '').trim()

      if (!cityName) {
        await this.showGoSelectDialog('定位失败', '未识别到当前城市，可手动选择目标地区')
        return
      }

      AppStorage.setOrCreate('currentCityName', cityName)
      // 定位切城市时清空区，避免残留
      AppStorage.setOrCreate('currentDistrictCode', '')
      // 通知首页刷新推荐
      AppStorage.setOrCreate('needReloadHomeRooms', true)

      promptAction.showToast({ message: `已切换到 ${cityName}` })
    } catch (e) {
      await this.showGoSelectDialog(
        '定位不可用',
        '可能无法开启定位权限/定位服务，请先打开后使用。如无法使用请手动设置位置。'
      )
    }
  }

  build() {
    Row({ space: rvp(16) }) {
      // 左侧：当前城市（可点：手动选择）
      Row({ space: rvp(4) }) {
        Text(this.currentCityName)
          .fontSize(14)
          .fontColor(this.barData.fontColor)

        // 如果你没有 arrow_down 资源，就删掉这一行
        Image($r('app.media.arrow_down'))
          .width(rvp(10))
          .height(rvp(10))
          .fillColor(this.barData.fontColor)
      }
      .onClick(() => this.goSelectRegion())

      // 中间：搜索框 + 定位
      Stack() {
        TextInput()
          .placeholderFont({ size: 12 })
          .width('100%')
          .height(rvp(30))
          .backgroundColor(Color.White)
          .borderColor($r('app.color.gray'))
          .borderWidth(1)

        Row() {
          // 搜索区域
          Row() {
            Image($r('app.media.search'))
              .width(rvp(18))
              .height(rvp(18))

            Text('公园/地铁')
              .fontSize(10)
              .fontColor($r('app.color.text_gray'))
              .layoutWeight(1)
          }
          .layoutWeight(1)
          .onClick(() => {
            router.pushUrl({ url: 'pages/rentRoom/RoomList' })
          })

          Column()
            .width(1)
            .height(rvp(18))
            .backgroundColor('#ffababab')
            .margin({ left: rvp(10), right: rvp(10) })

          // 定位图标
          Image($r('app.media.position'))
            .width(rvp(18))
            .height(rvp(18))
            .onClick(() => this.onClickLocate())
        }
        .width('100%')
        .padding({ left: rvp(16), right: rvp(16) })
      }
      .layoutWeight(1)

      // 右侧：消息
      Stack() {
        Image($r('app.media.message'))
          .width(rvp(20))
          .height(rvp(20))
          .fillColor(this.barData.fontColor)

        if (this.hasUnreadMessage) {
          Column() {}
          .width(rvp(8))
          .height(rvp(8))
          .borderRadius(rvp(4))
          .backgroundColor('#FF3B30')
          .align(Alignment.TopEnd)
          .offset({ x: rvp(2), y: -rvp(2) })
        }
      }
      .onClick(() => {
        router.pushUrl({ url: 'pages/ChatList' })
      })
    }
    .width('100%')
    .backgroundColor(this.barData.bgColor)
    .padding({
      left: rvp(16),
      right: rvp(16),
      top: rvp(4) + this.topRectHeight,
      bottom: rvp(6)
    })
  }
}

//默认导出，解决 Home 里 “has no exported member”
export default SearchBar
