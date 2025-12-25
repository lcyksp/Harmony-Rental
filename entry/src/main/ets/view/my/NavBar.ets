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

  build() {
    Row() {
      // 左侧不再显示“业主版”，留一个占位
      Blank()

      // 右侧三个图标：客服 / 消息 / 设置
      Row({ space: rvp(16) }) {
        // 客服：暂未开通
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

        // 消息：跳到全局 ChatList 页面（放在 pages 目录）
        Image($r('app.media.message'))
          .width(rvp(20))
          .height(rvp(20))
          .fillColor(this.barData.fontColor)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ChatList'
            })
          })

        // 设置：跳到“我的”目录下的 Settings 页面
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
