// entry/src/main/ets/pages/rentRoom/RoomDetail.ets
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
import { PUBLIC_BASE_URL } from '../../common/utils/Request'

// ✅ 新增：足迹写入
import { addFootprintApi } from '../../api/footprint'

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
    return {
      id: user.id.toString(),
      address: user.address,
      houseTitle: user.title,
      rentArea: String(user.area),
      rentPriceUnit: '元/月',
      rentPriceUnitListing: String(user.price),
      housePicture: [
        { spaceName: '房源图片', picList: [user.cover] }
      ],
      tags: [{ name: '个人房源' }],
      discounts: [],
      distanceInfo: { line: '', name: '该房源附近暂无地铁信息', distance: '' },
      metaInfo: [
        { name: '使用面积', desc: String(user.area) },
        { name: '朝向', desc: '南' },
        { name: '户型', desc: '1室1厅1卫' },
        { name: '楼层', desc: '1/1层' }
      ],
      rentInfo: [],
      householdItem: [],
      support: [],
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
    if (!raw) return ''
    let s: string = raw.trim()
    if (s.startsWith('http://') || s.startsWith('https://')) return s
    s = s.replace(/^\/public\//, '').replace(/^\//, '')
    return PUBLIC_BASE_URL + s
  }

  private toggleWantSee(): void {
    this.isWantSee = !this.isWantSee
    promptAction.showToast({
      message: this.isWantSee ? '已加入「想看」' : '已取消「想看」',
      duration: 2000
    })
  }

  /** ✅ 新增：记录足迹（失败不影响详情页） */
  private recordFootprint(houseId: string): void {
    const userId: string = AppStorage.Has('userPhone') ? (AppStorage.Get('userPhone') as string) : ''
    if (!userId || !houseId) return

    addFootprintApi(userId, String(houseId)).catch(() => {
      // 静默失败即可
    })
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    const idFromRoute = params.id
    this.houseId = idFromRoute

    console.info('[RoomDetail] idFromRoute = ' + idFromRoute)

    const userList = getUserHouses()
    const found = userList.find(u => u.id.toString() === idFromRoute)

    // ✅ 本地房源：拼好 detail 后记录足迹（用 idFromRoute 就行）
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

      // ✅ 记录足迹（本地）
      this.recordFootprint(String(idFromRoute))
      return
    }

    // ✅ 远端房源：拿到详情后记录足迹（用 data.id 更准）
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

      // ✅ 记录足迹（远端：以 data.id 为准）
      if (this.houseId) {
        this.recordFootprint(this.houseId)
      } else {
        this.recordFootprint(String(idFromRoute))
      }
    })
  }

  private getCover(): string {
    const list: HousePictureItem[] = this.housePictureList ?? []
    if (list.length === 0) return ''
    const first: HousePictureItem = list[0]
    const pics: string[] = Array.isArray(first.picList) ? first.picList : []
    return pics.length > 0 ? pics[0] : ''
  }

  private getPriceText(): string {
    const listing: string = this.room.rentPriceUnitListing ?? ''
    const unit: string = this.room.rentPriceUnit ?? ''
    if (!listing && !unit) return ''
    return `${listing}${unit}`
  }

  build() {
    Column() {
      NavBar({ title: this.title })

      Scroll() {
        Column() {

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

      Book({
        houseId: this.houseId,
        title: this.room.houseTitle ?? '',
        cover: this.getCover(),
        priceText: this.getPriceText(),
        location: this.room.address ?? ''
      })
    }
    .height('100%')
    .width('100%')
  }
}
