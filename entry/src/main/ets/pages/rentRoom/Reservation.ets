import { rvp } from '../../common/utils/DeviceScreen';
import { createReservationApi, type ReservationParams } from '../../api/room';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Component
export struct ReservationPage {
  @State name: string = '';
  @State phone: string = '';
  @State visitTime: string = '';
  @State remark: string = '';

  // 从详情页传进来的参数
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

    const body: ReservationParams = {
      houseId: this.houseId,
      name: this.name,
      phone: this.phone,
      visitTime: this.visitTime,
      remark: this.remark
    };

    createReservationApi(body)
      .then(() => {
        promptAction.showToast({ message: '预约成功！' });
        router.back();   // 成功后返回上一页，或者跳到“我的预约”页
      })
      .catch((err: Error) => {
        console.error('[Reservation] 预约失败 = ' + JSON.stringify(err));
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

      // 姓名
      Column() {
        Text('联系人姓名').fontSize(rvp(14));
        TextInput({ placeholder: '请输入姓名', text: this.name })
          .onChange(value => this.name = value)
          .height(rvp(40));
      }.width('100%');

      // 电话
      Column() {
        Text('联系电话').fontSize(rvp(14));
        TextInput({ placeholder: '请输入手机号码', text: this.phone })
          .onChange(value => this.phone = value)
          .height(rvp(40))
          .type(InputType.PhoneNumber);
      }.width('100%');

      // 看房时间（简单用一个 TextInput，后面你可以换成 DatePicker）
      Column() {
        Text('看房时间').fontSize(rvp(14));
        TextInput({ placeholder: '如：2025-01-02 14:30', text: this.visitTime })
          .onChange(value => this.visitTime = value)
          .height(rvp(40));
      }.width('100%');

      // 备注
      Column() {
        Text('备注').fontSize(rvp(14));
        TextInput({ placeholder: '选填', text: this.remark })
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

      Blank(); // 顶上/底部留白
    }
    .padding(rvp(16))
    .width('100%')
    .height('100%');
  }
}
