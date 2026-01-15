// entry/src/main/ets/pages/admin/AdminHome.ets
import { NavBar } from '../../component/NavBar'
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import promptAction from '@ohos.promptAction'


@Entry
@Component
struct AdminHome {
  build() {
    Column() {
      NavBar({ title: '管理后台' })

      Text('这里是管理员后台占位页')
        .fontSize(rvp(16))
        .margin({ top: rvp(24) })

      // ✅ 新增：进入房源管理
      Button('房源管理')
        .margin({ top: rvp(16) })
        .onClick(() => {
          console.info('[AdminHome] click 房源管理')
          // 你能看到 toast 说明按钮真的点到了
          promptAction.showToast({ message: '点击：房源管理', duration: 1200 })
          router.pushUrl({ url: 'pages/admin/AdminRoomManage' })
        })

      Button('返回首页')
        .margin({ top: rvp(16) })
        .onClick(() => router.replaceUrl({ url: 'pages/Index' }))
    }
    .width('100%')
    .height('100%')
  }
}
