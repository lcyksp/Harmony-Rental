// entry/src/main/ets/view/roomList/ListContent.ets
import { rvp } from '../../common/utils/DeviceScreen';
import { getRoomListApi } from '../../api/room';
import { router } from '@kit.ArkUI';
import type { SearchParams, RoomItem, RoomListModel } from '../../viewmodel/RoomListModel';
import promptAction from '@ohos.promptAction';
import { getUserHouses, UserHouse } from '../../store/UserHouseStore';
import { mapUserHouseToRecommend } from '../../mapper/UserHouseMapper';
import type { RoomRecommendItem, TagItem } from '../../viewmodel/HomeModel';

import { PUBLIC_BASE_URL } from '../../common/utils/Request';
const BASE_URL: string = PUBLIC_BASE_URL;

// ---------- 仅用于从接口原始数据里取字段 ----------
interface MetaInfoItem {
  name: string;
  desc: string;
}

interface HousePictureItem {
  spaceName: string;
  picList: string[];
}

interface RoomFromApi {
  id: string;
  houseId?: string;
  roomId?: string;
  title?: string;
  location?: string;
  rentPrice?: string;
  rentPriceUnit?: string;
  rentPriceUnitListing?: string;
  rentPriceListing?: string;
  rentArea?: string;
  imageUrl?: string;
  coverUrl?: string;
  houseTitle?: string;
  address?: string;
  tags?: TagItem[];
  metaInfo?: MetaInfoItem[];
  housePicture?: Array<HousePictureItem> | string;
}

@Component
export struct ListContent {
  @Consume searchParams: SearchParams;

  @State roomList: RoomItem[] = [];
  @State displayList: RoomItem[] = [];
  @State isLoading: boolean = true; //是否正在加载

  // ------------------- 本地房源映射 -------------------
  private fromUserHouse(user: UserHouse): RoomItem {
    const rec: RoomRecommendItem = mapUserHouseToRecommend(user);

    let cover: string = rec.housePicture || '';
    if (cover && !cover.startsWith('http://') && !cover.startsWith('https://')) {
      if (cover.startsWith('/')) {
        cover = cover.substring(1);
      }
      cover = BASE_URL + cover;
    }

    const result: RoomItem = {
      id: 'local-' + String(rec.id),
      houseTitle: rec.houseTitle,
      housePicture: cover,
      address: rec.address,
      rentPriceListing: rec.rentPriceListing,
      rentPriceUnit: rec.rentPriceUnit,
      rentArea: rec.rentArea,
      tags: rec.tags as TagItem[]
    };
    return result;
  }

  // ------------------- 后端房源映射 -------------------
  private fromApiRoom(api: RoomFromApi): RoomItem {
    let cover: string = '';

    if (api.coverUrl) {
      cover = api.coverUrl;
    } else if (api.imageUrl) {
      cover = api.imageUrl;
    } else if (Array.isArray(api.housePicture)) {
      const group: HousePictureItem = api.housePicture[0];
      if (group && group.picList && group.picList.length > 0) {
        cover = group.picList[0];
      }
    } else if (typeof api.housePicture === 'string') {
      cover = api.housePicture;
    }

    // 补全成完整 URL
    if (cover && !cover.startsWith('http://') && !cover.startsWith('https://')) {
      if (cover.startsWith('/')) {
        cover = cover.substring(1);
      }
      cover = BASE_URL + cover;
    }

    // 租金字段兜底
    const rentListing: string =
      api.rentPriceListing ?? api.rentPriceUnitListing ?? api.rentPrice ?? '';

    // 面积字段兜底
    let rentArea: string = api.rentArea ?? '';
    if (!rentArea && api.metaInfo) {
      for (const item of api.metaInfo) {
        if (item.name === '使用面积') {
          rentArea = item.desc;
          break;
        }
      }
    }

    //这里用联合类型来判断取哪个字段
    const roomId: string =
      api.houseId ?? api.roomId ?? api.id ?? ''; // 尝试 houseId、roomId、id

    console.info('[ListContent] fromApiRoom resolved roomId = ' + roomId);

    const result: RoomItem = {
      id: roomId,
      houseTitle: api.houseTitle ?? api.title ?? '',
      housePicture: cover,
      address: api.address ?? api.location ?? '',
      rentPriceListing: rentListing,
      rentPriceUnit: api.rentPriceUnit ?? '元/月',
      rentArea: rentArea,
      tags: api.tags ?? []
    };

    return result;
  }

  // ------------------- 列表刷新 -------------------
  private refreshDisplayList(): void {
    const category: string = this.searchParams?.navTitle ?? '';

    const matched: RoomItem[] = this.roomList.filter((item: RoomItem) =>
    this.matchByCategory(category, item)
    );

    // 分类没有匹配项 → 显示全部房源
    this.displayList =
      matched.length === 0 && this.roomList.length > 0
        ? this.roomList
        : matched;
  }

  // ------------------- 页面加载 -------------------
  aboutToAppear(): void {
    this.loadRooms()
  }

  // ------------------- 根据当前 searchParams 加载列表 -------------------
  private loadRooms(): void {
    this.isLoading = true //进入加载状态

    const routeParams = router.getParams() as Record<string, Object> | undefined
    let keyword: string = ''
    if (routeParams && typeof routeParams['keyword'] === 'string') {
      keyword = routeParams['keyword'] as string
    }

    const params: SearchParams = {
      page: this.searchParams?.page ?? 1,
      limit: this.searchParams?.limit ?? 10,
      provinceCode: this.searchParams?.provinceCode ?? '',
      cityCode: this.searchParams?.cityCode ?? '',
      districtCode: this.searchParams?.districtCode ?? '',
      minRent: this.searchParams?.minRent ?? '',
      maxRent: this.searchParams?.maxRent ?? '',
      paymentType: this.searchParams?.paymentType ?? '',
      orderBy: this.searchParams?.orderBy ?? 'area',
      orderType: this.searchParams?.orderType ?? '',
      navTitle: this.searchParams?.navTitle ?? '',
      roomType: this.searchParams?.roomType,
      keyword: this.searchParams?.keyword ?? ''
    }

    console.info('[ListContent] loadRooms params = ' + JSON.stringify(params))

    getRoomListApi(params)
      .then((res: RoomListModel) => {
        console.log('[ListContent] getRoomListApi res = ' + JSON.stringify(res))

        let source: RoomFromApi[] = []

        if (Array.isArray(res.list)) {
          source = res.list as RoomFromApi[]
        } else if (Array.isArray(res.records)) {
          source = res.records as RoomFromApi[]
        }

        const finalList: RoomItem[] = []

        // 本地房源
        const locals = getUserHouses()
        for (const u of locals) {
          finalList.push(this.fromUserHouse(u))
        }

        // 后端房源
        for (const a of source) {
          finalList.push(this.fromApiRoom(a))
        }

        console.log('[ListContent] final room count = ' + finalList.length.toString())

        this.roomList = finalList
        this.refreshDisplayList()
        this.isLoading = false
      })
      .catch((err: Error) => {
        console.error('[ListContent] getRoomListApi error = ' + JSON.stringify(err))

        const finalList: RoomItem[] = []
        const locals = getUserHouses()
        for (const u of locals) {
          finalList.push(this.fromUserHouse(u))
        }
        this.roomList = finalList
        this.refreshDisplayList()
        this.isLoading = false
      })
  }

  // ------------------- 分类规则 -------------------
  private matchByCategory(category: string, item: RoomItem): boolean {
    if (!category) {
      return true;
    }

    const title: string = item.houseTitle ?? '';
    const area: number = Number(item.rentArea ?? '0');
    const tags: string[] = (item.tags ?? []).map((t: TagItem) => t.name);

    switch (category) {
      case '合租':
        return title.includes('合租·');
      case '独立主卧':
        return title.includes('合租·') && title.includes('主卧');
      case '整租1居':
        return title.includes('整租·') && title.includes('1室');
      case '整租2-3居':
        return (
          title.includes('整租·') &&
            (title.includes('2室') || title.includes('3室'))
        );
      case '短租':
        return tags.includes('月租');
      case '小客厅':
        return area > 0 && area <= 40;
      case '大客厅':
        return area >= 60;
      case '押金0首付':
        return tags.includes('押一付一');
      default:
        return true;
    }
  }

  // ------------------- 跳转 -------------------
  private goDetail(id: string): void {
    console.info('[ListContent] goDetail id = ' + id)

    if (!id) {
      promptAction.showToast({
        message: '该房源暂不支持查看详情',
        duration: 2000
      });
      return;
    }

    router.pushUrl({
      url: 'pages/rentRoom/RoomDetail',
      params: { id }
    });
  }

  // ------------------- UI -------------------
  build(): void {
    Column() {
      if (this.isLoading) {
        //加载中：使用 LoadingProgress 转圈动画
        Column() {
          LoadingProgress()
            .color('#FF5500')
            .size({ width: rvp(40), height: rvp(40) });

          Text('加载中...')
            .fontSize(rvp(12))
            .fontColor('#999')
            .margin({ top: rvp(8) });
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%');
      } else if (!this.displayList || this.displayList.length === 0) {
        //加载结束但没有房源
        Text('暂无房源')
          .fontSize(rvp(14))
          .fontColor('#999')
          .margin({ top: rvp(40) });
      } else {
        //有房源，展示列表
        List() {
          ForEach(
            this.displayList,
            (item: RoomItem) => {
              ListItem() {
                Row() {
                  Image(item.housePicture)
                    .width(rvp(120))
                    .height(rvp(90))
                    .objectFit(ImageFit.Cover)
                    .borderRadius(rvp(8));

                  Column({ space: rvp(4) }) {
                    Text(item.houseTitle)
                      .fontSize(rvp(14))
                      .fontWeight(FontWeight.Medium)
                      .maxLines(2);

                    Text(item.address)
                      .fontSize(rvp(12))
                      .fontColor('#666')
                      .maxLines(1);

                    Row({ space: rvp(4) }) {
                      Text(String(item.rentPriceListing))
                        .fontSize(rvp(16))
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FF5500');

                      Text(item.rentPriceUnit ?? '元/月')
                        .fontSize(rvp(12))
                        .fontColor('#FF5500');
                    }
                  }
                  .margin({ left: rvp(12) });
                }
                .padding(rvp(12))
                .onClick(() => this.goDetail(item.id));
              }
            },
            (item: RoomItem) => item.id
          );
        }
      }
    }
    .width('100%')
    .height('100%');
  }
}

