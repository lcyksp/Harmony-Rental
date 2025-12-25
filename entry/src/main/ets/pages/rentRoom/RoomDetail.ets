/**
 * 房源详情
 */
import { BarData } from '../../component/ScrollContainer'
import { HousePictureItem, RentTermItem, RoomDetailModel } from '../../viewmodel/RoomDetailModel'
import { router } from '@kit.ArkUI'
import { getRoomDetailApi } from '../../api/roomDetail'
import { HousePictureList } from '../../view/roomDetail/HousePictureList'
import { rvp } from '../../common/utils/DeviceScreen'
import { RentPrice } from '../../view/roomDetail/RentPrice'
import { DiscountsList } from '../../view/roomDetail/DiscountsList'
import { MetaInfo } from '../../view/roomDetail/MetaInfo'
import { TagList } from '../../view/roomDetail/TagList'
import { RentTerm } from '../../view/roomDetail/RentTerm'
import { RentInfo } from '../../view/roomDetail/RentInfo'
import { Household } from '../../view/roomDetail/Household'
import { SupportList } from '../../view/roomDetail/SupportList'
import { Book } from '../../view/roomDetail/Book'
import { NavBar } from '../../view/roomDetail/NavBar'
import { getUserHouses, UserHouse } from '../../store/UserHouseStore'
import { PUBLIC_BASE_URL } from '../../common/utils/Request'   // ⭐ 使用静态资源前缀
// import promptAction from '@ohos.promptAction';  // 如无使用可删除

@Entry
@Component
struct RoomDetail {
  @State barData: BarData = new BarData()
  @State room: Partial<RoomDetailModel> = {}
  @State title: string = ''
  @State housePictureList: HousePictureItem[] = []
  @State rentTerm: RentTermItem = {} as RentTermItem
  @State houseId: string = ''

  @State isUserHouse: boolean = false
  @State userHouse: UserHouse = new UserHouse()

  /**
   * 生成本地发布房源的假详情
   */
  private makeLocalDetail(user: UserHouse): RoomDetailModel {
    return {
      id: user.id.toString(),
      address: user.address,
      houseTitle: user.title,
      rentArea: String(user.area),
      rentPriceUnit: '元/月',
      rentPriceUnitListing: String(user.price),

      housePicture: [
        {
          spaceName: '房源图片',
          picList: [user.cover]  // 这里是文件名 / 相对路径，后面统一用 buildPicUrl 转
        }
      ],

      tags: [{ name: '个人房源' }],
      discounts: [],

      distanceInfo: {
        line: '',
        name: '该房源附近没有地铁',
        distance: ''
      },

      metaInfo: [
        { name: '使用面积', desc: String(user.area) },
        { name: '朝向', desc: '南' },
        { name: '户型', desc: '1室1厅1卫' },
        { name: '楼层', desc: '1/1层' }
      ],

      rentInfo: [],

      rentTerm: {
        checkInTime: '随时入住',
        term: '租期可协商',
        kitchen: '有',
        lift: '有',
        year: '近年建成',
        renovation: '精装',
        heating: '集中供暖',
        house: '非首次出租',
        green: '30%',
        grounding: '',
        protection: '',
        seeTime: '随时可看'
      },

      householdItem: [],
      support: []
    }
  }

  // 将 picList 中的单个图片字段转换成可访问的完整 URL
  private buildPicUrl(raw: string): string {
    if (!raw) {
      return ''
    }

    let s: string = raw.trim()

    // 已经是 http/https 了，直接用
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return s
    }

    // 去掉可能存在的前缀 /public/ 或开头的 /
    s = s.replace(/^\/public\//, '').replace(/^\//, '')

    // PUBLIC_BASE_URL 形如 http://192.168.x.x:7000/public/
    // 所以这里不再拼 'public/'，直接拼文件名
    return PUBLIC_BASE_URL + s
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    const idFromRoute = params.id
    this.houseId = idFromRoute

    console.info('[RoomDetail] idFromRoute = ' + idFromRoute)

    // 查找是否是本地发布房源
    const userList = getUserHouses()
    const found = userList.find(u => u.id.toString() === idFromRoute)

    if (found) {
      this.isUserHouse = true
      this.userHouse = found
      const detail = this.makeLocalDetail(found)

      // 把本地数据也过一遍 buildPicUrl，保证路径一致
      const localPics: HousePictureItem[] = detail.housePicture.map((hp: HousePictureItem) => {
        const pics: string[] = Array.isArray(hp.picList) ? hp.picList : []
        const newPics: string[] = pics.map((p: string) => this.buildPicUrl(p))
        hp.picList = newPics
        return hp
      })

      this.room = detail
      this.title = detail.houseTitle
      this.housePictureList = localPics
      this.rentTerm = detail.rentTerm
      return
    }

    // 调后端接口
    getRoomDetailApi(idFromRoute).then((data: RoomDetailModel) => {
      console.info('[RoomDetail] detail = ' + JSON.stringify(data))

      this.room = data ?? {}
      this.title = data?.houseTitle ?? ''
      this.houseId = data?.id ?? ''

      // 处理 housePicture，统一转成完整 URL
      const rawList: HousePictureItem[] = Array.isArray(data?.housePicture)
        ? data.housePicture
        : []

      const mappedList: HousePictureItem[] = rawList.map((hp: HousePictureItem) => {
        const pics: string[] = Array.isArray(hp.picList) ? hp.picList : []
        const newPics: string[] = pics.map((p: string) => this.buildPicUrl(p))
        hp.picList = newPics
        return hp
      })

      this.housePictureList = mappedList
      this.rentTerm = data?.rentTerm ?? {} as RentTermItem
    })
  }

  build() {
    Column() {
      NavBar({ title: this.title })

      Scroll() {
        Column() {

          // 顶部大图轮播
          HousePictureList({ housePictureList: this.housePictureList })

          Column({ space: rvp(8) }) {
            RentPrice({
              rentPriceListing: this.room.rentPriceUnitListing ?? '',
              rentPriceUnit: this.room.rentPriceUnit ?? '元/月'
            })

            DiscountsList({ discountsList: this.room.discounts ?? [] })
            MetaInfo({ metaInfoList: this.room.metaInfo ?? [] })
            TagList({ tagList: this.room.tags ?? [] })

          }
          .margin({ top: rvp(16) })
          .padding({ left: rvp(16), right: rvp(16) })

          Column({ space: rvp(16) }) {
            RentTerm({ rentTerm: this.rentTerm })
            RentInfo({ rentInfoList: this.room.rentInfo ?? [] })
            Household({ householdList: this.room.householdItem ?? [] })
            SupportList({ supportList: this.room.support ?? [] })

            Button('查看全部内容')
              .type(ButtonType.Normal)
              .width('100%')
              .height(rvp(44))
              .fontSize(12)
              .fontColor('#ABA9AC')
              .backgroundColor('#eee')
              .border({
                width: 1,
                color: '#F5F5F5',
                radius: rvp(8)
              })
          }
          .padding({ left: rvp(16), right: rvp(16) })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 底部预约
      Book({ houseId: this.isUserHouse ? '' : this.houseId })
    }
    .height('100%')
    .width('100%')
  }
}
