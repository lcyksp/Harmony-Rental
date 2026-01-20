// entry/src/main/ets/view/index/My.ets
/**
 * 我的
 */
import { rvp } from '../../common/utils/DeviceScreen'
import { BarData, ScrollContainer } from '../../component/ScrollContainer'
import { Bg } from '../my/Bg'
import { NavBar } from '../my/NavBar'
import { Order } from '../my/Order'
import { PlanList } from '../my/PlanList'
import { TimePlan } from '../my/TimePlan'
import { UserInfo } from '../my/UserInfo'
import { MyRoomCarousel } from '../my/MyRoomCarousel'

@Preview
@Component
export struct My {
  @State barData: BarData = new BarData()
  // 从全局持久化里拿 token（相当于当前用户 ID）
  @StorageProp('token') token: string = ''

  @Builder
  navBar() {
    NavBar({ barData: this.barData })
  }

  @Builder
  content() {
    Stack({ alignContent: Alignment.TopStart }) {
      Bg()
      Column() {
        // 如果以后 UserInfo 需要 token，可以改成：
        // UserInfo({ token: this.token })
        UserInfo()
        TimePlan()
        Order()
        PlanList()
      }
      .padding({ left: rvp(8), right: rvp(8), top: this.barData.navBarHeight })
    }
    .width('100%')
    .align(Alignment.TopStart)
  }

  build() {
    ScrollContainer({
      barData: this.barData,
      navBar: () => {
        this.navBar()
      },
      content: () => {
        this.content()
      }
    })
  }
}
