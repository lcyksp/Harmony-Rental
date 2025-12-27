/**
 * 房源详情
 */
import { BarData } from '../../component/ScrollContainer'
import { HousePictureItem, RentTermItem, RoomDetailModel } from '../../viewmodel/RoomDetailModel'
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
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
  @State isWantSee: boolean = false

  private makeLocalDetail(user: UserHouse): RoomDetailModel {
    // 用本地发布的房源数据拼一个假的 RoomDetailModel
    return {
      id: user.id.toString(),
      address: user.address,
      houseTitle: user.title,
      rentArea: String(user.area),

      // 价格：xxx 元/月
      rentPriceUnit: '元/月',
      rentPriceUnitListing: String(user.price),

      // 本地房源图片，先存文件名，后面统一用 buildPicUrl 转成完整 URL
      housePicture: [
        {
          spaceName: '房源图片',
          picList: [user.cover]
        }
      ],

      // 标签随便给个「个人房源」
      tags: [{ name: '个人房源' }],

      // 优惠信息先空
      discounts: [],

      // 距离信息：本地没有就给个默认文案
      distanceInfo: {
        line: '',
        name: '该房源附近暂无地铁信息',
        distance: ''
      },

      // 基本信息
      metaInfo: [
        { name: '使用面积', desc: String(user.area) },
        { name: '朝向', desc: '南' },
        { name: '户型', desc: '1室1厅1卫' },
        { name: '楼层', desc: '1/1层' }
      ],

      // 下面这几个列表先给空
      rentInfo: [],
      householdItem: [],
      support: [],

      // 租住条款，随便给一些默认值
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
      }
    }
  }

  private buildPicUrl(raw: string): string {
    if (!raw) {
      return ''
    }

    let s: string = raw.trim()

    // 已经是完整 http/https 地址了，直接用
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return s
    }

    // 去掉可能的 /public/ 前缀和开头的 /
    s = s.replace(/^\/public\//, '').replace(/^\//, '')

    // PUBLIC_BASE_URL 一般是形如 http://xxx:7000/public/
    // 这里直接拼文件名即可
    return PUBLIC_BASE_URL + s
  }


  private toggleWantSee(): void {
    this.isWantSee = !this.isWantSee

    promptAction.showToast({
      message: this.isWantSee ? '已加入「想看」' : '已取消「想看」',
      duration: 2000
    })
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    const idFromRoute = params.id
    this.houseId = idFromRoute

    console.info('[RoomDetail] idFromRoute = ' + idFromRoute)

    const userList = getUserHouses()
    const found = userList.find(u => u.id.toString() === idFromRoute)

    if (found) {
      this.isUserHouse = true
      this.userHouse = found
      const detail = this.makeLocalDetail(found)

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

    getRoomDetailApi(idFromRoute).then((data: RoomDetailModel) => {
      console.info('[RoomDetail] detail = ' + JSON.stringify(data))

      this.room = data ?? {}
      this.title = data?.houseTitle ?? ''
      this.houseId = data?.id ?? ''

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

  private getCover(): string {
    const list: HousePictureItem[] = this.housePictureList ?? []
    if (list.length === 0) {
      return ''
    }
    const first: HousePictureItem = list[0]
    const pics: string[] = Array.isArray(first.picList) ? first.picList : []
    return pics.length > 0 ? pics[0] : ''
  }

  // 拼价格文案：1100元/月
  private getPriceText(): string {
    const listing: string = this.room.rentPriceUnitListing ?? ''
    const unit: string = this.room.rentPriceUnit ?? ''
    if (!listing && !unit) {
      return ''
    }
    return `${listing}${unit}`
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

      // ⭐ 底部预约 + 左下角想看
      Book({
        houseId: this.houseId,
        // 标题：整租·华茂1958C区 1室1厅 南...
        title: this.room.houseTitle ?? '',
        // 封面：用 getCover() 算
        cover: this.getCover(),
        // 价格文案：用 getPriceText() 拼
        priceText: this.getPriceText(),
        // 位置文案：直接用 address
        location: this.room.address ?? ''
      })
    }
    .height('100%')
    .width('100%')
  }

}
