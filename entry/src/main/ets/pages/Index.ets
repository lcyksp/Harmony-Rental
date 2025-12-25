import { setSystemBar } from '../common/utils/DeviceScreen'
import { Home } from '../view/index/Home'
import { See } from '../view/index/See'
import { My } from '../view/index/My'
// ⭐ 不再需要服务和发现页
// import { Service } from '../view/index/Service'
// import { Discover } from '../view/index/Discover'

PersistentStorage.persistProp('token', '')

@Entry
@Component
struct Index {
  @State index: number = 0
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0

  aboutToAppear(): void {
    this.changeBar()
  }

  /**
   * 切换菜单改变状态栏
   */
  changeBar() {
    if (this.index == 0) { // 首页
      setSystemBar({
        statusBarContentColor: '#ffffff'
      })
    } else if (this.index == 1) { // 想看
      setSystemBar({
        statusBarContentColor: '#000000'
      })
    } else if (this.index == 2) { // 我的（原来 index=4，也是白色）
      setSystemBar({
        statusBarContentColor: '#ffffff'
      })
    }
  }

  @Builder
  tabBar(image: Resource, activeImage: Resource, text: string, index: number) {
    Column() {
      Image(this.index == index ? activeImage : image)
        .width(28)
        .height(28)
      Text(text)
        .fontSize(10)
        .fontColor(this.index == index ? '#000' : '#a0a0a0')
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.index }) {
      // 0：首页
      TabContent() {
        Home()
      }.tabBar(
        this.tabBar(
          $r('app.media.tabbar_home'),
          $r('app.media.tabbar_home_active'),
          '首页',
          0
        )
      )

      // 1：想看
      TabContent() {
        See()
      }.tabBar(
        this.tabBar(
          $r('app.media.tabbar_see'),
          $r('app.media.tabbar_see_active'),
          '想看',
          1
        )
      )

      // 2：我的
      TabContent() {
        My()
      }.tabBar(
        this.tabBar(
          $r('app.media.tabbar_my'),
          $r('app.media.tabbar_my_active'),
          '我的',
          2
        )
      )
    }
    .width('100%')
    .barHeight(50 + this.bottomRectHeight)
    .scrollable(false) // 禁止滚动切换tab
    .onChange((index: number) => {
      this.index = index
      this.changeBar()
    })
  }
}
