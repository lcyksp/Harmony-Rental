// entry/src/main/ets/view/home/RoomRecommend.ets
/**
 * 首页 - 房源推荐组件（按当前“市”优先 + 空态）
 */
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import { PUBLIC_BASE_URL } from '../../common/utils/Request'
import RoomRecommendDataSource from '../../viewmodel/datasource/RoomRecommendDataSource'
import { RoomRecommendItem, TagItem } from '../../viewmodel/HomeModel'

import { getRoomListApi } from '../../api/room'
import type { RoomListModel, RoomItem, SearchParams } from '../../viewmodel/RoomListModel'

// 与后端 housePicture 结构对应
interface HousePictureDTO {
  spaceName?: string
  picList?: string[]
}

/**
 * 后端房源 item 可能包含城市字段（两种命名方式）
 */
interface RoomItemWithCity extends RoomItem {
  cityCode?: string
  city_code?: string
}

/**
 * 兼容 SearchParams + 额外传 snake 字段
 */
interface RoomListQueryParams extends SearchParams {
  city_code: string
}

@Component
export struct RoomRecommend {
  @State roomRecommendDataSource: RoomRecommendDataSource = new RoomRecommendDataSource()
  @State isEmpty: boolean = false

  @StorageLink('currentCityCode')
  @Watch('onCityChanged')
  currentCityCode: string = ''

  @StorageLink('needReloadHomeRooms')
  @Watch('onNeedReloadChanged')
  needReloadHomeRooms: boolean = false

  private cityTimerId: number = 0

  private onCityChanged(): void {
    if (this.cityTimerId) {
      clearTimeout(this.cityTimerId)
      this.cityTimerId = 0
    }
    this.cityTimerId = setTimeout(() => {
      this.loadRecommend()
    }, 120)
  }

  private onNeedReloadChanged(): void {
    if (this.needReloadHomeRooms) {
      AppStorage.setOrCreate('needReloadHomeRooms', false)
      this.loadRecommend()
    }
  }

  aboutToAppear(): void {
    // 触发一次，避免被检查器认为“未使用”
    this.onNeedReloadChanged()
    this.onCityChanged()
  }

  private getCityCode(it: RoomItemWithCity): string {
    if (it.cityCode !== undefined && it.cityCode !== null) return String(it.cityCode)
    if (it.city_code !== undefined && it.city_code !== null) return String(it.city_code)
    return ''
  }

  private preferLocalCity(list: RoomItemWithCity[], cityCode: string): RoomItemWithCity[] {
    const c: string = (cityCode || '').trim()
    if (!c || list.length === 0) return list

    const first: RoomItemWithCity = list[0]
    const hasCityField: boolean = first.cityCode !== undefined || first.city_code !== undefined
    if (!hasCityField) return list

    const local: RoomItemWithCity[] = []
    const other: RoomItemWithCity[] = []

    for (let i = 0; i < list.length; i++) {
      const it: RoomItemWithCity = list[i]
      const itC: string = this.getCityCode(it)
      if (itC && itC === c) local.push(it)
      else other.push(it)
    }
    return local.concat(other)
  }

  private loadRecommend(): void {
    const c: string = (this.currentCityCode || '').trim()

    const params: RoomListQueryParams = {
      page: 1,
      limit: 10,

      // SearchParams 常见必填字段：补齐（即使不用也给空串）
      provinceCode: '',
      cityCode: c,
      districtCode: '',

      // 兼容后端 snake
      city_code: c,

      minRent: '',
      maxRent: '',
      paymentType: '',
      orderBy: '',
      orderType: ''
    }

    getRoomListApi(params)
      .then((res: RoomListModel) => {
        let serverList: RoomItemWithCity[] = []

        if (res.list && res.list.length > 0) {
          serverList = res.list as RoomItemWithCity[]
        } else if ((res as RoomListModel).records && (res as RoomListModel).records!.length > 0) {
          serverList = (res as RoomListModel).records as RoomItemWithCity[]
        }

        if (serverList.length === 0) {
          this.isEmpty = true
          this.roomRecommendDataSource.setList([])
          return
        }

        serverList = this.preferLocalCity(serverList, c)

        const finalList: RoomRecommendItem[] = []
        const maxServer: number = 10

        for (let j = 0; j < serverList.length && j < maxServer; j++) {
          const item: RoomItemWithCity = serverList[j]

          let cover: string = ''

          if (Array.isArray(item.housePicture)) {
            const hpList: HousePictureDTO[] = item.housePicture as HousePictureDTO[]
            if (hpList.length > 0) {
              const firstPic: HousePictureDTO = hpList[0]
              const picList: string[] = firstPic.picList ?? []
              if (picList.length > 0) {
                let raw: string = picList[0].trim()
                if (raw.startsWith('http://') || raw.startsWith('https://')) {
                  cover = raw
                } else {
                  raw = raw.replace(/^\/public\//, '').replace(/^\//, '')
                  cover = PUBLIC_BASE_URL + raw
                }
              }
            }
          }

          if (!cover && typeof item.housePicture === 'string') {
            let raw: string = (item.housePicture as string).trim()
            if (raw.startsWith('http://') || raw.startsWith('https://')) {
              cover = raw
            } else {
              raw = raw.replace(/^\/public\//, '').replace(/^\//, '')
              cover = PUBLIC_BASE_URL + raw
            }
          }

          if (!cover && item.imageUrl) cover = item.imageUrl
          if (!cover && item.coverUrl) cover = item.coverUrl

          const rec: RoomRecommendItem = {
            id: item.id,
            houseTitle: item.houseTitle,
            rentPriceListing: item.rentPriceListing,
            rentPriceUnit: item.rentPriceUnit,
            rentArea: item.rentArea,
            address: item.address,
            housePicture: cover,
            tags: item.tags
          }

          finalList.push(rec)
        }

        this.isEmpty = finalList.length === 0
        this.roomRecommendDataSource.setList(finalList)
      })
      .catch((err: Error) => {
        console.error('[RoomRecommend] getRoomListApi error: ', err.message)
        this.isEmpty = true
        this.roomRecommendDataSource.setList([])
      })
  }

  // ================= UI =================

  @Builder
  RoomNav() {
    Row() {
      Text() {
        Span('同城房源').fontWeight(700)
        Span('推荐').fontColor($r('app.color.primary'))
      }.fontSize(rvp(18))

      Row({ space: 6 }) {
        Text('更多推荐')
          .fontColor($r('app.color.gray_second'))
          .fontSize(rvp(12))
        Image($r('app.media.arrow_right'))
          .width(rvp(4))
          .height(rvp(8))
      }
      .onClick(() => {
        try {
          router.pushUrl({ url: 'pages/rentRoom/RoomList' })
        } catch (e) {
          const msg: string = (e instanceof Error) ? e.message : String(e)
          console.error('[RoomRecommend] router.pushUrl error:', msg)
        }
      })
    }
    .width('100%')
    .height(rvp(50))
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  EmptyView() {
    Column() {
      Text('当前城市暂无房源')
        .fontSize(rvp(14))
        .fontColor($r('app.color.text_gray'))
        .margin({ top: rvp(12), bottom: rvp(12) })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  roomInfo(item: RoomRecommendItem) {
    Column() {
      Row() {
        Text() {
          Span(item.rentPriceListing).fontSize(rvp(16)).fontColor('#E03810')
          Span(item.rentPriceUnit).fontSize(rvp(14)).fontColor('#E03810')
        }.height(rvp(22))

        Text(item.rentArea + '㎡')
          .fontSize(rvp(12))
          .fontColor($r('app.color.gray'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(item.houseTitle)
        .fontSize(rvp(14))
        .margin({ top: rvp(2) })
        .height(rvp(19))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: rvp(6) }) {
        ForEach(item.tags.slice(0, 2), (tag: TagItem, index: number) => {
          Text(tag.name)
            .padding({ top: rvp(1), bottom: rvp(1), left: rvp(4), right: rvp(4) })
            .fontColor(index === 0 ? $r('app.color.white') : $r('app.color.text_gray'))
            .backgroundColor(index === 0 ? $r('app.color.primary') : $r('app.color.bg_gray'))
            .fontSize(rvp(12))
        })
      }
      .width('100%')
      .margin({ top: rvp(9) })
    }
    .padding(rvp(12))
    .alignItems(HorizontalAlign.Start)
    .height(rvp(91))
  }

  @Builder
  address(room: RoomRecommendItem) {
    Image($r('app.media.room_text_bg'))
      .width('100%')
      .height(rvp(120))
    Row({ space: rvp(6) }) {
      Image($r('app.media.location'))
        .width(rvp(12))
        .height(rvp(14))
      Text(room.address)
        .fontSize(rvp(12))
        .fontColor($r('app.color.white'))
    }
    .margin({ left: rvp(8), top: rvp(99) })
  }

  @Builder
  roomItem(room: RoomRecommendItem) {
    Stack() {
      Column() {
        Image(room.housePicture)
          .width('100%')
          .height(rvp(120))
          .objectFit(ImageFit.Fill)
        this.roomInfo(room)
      }
      .width('100%')
      .height('100%')
      .borderRadius(rvp(8))
      .clip(true)
      .borderWidth(1)
      .borderColor('#e1e1e1')

      this.address(room)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.TopStart)
    .onClick(() => {
      try {
        router.pushUrl({
          url: 'pages/rentRoom/RoomDetail',
          params: { id: room.id }
        })
      } catch (e) {
        const msg: string = (e instanceof Error) ? e.message : String(e)
        console.error('[RoomRecommend] router.pushUrl detail error:', msg)
      }
    })
  }

  @Builder
  RoomList() {
    if (this.isEmpty) {
      this.EmptyView()
    } else if (this.roomRecommendDataSource.roomRecommendList.length) {
      Grid() {
        LazyForEach(this.roomRecommendDataSource, (room: RoomRecommendItem) => {
          GridItem() {
            this.roomItem(room)
          }
          .width('100%')
          .height(rvp(210))
        }, (room: RoomRecommendItem) => room.id)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(rvp(8))
      .rowsGap(rvp(8))
      .width('100%')
    }
  }

  build() {
    Column() {
      this.RoomNav()
      this.RoomList()
    }.width('100%')
  }
}
