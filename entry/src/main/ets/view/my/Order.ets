// entry/src/main/ets/view/my/Order.ets
/**
 * “我的”页面功能入口：想看 / 足迹 / 约看  +  租到的 / 租出的 / 已发布房源
 */
import { Card } from '../../component/Card'
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import { getLandlordRentListApi } from '../../api/rent'   // ✅ 新增：用于红点判断

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
      icon: $r('app.media.my_icon_5')
    },
    {
      id: 2,
      text: '租出的房',
      icon: $r('app.media.my_icon_6')
    },
    {
      id: 3,
      text: '我发布的',
      icon: $r('app.media.my_icon_9')
    }
  ]

  // ✅ 红点：租出的房
  @State showLeaseDot: boolean = false

  // ✅ 当前用户手机号（房东电话）
  private userPhone: string = ''

  aboutToAppear() {
    this.userPhone = this.getCurrentUserPhone()
    this.refreshLeaseDot()
  }

  private getCurrentUserPhone(): string {
    // 尽量兼容你现在项目里已有的存储方式
    if (AppStorage.Has('phone')) {
      const p = AppStorage.Get('phone') as string
      if (p && p.length > 0) return p
    }
    if (AppStorage.Has('userId')) {
      const id = AppStorage.Get('userId') as string
      if (id && id.length > 0) return id
    }
    return ''
  }

  private async refreshLeaseDot() {
    if (!this.userPhone) {
      this.showLeaseDot = false
      return
    }

    try {
      const list = await getLandlordRentListApi(this.userPhone)
      // ✅ 有“新订单(pending)”或“退租申请(quit_pending)”就亮红点
      this.showLeaseDot = list.some(it => it.status === 'pending' || it.status === 'quit_pending')
    } catch (e) {
      this.showLeaseDot = false
    }
  }

  build() {
    Column() {
      Card({ cardPadding: rvp(8) }) {

        // --------- navList1（想看 / 足迹 / 约看）---------
        Row({ space: rvp(50) }) {
          ForEach(this.navList1, (nav: INavItem) => {
            Row({ space: rvp(4) }) {
              Image(nav.icon).width(rvp(16)).height(rvp(16))
              Text(nav.text).fontSize(rvp(12)).fontColor($r('app.color.black'))
            }
            .onClick(() => {
              switch (nav.text) {
                case '想看':
                  router.pushUrl({ url: 'pages/MyWantSee' })
                  break
                case '约看':
                  router.pushUrl({ url: 'pages/ReservationList' })
                  break
                // 足迹后续再接页面
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
              // ✅ 图标 + 红点（只对“租出的房”生效）
              Stack() {
                Image(nav.icon).width(rvp(16)).height(rvp(16))

                if (nav.text === '租出的房' && this.showLeaseDot) {
                  Circle()
                    .width(rvp(6))
                    .height(rvp(6))
                    .fill('#FF3B30')
                    .position({ x: rvp(12), y: rvp(-2) })
                }
              }
              .width(rvp(16))
              .height(rvp(16))

              Text(nav.text).fontSize(rvp(12)).fontColor($r('app.color.black'))
            }
            .onClick(() => {
              switch (nav.text) {
                case '租到的房':
                  router.pushUrl({ url: 'pages/MyRentList' })
                  break
                case '租出的房':
                  router.pushUrl({ url: 'pages/MyLeaseList' })
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
