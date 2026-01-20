// entry/src/main/ets/view/index/See.ets
/**
 * 想看 Tab 页面
 */
import { BarData, ScrollContainer } from '../../component/ScrollContainer'
import { NavBar } from '../see/NavBar'
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'

// ⭐ 想看 store
import { getWantSeeList, WantSeeItem } from '../../store/WantSeeStore'

@Preview
@Component
export struct See {
  @State barData: BarData = new BarData()

  // 想看列表
  @StorageLink('wantSeeIds') wantList: WantSeeItem[] = []

  @Builder
  navBar() {
    NavBar({ barData: this.barData })
  }

  // 跳转详情
  private goDetail(id: string): void {
    router.pushUrl({
      url: 'pages/rentRoom/RoomDetail',
      params: { id }
    })
  }

  @Builder
  content() {
    Column() {
      if (this.wantList.length === 0) {
        Column() {
          Text('还没有加入想看的房子')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          Text('想看')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)

          Text(`（${this.wantList.length}）`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: rvp(4) })

          Blank().layoutWeight(1)
        }
        .padding({ left: rvp(16), right: rvp(16), top: rvp(8), bottom: rvp(8) })

        List() {
          ForEach(this.wantList, (item: WantSeeItem) => {
            ListItem() {
              Column() {
                Row() {
                  // 左边封面：如果 cover 是 url，就用远程图片组件；如果是本地资源，就按本地资源来
                  if (item.cover && item.cover !== '') {
                    Image(item.cover) // 这里根据你实际封面类型改成 $r('app.media.xxx') 或者 { src: item.cover }
                      .width(rvp(90))
                      .height(rvp(70))
                      .borderRadius(rvp(6))
                  } else {
                    // 没封面就灰块占位
                    Blank()
                      .width(rvp(90))
                      .height(rvp(70))
                      .backgroundColor('#F5F5F5')
                      .borderRadius(rvp(6))
                  }

                  Column({ space: rvp(4) }) {
                    // ⭐ 标题：整租·华贸1958C区 1室1厅 南 ...
                    Text(item.title || '房源标题')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (item.location && item.location !== '') {
                      Text(item.location)
                        .fontSize(11)
                        .fontColor('#999999')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }

                    if (item.priceText && item.priceText !== '') {
                      Text(item.priceText)
                        .fontSize(13)
                        .fontColor('#FF7F24')
                    }
                  }
                  .margin({ left: rvp(12) })

                  Blank().layoutWeight(1)
                }
              }
              .padding({ left: rvp(12), right: rvp(12), top: rvp(10), bottom: rvp(10) })
              .backgroundColor('#FFFFFF')
              .borderRadius(rvp(10))
              .shadow({ radius: rvp(6), color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: rvp(2) })
              .margin({ left: rvp(16), right: rvp(16), bottom: rvp(10) })
              .onClick(() => this.goDetail(item.id))
            }
          }, (item: WantSeeItem) => item.id)
        }
        .padding({ bottom: rvp(16) })
      }
    }
    .padding({ top: this.barData.navBarHeight })
    .linearGradient({
      angle: 180,
      direction: GradientDirection.Top,
      colors: [
        ['#DEFBE5', 0],
        ['#ffffff', 0.3],
        ['#ffffff', 1],
      ],
      repeating: false,
    })
  }


  build() {
    // ScrollContainer 作为唯一根节点，满足 @Entry/@Preview 要求
    ScrollContainer({
      barData: this.barData,
      barColorStart: '#000000',
      barColorEnd: '#000000',
      navBar: () => {
        this.navBar()
      },
      content: () => {
        this.content()
      }
    })
  }
}
