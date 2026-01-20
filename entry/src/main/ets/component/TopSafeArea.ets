// entry/src/main/ets/component/TopSafeArea.ets
/**
 * 避让区填充容器
 */
@Component
export struct TopSafeArea {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0

  build() {
    Row() {

    }
    .width('100%')
    .height(this.topRectHeight)

  }
}

