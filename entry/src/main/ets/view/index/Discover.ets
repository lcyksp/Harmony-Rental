// entry/src/main/ets/view/index/Discover.ets
/**
 * 发现页（已简化），社区相关功能暂未开放，仅展示信息页面
 */

@Component
export struct Discover {

  build() {
    Column() {
      Text('发现页暂未开放')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Black)
        .margin({ bottom: 10 })

      Text('当前版本专注于核心租房功能')
        .fontSize(14)
        .fontColor('#888888')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F7F7F7')
  }
}
