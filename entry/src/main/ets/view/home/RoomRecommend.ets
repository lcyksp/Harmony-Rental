// entry/src/main/ets/view/home/RoomRecommend.ets
/**
 * 首页 - 房源推荐组件（按当前区域筛选 + 空态）
 */
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import { PUBLIC_BASE_URL } from '../../common/utils/Request'
import RoomRecommendDataSource from '../../viewmodel/datasource/RoomRecommendDataSource'
import { RoomRecommendItem, TagItem } from '../../viewmodel/HomeModel'

import { getRoomListApi } from '../../api/room'
import type { RoomListModel, RoomItem, SearchParams } from '../../viewmodel/RoomListModel'

// 本地类型：和后端 housePicture 结构对应
interface HousePictureDTO {
  spaceName?: string
  picList?: string[]
}

// ✅ ArkTS：用继承代替交叉类型
interface RoomItemWithRegion extends RoomItem {
  provinceCode?: string
  cityCode?: string
  districtCode?: string
}

@Component
export struct RoomRecommend {
  @State roomRecommendDataSource: RoomRecommendDataSource = new RoomRecommendDataSource()
  @State isEmpty: boolean = false

  // ✅ 任意区域变化都刷新（防抖）
  @StorageLink('currentProvinceCode')
  @Watch('onRegionChanged')
  currentProvinceCode: string = ''

  @StorageLink('currentCityCode')
  @Watch('onRegionChanged')
  currentCityCode: string = ''

  @StorageLink('currentDistrictCode')
  @Watch('onRegionChanged')
  currentDistrictCode: string = ''

  // ✅ 外部触发刷新信号
  @StorageLink('needReloadHomeRooms')
  @Watch('onNeedReloadChanged')
  needReloadHomeRooms: boolean = false

  private regionTimerId: number = 0

  private onRegionChanged(): void {
    if (this.regionTimerId) {
      clearTimeout(this.regionTimerId)
      this.regionTimerId = 0
    }
    this.regionTimerId = setTimeout(() => {
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
    this.loadRecommend()
  }

  private loadRecommend(): void {
    const params: SearchParams = {
      page: 1,
      limit: 10,
      provinceCode: this.currentProvinceCode || '',
      cityCode: this.currentCityCode || '',
      districtCode: this.currentDistrictCode || '',
      minRent: '',
      maxRent: '',
      paymentType: '',
      orderBy: '',
      orderType: ''
    }

    getRoomListApi(params)
      .then((res: RoomListModel) => {
        const finalList: RoomRecommendItem[] = []

        // 兼容 list / records
        let serverList: RoomItemWithRegion[] = []
        if (res.list && res.list.length > 0) {
          serverList = res.list as RoomItemWithRegion[]
        } else if (res.records && res.records.length > 0) {
          serverList = res.records as RoomItemWithRegion[]
        }

        // ✅ 前端兜底过滤：仅当后端返回里确实有这些字段时才过滤
        const pCode: string = this.currentProvinceCode || ''
        const cCode: string = this.currentCityCode || ''
        const dCode: string = this.currentDistrictCode || ''

        if (serverList.length > 0 && (pCode || cCode || dCode)) {
          const first: RoomItemWithRegion = serverList[0]
          const hasRegionField: boolean =
            (first.provinceCode !== undefined) || (first.cityCode !== undefined) || (first.districtCode !== undefined)

          if (hasRegionField) {
            serverList = serverList.filter((it: RoomItemWithRegion) => {
              const itP: string = String(it.provinceCode ?? '')
              const itC: string = String(it.cityCode ?? '')
              const itD: string = String(it.districtCode ?? '')

              // 区 > 市 > 省
              if (dCode) return itD === dCode
              if (cCode) return itC === cCode
              if (pCode) return itP === pCode
              return true
            })
          }
        }

        // ✅ 空态
        if (serverList.length === 0) {
          this.isEmpty = true
          this.roomRecommendDataSource.setList([])
          return
        }

        this.isEmpty = false

        const maxServer: number = 10
        for (let j = 0; j < serverList.length && j < maxServer; j++) {
          const item: RoomItemWithRegion = serverList[j]

          // ===== 封面图统一取 string URL =====
          let cover: string = ''

          // ① housePicture 是数组：取第一张
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

          // ② housePicture 是字符串（兼容旧格式）
          if (!cover && typeof item.housePicture === 'string') {
            let raw: string = (item.housePicture as string).trim()
            if (raw.startsWith('http://') || raw.startsWith('https://')) {
              cover = raw
            } else {
              raw = raw.replace(/^\/public\//, '').replace(/^\//, '')
              cover = PUBLIC_BASE_URL + raw
            }
          }

          // ③ 兜底字段
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

        this.roomRecommendDataSource.setList(finalList)
      })
      .catch((err: Error) => {
        console.error('getRoomListApi error: ', JSON.stringify(err))
        this.isEmpty = true
        this.roomRecommendDataSource.setList([])
      })
  }

  // 头部导航
  @Builder
  RoomNav() {
    Row() {
      Text() {
        Span('周边房源').fontWeight(700)
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
        router.pushUrl({ url: 'pages/rentRoom/RoomList' })
      })
    }
    .width('100%')
    .height(rvp(50))
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  EmptyView() {
    Column() {
      Text('当前地区暂无房源')
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
        .height(rvp(14)) // ✅ 这里别再有多余的 () 了
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
      router.pushUrl({
        url: 'pages/rentRoom/RoomDetail',
        params: { id: room.id }
      })
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
