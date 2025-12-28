// entry/src/main/ets/view/roomDetail/Book.ets
import { reservationApi } from '../../api/book';
import { YuDing } from './YuDing';
import { promptAction, router } from '@kit.ArkUI';
import { rvp } from '../../common/utils/DeviceScreen';
import { ReserveRoomParams } from '../../viewmodel/BookRoomModel';
import { getUserHouses, UserHouse, setHouseRented } from '../../store/UserHouseStore';

// 下单接口
import { CreateOrderPayload, createRoomOrderApi } from '../../api/room';

// ⭐ 想看 store
import { isInWantSee, toggleWantSee } from '../../store/WantSeeStore';

// 兼容 axios 返回的错误结构（显式类型，避免 ArkTS 报错）
interface AxiosErrorResponseLite {
  status?: number;
  data?: object;
}

interface HttpError extends Error {
  status?: number;        // 有些封装会直接挂在这里
  code?: string;          // 比如 'ERR_BAD_REQUEST'
  response?: AxiosErrorResponseLite; // axios 标准字段
}

@Component
export struct Book {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0

  @StorageProp('token')
  token: string = ''

  // 房源 ID
  @Prop houseId: string

  // ⭐ 新增：房源标题、封面、价格文案、位置文案
  @Prop title: string = ''
  @Prop cover: string = ''
  @Prop priceText: string = ''
  @Prop location: string = ''

  // 是否本地发布的房源 + 是否已租
  @State isUserHouse: boolean = false
  @State isRented: boolean = false

  // 当前房源是否在「想看」
  @State isWantSee: boolean = false

  // 填写“住房个人信息”用到的状态
  @State baseName: string = ''
  @State basePhone: string = ''
  @State baseRemark: string = ''
  @State baseSubmitting: boolean = false

  aboutToAppear() {
    // 判断 houseId 是否属于本地发布的房源
    const list: UserHouse[] = getUserHouses()
    for (let i = 0; i < list.length; i++) {
      if (list[i].id.toString() === this.houseId) {
        this.isUserHouse = true
        this.isRented = list[i].isRented
        break
      }
    }

    // ⭐ 根据 store 初始化当前房源是否已想看
    this.isWantSee = isInWantSee(this.houseId)
  }

  // ⭐ 切换「想看」状态：更新 Store + 本地状态
  private handleToggleWantSee(): void {
    const now: boolean = toggleWantSee(this.houseId, {
      title: this.title,
      cover: this.cover,
      priceText: this.priceText,
      location: this.location
    })

    this.isWantSee = now

    promptAction.showToast({
      message: now ? '已加入「想看」' : '已取消「想看」',
      duration: 2000
    })
  }

  // 原有预约弹窗
  yuDingController: CustomDialogController = new CustomDialogController({
    builder: YuDing({
      confirm: (param: ReserveRoomParams) => {
        // 填上当前房源 ID
        param.houseId = this.houseId

        // 打日志确认真正提交的参数
        console.info('Book.ets submit param => ', JSON.stringify(param))

        // 本地房源：永远预约成功
        if (this.isUserHouse) {
          setHouseRented(Number.parseInt(this.houseId), true)
          this.isRented = true
          promptAction.showToast({ message: '预约成功！房源已被标记为已租' })
          this.yuDingController.close()
          return
        }

        // 后端房源逻辑
        reservationApi(param)
          .then(() => {
            // ✅ 只有 HTTP 2xx 才会走这里
            promptAction.showToast({ message: '预约成功，等待房东确认' })
            this.yuDingController.close()
          })
          .catch((error: Error) => {
            const httpError: HttpError = error as HttpError

            // 兼容 axios：优先从 response.status 取，没有再看 error.status
            let status: number = 0
            if (httpError.response && httpError.response.status !== undefined) {
              status = httpError.response.status
            } else if (httpError.status !== undefined) {
              status = httpError.status
            }

            const msg: string = httpError.message || ''

            console.error('reservationApi error raw => status = ', status, ', msg = ', msg)

            if (status === 0 && msg.indexOf('成功') >= 0) {
              promptAction.showToast({ message: msg }) // 直接弹“预约成功”
              return
            }

            if (status === 409 || msg.indexOf('时间冲突') >= 0) {
              promptAction.showToast({ message: '预约失败：该日期已有人预约' })
            } else if (status === 400 && msg.indexOf('过去的日期') >= 0) {
              promptAction.showToast({ message: '不能预约过去的日期' })
            } else {
              promptAction.showToast({ message: '预约失败，请稍后重试' })
            }
          })
      }
    }),
    alignment: DialogAlignment.Bottom,
    autoCancel: true,
    customStyle: true,
    isModal: true,
    maskColor: 'rgba(0,0,0,0.7)',
  })

  // 填写入住基本信息的弹窗
  baseInfoController: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.buildBaseInfoDialog()
    },
    alignment: DialogAlignment.Bottom,
    autoCancel: true,
    customStyle: true,
    isModal: true,
    maskColor: 'rgba(0,0,0,0.7)',
  })

  /**
   * “立即预定”逻辑
   */
  private handleBookNow() {
    // 本地房源已租：按钮不可继续预约
    if (this.isUserHouse && this.isRented) {
      promptAction.showToast({ message: '该房源已被租出' })
      return
    }

    // 未登录 → 要求登录
    if (!this.token) {
      router.pushUrl({
        url: 'pages/login/LoginPhone',
        params: {
          redirectUrl: 'pages/rentRoom/RoomDetail',
          redirectParams: { id: this.houseId }
        }
      })
      return
    }

    // 登录后弹出预约时间弹窗
    this.yuDingController.open()
  }

  /**
   * 提交“住房基本信息” → 调 /rooms/:id/orders
   */
  private submitBaseInfo() {
    const phoneTrim: string = this.basePhone.trim()
    const nameTrim: string = this.baseName.trim()

    if (!phoneTrim) {
      promptAction.showToast({ message: '请输入手机号' })
      return
    }

    if (!this.houseId) {
      // 理论上不会发生，只是兜底
      promptAction.showToast({ message: '房源信息缺失，无法提交' })
      return
    }

    const payload: CreateOrderPayload = new CreateOrderPayload()
    payload.tenantId = phoneTrim             // 直接用手机号作为租客唯一标识
    payload.tenantName = nameTrim || '租客'
    payload.tenantPhone = phoneTrim
    payload.remark = this.baseRemark.trim()

    this.baseSubmitting = true

    createRoomOrderApi(this.houseId, payload)
      .then(() => {
        promptAction.showToast({ message: '信息已提交，等待房东确认' })
        // 提交成功后收起弹窗并清空表单
        this.baseInfoController.close()
        this.baseRemark = ''
      })
      .catch(() => {
        promptAction.showToast({ message: '提交失败，请稍后重试' })
      })
      .then(() => {
        this.baseSubmitting = false
      })
  }

  /**
   * “就要这间了”点击逻辑：
   *  - 先要求登录
   *  - 再弹出“填写基本信息”的弹窗
   */
  private handleGoVisit() {
    if (!this.token) {
      router.pushUrl({
        url: 'pages/login/LoginPhone',
        params: {
          redirectUrl: 'pages/rentRoom/RoomDetail',
          redirectParams: { id: this.houseId }
        }
      })
      return
    }

    this.baseInfoController.open()
  }

  /**
   * 弹出的“住房基本信息”对话框 UI
   */
  @Builder
  private buildBaseInfoDialog() {
    Column() {
      Column({ space: rvp(8) }) {
        Text('填写入住人基本信息')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: rvp(8) })

        // 姓名
        TextInput({ text: this.baseName, placeholder: '姓名（选填）' })
          .height(rvp(36))
          .fontSize(14)
          .onChange((value: string) => {
            this.baseName = value
          })

        // 手机号
        TextInput({ text: this.basePhone, placeholder: '手机号（必填）' })
          .type(InputType.PhoneNumber)
          .height(rvp(36))
          .fontSize(14)
          .onChange((value: string) => {
            this.basePhone = value
          })

        // 备注
        TextInput({ text: this.baseRemark, placeholder: '备注（可写入住人数、作息等）' })
          .height(rvp(36))
          .fontSize(14)
          .onChange((value: string) => {
            this.baseRemark = value
          })
      }

      Row() {
        Button('取消', { type: ButtonType.Normal })
          .borderRadius(rvp(4))
          .backgroundColor('#F5F5F5')
          .fontColor('#666666')
          .height(rvp(36))
          .layoutWeight(1)
          .onClick(() => {
            this.baseInfoController.close()
          })

        Button(this.baseSubmitting ? '提交中...' : '提交', { type: ButtonType.Normal })
          .borderRadius(rvp(4))
          .backgroundColor('#24A17B')
          .fontColor('#FFFFFF')
          .height(rvp(36))
          .layoutWeight(1)
          .margin({ left: rvp(12) })
          .enabled(!this.baseSubmitting)
          .onClick(() => {
            if (!this.baseSubmitting) {
              this.submitBaseInfo()
            }
          })
      }
      .margin({ top: rvp(16) })
    }
    .backgroundColor($r('app.color.white'))
    .padding({ left: rvp(16), right: rvp(16), top: rvp(16), bottom: rvp(16) })
    .width('100%')
    .borderRadius({ topLeft: rvp(12), topRight: rvp(12) })
  }

  build() {
    Row() {
      // ⭐ 左下角：爱心 + 99+ + 想看/已想看
      Column({ space: rvp(2) }) {
        Image($r('app.media.my_icon_1'))
          .width(rvp(18))

        Text(this.isWantSee ? '已想看' : '想看')
          .fontSize(12)
          .fontColor(this.isWantSee ? '#24A17B' : $r('app.color.gray'))
      }
      .onClick(() => {
        this.handleToggleWantSee()
      })

      Column({ space: rvp(4) }) {
        Image($r('app.media.message')).width(rvp(18)).fillColor($r('app.color.black'))
        Text('咨询').fontSize(12).fontColor($r('app.color.gray'))
      }

      // “立即预定”按钮（原逻辑，带已租状态）
      Button(this.isRented ? '已租出' : '立即预定', { type: ButtonType.Normal })
        .borderRadius(rvp(2))
        .backgroundColor(this.isRented ? '#cccccc' : '#24A17B')
        .padding({ left: rvp(30), right: rvp(30) })
        .height(rvp(34))
        .onClick(() => {
          if (!this.isRented) {
            this.handleBookNow()
          }
        })

      // “就要这间了”：弹出填写基本信息
      Button('就要这间了', { type: ButtonType.Normal })
        .borderRadius(rvp(2))
        .backgroundColor('#6BE3BE')
        .padding({ left: rvp(30), right: rvp(30) })
        .height(rvp(34))
        .onClick(() => this.handleGoVisit())
    }
    .backgroundColor($r('app.color.white'))
    .padding({ bottom: this.bottomRectHeight })
    .justifyContent(FlexAlign.SpaceEvenly)
    .width('100%')
  }
}
