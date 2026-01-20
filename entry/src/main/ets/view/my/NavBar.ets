// entry/src/main/ets/view/my/NavBar.ets
/**
 * “我的”界面顶部Navbar组件
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { rvp } from '../../common/utils/DeviceScreen'
import { BarData } from '../../component/ScrollContainer'

@Component
export struct NavBar {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0
  @Prop barData: BarData

  //小红点：读取全局“是否有未读消息”布尔值
  @StorageLink('hasUnreadMessage')
  hasUnreadMessage: boolean = false

  build() {
    Row() {
      // 左侧不显示内容，保持布局对称
      Blank()

      // 右侧三个图标：客服 / 消息 / 设置
      Row({ space: rvp(16) }) {

        // -------- 客服（无小红点） --------
        Image($r('app.media.customer'))
          .width(rvp(20))
          .height(rvp(20))
          .fillColor(this.barData.fontColor)
          .onClick(() => {
            promptAction.showDialog({
              title: '提示',
              message: '该服务暂未开通',
            })
          })

        // -------- 消息（带小红点）--------
        Stack() {
          Image($r('app.media.message'))
            .width(rvp(20))
            .height(rvp(20))
            .fillColor(this.barData.fontColor)

          //小红点：只要 hasUnreadMessage 为 true 就显示
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
            url: 'pages/ChatList'
          })
        })

        // -------- 设置 --------
        Image($r('app.media.setting'))
          .width(rvp(20))
          .height(rvp(20))
          .fillColor(this.barData.fontColor)
          .onClick(() => {
            router.pushUrl({
              url: 'view/my/Settings'
            })
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({
      left: rvp(8),
      right: rvp(8),
      top: this.topRectHeight + rvp(8),
      bottom: rvp(8)
    })
    .backgroundColor(this.barData.bgColor)
  }
}
