// entry/src/main/ets/view/index/Home.ets
/**
 * 首页
 */
import { getHomeDataApi } from '../../api/home'
import { rvp } from '../../common/utils/DeviceScreen'
import { BarData, ScrollContainer } from '../../component/ScrollContainer'
import BannerListDataSource from '../../viewmodel/datasource/BannerListDataSource'
import { NavItem, PlanItem, TileItem, BannerItem } from '../../viewmodel/HomeModel'
import { Ad } from '../home/Ad'
import { NavList } from '../home/NavList'
import { PlanList } from '../home/PlanList'
import { RoomRecommend } from '../home/RoomRecommend'
import SearchBar from '../home/SearchBar'
import { SwiperLayout } from '../home/SwiperLayout'
import { TileList } from '../home/TileList'

// 给首页接口的返回数据补一个显式类型，避免 data 被推成 any
interface HomeDataModel {
  bannerList: BannerItem[];
  adPicture: string;
  navList: NavItem[];
  planList: PlanItem[];
  tileList: TileItem[];
}

@Preview
@Component
export struct Home {
  @State barData: BarData = new BarData()
  @State bannerListDataSource: BannerListDataSource = new BannerListDataSource()
  @State adPicture: string = ''
  @State navList: NavItem[] = []
  @State planList: PlanItem[] = []
  @State tileList: TileItem[] = []

  // ✅ 关键：让 Home 感知区域变化
  @StorageLink('currentProvinceCode') currentProvinceCode: string = ''
  @StorageLink('currentCityCode') currentCityCode: string = ''
  @StorageLink('currentDistrictCode') currentDistrictCode: string = ''

  aboutToAppear(): void {
    getHomeDataApi()
      .then((data: HomeDataModel) => {
        console.info('🚀 planList 数据：', JSON.stringify(data.planList))

        this.bannerListDataSource.setList(data.bannerList)
        this.adPicture = data.adPicture
        this.navList = data.navList
        this.planList = data.planList
        this.tileList = data.tileList
      })
  }

  @Builder
  navBar() {
    SearchBar({ barData: this.barData })
  }

  @Builder
  content() {
    Column() {
      SwiperLayout({ bannerListDataSource: this.bannerListDataSource })
      Column({ space: rvp(8) }) {
        NavList({ navList: this.navList })
        TileList({ tileList: this.tileList })
        PlanList()
        Ad({ adPicture: this.adPicture })

        // ✅ 关键：区域变化时强制重建 RoomRecommend
        RoomRecommend()
          .key(`${this.currentProvinceCode}_${this.currentCityCode}_${this.currentDistrictCode}`)
      }
      .padding(rvp(16))
    }
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
