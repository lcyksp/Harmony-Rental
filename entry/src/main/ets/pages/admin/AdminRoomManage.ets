// entry/src/main/ets/pages/admin/AdminRoomManage.ets
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { NavBar } from '../../component/NavBar'
import { rvp } from '../../common/utils/DeviceScreen'
import { SERVER_URL } from '../../common/utils/Request'
import {
  AdminRoomListItem,
  adminListRoomsApi,
  adminDeleteRoomApi,
  adminSetRoomOnlineApi
} from '../../api/adminRooms'

interface GoEditParams {
  id: string
}

type RoomStatusTab = 'all' | 'online' | 'offline'

interface HousePictureSpace {
  spaceName?: string
  picList?: string[]
}
type HousePicture = HousePictureSpace[]

interface AdminRoomItemDynamic {
  coverUrl?: string
  imageUrl?: string
  housePicture?: string | HousePicture | null
}

@Entry
@Component
struct AdminRoomManage {
  @State keyword: string = ''
  @State status: RoomStatusTab = 'all'
  @State list: AdminRoomListItem[] = []
  @State loading: boolean = false
  @State refreshing: boolean = false

  private getToken(): string {
    return AppStorage.Has('token') ? (AppStorage.Get('token') as string) : ''
  }

  private getRole(): string {
    return AppStorage.Has('userRole') ? (AppStorage.Get('userRole') as string) : ''
  }

  aboutToAppear(): void {
    const role: string = this.getRole()
    if (role !== 'admin') {
      promptAction.showToast({ message: '无管理员权限', duration: 2000 })
      router.back()
      return
    }
    this.load()
  }

  private async load(): Promise<void> {
    const token: string = this.getToken()
    if (!this.refreshing) this.loading = true
    try {
      const data = await adminListRoomsApi(this.keyword, this.status, token)
      this.list = data.list as AdminRoomListItem[]
    } catch (e) {
      promptAction.showToast({ message: '加载失败', duration: 2000 })
    } finally {
      this.loading = false
      this.refreshing = false
    }
  }

  private async setOnline(id: string, online: boolean): Promise<void> {
    const token: string = this.getToken()
    try {
      await adminSetRoomOnlineApi(id, online, token)
      promptAction.showToast({ message: online ? '已上架' : '已下架', duration: 1500 })
      this.load()
    } catch (e) {
      promptAction.showToast({ message: '操作失败', duration: 2000 })
    }
  }

  private async removeRoom(id: string): Promise<void> {
    const token: string = this.getToken()
    try {
      await adminDeleteRoomApi(id, token)
      promptAction.showToast({ message: '已删除', duration: 1500 })
      this.load()
    } catch (e) {
      promptAction.showToast({ message: '删除失败', duration: 2000 })
    }
  }

  private goEdit(id: string): void {
    const p: GoEditParams = { id: id }
    router.pushUrl({ url: 'pages/admin/AdminRoomJsonEdit', params: p })
  }

  private isOnline(s: string): boolean {
    return (s || '').toLowerCase() === 'online'
  }

  private statusText(s: string): string {
    return this.isOnline(s) ? '上架中' : '已下架'
  }

  private chipText(tab: RoomStatusTab): string {
    if (tab === 'all') return '全部'
    if (tab === 'online') return '上架'
    return '下架'
  }

  private chipActive(tab: RoomStatusTab): boolean {
    return this.status === tab
  }

  private setTab(tab: RoomStatusTab): void {
    this.status = tab
    this.load()
  }

  // ---------------- 图片 URL：不写死 IP，复用 Request.ts 的 SERVER_URL ----------------
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

  private pickFirstPicFromHousePicture(hp: HousePicture): string {
    if (hp.length === 0) return ''
    const first: HousePictureSpace = hp[0]
    const list: string[] | undefined = first.picList
    if (!list || list.length === 0) return ''
    return this.joinUrl(list[0])
  }

  // coverUrl > imageUrl > housePicture(array) > housePicture(string)
  private getCover(item: AdminRoomListItem): string {
    const dyn: AdminRoomItemDynamic = item as AdminRoomItemDynamic

    if (dyn.coverUrl && dyn.coverUrl.length > 0) return this.joinUrl(dyn.coverUrl)
    if (dyn.imageUrl && dyn.imageUrl.length > 0) return this.joinUrl(dyn.imageUrl)

    const hp: string | HousePicture | null | undefined = dyn.housePicture
    if (hp instanceof Array) {
      return this.pickFirstPicFromHousePicture(hp as HousePicture)
    }
    if (typeof hp === 'string' && hp.length > 0) return this.joinUrl(hp)

    return ''
  }

  // ---------------- “华丽谢幕”UI 组件 ----------------

  @Builder
  private LuxuryHeader() {
    // 氛围层：柔和“光斑”
    Stack() {
      // 背景底色
      Column().width('100%').height(rvp(160)).backgroundColor('#F6F7FB')

      // 左上光斑
      Column()
        .width(rvp(220)).height(rvp(220))
        .borderRadius(rvp(999))
        .backgroundColor('#2F6BFF')
        .opacity(0.10)
        .position({ x: rvp(-80), y: rvp(-120) })

      // 右上光斑
      Column()
        .width(rvp(240)).height(rvp(240))
        .borderRadius(rvp(999))
        .backgroundColor('#45B97C')
        .opacity(0.10)
        .position({ x: rvp(220), y: rvp(-140) })

      // 内容层
      Column({ space: rvp(10) }) {
        // 你已有 NavBar（你这版 UI 已经很稳），保留
        NavBar({ title: '房源管理' })

        Row({ space: rvp(10) }) {
          // 搜索胶囊
          Row({ space: rvp(8) }) {
            TextInput({ text: this.keyword, placeholder: '搜索标题 / 地址 / ID' })
              .layoutWeight(1)
              .backgroundColor('rgba(0,0,0,0)')
              .fontSize(rvp(14))
              .onChange((v: string) => { this.keyword = v })

            Text('搜索')
              .fontSize(rvp(13))
              .fontColor('#FFFFFF')
              .padding({ left: rvp(14), right: rvp(14), top: rvp(8), bottom: rvp(8) })
              .backgroundColor('#2F6BFF')
              .borderRadius(rvp(999))
              .onClick(() => this.load())
          }
          .padding({ left: rvp(14), right: rvp(10), top: rvp(10), bottom: rvp(10) })
          .backgroundColor('#FFFFFF')
          .borderRadius(rvp(18))
          .shadow({ radius: rvp(14), color: '#14000000', offsetX: 0, offsetY: rvp(8) })
          .layoutWeight(1)

          // 刷新按钮
          Text(this.loading ? '...' : '刷新')
            .fontSize(rvp(13))
            .fontColor('#2F6BFF')
            .padding({ left: rvp(16), right: rvp(16), top: rvp(12), bottom: rvp(12) })
            .backgroundColor('#FFFFFF')
            .borderRadius(rvp(18))
            .shadow({ radius: rvp(14), color: '#14000000', offsetX: 0, offsetY: rvp(8) })
            .onClick(() => this.load())
        }
        .padding({ left: rvp(12), right: rvp(12) })

        // 分段筛选（更高级：胶囊分段）
        Row({ space: rvp(6) }) {
          ForEach(['all', 'online', 'offline'] as RoomStatusTab[], (t: RoomStatusTab) => {
            Text(this.chipText(t))
              .fontSize(rvp(13))
              .fontColor(this.chipActive(t) ? '#FFFFFF' : '#222222')
              .padding({ left: rvp(18), right: rvp(18), top: rvp(10), bottom: rvp(10) })
              .backgroundColor(this.chipActive(t) ? '#2F6BFF' : '#FFFFFF')
              .borderRadius(rvp(999))
              .shadow(this.chipActive(t)
                ? { radius: rvp(10), color: '#1A2F6BFF', offsetX: 0, offsetY: rvp(6) }
                : { radius: rvp(10), color: '#0C000000', offsetX: 0, offsetY: rvp(4) }
              )
              .onClick(() => this.setTab(t))
          })
        }
        .padding({ left: rvp(12), right: rvp(12) })
      }
      .padding({ top: rvp(10) })
    }
    .width('100%')
    .height(rvp(200))
  }

  @Builder
  private EmptyState() {
    Column({ space: rvp(8) }) {
      Text('暂无房源')
        .fontSize(rvp(16))
        .fontColor('#222')
        .fontWeight(FontWeight.Medium)

      Text('换个关键词试试，或者点击“刷新”重新加载')
        .fontSize(rvp(12))
        .fontColor('#888')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private SkeletonList() {
    // 轻量骨架屏（不依赖任何库）
    Column() {
      ForEach([0, 1, 2, 3, 4], (i: number) => {
        Row({ space: rvp(12) }) {
          Column()
            .width(rvp(92)).height(rvp(72))
            .borderRadius(rvp(12))
            .backgroundColor('#ECEFF4')

          Column({ space: rvp(8) }) {
            Column().width('75%').height(rvp(12)).borderRadius(rvp(6)).backgroundColor('#ECEFF4')
            Column().width('60%').height(rvp(10)).borderRadius(rvp(6)).backgroundColor('#ECEFF4')
            Column().width('40%').height(rvp(10)).borderRadius(rvp(6)).backgroundColor('#ECEFF4')
          }.layoutWeight(1)
        }
        .padding(rvp(12))
        .backgroundColor('#FFFFFF')
        .borderRadius(rvp(16))
        .shadow({ radius: rvp(14), color: '#12000000', offsetX: 0, offsetY: rvp(8) })
        .margin({ left: rvp(12), right: rvp(12), top: rvp(10) })
      })
      Blank().height(rvp(18))
    }
  }

  build() {
    Column() {
      // 顶部“华丽”头部
      this.LuxuryHeader()

      // 主体：支持下拉刷新
      Refresh({ refreshing: this.refreshing, offset: rvp(90), friction: 0.75 }) {
        Column() {
          if (this.loading && !this.refreshing) {
            this.SkeletonList()
          } else if (this.list.length === 0) {
            this.EmptyState()
          } else {
            List() {
              ForEach(this.list, (item: AdminRoomListItem) => {
                ListItem() {
                  Column() {
                    Row({ space: rvp(12) }) {

                      // 这里不写 const/let，避免 “Only UI component syntax...”
                      if (this.getCover(item).length > 0) {
                        Image(this.getCover(item))
                          .width(rvp(92))
                          .height(rvp(72))
                          .borderRadius(rvp(14))
                          .objectFit(ImageFit.Cover)
                          .backgroundColor('#F1F3F6')
                      } else {
                        Column() { Text('暂无图').fontSize(rvp(12)).fontColor('#888') }
                        .width(rvp(92))
                        .height(rvp(72))
                        .borderRadius(rvp(14))
                        .backgroundColor('#F1F3F6')
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                      }

                      Column({ space: rvp(6) }) {
                        Row() {
                          Text(item.houseTitle)
                            .fontSize(rvp(15))
                            .fontWeight(FontWeight.Medium)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)

                          // 状态徽章更“高级”
                          Text(this.statusText(item.status))
                            .fontSize(rvp(11))
                            .fontColor(this.isOnline(item.status) ? '#0B8F4D' : '#8A5A00')
                            .padding({ left: rvp(10), right: rvp(10), top: rvp(5), bottom: rvp(5) })
                            .backgroundColor(this.isOnline(item.status) ? '#E7F7EE' : '#FFF2D8')
                            .borderRadius(rvp(999))
                        }

                        Text(`${item.rentPriceListing}${item.rentPriceUnit}  ·  ${item.address}`)
                          .fontSize(rvp(12))
                          .fontColor('#666')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(`ID: ${item.id}`)
                          .fontSize(rvp(11))
                          .fontColor('#999')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })

                        // 操作按钮：更精致的小胶囊
                        Row({ space: rvp(8) }) {
                          Text('编辑')
                            .fontSize(rvp(12))
                            .fontColor('#2F6BFF')
                            .padding({ left: rvp(12), right: rvp(12), top: rvp(7), bottom: rvp(7) })
                            .backgroundColor('#EEF3FF')
                            .borderRadius(rvp(999))
                            .onClick(() => this.goEdit(item.id))

                          Text(this.isOnline(item.status) ? '下架' : '上架')
                            .fontSize(rvp(12))
                            .fontColor(this.isOnline(item.status) ? '#8A5A00' : '#0B8F4D')
                            .padding({ left: rvp(12), right: rvp(12), top: rvp(7), bottom: rvp(7) })
                            .backgroundColor(this.isOnline(item.status) ? '#FFF2D8' : '#E7F7EE')
                            .borderRadius(rvp(999))
                            .onClick(() => this.setOnline(item.id, !this.isOnline(item.status)))

                          Text('删除')
                            .fontSize(rvp(12))
                            .fontColor('#E5484D')
                            .padding({ left: rvp(12), right: rvp(12), top: rvp(7), bottom: rvp(7) })
                            .backgroundColor('#FDECEE')
                            .borderRadius(rvp(999))
                            .onClick(() => this.removeRoom(item.id))
                        }
                      }
                      .layoutWeight(1)
                    }
                    .padding(rvp(12))
                  }
                  .backgroundColor('#FFFFFF')
                  .borderRadius(rvp(18))
                  .shadow({ radius: rvp(16), color: '#12000000', offsetX: 0, offsetY: rvp(10) })
                  .margin({ left: rvp(12), right: rvp(12), top: rvp(10) })
                }
              }, (it: AdminRoomListItem) => it.id)
            }
            Blank().height(rvp(18))
          }
        }
        .width('100%')
        .backgroundColor('#F6F7FB')
      }
      .onStateChange((state: RefreshStatus) => {
        if (state === RefreshStatus.Refresh) {
          this.refreshing = true
          this.load()
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }
}
