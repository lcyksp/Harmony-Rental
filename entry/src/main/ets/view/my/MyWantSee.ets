// entry/src/main/ets/view/my/MyWantSee.ets
/**
 * 我的 → 想看列表
 * 和底部 tab 的「想看」共用同一份数据，但界面长得更像“我的”页面
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { router } from '@kit.ArkUI'
import { WantSeeItem } from '../../store/WantSeeStore'

@Entry
@Component
struct MyWantSee {
  // 跟全局想看 Store 绑定，数据和 See 页是同步的
  @StorageLink('wantSeeIds') wantSeeList: WantSeeItem[] = []

  build() {
    Column() {
      // 顶部简单导航栏
      // 顶部返回 + 标题
      Row() {
        // 左：返回
        Text('< 返回')
          .fontSize(rvp(16))
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1)

        // 中：标题（居中）
        Text('我的想看')
          .fontSize(rvp(20))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        // 右：占位
        Blank().layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: rvp(16),
        right: rvp(16),
        top: rvp(48),
        bottom: rvp(8)
      })
      .backgroundColor('#8FE1A2')

      // 列表区域
      if (this.wantSeeList.length === 0) {
        // 空状态
        Column() {
          Text('你还没有想看的房子~')
            .fontSize(rvp(14))
            .fontColor('#999999')
            .margin({ bottom: rvp(4) })

          Text('去首页看看喜欢的房子吧')
            .fontSize(rvp(12))
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 有数据：列表
        List() {
          ForEach(this.wantSeeList, (item: WantSeeItem) => {
            ListItem() {
              Row() {
                // 左侧封面图
                Image(item.cover || '')
                  .width(rvp(80))
                  .height(rvp(80))
                  .borderRadius(rvp(8))
                  .objectFit(ImageFit.Cover)

                Column({ space: rvp(6) }) {
                  // 标题
                  Text(item.title || '房源标题')
                    .fontSize(rvp(14))
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 价格
                  Text(item.priceText || '')
                    .fontSize(rvp(13))
                    .fontColor('#FF6A00')

                  // 地址
                  Text(item.location || '')
                    .fontSize(rvp(12))
                    .fontColor('#999999')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .margin({ left: rvp(12) })

                Blank().layoutWeight(1)

                // 右边的小箭头
                Text('>')
                  .fontSize(rvp(12))
                  .fontColor('#CCCCCC')
              }
              .padding({ left: rvp(16), right: rvp(16), top: rvp(10), bottom: rvp(10) })
              .onClick(() => {
                // 点整条进入房源详情
                router.pushUrl({
                  url: 'pages/rentRoom/RoomDetail',  // 你的详情页路由如果不同就在这里改
                  params: { id: item.id }
                })
              })
            }
          }, (item: WantSeeItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}
