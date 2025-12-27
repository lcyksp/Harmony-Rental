// entry/src/main/ets/view/my/Order.ets
/**
 * “我的”页面功能入口：想看 / 足迹 / 约看  +  租到的 / 租出的 / 已发布房源
 */
import { Card } from '../../component/Card'
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'

@Component
export struct Order {
  // ⭐ 上面一排：只保留 3 个（想看 / 足迹 / 约看），去掉“拼租”
  navList1: INavList = [
    {
      id: 1,
      text: '想看',
      icon: $r('app.media.my_icon_1')
    },
    {
      id: 2,
      text: '足迹',
      icon: $r('app.media.my_icon_2')
    },
    {
      id: 3,
      text: '约看',
      icon: $r('app.media.my_icon_3')
    }
  ]

  /**
   * 下边一排：租到的 / 租出的 / 我发布的
   */
  navList2: INavList = [
    {
      id: 1,
      text: '租到的房',
      icon: $r('app.media.my_icon_5')  // 合同图标沿用
    },
    {
      id: 2,
      text: '租出的房',
      icon: $r('app.media.my_icon_6')  // 账单图标沿用
    },
    {
      id: 3,
      text: '我发布的',
      icon: $r('app.media.my_icon_9')  // 钱包图标沿用
    }
  ]

  build() {
    Column() {
      Card({ cardPadding: rvp(8) }) {

        // --------- navList1（想看 / 足迹 / 约看）---------
        Row({ space: rvp(50) }) {  // 三个图标，间距稍微拉大一点
          ForEach(this.navList1, (nav: INavItem) => {
            Row({ space: rvp(4) }) {
              Image(nav.icon).width(rvp(16)).height(rvp(16))
              Text(nav.text).fontSize(rvp(12)).fontColor($r('app.color.black'))
            }
            .onClick(() => {
              switch (nav.text) {
                case '想看':
                  // 👉 点“想看”跳到想看列表页
                  router.pushUrl({
                    // 注意：这里不要带前面的 '/'
                    // 确保和 config.json5 里这个页面的 url 一致
                    url: 'pages/MyWantSee'
                  })
                  break
                case '约看':
                  router.pushUrl({ url: 'pages/rentRoom/BookRoomList' })
                  break
                // 足迹先留空，后面有页面再加
              }
            })
          }, (nav: INavItem) => nav.id + '')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Divider().margin({ top: rvp(16) })

        // --------- navList2（租到的 / 租出的 / 我发布的）---------
        Row({ space: rvp(39) }) {
          ForEach(this.navList2, (nav: INavItem) => {
            Column({ space: rvp(6) }) {
              Image(nav.icon).width(rvp(16)).height(rvp(16))
              Text(nav.text).fontSize(rvp(12)).fontColor($r('app.color.black'))
            }
            .onClick(() => {
              switch (nav.text) {
                case '租到的房':
                  router.pushUrl({ url: 'pages/my/MyRentList' })
                  break
                case '租出的房':
                  router.pushUrl({ url: 'pages/my/MyLeaseList' })
                  break
                case '我发布的':
                  router.pushUrl({ url: 'pages/my/MyPublishedRooms' })
                  break
              }
            })
          }, (nav: INavItem) => nav.id + '')
        }
        .margin({ top: rvp(12) })
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
    }
    .margin({ top: rvp(10) })
  }
}

export interface INavItem {
  id: number
  text: string
  icon: Resource
}

export type INavList = INavItem[]
