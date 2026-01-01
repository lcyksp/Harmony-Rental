// entry/src/main/ets/view/roomDetail/YuDing.ets
/**
 * 预定
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { ReserveRoomParams } from '../../viewmodel/BookRoomModel'
import { promptAction } from '@kit.ArkUI'

class ReserveRoomParamsImpl implements ReserveRoomParams {
  houseId: string = '';
  name: string = '';
  phone: string = '';
  date: string = '';
  comment: string = '';
  landlordPhone: string = ''; // 类型中要求，哪怕先给空字符串
}

@Component
@CustomDialog
export struct YuDing {
  controller?: CustomDialogController

  @StorageProp('bottomHeight')
  bottomHeight: number = 0

  @State name: string = ''
  @State phone: string = ''
  @State date: string = ''      // yyyy-MM-dd
  @State remark: string = ''



  // 父组件传进来的确认回调
  confirm: (param: ReserveRoomParams) => void = () => {}

  build() {
    Column({ space: rvp(16) }) {
      Text('预约信息')
        .fontSize(18)
        .fontWeight(700)

      Column({ space: rvp(20) }) {

        // 姓名
        Row({ space: rvp(18) }) {
          Text('姓名')
            .width(rvp(56))
            .fontSize(14)

          TextInput({ placeholder: '请输入姓名' })
            .textInputStyles()
            .onChange((value: string) => {
              this.name = value
            })
        }
        .width('100%')

        // 手机号
        Row({ space: rvp(18) }) {
          Text('手机号')
            .width(rvp(56))
            .fontSize(14)

          TextInput({ placeholder: '请输入手机号' })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .textInputStyles()
            .onChange((value: string) => {
              this.phone = value
            })
        }
        .width('100%')

        // 预约日期
        Row({ space: rvp(18) }) {
          Text('预约日期').width(rvp(56)).fontSize(14)

          Row() {
            TextInput({ placeholder: '请选择预约日期', text: $$this.date }) // 必须是 $$this.date
              .enabled(false)
              .textInputStyles()
            Image($r('app.media.arrow_down_2')).width(rvp(10))
          }
          .layoutWeight(1)
          .onClick(() => {
            const today = new Date()
            today.setHours(0,0,0,0)

            DatePickerDialog.show({
              start: today,
              end: new Date(today.getTime() + 86400*1000*30),
              alignment: DialogAlignment.Bottom,

              onAccept: (value: DatePickerResult) => {
                if (value.year == undefined || value.month == undefined || value.day == undefined) return

                // month 必须 +1，因为从 0 开始
                const picked = `${value.year}-${addZero(value.month + 1)}-${addZero(value.day)}`

                console.info('picked date => ', picked)

                this.date = picked   // ✔ 会更新
              }
            })
          })
        }
        .width('100%')

        // 备注
        Row({ space: rvp(18) }) {
          Text('备注信息')
            .width(rvp(56))
            .fontSize(14)

          TextArea({ placeholder: '请输入备注信息' })
            .textAreaStyles()
            .onChange((value: string) => {
              this.remark = value
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(4)

      // 在 Button('预约看房') 上面加这一段
      Text(`当前选择日期：${this.date || '未选择'}`)
        .fontSize(12)
        .fontColor(Color.Gray)
        .width('100%')
        .textAlign(TextAlign.Start)

      // 提交按钮
      Button('预约看房', { type: ButtonType.Normal })
        .onClick(() => {
          if (!this.name || !this.phone || !this.date) {
            promptAction.showToast({
              message: '请输入完整信息！',
              duration: 1000,
              bottom: 150
            })
            return
          }

          if (isPastDate(this.date)) {
            promptAction.showToast({
              message: '不能预约过去的日期',
              duration: 1500,
              bottom: 150
            })
            return
          }

          // 这里用强类型对象，避免 ArkTS 报 no-untyped-obj-literals
          const param = new ReserveRoomParamsImpl()
          param.houseId = ''                      // 按你原代码这里是 ''
          param.name = this.name
          param.phone = this.phone
          param.date = this.date
          param.comment = this.remark
          param.landlordPhone = ''

          console.log(JSON.stringify(param))

          this.confirm(param)
          this.controller?.close()
        })
        .backgroundColor('#24A17B')
        .fontColor(Color.White)
        .borderRadius(2)
        .height(43)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .borderRadius({ topLeft: 20, topRight: 20 })
    .backgroundColor('#ffececec')
    .padding({
      top: 16,
      left: 16,
      right: 16,
      bottom: 16 + this.bottomHeight
    })
  }
}

// =================== 工具函数（都有明确类型） ===================

const ONE_DAY_MS: number = 24 * 60 * 60 * 1000

// 今天 00:00
function getToday(): Date {
  const d: Date = new Date()
  d.setHours(0, 0, 0, 0)
  return d
}

// x < 10 前面补 0
function addZero(x: number): string {
  if (x < 10) {
    return `0${x}`
  } else {
    return `${x}`
  }
}

// 判断一个 yyyy-MM-dd 字符串是不是“今天之前”
function isPastDate(dateStr: string): boolean {
  if (!dateStr) {
    return false
  }
  const parts: string[] = dateStr.split('-')
  if (parts.length !== 3) {
    return false
  }
  const year: number = Number.parseInt(parts[0])
  const month: number = Number.parseInt(parts[1])
  const day: number = Number.parseInt(parts[2])

  const picked: Date = new Date(year, month - 1, day)
  picked.setHours(0, 0, 0, 0)

  const today: Date = getToday()
  return picked.getTime() < today.getTime()
}

@Styles
function pressedStyles() {
  .backgroundColor('#F6F6F6')
}

@Extend(TextInput)
function textInputStyles() {
  .layoutWeight(1)
  .backgroundColor(Color.Transparent)
  .placeholderColor($r('app.color.gray'))
  .placeholderFont({ size: 14 })
  .caretColor($r('app.color.gray'))
  .fontSize(14)
  .borderRadius(rvp(8))
  .stateStyles({
    pressed: pressedStyles,
  })
  .padding(0)
}

@Extend(TextArea)
function textAreaStyles() {
  .layoutWeight(1)
  .backgroundColor('#F6F6F6')
  .placeholderColor($r('app.color.gray'))
  .placeholderFont({ size: 14 })
  .caretColor($r('app.color.gray'))
  .fontSize(14)
  .borderRadius(rvp(8))
  .stateStyles({
    pressed: pressedStyles,
  })
  .padding(rvp(0))
  .height(rvp(60))
}
