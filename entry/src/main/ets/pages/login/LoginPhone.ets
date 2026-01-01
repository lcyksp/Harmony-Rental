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
  // 手机号正则
  reg = new RegExp(/^1(3|4|5|6|7|8|9)\d{9}$/);

  @StorageLink('token') token: string = ''

  @State phone: string = ''
  @State password: string = ''          // 6 位数字密码
  @State isChecked: boolean = false
  @State isValidPhone: boolean = false
  @State isValidPassword: boolean = false

  // 登录后要跳转的页面信息
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
    // 6 位数字
    return /^[0-9]{6}$/.test(pwd);
  }

  // 使用后端密码登录接口
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

      console.log('[LoginPhone] 点击登录时 this.phone = ' + this.phone);

      // 能走到这里说明后端 code=200，登录成功（axios 拦截器已判断）
      this.token = data.token;
      AppStorage.setOrCreate('user', data.user);
      AppStorage.setOrCreate('userPhone', data.user.phone);

      // ⭐ 写入全局用户手机号（ChatList、消息小红点都靠这个）
      if (data.user && data.user.id) {
        AppStorage.setOrCreate('userId', String(data.user.id));
      }
      console.log('[LoginPhone] 服务端返回 data.user = ' + JSON.stringify(data.user));
      console.log('[LoginPhone] 保存 userPhone = ' + this.phone);

      // ⭐ 如果你想兼容 userId，也可以写一下（可选）
      if (data.user && data.user.id) {
        AppStorage.SetOrCreate('userId', String(data.user.id));
      }


      promptAction.showToast({ message: '登录成功' });
      console.log('[LoginPhone] 服务端返回 data.user = ' + JSON.stringify(data.user));

      if (this.redirectUrl && this.redirectUrl.length > 0) {
        router.replaceUrl({
          url: this.redirectUrl,
          params: this.redirectParams
        });
      } else {
        router.replaceUrl({ url: 'pages/Index' });
      }
    } catch (err) {  // 不写类型，避免 ArkTS 检查
      // 失败提示交给全局拦截器，这里只记录一行日志
      console.log('loginByPwdApi error');
    }
  }

  // 注册/找回密码
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
        // ========= 手机号 =========
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

        // ========= 密码（6 位数字） =========
        // 用 Stack 包一层，布局和手机号完全一致，提示文字位置也会对齐
        Stack() {
          TextInput({ placeholder: '请输入密码（6 位数字）' })
            .backgroundColor('rgba(0,0,0,0)')
            .fontSize(rvp(16))
            .showUnderline(true)
            .underlineColor($r('app.color.gray'))  // 注意：underlineColor 全小写
            .caretStyle({ color: $r('app.color.gray_second') })
            .width('100%')
            .type(InputType.Password)
            .onChange((text: string) => {
              this.password = text;
              this.isValidPassword = this.checkPassword(text);
            })

          // 这里暂时不放任何图标（你没有眼睛图标），保持右侧空白
        }
        .alignContent(Alignment.End)

        // ========= 协议 =========
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

        // ========= 登录按钮（绿色） =========
        Button('登录')
          .onClick(() => this.doLogin())
          .width('80%')
          .height(rvp(44))
          .margin({ top: rvp(32) })
          .alignSelf(ItemAlign.Center)
          .backgroundColor('#8FE1A2')
          .fontSize(rvp(16))
          .enabled(this.isChecked && this.isValidPhone && this.isValidPassword)

        // ========= 注册按钮（蓝色） =========
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
