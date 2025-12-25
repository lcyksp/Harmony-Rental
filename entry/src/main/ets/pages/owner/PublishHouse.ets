import { router, promptAction } from '@kit.ArkUI';
import { rvp } from '../../common/utils/DeviceScreen';
import { addUserHouse } from '../../store/UserHouseStore';

@Entry
@Component
struct PublishHousePage {
  @State title: string = ''
  @State price: string = ''
  @State address: string = ''
  @State area: string = ''
  @State submitting: boolean = false

  submit() {
    if (!this.title || !this.price || !this.address) {
      promptAction.showToast({ message: '请填写标题、租金、地址' })
      return
    }

    this.submitting = true

    const newHouse = addUserHouse(
      this.title,
      Number.parseInt(this.price),
      this.address,
      Number.parseInt(this.area || '0'),
      '' // cover 图片先空着
    )

    promptAction.showToast({ message: '发布成功' })

    router.replaceUrl({
      url: 'pages/house/HouseDetail',
      params: {
        houseId: newHouse.id,
        fromUser: true
      }
    })

    this.submitting = false
  }

  build() {
    Column() {
      Text('发布房源')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: rvp(16), bottom: rvp(16) })

      Column({ space: rvp(12) }) {
        Text('标题')
        TextInput({ placeholder: '如：整租·一室一厅' })
          .onChange(v => this.title = v)

        Text('租金（元/月）')
        TextInput({ placeholder: '例如：2000', text: this.price })
          .type(InputType.Number)
          .onChange(v => this.price = v)

        Text('地址')
        TextInput({ placeholder: '例如：东中街 3号', text: this.address })
          .onChange(v => this.address = v)

        Text('面积（㎡）')
        TextInput({ placeholder: '例如：35', text: this.area })
          .type(InputType.Number)
          .onChange(v => this.area = v)

        Button(this.submitting ? '提交中…' : '发布房源')
          .width('100%')
          .height(rvp(40))
          .margin({ top: rvp(24) })
          .backgroundColor('#24A17B')
          .onClick(() => {
            if (!this.submitting) this.submit()
          })
      }
      .padding({ left: rvp(20), right: rvp(20) })
    }
  }
}
