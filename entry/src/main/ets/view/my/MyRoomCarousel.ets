// entry/src/main/ets/view/my/MyRoomCarousel.ets

import promptAction from '@ohos.promptAction'
import { rvp } from '../../common/utils/DeviceScreen'

// 引入原有的 Room 相关
import {
  SimpleRoom,
  getMyPublishedRoomsApi,
  deleteRoomApi
} from '../../api/room'

// ✅ 新增：引入 Rent 相关接口和类型
import {
  RentContractItem,
  getMyActiveRentApi,
  applyQuitApi
} from '../../api/rent'

interface TabItem {
  id: number
  label: string
}

const TAB_ITEMS: TabItem[] = [
  { id: 0, label: '我租到的' },
  { id: 1, label: '我发布的' }
]

// ✅ 辅助函数：获取当前用户手机号 (和 MyRentList 保持一致)
interface UserInfo {
  phone?: string;
  userId?: string;
}
function getCurrentUserPhone(): string {
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
  if (AppStorage.Has('userId')) {
    const id = AppStorage.Get('userId') as string
    if (id && id.length > 0) return id
  }
  return ''
}

// ✅ 辅助函数：处理空字符串
function safeStr(v: string | undefined | null, fallback: string = ''): string {
  return typeof v === 'string' ? v : fallback;
}
function hasText(v: string | undefined | null): boolean {
  return typeof v === 'string' && v.length > 0;
}

@Component
export struct MyRoomCarousel {
  @StorageProp('token') token: string = ''
  @StorageProp('needReloadMyRooms') needReload: boolean = false

  @State currentIndex: number = 0

  // ✅ 修改：rentedList 改为 RentContractItem 类型
  @State rentedList: RentContractItem[] = []
  @State publishedList: SimpleRoom[] = []

  @State loading: boolean = false
  @State refreshing: boolean = false

  private userPhone: string = ''

  aboutToAppear() {
    this.userPhone = getCurrentUserPhone(); // 获取手机号

    if (this.needReload) {
      this.needReload = false
      this.loadData()
    } else {
      this.loadData()
    }
  }

  private async loadData() {
    if (!this.token && !this.userPhone) {
      this.refreshing = false
      return
    }

    this.loading = !this.refreshing
    try {
      // ✅ 1. 加载“我租到的” (使用 getMyActiveRentApi)
      if (this.userPhone) {
        this.rentedList = await getMyActiveRentApi(this.userPhone)
      } else {
        this.rentedList = []
      }

      // 2. 加载“我发布的” (保持原有逻辑)
      if (this.token) {
        this.publishedList = await getMyPublishedRoomsApi(this.token)
      }

    } catch (err) {
      console.error('[loadData] error', JSON.stringify(err))
      promptAction.showToast({ message: '加载失败，请稍后再试' })
    } finally {
      this.loading = false
      this.refreshing = false
    }
  }

  // ✅ 新增：退租逻辑
  private async onQuit(item: RentContractItem) {
    try {
      // 这里的第二个参数是 reason，暂时传空字符串
      await applyQuitApi(item.id, this.userPhone, '')
      promptAction.showToast({ message: '已提交退租申请' })
      // 刷新列表
      this.loadData()
    } catch (e) {
      promptAction.showToast({ message: '操作失败' })
    }
  }

  private async removeRoom(id: string) {
    try {
      await deleteRoomApi(id)
      this.publishedList = this.publishedList.filter(item => item.id !== id)
      AppStorage.set('needReloadMyRooms', true)
      promptAction.showToast({ message: '房源已下架' })
    } catch (err) {
      promptAction.showToast({ message: '删除失败，请稍后再试' })
    }
  }

  // ---------------- UI 渲染 ----------------

  @Builder
  TabHeader() {
    Row({ space: rvp(30) }) {
      ForEach(TAB_ITEMS, (item: TabItem) => {
        Column() {
          Text(item.label)
            .fontSize(rvp(14))
            .fontColor(this.currentIndex === item.id ? '#222' : '#999')

          if (this.currentIndex === item.id) {
            Blank().width(rvp(24)).height(2).backgroundColor('#45B97C').margin({ top: rvp(4) })
          } else {
            Blank().height(2).margin({ top: rvp(4) })
          }
        }
        .onClick(() => (this.currentIndex = item.id))
      }, (item: TabItem) => item.id.toString())
    }
    .padding({ left: rvp(16), right: rvp(16), top: rvp(8), bottom: rvp(8) })
  }

  // ✅ 新增：专门渲染“我租到的”卡片 (带退租按钮)
  @Builder
  RentedListContent() {
    if (this.rentedList.length === 0) {
      this.EmptyContent('你还没有正在租住的房源，去首页看看喜欢的房子吧～')
    } else {
      Scroll() {
        Column() {
          ForEach(this.rentedList, (item: RentContractItem) => {
            Row() {
              // 图片
              if (hasText(item.coverUrl)) {
                Image(safeStr(item.coverUrl))
                  .width(rvp(80)).height(rvp(80))
                  .borderRadius(rvp(6)).objectFit(ImageFit.Cover)
                  .margin({ right: rvp(10) })
              } else {
                Column() { Text('无图').fontSize(rvp(12)).fontColor('#999') }
                .width(rvp(80)).height(rvp(80))
                .borderRadius(rvp(6)).backgroundColor('#F3F4F6')
                .justifyContent(FlexAlign.Center).margin({ right: rvp(10) })
              }

              // 中间文本
              Column() {
                Text(safeStr(item.houseTitle, '房源名称'))
                  .fontSize(rvp(15)).fontWeight(FontWeight.Bold).fontColor('#111')
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%').margin({ bottom: rvp(6) })

                Text(`房东：${safeStr(item.landlord_phone, '-')}`)
                  .fontSize(rvp(12)).fontColor('#555').margin({ bottom: rvp(2) })

                if (hasText(item.remark)) {
                  Text(`备注：${safeStr(item.remark)}`)
                    .fontSize(rvp(12)).fontColor('#999')
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 右侧退租按钮
              Column() {
                Button('退租')
                  .fontSize(rvp(12)).height(rvp(26)).width(rvp(56))
                  .padding(0).backgroundColor('#ff4b4b').fontColor('#fff')
                  .onClick(() => this.onQuit(item))
              }
              .width(rvp(60)).alignItems(HorizontalAlign.End).margin({ left: rvp(4) })
            }
            .width('100%')
            .padding(rvp(12))
            .backgroundColor('#FFF')
            .borderRadius(rvp(12))
            .margin({ top: rvp(8) })
            .alignItems(VerticalAlign.Top)
          }, (item: RentContractItem) => item.id.toString())

          Blank().height(rvp(8))
        }
      }
      .width('100%').height('auto')
    }
  }

  // ✅ 原有：渲染“我发布的”卡片 (带删除按钮)
  @Builder
  PublishedListContent() {
    if (this.publishedList.length === 0) {
      this.EmptyContent('你还没有上架房源，去发布一套试试吧～')
    } else {
      Scroll() {
        Column() {
          ForEach(this.publishedList, (item: SimpleRoom) => {
            Column() {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(rvp(15)).fontWeight(FontWeight.Medium).fontColor('#222')
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(item.address)
                    .fontSize(rvp(12)).fontColor('#999').margin({ top: rvp(4) })
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${item.price} 元/月`)
                    .fontSize(rvp(16)).fontWeight(FontWeight.Bold).fontColor('#FF7D00')
                    .margin({ top: rvp(8) })
                }
                .layoutWeight(1)

                Text('删除')
                  .fontSize(rvp(13)).fontColor('#E24A4A').margin({ left: rvp(12) })
                  .onClick(() => this.removeRoom(item.id))
              }
            }
            .width('100%')
            .padding({ left: rvp(16), right: rvp(16), top: rvp(12), bottom: rvp(12) })
            .backgroundColor('#FFF')
            .borderRadius(rvp(12))
            .margin({ top: rvp(8) })
          }, (item: SimpleRoom) => item.id)
          Blank().height(rvp(8))
        }
      }
      .width('100%').height('auto')
    }
  }

  @Builder
  EmptyContent(text: string) {
    Column() {
      Text(text)
        .fontSize(rvp(14)).fontColor('#999')
        .margin({ top: rvp(32), bottom: rvp(32) })
    }
    .width('100%').alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Refresh({ refreshing: this.refreshing, offset: rvp(80), friction: 0.7 }) {
        Column() {
          Column() {
            this.TabHeader()

            // ✅ 根据 index 切换不同的渲染内容
            if (this.loading && !this.refreshing) {
              Column() { Text('加载中…').fontSize(rvp(14)).fontColor('#777').margin({ top: rvp(16) }) }
              .width('100%').alignItems(HorizontalAlign.Center)
            } else {
              if (this.currentIndex === 0) {
                this.RentedListContent() // 渲染带退租按钮的租房列表
              } else {
                this.PublishedListContent() // 渲染带删除按钮的发布列表
              }
            }
          }
          .backgroundColor('#F7F7F7')
          .borderRadius(rvp(16))
          .padding({ top: rvp(12), bottom: rvp(12), left: rvp(8), right: rvp(8) })
        }
        .width('100%')
      }
      .onStateChange((state: RefreshStatus) => {
        if (state === RefreshStatus.Refresh) {
          this.refreshing = true
          this.loadData()
        }
      })
    }
    .width('100%')
  }
}