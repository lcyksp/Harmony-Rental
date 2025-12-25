import { rvp } from '../../common/utils/DeviceScreen'
import { NavItem } from '../../viewmodel/HomeModel'
import { router } from '@kit.ArkUI'

interface NavParams {
  navTitle: string;
}

interface RouterOptions {
  url: string;
  params?: NavParams;
}

@Component
export struct NavList {
  @Prop navList: NavItem[]

  // 根据标题返回对应的本地图片资源
  private getIconByTitle(title: string): Resource {
    switch (title) {
      case '合租':
        return $r('app.media.nav_hezu')
      case '独立主卧':
        return $r('app.media.nav_zhuwu')
      case '整租1居':
        return $r('app.media.nav_yiju')
      case '整租2-3居':
        return $r('app.media.nav_23ju')
      case '小客厅':
        return $r('app.media.nav_small_living')
      case '大客厅':
        return $r('app.media.nav_big_living')
      case '短租':
        return $r('app.media.nav_short')
      case '押金0首付':
        return $r('app.media.nav_zero_deposit')
      default:
        return $r('app.media.nav_hezu')
    }
  }

  build() {
    Grid() {
      ForEach(this.navList, (nav: NavItem) => {
        GridItem() {
          Column({ space: rvp(12) }) {
            // ⬇️ 这里改成用本地图片
            Image(this.getIconByTitle(nav.title))
              .width(rvp(60))
              .height(rvp(60))
              .objectFit(ImageFit.Cover)
              .borderRadius(rvp(8))

            Text(nav.title)
              .fontSize(rvp(12))
              .fontColor($r('app.color.black'))
              .fontWeight(500)
          }
          .onClick(() => {
            const params: NavParams = {
              navTitle: nav.title
            };
            const options: RouterOptions = {
              url: 'pages/rentRoom/RoomList',
              params: params
            };
            router.pushUrl(options);
          })
        }
      })
    }
    .width('100%')
    .columnsTemplate('1fr 1fr 1fr 1fr') // 4 列，navList 有 8 条就会是 2 行×4 列
    .rowsGap(rvp(8))
  }
}
