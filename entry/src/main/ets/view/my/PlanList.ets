/**
 * “我的家 + 我租的 / 我发布的”区域
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { Card } from '../../component/Card'
import { MyRoomCarousel } from './MyRoomCarousel'

@Component
export struct PlanList {
  build() {
    Column() {

      Card({ cardPadding: rvp(8) }) {

        Column() {

          // ===== 顶部标题：我的家 =====
          Row() {
            Text('我的家')
              .fontSize(rvp(16))
              .fontWeight(FontWeight.Bold)

            Row()
              .width(rvp(1))
              .height(rvp(12))
              .backgroundColor('#CCCCCC')
              .margin({ left: rvp(14), right: rvp(12) })

            Text('感谢你选择谷粒')
              .fontSize(rvp(12))
              .fontColor('#999999')
          }
          .margin({ bottom: rvp(12) })

          // ===== 新增：轮播卡片 =====
          MyRoomCarousel()
            .margin({ top: rvp(8) })

        }
        .alignItems(HorizontalAlign.Start)

      }

    }
    .margin({ top: rvp(10) })
  }
}
