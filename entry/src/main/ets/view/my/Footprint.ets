// entry/src/main/ets/view/my/Footprint.ets
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { rvp } from '../../common/utils/DeviceScreen'
import {
  FootprintItem,
  getFootprintListApi,
  removeFootprintApi,
  clearFootprintApi
} from '../../api/footprint'

@Entry
@Component
struct Footprint {
  @State list: FootprintItem[] = []
  @State loading: boolean = false

  private userId: string = ''

  aboutToAppear(): void {
    this.userId = this.getUserId()
    this.loadList()
  }

  // --------- 基础工具函数，不在 UI 里声明变量 ---------
  private getUserId(): string {
    if (AppStorage.Has('userPhone')) {
      const v = AppStorage.Get('userPhone') as string
      if (typeof v === 'string' && v.length > 0) return v
    }
    if (AppStorage.Has('phone')) {
      const v2 = AppStorage.Get('phone') as string
      if (typeof v2 === 'string' && v2.length > 0) return v2
    }
    if (AppStorage.Has('userId')) {
      const v3 = AppStorage.Get('userId') as string
      if (typeof v3 === 'string' && v3.length > 0) return v3
    }
    return ''
  }

  private async loadList(): Promise<void> {
    if (!this.userId) {
      this.list = []
      return
    }
    this.loading = true
    try {
      const arr: FootprintItem[] = await getFootprintListApi(this.userId, 100)
      this.list = Array.isArray(arr) ? arr : []
    } catch (e) {
      this.list = []
      promptAction.showToast({ message: '加载失败', duration: 2000 })
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

  private getTitle(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.title, '房源标题')
  }

  private getCover(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.coverUrl, '')
  }

  private getPrice(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.priceText, '')
  }

  private getAddress(item: FootprintItem): string {
    return this.safeStr(item.snapshot?.address, '')
  }

  private onClickItem(item: FootprintItem): void {
    const id = this.safeStr(item.houseId, '')
    if (!id) {
      return
    }
    router.pushUrl({
      url: 'pages/rentRoom/RoomDetail',
      params: { id }
    })
  }

  private async onClear(): Promise<void> {
    if (!this.userId) return
    try {
      await clearFootprintApi(this.userId)
      this.list = []
      promptAction.showToast({ message: '已清空足迹', duration: 1500 })
    } catch (e) {
      promptAction.showToast({ message: '操作失败', duration: 2000 })
    }
  }

  private async onRemove(item: FootprintItem): Promise<void> {
    if (!this.userId || !item.houseId) return
    try {
      await removeFootprintApi(this.userId, String(item.houseId))
      this.loadList()
    } catch (e) {
      promptAction.showToast({ message: '操作失败', duration: 2000 })
    }
  }

  // --------- UI 片段：空状态 / 列表 Item ---------
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
        // 左侧封面图
        if (this.hasText(this.getCover(item))) {
          Image(this.getCover(item))
            .width(rvp(80))
            .height(rvp(80))
            .borderRadius(rvp(8))
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('无图')
              .fontSize(rvp(12))
              .fontColor('#999999')
          }
          .width(rvp(80))
          .height(rvp(80))
          .borderRadius(rvp(8))
          .backgroundColor('#F3F4F6')
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: rvp(6) }) {
          // 标题
          Text(this.getTitle(item))
            .fontSize(rvp(14))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 价格
          if (this.hasText(this.getPrice(item))) {
            Text(this.getPrice(item))
              .fontSize(rvp(13))
              .fontColor('#FF6A00')
          }

          // 地址
          if (this.hasText(this.getAddress(item))) {
            Text(this.getAddress(item))
              .fontSize(rvp(12))
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          // 浏览时间（小字）
          if (item.viewedAt) {
            Text(`浏览时间：${this.formatTime(item.viewedAt)}`)
              .fontSize(rvp(11))
              .fontColor('#BBBBBB')
          }
        }
        .margin({ left: rvp(12) })

        Blank().layoutWeight(1)

        // 右边小箭头 & 删除
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

  // --------- 整页 UI ---------
  build() {
    Column() {
      // 顶部导航栏（对齐 MyWantSee UI）
      Row() {
        // 左：返回
        Text('< 返回')
          .fontSize(rvp(16))
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1)

        // 中：标题
        Text('浏览足迹')
          .fontSize(rvp(20))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        // 右：清空
        Text('清空')
          .fontSize(rvp(14))
          .fontColor('#FF4B4B')
          .textAlign(TextAlign.End)
          .onClick(() => this.onClear())
          .layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: rvp(16),
        right: rvp(16),
        top: rvp(48),  // 和 MyWantSee 保持一致
        bottom: rvp(8)
      })
      .backgroundColor('#8FE1A2')

      // 列表区域
      if (this.loading) {
        this.LoadingView()
      } else if (!this.list || this.list.length === 0) {
        this.EmptyView()
      } else {
        List() {
          ForEach(
            this.list,
            (item: FootprintItem) => {
              this.FootprintListItem(item)
            },
            (item: FootprintItem) => this.safeStr(item.houseId, '')
          )
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
