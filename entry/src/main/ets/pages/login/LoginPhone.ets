// entry/src/main/ets/pages/login/LoginPhone.ets
import { NavBar } from '../../component/NavBar'
import { router, promptAction } from '@kit.ArkUI';
import { rvp } from '../../common/utils/DeviceScreen';
import { loginByPwdApi, LoginPwdData } from '../../api/user'

class UserInfo {
  id: number = 0;
  nickname: string = '';
  phone: string = '';
}

@Entry
@Component
struct LoginPhone {
  reg = new RegExp(/^1(3|4|5|6|7|8|9)\d{9}$/);

  @StorageLink('token') token: string = ''

  @State phone: string = ''
  @State password: string = ''
  @State isChecked: boolean = false
  @State isValidPhone: boolean = false
  @State isValidPassword: boolean = false

  @State redirectUrl: string = ''
  redirectParams: Record<string, Object> = {}

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.redirectUrl = params?.redirectUrl as string ?? '';
    this.redirectParams = params?.redirectParams as Record<string, Object> ?? {};

    const phoneFromParams = params?.phone as string;
    if (phoneFromParams && phoneFromParams.length > 0) {
      this.phone = phoneFromParams;
      this.isValidPhone = this.reg.test(phoneFromParams);
    }
  }

  private checkPassword(pwd: string): boolean {
    return /^[0-9]{6}$/.test(pwd);
  }

  private async doLogin() {
    if (!this.isChecked) {
      promptAction.showToast({ message: '请先同意《用户协议》和《隐私政策》' });
      return;
    }
    if (!this.isValidPhone) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (!this.isValidPassword) {
      promptAction.showToast({ message: '请输入 6 位数字密码' });
      return;
    }

    try {
      const data: LoginPwdData = await loginByPwdApi(this.phone, this.password);

      console.log('[LoginPhone] 登录成功 this.phone = ' + this.phone);

      // ⭐ StorageLink 自动刷新应用全局 token
      this.token = data.token;

      // ⭐⭐ 关键修复 1：强制覆盖 AppStorage（不能再用 setOrCreate）
      AppStorage.set('user', data.user);
      AppStorage.set('userPhone', data.user.phone);
      AppStorage.set('userId', String(data.user.id));

      // ⭐⭐ 关键修复 2（你之前写成 SetOrCreate，这是错的）
      // AppStorage.SetOrCreate('userId', ...) ← 这是无效语法！！！ArkTS 没有这个方法

      promptAction.showToast({ message: '登录成功' });

      if (this.redirectUrl && this.redirectUrl.length > 0) {
        router.replaceUrl({
          url: this.redirectUrl,
          params: this.redirectParams
        });
      } else {
        router.replaceUrl({ url: 'pages/Index' });
      }

    } catch (err) {
      console.log('loginByPwdApi error');
    }
  }

  private goRegister() {
    if (!this.isChecked) {
      promptAction.showToast({ message: '请先同意《用户协议》和《隐私政策》' });
      return;
    }

    router.pushUrl({
      url: 'pages/login/LoginCode',
      params: {
        phone: this.phone,
        redirectUrl: this.redirectUrl,
        redirectParams: this.redirectParams
      }
    });
  }

  build() {
    Column() {
      NavBar({ title: '手机号登录' })

      Column({ space: rvp(16) }) {
        // 手机号
        Stack() {
          TextInput({ placeholder: '请输入手机号' })
            .backgroundColor('rgba(0,0,0,0)')
            .fontSize(rvp(16))
            .showUnderline(true)
            .underlineColor($r('app.color.gray'))
            .caretStyle({ color: $r('app.color.gray_second') })
            .width('100%')
            .onChange((text: string) => {
              this.phone = text;
              this.isValidPhone = this.reg.test(text);
            })

          Image($r('app.media.success'))
            .width(rvp(12))
            .height(rvp(8))
            .objectFit(ImageFit.Fill)
            .visibility(this.isValidPhone ? Visibility.Visible : Visibility.Hidden)
        }
        .alignContent(Alignment.End)

        // 密码
        Stack() {
          TextInput({ placeholder: '请输入密码（6 位数字）' })
            .backgroundColor('rgba(0,0,0,0)')
            .fontSize(rvp(16))
            .showUnderline(true)
            .underlineColor($r('app.color.gray'))
            .caretStyle({ color: $r('app.color.gray_second') })
            .width('100%')
            .type(InputType.Password)
            .onChange((text: string) => {
              this.password = text;
              this.isValidPassword = this.checkPassword(text);
            })
        }
        .alignContent(Alignment.End)

        // 协议勾选
        Row({ space: rvp(4) }) {
          Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
            .select(false)
            .selectedColor($r('app.color.primary'))
            .shape(CheckBoxShape.CIRCLE)
            .onChange((value: boolean) => {
              this.isChecked = value;
            })
            .width(rvp(14))
            .height(rvp(14))

          Text() {
            Span('同意').fontColor($r('app.color.text_gray'))
            Span('《用户协议》').fontColor($r('app.color.primary'))
            Span('和').fontColor($r('app.color.text_gray'))
            Span('《隐私政策》').fontColor($r('app.color.primary'))
          }
          .fontWeight(500)
          .fontSize(rvp(12))
        }
        .width('100%')

        // 登录按钮
        Button('登录')
          .onClick(() => this.doLogin())
          .width('80%')
          .height(rvp(44))
          .margin({ top: rvp(32) })
          .alignSelf(ItemAlign.Center)
          .backgroundColor('#8FE1A2')
          .fontSize(rvp(16))
          .enabled(this.isChecked && this.isValidPhone && this.isValidPassword)

        Button('注册/找回密码')
          .onClick(() => this.goRegister())
          .width('80%')
          .height(rvp(44))
          .margin({ top: rvp(12) })
          .alignSelf(ItemAlign.Center)
          .backgroundColor('#46A2EE')
          .enabled(this.isChecked)
      }
      .width('100%')
      .padding({ left: rvp(37), right: rvp(37), top: rvp(37) })

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
