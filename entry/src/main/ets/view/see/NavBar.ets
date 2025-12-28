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

  // ⭐ 跟首页一样，绑定全局未读消息数
  @StorageLink('unreadCount') unread: number = 0

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

      // 右侧：两个图标区域（消息 + 另一个“消息”）
      Row({ space: rvp(28) }) {

        // ====== 消息（带小红点）======
        Column({ space: 1 }) {
          // 图标 + 小红点叠加
          Stack() {
            Image($r('app.media.message'))
              .width(rvp(20))
              .height(rvp(20))
              .fillColor($r('app.color.black'))

            if (this.unread > 0) {
              Column() { }                // 小红点
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

        // ====== 右边这个“消息”（你后面可以改文案，比如“路线”）======
        Column({ space: 1 }) {
          Image($r('app.media.journey'))
            .width(rvp(20))
            .height(rvp(20))
            .fillColor($r('app.color.black'))
          Text('消息')
            .fontSize(10)
            .fontColor($r('app.color.black'))
        }
      }

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
