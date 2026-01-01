// entry/src/main/ets/pages/login/LoginCode.ets
import { router, promptAction } from '@kit.ArkUI';
import { sendSMSCodeApi, registerApi, RegisterReq, RegisterResp } from '../../api/user';
import { rvp } from '../../common/utils/DeviceScreen';
import { NavBar } from '../../component/NavBar';

class UserInfo {
  id: number = 0;
  nickname: string = '';
  phone: string = '';
}

// 路由参数的简单类型
interface RouterParams {
  phone?: string;
  redirectUrl?: string;
  redirectParams?: Record<string, string>;
}

@Entry
@Component
struct LoginCode {
  @StorageLink('token') token: string = ''

  @State phone: string = ''
  @State password: string = ''   // 6 位数字密码
  @State code: string = ''
  @State codeTime: number = 60
  timer: number = 0

  // 校验
  regPhone = new RegExp(/^1(3|4|5|6|7|8|9)\d{9}$/);
  @State isValidPhone: boolean = false
  @State isValidPassword: boolean = false
  @State isValidCode: boolean = false

  // 登录后要跳转的页面信息
  @State redirectUrl: string = ''
  redirectParams: Record<string, string> = {}

  /**
   * 倒计时
   */
  countDown(): void {
    // ArkTS 的 setInterval 返回值就是 number，这里直接赋值即可
    this.timer = setInterval(() => {
      this.codeTime--
      if (this.codeTime == 0) {
        clearInterval(this.timer)
      }
    }, 1000);
  }

  /**
   * 发送验证码
   * （毕设：可以当成“假发”，后端只接收 code，不做内容校验）
   */
  async sendCode(): Promise<void> {
    if (!this.isValidPhone) {
      return;
    }
    try {
      await sendSMSCodeApi(this.phone)
    } catch (e) {
      // catch 不写类型，不做 any/unknown 断言，只简单打印
      console.log('sendSMSCodeApi error', e);
    }
    this.codeTime = 60
    this.countDown()
  }

  /**
   * 注册成功后统一跳转
   */
  private redirectAfterRegister(): void {
    if (this.redirectUrl && this.redirectUrl.length > 0) {
      router.replaceUrl({
        url: this.redirectUrl,
        params: this.redirectParams
      })
    } else {
      router.replaceUrl({
        url: 'pages/Index'
      })
    }
  }

  /**
   * 注册：调用后端，把用户真实写入数据库
   * 验证码只要求 6 位数字（后端也是这样处理）
   */
  private async register(): Promise<void> {
    if (!this.isValidPhone) {
      promptAction.showToast({ message: '请输入正确的手机号' })
      return
    }
    if (!this.isValidPassword) {
      promptAction.showToast({ message: '请输入 6 位数字密码' })
      return
    }
    if (!this.isValidCode) {
      promptAction.showToast({ message: '请输入 6 位验证码（任意数字即可）' })
      return
    }

    try {
      const req: RegisterReq = {
        phone: this.phone,
        password: this.password,
        code: this.code
      }

      const res: RegisterResp = await registerApi(req)

      // 处理 token
      this.token = res.token ?? ('mock-token-' + this.phone)

      // 处理 user
      const user = new UserInfo()
      if (res.user) {
        user.id = res.user.id
        user.nickname = res.user.nickname
        user.phone = res.user.phone
      } else {
        user.id = 1
        user.nickname = '用户' + this.phone.slice(-4)
        user.phone = this.phone
      }

      AppStorage.setOrCreate('user', user)
      AppStorage.setOrCreate('userPhone', user.phone);
      AppStorage.setOrCreate('userId', String(user.id))

      promptAction.showToast({ message: '注册成功，已自动登录' })
      this.redirectAfterRegister()
    } catch (e) {
      // 不写类型，不用 any/unknown，只给个兜底提示
      console.log('register error', e);
      promptAction.showToast({ message: '注册失败，请稍后重试' })
    }
  }

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams;
    this.phone = params.phone ?? '';
    this.redirectUrl = params.redirectUrl ?? '';
    this.redirectParams = params.redirectParams ?? {};

    this.isValidPhone = this.regPhone.test(this.phone);
    if (this.isValidPhone) {
      this.sendCode();
    }
  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  build() {
    Column() {
      NavBar({ title: '注册' })

      Column({ space: rvp(16) }) {
        // 1. 手机号
        TextInput({ placeholder: '请输入手机号' })
          .backgroundColor('rgba(0,0,0,0)')
          .fontSize(16)
          .showUnderline(true)
          .underlineColor($r('app.color.gray'))
          .caretStyle({ color: $r('app.color.gray_second') })
          .width('100%')
          .onChange((text: string) => {
            this.phone = text
            this.isValidPhone = this.regPhone.test(text)
          })

        // 2. 密码（6 位数字）
        TextInput({ placeholder: '请输入 6 位数字密码' })
          .backgroundColor('rgba(0,0,0,0)')
          .fontSize(16)
          .showUnderline(true)
          .underlineColor($r('app.color.gray'))
          .caretStyle({ color: $r('app.color.gray_second') })
          .width('100%')
          .onChange((text: string) => {
            this.password = text
            this.isValidPassword = /^[0-9]{6}$/.test(text)
          })

        // 3. 验证码（任意 6 位数字）
        Stack() {
          TextInput({ placeholder: '请输入 6 位验证码（任意数字即可）' })
            .inputFilter('^.{0,6}$')
            .backgroundColor('rgba(0,0,0,0)')
            .fontSize(16)
            .showUnderline(true)
            .underlineColor($r('app.color.gray'))
            .caretStyle({ color: $r('app.color.gray_second') })
            .width('100%')
            .onChange((text: string) => {
              this.code = text
              this.isValidCode = /^[0-9]{6}$/.test(text)
            })

          Text(this.codeTime == 0 ? '重新获取' : this.codeTime + 's')
            .fontSize(rvp(16))
            .fontWeight(500)
            .fontColor($r('app.color.primary'))
            .onClick(() => {
              if (this.codeTime == 0) {
                this.sendCode()
              }
            })
        }
        .alignContent(Alignment.End)

        // 注册按钮
        Button('注册')
          .onClick(() => this.register())
          .width('80%')
          .height(rvp(44))
          .margin({ top: rvp(32) })
          .alignSelf(ItemAlign.Center)
          .backgroundColor('#8FE1A2')
          .fontSize(rvp(16))
          .enabled(this.isValidPhone && this.isValidPassword && this.isValidCode)
      }
      .width('100%')
      .padding({ left: rvp(40), right: rvp(37), top: rvp(40) })

    }
    .height('100%')
    .width('100%')
    .linearGradient({
      colors: [
        ['#ddffdb', 0],
        ['#ffffff', 0.1]
      ]
    })
  }
}
