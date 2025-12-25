/**
 * @author yongoe
 * @since 2024/9/8
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { Card } from '../../component/Card'
import { ContentBlockItem, PostZone } from '../../viewmodel/DiscoverModel'

@Component
export default struct Ad {
  @Prop postZone: PostZone

  build() {
    Row({ space: rvp(14) }) {
      // 左侧主帖子
      Column() {
        Card({ cardPadding: rvp(12) }) {
          // 关注人数：postZone 或 mainPost 可能还没拿到数据，用可选链兜底
          Text(`${this.postZone?.mainPost?.followerNum ?? 0}位小谷粒`)
            .fontSize(10)
            .fontColor($r('app.color.gray_second'))
            .margin({ top: rvp(4), left: rvp(4) })

          Text(this.postZone?.mainPost?.title ?? '')
            .fontSize(26)
            .fontWeight(700)
            .margin({ top: rvp(20), left: rvp(4) })

          Column({ space: rvp(10) }) {
            Row({ space: rvp(8) }) {
              // 头像：没有就用一个占位图
              Image(this.postZone?.mainPost?.userAvatar ?? $r('app.media.app_icon'))
                .width(rvp(28))
                .height(rvp(28))
                .objectFit(ImageFit.Fill)

              Text(this.postZone?.mainPost?.userName ?? '')
                .fontSize(12)
                .fontColor('#636363')
            }

            Text(this.postZone?.mainPost?.postContent ?? '')
              .fontSize(12)
              .fontColor('#636363')
              .maxLines(4)
              .textOverflow({
                overflow: TextOverflow.Ellipsis
              })
          }
          .width('100%')
          .height(rvp(120))
          .padding(rvp(12))
          .backgroundColor('#F9F9F9')
          .borderRadius(rvp(8))
          .alignItems(HorizontalAlign.Start)
          .margin({ top: rvp(7) })
        }
      }
      .width(rvp(192))
      .height('100%')

      // 右侧内容块列表：contentBlockList 可能是 undefined，用 ?? [] 兜底
      Column({ space: rvp(9) }) {
        ForEach(this.postZone?.contentBlockList ?? [], (item: ContentBlockItem) => {
          Image(item.img ?? '')
            .width('100%')
            .height(rvp(67))
            .objectFit(ImageFit.Fill)
        })
      }
      .width(rvp(122))
      .height('100%')
    }
    .width('100%')
    .margin({ top: rvp(19) })
    .height(rvp(218))
  }
}
