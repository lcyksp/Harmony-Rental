// entry/src/main/ets/view/see/NavBar.ets
/**
 * 想看页面NavBar组件
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { BarData } from '../../component/ScrollContainer'
import { router } from '@kit.ArkUI'

@Component
export struct NavBar {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0
  @Prop barData: BarData

  //跟首页一样，绑定全局“是否有未读消息”的布尔值
  @StorageLink('hasUnreadMessage')
  hasUnreadMessage: boolean = false

  build() {
    Row() {
      // 左侧：通勤地址
      Row({ space: rvp(16) }) {
        Image($r('app.media.bag'))
          .width(rvp(20))
          .height(rvp(20))
        Text('填写通勤地址')
          .fontSize(rvp(12))
          .fontWeight(500)
          .fontColor($r('app.color.black'))
      }

      // 右侧：只有一个“消息”按钮（带小红点）
      Column({ space: 1 }) {
        // 图标 + 小红点叠加
        Stack() {
          Image($r('app.media.message'))
            .width(rvp(20))
            .height(rvp(20))
            .fillColor($r('app.color.black'))

          //小红点：只看 hasUnreadMessage
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

        Text('消息')
          .fontSize(rvp(10))
          .fontColor($r('app.color.black'))
      }
      // 整个“消息”列都可点击
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ChatList'
        })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(this.barData.bgColor)
    .padding({
      left: 8,
      right: 8,
      top: 8 + this.topRectHeight,
      bottom: 8
    })
  }
}
