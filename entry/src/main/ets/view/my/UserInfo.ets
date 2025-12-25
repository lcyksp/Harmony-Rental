/**
 * 用户头像
 */
import { Avatar } from '../../component/Avatar'
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { UserModel } from '../../viewmodel/UserModel'
import { getUserInfoApi } from '../../api/user'
import { rvp } from '../../common/utils/DeviceScreen'

@Component
export struct UserInfo {
  @State avatarSrc: string = ''

  // 允许 user 为 null，不会再闪退
  @StorageProp('user')
  user: UserModel | null = null

  @StorageLink('token') token: string = ''

  async getUser(): Promise<void> {
    if (!this.token) {
      // 未登录清空数据
      this.user = null
      this.avatarSrc = ''
      return
    }

    try {
      const user = await getUserInfoApi()
      this.avatarSrc = user.avatar ?? ''
      AppStorage.setOrCreate('user', user)
      this.user = user
    } catch (e) {
      console.log('getUser error', e)
    }
  }

  aboutToAppear(): void {
    this.getUser()
  }

  goLoginPhone(): void {
    if (this.token && this.user?.nickname) {
      promptAction.showToast({ message: '您已登录，无需重复登录' })
      return
    }

    router.pushUrl({ url: 'pages/login/LoginPhone' })
  }

  build() {
    Row({ space: rvp(10) }) {

      // ★★★★★ 关键修复：UI 内不能直接访问 user.nickname，因为 user 可能为 null
      // 所以必须完整写成 this.user?.nickname

      if (this.user?.nickname) {
        // ========= 已登录 =========
        Avatar({ src: this.avatarSrc, avatarSize: rvp(60) })
          .onClick(() => this.goLoginPhone())

        Column({ space: rvp(4) }) {
          Text('Hi，' + this.user!.nickname)
            .fontSize(rvp(16))
            .fontColor($r('app.color.white'))
            .fontWeight(700)

          Text('谷粒点15')
            .fontSize(rvp(12))
            .fontColor($r('app.color.white'))
        }.alignItems(HorizontalAlign.Start)

      } else {
        // ========= 未登录 =========
        Avatar({ src: this.avatarSrc, avatarSize: rvp(60) })
          .onClick(() => this.goLoginPhone())

        Text('请登录')
          .fontSize(rvp(16))
          .fontColor($r('app.color.white'))
          .fontWeight(700)
      }

    }
    .margin({ top: rvp(11) })
    .width('100%')
  }
}
