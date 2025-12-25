/**
 * 首页 - 房源推荐组件
 */
import { router } from '@kit.ArkUI'
import { rvp } from '../../common/utils/DeviceScreen'
import { PUBLIC_BASE_URL } from '../../common/utils/Request' // ⭐ 使用你定义的静态资源前缀
import RoomRecommendDataSource from '../../viewmodel/datasource/RoomRecommendDataSource'
import { RoomRecommendItem, TagItem } from '../../viewmodel/HomeModel'

// 本地用户发布的房源
import { getUserHouses, UserHouse } from '../../store/UserHouseStore'
import { mapUserHouseToRecommend } from '../../mapper/UserHouseMapper'

// 从 /rooms 接口获取房源列表
import { getRoomListApi } from '../../api/room'
import type { RoomListModel, RoomItem, SearchParams } from '../../viewmodel/RoomListModel'

// 本地类型：和后端 housePicture 结构对应
interface HousePictureDTO {
  spaceName?: string;
  picList?: string[];
}

@Component
export struct RoomRecommend {
  @State roomRecommendDataSource: RoomRecommendDataSource = new RoomRecommendDataSource()

  aboutToAppear(): void {
    // 按 SearchParams 的定义，给一份基础默认参数
    const params: SearchParams = {
      page: 1,
      limit: 10,          // 首页推荐最多拉 10 条就够了
      provinceCode: '',
      cityCode: '',
      districtCode: '',
      minRent: '',
      maxRent: '',
      paymentType: '',
      orderBy: '',
      orderType: '',
      // navTitle 和 roomType 是可选的，这里用不到可以不传
    }

    getRoomListApi(params)
      .then((res: RoomListModel) => {
        const finalList: RoomRecommendItem[] = []

        // 1. 本地用户自己发布的房源
        const userList: UserHouse[] = getUserHouses()
        const maxLocal: number = 5
        for (let i = 0; i < userList.length && i < maxLocal; i++) {
          finalList.push(mapUserHouseToRecommend(userList[i]))
        }

        // 2. 后端 /rooms 返回的房源（兼容 list / records）
        let serverList: RoomItem[] = []
        if (res.list && res.list.length > 0) {
          serverList = res.list
        } else if (res.records && res.records.length > 0) {
          serverList = res.records
        }

        const maxServer: number = 10 // 首页推荐最多展示 10 条接口数据
        for (let j = 0; j < serverList.length && j < maxServer; j++) {
          const item: RoomItem = serverList[j]

          // ========== 关键：封面图统一取字符串 URL ==========
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
                  // 默认后端静态路径是 /public/
                  raw = raw.replace(/^\/public\//, '').replace(/^\//, '')
                  cover = PUBLIC_BASE_URL + raw   // ⭐ 使用 PUBLIC_BASE_URL
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

          // ③ 优先用 imageUrl / coverUrl（后端自动生成）
          if (!cover && item.imageUrl) {
            cover = item.imageUrl
          }
          if (!cover && item.coverUrl) {
            cover = item.coverUrl
          }

          const rec: RoomRecommendItem = {
            id: item.id,
            houseTitle: item.houseTitle,
            rentPriceListing: item.rentPriceListing,
            rentPriceUnit: item.rentPriceUnit,
            rentArea: item.rentArea,
            address: item.address,
            housePicture: cover, // 这里一定是 string（或者空字符串）
            tags: item.tags
          }

          finalList.push(rec)
        }

        this.roomRecommendDataSource.setList(finalList)
      })
      .catch((err: Error) => {
        console.error('getRoomListApi error: ', JSON.stringify(err))

        // 即使接口挂了，也至少展示本地用户发布的房源
        const localList: RoomRecommendItem[] = []
        const userList: UserHouse[] = getUserHouses()
        for (let i = 0; i < userList.length; i++) {
          localList.push(mapUserHouseToRecommend(userList[i]))
        }
        this.roomRecommendDataSource.setList(localList)
      })
  }

  // 头部导航
  @Builder
  RoomNav() {
    Row() {
      Text() {
        Span('周边房源')
          .fontWeight(700)
        Span('推荐')
          .fontColor($r('app.color.primary'))
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
        router.pushUrl({
          url: 'pages/rentRoom/RoomList'
        })
      })
    }
    .width('100%')
    .height(rvp(50))
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 底部房间详情
   */
  @Builder
  roomInfo(item: RoomRecommendItem) {
    Column() {
      Row() {
        Text() {
          Span(item.rentPriceListing)
            .fontSize(rvp(16))
            .fontColor('#E03810')
          Span(item.rentPriceUnit)
            .fontSize(rvp(14))
            .fontColor('#E03810')
        }
        .height(rvp(22))

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
            .padding({
              top: rvp(1),
              bottom: rvp(1),
              left: rvp(4),
              right: rvp(4)
            })
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
      router.pushUrl({
        url: 'pages/rentRoom/RoomDetail',  // ⭐ 跟你现在的详情页路径一致
        params: { id: room.id }
      })
    })
  }

  // 房源列表
  @Builder
  RoomList() {
    if (this.roomRecommendDataSource.roomRecommendList.length) {
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
