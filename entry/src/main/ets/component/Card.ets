// entry/src/main/ets/component/Card.ets
/**
 * 卡片组件
 */
@Component
export struct Card {
  //卡片内边距
  @Prop cardPadding: number = 8

  @Builder
  default() {
  }

  @BuilderParam content: () => void = this.default

  build() {
    Column() {
      this.content()

    }
    .alignItems(HorizontalAlign.Start)
    .padding(this.cardPadding)
    .borderRadius(8)
    .backgroundColor($r('app.color.white'))

  }
}

