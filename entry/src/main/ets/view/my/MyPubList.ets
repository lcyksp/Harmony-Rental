import router from '@ohos.router'
import prompt from '@ohos.prompt'
import { rvp } from '../../common/utils/DeviceScreen'
import {
  SimpleRoom,
  getMyRoomsApi,
  offShelfRoomApi,
  onShelfRoomApi
} from '../../api/room'

function safeStr(v: string | undefined | null, fallback: string = ''): string {
  return typeof v === 'string' ? v : fallback
}
function hasText(v: string | undefined | null): boolean {
  return typeof v === 'string' && v.length > 0
}

interface UserInfo {
  phone?: string
  userId?: string
}

@Entry
@Component
struct MyPubList {
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('token') token: string = '' // ✅ token 优先

  @State currentTab: number = 0 // 0=已上架, 1=已下架, 2=全部
  @State list: SimpleRoom[] = []
  @State loading: boolean = false

  private scroller: Scroller = new Scroller()
  private ownerId: string = ''

  aboutToAppear(): void {
    this.ownerId = this.getOwnerId()
    this.loadList()
  }

  private getOwnerId(): string {
    if (AppStorage.Has('userPhone')) {
      const p = AppStorage.Get('userPhone') as string
      if (p && p.length > 0) return p
    }
    if (AppStorage.Has('user')) {
      const u = AppStorage.Get('user') as UserInfo
      if (u?.phone && u.phone.length > 0) {
        AppStorage.setOrCreate('userPhone', u.phone)
        return u.phone
      }
      if (u?.userId && u.userId.length > 0) return u.userId
    }
    if (AppStorage.Has('phone')) {
      const p2 = AppStorage.Get('phone') as string
      if (p2 && p2.length > 0) return p2
    }
    if (AppStorage.Has('userId')) {
      const id = AppStorage.Get('userId') as string
      if (id && id.length > 0) return id
    }
    return ''
  }

  private async loadList(): Promise<void> {
    const id = (this.token && this.token.length > 0) ? this.token : this.ownerId
    if (!id) {
      this.list = []
      return
    }

    this.loading = true
    try {
      const data: SimpleRoom[] = await getMyRoomsApi(id)
      this.list = Array.isArray(data) ? data : []
    } catch (e) {
      this.list = []
      prompt.showToast({ message: '加载失败' })
    } finally {
      this.loading = false
    }
  }

  private isOnline(status: string): boolean {
    const s = String(status ?? '').toLowerCase()
    return s === 'online' || s === 'published' || s === '1' || s === 'true'
  }

  private getFilteredList(): SimpleRoom[] {
    const arr: SimpleRoom[] = Array.isArray(this.list) ? this.list : []
    if (this.currentTab === 2) return arr
    if (this.currentTab === 0) return arr.filter((it: SimpleRoom) => this.isOnline(it.status))
    return arr.filter((it: SimpleRoom) => !this.isOnline(it.status))
  }

  private getLocationText(item: SimpleRoom): string {
    const loc = (safeStr(item.province) + ' ' + safeStr(item.city) + ' ' + safeStr(item.district)).trim()
    if (hasText(loc)) return loc
    return safeStr(item.address, '')
  }

  private updateStatusById(id: string, status: string): void {
    const next: SimpleRoom[] = this.list.map((r: SimpleRoom) => {
      if (r.id !== id) return r
      const n = new SimpleRoom()
      n.id = r.id
      n.title = r.title
      n.price = r.price
      n.address = r.address
      n.pendingOrderCount = r.pendingOrderCount
      n.imageList = r.imageList
      n.province = r.province
      n.city = r.city
      n.district = r.district
      n.status = status
      return n
    })
    this.list = next
  }

  private async onOffShelf(item: SimpleRoom): Promise<void> {
    try {
      await offShelfRoomApi(item.id)
      prompt.showToast({ message: '已下架' })
      this.updateStatusById(item.id, 'offline')
    } catch (e) {
      prompt.showToast({ message: '操作失败' })
    }
  }

  private async onOnShelf(item: SimpleRoom): Promise<void> {
    try {
      await onShelfRoomApi(item.id)
      prompt.showToast({ message: '已重新上架' })
      this.updateStatusById(item.id, 'online')
    } catch (e) {
      prompt.showToast({ message: '操作失败' })
    }
  }

  private goDetail(id: string): void {
    if (!id) return
    router.pushUrl({
      url: 'pages/rentRoom/RoomDetail', // 你详情页路由不同就在这里改
      params: { id }
    })
  }

  @Builder
  private RoomCard(item: SimpleRoom) {
    // ✅ 关键：只让“左侧内容区”可点击进详情，右侧按钮区不绑定进详情
    Row() {
      // 左侧内容区（可点）
      Row() {
        if (item.imageList.length > 0 && hasText(item.imageList[0])) {
          Image(item.imageList[0])
            .width(rvp(80)).height(rvp(80))
            .borderRadius(rvp(6)).objectFit(ImageFit.Cover)
            .margin({ right: rvp(10) })
        } else {
          Column() { Text('无图').fontSize(rvp(12)).fontColor('#999') }
          .width(rvp(80)).height(rvp(80))
          .borderRadius(rvp(6)).backgroundColor('#F3F4F6')
          .justifyContent(FlexAlign.Center)
          .margin({ right: rvp(10) })
        }

        Column() {
          Text(safeStr(item.title, '未命名房源'))
            .fontSize(rvp(15)).fontWeight(FontWeight.Bold).fontColor('#111')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%').margin({ bottom: rvp(6) })

          Text(this.getLocationText(item))
            .fontSize(rvp(12)).fontColor('#555').margin({ bottom: rvp(2) })
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${safeStr(item.price, '')} 元/月`)
            .fontSize(rvp(14)).fontWeight(FontWeight.Bold).fontColor('#FF7D00')
            .margin({ top: rvp(4) })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .onClick(() => this.goDetail(item.id)) // ✅ 点左侧进详情

      // 右侧按钮区（只做上下架）
      Column() {
        if (!this.isOnline(item.status)) {
          Button('重新上架')
            .fontSize(rvp(12)).height(rvp(26)).width(rvp(68))
            .padding(0).backgroundColor('#22c55e').fontColor('#fff')
            .onClick(() => this.onOnShelf(item))
        } else {
          Button('下架')
            .fontSize(rvp(12)).height(rvp(26)).width(rvp(56))
            .padding(0).backgroundColor('#ff4b4b').fontColor('#fff')
            .onClick(() => this.onOffShelf(item))
        }
      }
      .width(rvp(70))
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .margin({ left: rvp(4) })
    }
    .width('100%')
    .constraintSize({ minHeight: rvp(90) })
    .padding(rvp(12))
    .backgroundColor('#FFFFFF')
    .borderRadius(rvp(8))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private EmptyView(msg: string) {
    Column() {
      Text(msg).fontSize(rvp(14)).fontColor('#999').margin({ top: rvp(50) })
    }.width('100%')
  }

  @Builder
  private TabItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(rvp(15))
        .fontColor(this.currentTab === index ? '#2AB673' : '#666')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)

      if (this.currentTab === index) {
        Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
      } else {
        Blank().height(rvp(7))
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: rvp(6), bottom: rvp(6) }) // ✅ 热区大一点更好点
    .onClick(() => this.currentTab = index)
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(rvp(16)).fontColor('#333')
          .onClick(() => router.back())
          .layoutWeight(1)

        Text('我发布的')
          .fontSize(rvp(18)).fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(2)

        Blank().layoutWeight(1)
      }
      .width('100%')
      .padding({ left: rvp(16), right: rvp(16), top: this.topRectHeight + rvp(10), bottom: rvp(10) })
      .backgroundColor('#FFFFFF')

      // ✅ Tab 三个都能点
      Row() {
        this.TabItem('已上架', 0)
        this.TabItem('已下架', 1)
        this.TabItem('全部', 2)
      }
      .width('100%')
      .padding({ top: rvp(6), bottom: rvp(6) })
      .backgroundColor('#FFFFFF')

      Column() {
        if (this.loading) {
          Text('加载中...').fontSize(rvp(14)).fontColor('#999').margin({ top: rvp(50) })
        } else if (this.getFilteredList().length === 0) {
          this.EmptyView('暂无相关房源')
        } else {
          Scroll(this.scroller) {
            Column() {
              ForEach(
                this.getFilteredList(),
                (item: SimpleRoom) => {
                  Column() { this.RoomCard(item) }
                  .margin({ bottom: rvp(10) })
                },
                (item: SimpleRoom) => `${item.id}_${this.currentTab}_${item.status}`
              )
            }
            .width('100%')
            .padding({ left: rvp(12), right: rvp(12), top: rvp(4), bottom: rvp(20) })
          }
          .width('100%')
          .height('100%')
          .align(Alignment.TopStart)
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F7FA')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
