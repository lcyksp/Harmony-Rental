/**
 * 顶部搜索组件
 */
import { BarData } from '../../component/ScrollContainer';
import { router } from '@kit.ArkUI';
import { rvp } from '../../common/utils/DeviceScreen';

@Component
export struct SearchBar {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0

  @Prop barData: BarData

  // ✅ 改这里：绑定全局 “是否有未读消息” 的布尔值
  @StorageLink('hasUnreadMessage')
  hasUnreadMessage: boolean = false

  build() {
    Row({ space: rvp(16) }) {
      // 左侧：当前城市
      Text('北京')
        .fontSize(14)
        .fontColor(this.barData.fontColor)

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
          Image($r('app.media.search'))
            .width(rvp(18))
            .height(rvp(18))

          Text('公园/地铁')
            .fontSize(10)
            .fontColor($r('app.color.text_gray'))
            .layoutWeight(1)

          Column()
            .width(1)
            .height(rvp(18))
            .backgroundColor('#ffababab')
            .margin({ left: rvp(10), right: rvp(10) })

          Image($r('app.media.position'))
            .width(rvp(18))
            .height(rvp(18))
        }
        .width('100%')
        .padding({ left: rvp(16), right: rvp(16) })
      }
      .layoutWeight(1)
      .onClick(() => {
        router.pushUrl({
          url: 'pages/rentRoom/RoomList'
        })
      })

      // 右侧：消息按钮（带小红点）
      Stack() {
        // 消息图标本体
        Image($r('app.media.message'))
          .width(rvp(20))
          .height(rvp(20))
          .fillColor(this.barData.fontColor)

        // 🔴 小红点：只看 hasUnreadMessage，不显示数字
        if (this.hasUnreadMessage) {
          Column() { }
          .width(rvp(8))
          .height(rvp(8))
          .borderRadius(rvp(4))
          .backgroundColor('#FF3B30')
          .align(Alignment.TopEnd)
          .offset({ x: rvp(2), y: -rvp(2) })
        }
      }
      .onClick(() => {
        router.pushUrl({
          // 这里保持你原来的消息页路由
          url: 'pages/ChatList'
        })
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
