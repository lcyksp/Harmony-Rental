// entry/src/main/ets/view/home/PlanList.ets
import { rvp } from '../../common/utils/DeviceScreen'
import promptAction from '@ohos.promptAction'  // 新增这一行

@Component
export struct PlanList {

  @Builder
  PlanCard(title: string, subTitle: string, bgColor: string, onClick: () => void) {
    Column({ space: rvp(4) }) {
      Text(title)
        .fontSize(rvp(12))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)

      Text(subTitle)
        .fontSize(rvp(10))
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({
      left: rvp(8),
      right: rvp(8),
      top: rvp(10),
      bottom: rvp(10)
    })
    .backgroundColor(bgColor)
    .borderRadius(rvp(12))
    .height(rvp(70))      // 卡片高度
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .onClick(onClick)     // 在这里绑定点击事件
  }

  build() {
    Row({ space: rvp(8) }) {
      // 在校生
      this.PlanCard('谷粒计划', '在校生', '#E8F3FF', () => {
        promptAction.showToast({
          message: '活动太火爆了，请稍后再试~',
          duration: 2000
        })
      })

      // 毕业生
      this.PlanCard('精英计划', '毕业生', '#FFF3E0', () => {
        promptAction.showToast({
          message: '当前活动暂未开始，请留意后续通知~',
          duration: 2000
        })
      })

      // 打工人
      this.PlanCard('企业计划', '打工人', '#E8F5E9', () => {
        promptAction.showToast({
          message: '当前活动已结束，下次记得早点来吧~',
          duration: 2000
        })
      })

      // 外国人
      this.PlanCard('English', 'lao wai', '#F3E5F5', () => {
        promptAction.showToast({
          message: '暂不支持该功能',
          duration: 2000
        })
      })
    }
    .width('100%')
  }
}
