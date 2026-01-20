// entry/src/main/ets/view/my/Order.ets
import { Card } from '../../component/Card'
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import { getLandlordRentListApi, RentContractItem } from '../../api/rent'

@Component
export struct Order {
  navList1: INavList = [
    { id: 1, text: '想看', icon: $r('app.media.my_icon_1') },
    { id: 2, text: '足迹', icon: $r('app.media.my_icon_2') },
    { id: 3, text: '约看', icon: $r('app.media.my_icon_3') }
  ]

  navList2: INavList = [
    { id: 1, text: '租到的房', icon: $r('app.media.my_icon_5') },
    { id: 2, text: '租出的房', icon: $r('app.media.my_icon_6') },
    { id: 3, text: '我发布的', icon: $r('app.media.my_icon_9') }
  ]

  @State showLeaseDot: boolean = false
  private userPhone: string = ''

  aboutToAppear() {
    this.userPhone = this.getCurrentUserPhone()
    this.refreshLeaseDot()
  }

  private getCurrentUserPhone(): string {
    if (AppStorage.Has('userPhone')) {
      const p: string | undefined | null = AppStorage.Get('userPhone') as (string | undefined | null)
      if (typeof p === 'string' && p.length > 0) return p
    }
    if (AppStorage.Has('phone')) {
      const p: string | undefined | null = AppStorage.Get('phone') as (string | undefined | null)
      if (typeof p === 'string' && p.length > 0) return p
    }
    if (AppStorage.Has('userId')) {
      const id: string | undefined | null = AppStorage.Get('userId') as (string | undefined | null)
      if (typeof id === 'string' && id.length > 0) return id
    }
    return ''
  }

  private async refreshLeaseDot() {
    if (!this.userPhone) {
      this.showLeaseDot = false
      return
    }

    try {
      const res: RentContractItem[] = await getLandlordRentListApi(this.userPhone)
      const list: RentContractItem[] = Array.isArray(res) ? res : []

      this.showLeaseDot = list.some(
        (it: RentContractItem) => it.status === 'pending' || it.status === 'quit_pending'
      )
    } catch (e) {
      this.showLeaseDot = false
    }
  }

  build() {
    Column() {
      Card({ cardPadding: rvp(8) }) {

        Row({ space: rvp(50) }) {
          ForEach(this.navList1, (nav: INavItem) => {
            Row({ space: rvp(4) }) {
              Image(nav.icon).width(rvp(16)).height(rvp(16))
              Text(nav.text).fontSize(rvp(12)).fontColor($r('app.color.black'))
            }
            .onClick(() => {
              switch (nav.text) {
                case '想看':
                  router.pushUrl({ url: 'view/my/MyWantSee' })
                  break
                case '足迹':
                  router.pushUrl({ url: 'view/my/Footprint' })
                  break
                case '约看':
                  router.pushUrl({ url: 'view/my/ReservationList' })
                  break
              }
            })
          }, (nav: INavItem) => nav.id.toString())
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Divider().margin({ top: rvp(16) })

        Row({ space: rvp(39) }) {
          ForEach(this.navList2, (nav: INavItem) => {
            Column({ space: rvp(6) }) {
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
                  router.pushUrl({ url: 'view/my/MyRentList' })
                  break
                case '租出的房':
                  router.pushUrl({ url: 'view/my/MyLeaseList' })
                  break
                case '我发布的':
                  router.pushUrl({ url: 'view/my/MyPubList' })
                  break
              }
            })
          }, (nav: INavItem) => nav.id.toString())
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
