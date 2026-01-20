// entry/src/main/ets/component/BottomSafeArea.ets
/**
 * 避让区填充容器
 */
@Component
export struct BottomSafeArea {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0

  build() {
    Row() {

    }
    .width('100%')
    .height(this.bottomRectHeight)

  }
}

