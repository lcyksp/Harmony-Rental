// entry/src/main/ets/view/my/Settings.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

@Entry
@Component
struct SettingsPage {
  //用 StorageLink，this.token 改动会同步到 AppStorage
  @StorageLink('token') token: string = ''
  @StorageProp('topRectHeight') topRectHeight: number = 0

  private handleLogout() {
    // ① 清除当前组件 & 全局 token
    this.token = ''  // StorageLink 会把 AppStorage 里的 'token' 一起改掉

    // ② 清除全局 user
    AppStorage.setOrCreate('user', null)

    promptAction.showToast({ message: '已退出登录' })

    // ③ 退回登录页
    router.replaceUrl({
      url: 'pages/login/LoginPhone'
    })
  }

  build() {
    Column() {

      // ========= 顶部栏 =========
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1)

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Blank().layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: this.topRectHeight + 8,
        bottom: 8
      })
      .backgroundColor('#8FE1A2')

      // ========= 内容 =========
      Column() {
        Column() {
          Text('退出登录')
            .fontSize(16)
            .fontColor('#E24A4A')
            .margin({ top: 12, bottom: 4 })

          Text('退出后需要重新登录才能发布房源和查看想看列表')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 24, left: 12, right: 12 })
        .onClick(() => this.handleLogout())

        Blank().height(24)
      }
      .backgroundColor('#F7F7F7')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}
