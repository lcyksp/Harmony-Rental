import { rvp } from '../../common/utils/DeviceScreen'

@Component
export struct PlanList {

  @Builder
  PlanCard(title: string, subTitle: string, bgColor: string) {
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
    .height(rvp(70))      // 卡片高度，你可以微调
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  build() {
    Row({ space: rvp(8) }) {
      this.PlanCard('谷粒计划', '在校生', '#E8F3FF')
      this.PlanCard('精英计划', '毕业生', '#FFF3E0')
      this.PlanCard('企业计划', '打工人', '#E8F5E9')
      this.PlanCard('English', 'lao wai', '#F3E5F5')
    }
    .width('100%')
  }
}
