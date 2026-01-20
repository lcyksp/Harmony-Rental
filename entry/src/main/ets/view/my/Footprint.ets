// entry/src/main/ets/view/my/Footprint.ets
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { rvp } from '../../common/utils/DeviceScreen'
import { SERVER_URL } from '../../common/utils/Request'
import {
  FootprintItem,
  FootprintAuth,
  getFootprintListApi,
  removeFootprintApi,
  clearFootprintApi
} from '../../api/footprint'

interface UserInfo {
  id?: number | string
  userId?: string
  phone?: string
}

@Entry
@Component
struct Footprint {
  @State list: FootprintItem[] = []
  @State loading: boolean = false

  private auth: FootprintAuth = {}

  aboutToAppear(): void {
    this.auth = this.getAuthPair()
    this.loadList()
  }

  //优先从 AppStorage.user 取 phone + id，其次兼容旧字段
  private getAuthPair(): FootprintAuth {
    let phone: string = ''
    let userId: string = ''

    if (AppStorage.Has('user')) {
      const u: UserInfo = AppStorage.Get('user') as UserInfo
      if (u && u.phone && u.phone.length > 0) phone = String(u.phone)
      if (u && u.id !== undefined && u.id !== null) userId = String(u.id)
      if (!userId && u && u.userId && u.userId.length > 0) userId = u.userId
    }

    if (!phone && AppStorage.Has('userPhone')) {
      const v: string = AppStorage.Get('userPhone') as string
      if (typeof v === 'string' && v.length > 0) phone = v
    }
    if (!phone && AppStorage.Has('phone')) {
      const v2: string = AppStorage.Get('phone') as string
      if (typeof v2 === 'string' && v2.length > 0) phone = v2
    }
    if (!userId && AppStorage.Has('userId')) {
      const v3: string = AppStorage.Get('userId') as string
      if (typeof v3 === 'string' && v3.length > 0) userId = v3
    }

    const a: FootprintAuth = {}
    if (phone.length > 0) a.phone = phone
    if (userId.length > 0) a.userId = userId
    return a
  }

  private hasAuth(): boolean {
    return !!(this.auth.phone && this.auth.phone.length > 0) || !!(this.auth.userId && this.auth.userId.length > 0)
  }

  private async loadList(): Promise<void> {
    if (!this.hasAuth()) {
      this.list = []
      return
    }
    this.loading = true
    try {
      const arr: FootprintItem[] = await getFootprintListApi(this.auth, 100)
      this.list = (arr instanceof Array) ? arr : []
    } catch {
      this.list = []
      promptAction.showToast({ message: '足迹接口请求失败（看控制台📥日志）', duration: 2000 })
    } finally {
      this.loading = false
    }
  }

  private pad2(n: number): string {
    return n < 10 ? ('0' + n) : String(n)
  }

  private formatTime(ts: number): string {
    if (!ts) return ''
    const d = new Date(ts)
    const y = d.getFullYear()
    const m = this.pad2(d.getMonth() + 1)
    const day = this.pad2(d.getDate())
    const hh = this.pad2(d.getHours())
    const mm = this.pad2(d.getMinutes())
    return `${y}-${m}-${day} ${hh}:${mm}`
  }

  private safeStr(v: string | undefined | null, fallback: string = ''): string {
    return typeof v === 'string' ? v : fallback
  }

  private hasText(v: string | undefined | null): boolean {
    return typeof v === 'string' && v.length > 0
  }

  //图片支持相对路径：/public/xxx.jpg
  private joinUrl(path: string): string {
    const p: string = (path || '').trim()
    if (p.length === 0) return ''
    if (p.startsWith('http://') || p.startsWith('https://')) return p

    const base: string = (SERVER_URL || '').trim()
    if (base.length === 0) return p
    const b: string = base.endsWith('/') ? base.slice(0, base.length - 1) : base
    const pp: string = p.startsWith('/') ? p : `/${p}`
    return `${b}${pp}`
  }

  private getTitle(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.title, '房源标题')
  }

  private getCover(item: FootprintItem): string {
    return this.joinUrl(this.safeStr(item.snapshot?.coverUrl, ''))
  }

  private getPrice(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.priceText, '')
  }

  private getAddress(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.address, '')
  }

  //router 可能 throw：包 try/catch 解决 ArkTSCheck
  private onClickItem(item: FootprintItem): void {
    const id: string = this.safeStr(item.houseId, '')
    if (!id) return
    try {
      router.pushUrl({ url: 'pages/rentRoom/RoomDetail', params: { id } })
    } catch {
      promptAction.showToast({ message: '跳转失败', duration: 2000 })
    }
  }

  private async onClear(): Promise<void> {
    if (!this.hasAuth()) return
    try {
      await clearFootprintApi(this.auth)
      this.list = []
      promptAction.showToast({ message: '已清空足迹', duration: 1500 })
    } catch {
      promptAction.showToast({ message: '操作失败（看控制台📥日志）', duration: 2000 })
    }
  }

  private async onRemove(item: FootprintItem): Promise<void> {
    if (!this.hasAuth() || !item.houseId) return
    try {
      await removeFootprintApi(this.auth, String(item.houseId))
      this.loadList()
    } catch {
      promptAction.showToast({ message: '操作失败（看控制台📥日志）', duration: 2000 })
    }
  }

  @Builder
  private EmptyView() {
    Column() {
      Text('你还没有浏览过房子~')
        .fontSize(rvp(14))
        .fontColor('#999999')
        .margin({ bottom: rvp(4) })
      Text('去首页看看喜欢的房子吧')
        .fontSize(rvp(12))
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private LoadingView() {
    Column() {
      Text('加载中...')
        .fontSize(rvp(14))
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private FootprintListItem(item: FootprintItem) {
    ListItem() {
      Row() {
        if (this.hasText(this.getCover(item))) {
          Image(this.getCover(item))
            .width(rvp(80))
            .height(rvp(80))
            .borderRadius(rvp(8))
            .objectFit(ImageFit.Cover)
        } else {
          Column() { Text('无图').fontSize(rvp(12)).fontColor('#999999') }
          .width(rvp(80))
          .height(rvp(80))
          .borderRadius(rvp(8))
          .backgroundColor('#F3F4F6')
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: rvp(6) }) {
          Text(this.getTitle(item))
            .fontSize(rvp(14))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.hasText(this.getPrice(item))) {
            Text(this.getPrice(item))
              .fontSize(rvp(13))
              .fontColor('#FF6A00')
          }

          if (this.hasText(this.getAddress(item))) {
            Text(this.getAddress(item))
              .fontSize(rvp(12))
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          if (item.viewedAt) {
            Text(`浏览时间：${this.formatTime(item.viewedAt)}`)
              .fontSize(rvp(11))
              .fontColor('#BBBBBB')
          }
        }
        .margin({ left: rvp(12) })

        Blank().layoutWeight(1)

        Column({ space: rvp(8) }) {
          Text('>')
            .fontSize(rvp(12))
            .fontColor('#CCCCCC')

          Text('删除')
            .fontSize(rvp(11))
            .fontColor('#FF4B4B')
            .onClick(() => this.onRemove(item))
        }
      }
      .padding({ left: rvp(16), right: rvp(16), top: rvp(10), bottom: rvp(10) })
      .onClick(() => this.onClickItem(item))
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(rvp(16))
          .fontColor('#333333')
          .onClick(() => {
            try { router.back() } catch {}
          })
          .layoutWeight(1)

        Text('浏览足迹')
          .fontSize(rvp(20))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Text('清空')
          .fontSize(rvp(14))
          .fontColor('#FF4B4B')
          .textAlign(TextAlign.End)
          .onClick(() => this.onClear())
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: rvp(16), right: rvp(16), top: rvp(48), bottom: rvp(8) })
      .backgroundColor('#8FE1A2')

      if (this.loading) {
        this.LoadingView()
      } else if (!this.list || this.list.length === 0) {
        this.EmptyView()
      } else {
        //ArkTSCheck: List 建议设置 width/height
        Column() {
          List() {
            ForEach(
              this.list,
              (item: FootprintItem) => { this.FootprintListItem(item) },
              (item: FootprintItem) => this.safeStr(item.houseId, '')
            )
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}
