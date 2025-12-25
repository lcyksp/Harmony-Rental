/**
 * 服务（占位页，功能已下线）
 */

import { rvp } from '../../common/utils/DeviceScreen'

@Component
export struct Service {
  build() {
    Column() {
      Column() {
        Text('服务功能已下线')
          .fontSize(18)
          .fontWeight(500)
          .fontColor(Color.Gray)
          .margin({ bottom: rvp(8) })

        Text('当前版本仅保留核心租房功能')
          .fontSize(14)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(rvp(16))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F7F7F7')
  }
}
