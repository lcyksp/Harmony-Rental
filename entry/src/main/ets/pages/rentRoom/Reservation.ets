// entry/src/main/ets/pages/rentRoom/Reservation.ets
import { rvp } from '../../common/utils/DeviceScreen';
import { createReservationApi, type ReservationParams } from '../../api/room';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

// ArkTS 要求使用 class 来构造强类型参数
class ReservationParamsImpl implements ReservationParams {
  houseId: string = '';
  name: string = '';
  phone: string = '';
  date: string = '';
  comment?: string;
}

@Component
export struct ReservationPage {
  @State name: string = '';
  @State phone: string = '';
  @State visitTime: string = '';
  @State remark: string = '';

  // 房源参数
  private houseId: string = '';
  private houseTitle: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.houseId = params?.id as string ?? '';
    this.houseTitle = params?.title as string ?? '';
  }

  private submit() {
    if (!this.name || !this.phone || !this.visitTime) {
      promptAction.showToast({ message: '请填写完整信息' });
      return;
    }

    const body = new ReservationParamsImpl();
    body.houseId = this.houseId;
    body.name = this.name;
    body.phone = this.phone;
    body.date = this.visitTime;   // visitTime -> date
    body.comment = this.remark;

    console.info('[ReservationPage] submit params => ' + JSON.stringify(body));

    createReservationApi(body)
      .then(() => {
        promptAction.showToast({ message: '预约成功！' });
        router.back();
      })
      .catch((err: Error) => {
        console.error('[ReservationPage] 预约失败 = ' + JSON.stringify(err));
        promptAction.showToast({ message: '预约失败，请稍后重试' });
      });
  }

  build() {
    Column({ space: rvp(16) }) {
      // 标题
      Text(this.houseTitle || '预约看房')
        .fontSize(rvp(18))
        .fontWeight(FontWeight.Bold)
        .margin({ top: rvp(16) });

      // 姓名输入
      Column() {
        Text('联系人姓名').fontSize(rvp(14));
        TextInput({ placeholder: '请输入姓名', text: $$this.name })
          .onChange(value => this.name = value)
          .height(rvp(40));
      }.width('100%');

      // 电话输入
      Column() {
        Text('联系电话').fontSize(rvp(14));
        TextInput({ placeholder: '请输入手机号码', text: $$this.phone })
          .onChange(value => this.phone = value)
          .height(rvp(40))
          .type(InputType.PhoneNumber);
      }.width('100%');

      // 看房时间
      Column() {
        Text('看房时间').fontSize(rvp(14));
        TextInput({ placeholder: '如：2025-01-02 14:30', text: $$this.visitTime })
          .onChange(value => this.visitTime = value)
          .height(rvp(40));
      }.width('100%');

      // 备注
      Column() {
        Text('备注').fontSize(rvp(14));
        TextInput({ placeholder: '选填', text: $$this.remark })
          .onChange(value => this.remark = value)
          .height(rvp(80))
          .maxLines(3);
      }.width('100%');

      // 提交按钮
      Button('提交预约')
        .width('100%')
        .height(rvp(44))
        .borderRadius(rvp(22))
        .backgroundColor('#00C775')
        .fontColor('#FFFFFF')
        .onClick(() => this.submit());

      Blank();
    }
    .padding(rvp(16))
    .width('100%')
    .height('100%');
  }
}
