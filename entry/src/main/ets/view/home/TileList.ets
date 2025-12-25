/**
 * 2个平铺组件：硅谷家服 + 硅谷智能
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { TileItem } from '../../viewmodel/HomeModel'

@Component
export struct TileList {
  @Prop tileList: TileItem[]

  private getTileIcon(title: string): Resource {
    switch (title) {
      case '硅谷家服':
        return $r('app.media.tile_truck')
      case '硅谷智能':
        return $r('app.media.tile_cabinet')
      default:
        return $r('app.media.tile_truck')
    }
  }

  build() {
    Row({ space: rvp(16) }) {
      ForEach(this.tileList, (item: TileItem) => {
        Column({ space: rvp(8) }) {
          Image(this.getTileIcon(item.title))
            .width('100%')
            .height(rvp(58))
            .objectFit(ImageFit.Cover)
            .borderRadius(rvp(8))

          Row({ space: rvp(8) }) {
            Text(item.title)
              .fontSize(rvp(12))
              .fontColor($r('app.color.black'))
            Text(item.sub_title)
              .fontSize(10)
              .fontColor($r('app.color.text_gray'))
          }
          .width('100%')
        }
        .width('50%') // 1 行 2 列
      })
    }
    .width('100%')
  }
}
