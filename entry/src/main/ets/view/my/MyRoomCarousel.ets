// entry/src/main/ets/view/my/MyRoomCarousel.ets

import promptAction from '@ohos.promptAction'
import { rvp } from '../../common/utils/DeviceScreen'

import {
  SimpleRoom,
  getMyPublishedRoomsApi,
  getMyRentedRoomsApi,
  deleteRoomApi
} from '../../api/room'

interface TabItem {
  id: number
  label: string
}

const TAB_ITEMS: TabItem[] = [
  { id: 0, label: '我租到的' },
  { id: 1, label: '我发布的' }
]

@Component
export struct MyRoomCarousel {
  @StorageProp('token') token: string = ''

  // ⭐ 后端变动全局标记（不使用 @Watch，采用生命周期刷新）
  @StorageProp('needReloadMyRooms') needReload: boolean = false

  @State currentIndex: number = 0
  @State rentedList: SimpleRoom[] = []
  @State publishedList: SimpleRoom[] = []
  @State loading: boolean = false
  @State refreshing: boolean = false

  // ⭐ 页面每次“显示”都会执行 → 解决发布/删除后不刷新的核心
  aboutToAppear() {
    console.log('[MyRoomCarousel] appear, token=', this.token)

    // 若全局要求刷新，则刷新一次
    if (this.needReload) {
      console.log('[MyRoomCarousel] needReload = true → refresh list')
      this.needReload = false
      this.loadData()
    } else {
      // 正常进入页面，也刷新一次
      this.loadData()
    }
  }

  private async loadData() {
    if (!this.token || this.token.trim().length === 0) {
      this.refreshing = false
      return
    }

    console.log('[loadData] token used =', this.token);

    this.loading = !this.refreshing
    try {
      this.rentedList = await getMyRentedRoomsApi(this.token)
      this.publishedList = await getMyPublishedRoomsApi(this.token)

      console.log('[loadData] rented =', this.rentedList.length.toString())
      console.log('[loadData] published =', this.publishedList.length.toString())
    } catch (err) {
      console.error('[loadData] error', JSON.stringify(err))
      promptAction.showToast({ message: '加载房源失败，请稍后再试' })
    } finally {
      this.loading = false
      this.refreshing = false
    }
  }

  private async removeRoom(id: string) {
    try {
      await deleteRoomApi(id)

      // 立即本地删除
      this.publishedList = this.publishedList.filter(item => item.id !== id)

      // ⭐ 通知页面：数据已变更，下次显示时必须刷新
      AppStorage.set('needReloadMyRooms', true)

      promptAction.showToast({ message: '房源已下架' })
    } catch (err) {
      console.error('[delete] error', JSON.stringify(err))
      promptAction.showToast({ message: '删除失败，请稍后再试' })
    }
  }

  // ---------------- UI 渲染 ----------------

  @Builder
  TabHeader() {
    Row({ space: rvp(30) }) {
      ForEach(
        TAB_ITEMS,
        (item: TabItem) => {
          Column() {
            Text(item.label)
              .fontSize(rvp(14))
              .fontColor(this.currentIndex === item.id ? '#222' : '#999')

            if (this.currentIndex === item.id) {
              Blank()
                .width(rvp(24))
                .height(2)
                .backgroundColor('#45B97C')
                .margin({ top: rvp(4) })
            } else {
              Blank().height(2).margin({ top: rvp(4) })
            }
          }
          .onClick(() => (this.currentIndex = item.id))
        },
        (item: TabItem) => item.id.toString()
      )
    }
    .padding({ left: rvp(16), right: rvp(16), top: rvp(8), bottom: rvp(8) })
  }

  @Builder
  ListContent(list: SimpleRoom[], emptyText: string, allowDelete: boolean) {
    if (this.loading && !this.refreshing) {
      Column() {
        Text('加载中…')
          .fontSize(rvp(14))
          .fontColor('#777')
          .margin({ top: rvp(16), bottom: rvp(16) })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    } else if (list.length === 0) {
      Column() {
        Text(emptyText)
          .fontSize(rvp(14))
          .fontColor('#999')
          .margin({ top: rvp(32), bottom: rvp(32) })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    } else {
      Scroll() {
        Column() {
          ForEach(
            list,
            (item: SimpleRoom) => {
              Column() {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(rvp(15))
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#222')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(item.address)
                      .fontSize(rvp(12))
                      .fontColor('#999')
                      .margin({ top: rvp(4) })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(`${item.price} 元/月`)
                      .fontSize(rvp(16))
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF7D00')
                      .margin({ top: rvp(8) })
                  }
                  .layoutWeight(1)

                  if (allowDelete) {
                    Text('删除')
                      .fontSize(rvp(13))
                      .fontColor('#E24A4A')
                      .margin({ left: rvp(12) })
                      .onClick(() => this.removeRoom(item.id))
                  }
                }
              }
              .width('100%')
              .padding({
                left: rvp(16),
                right: rvp(16),
                top: rvp(12),
                bottom: rvp(12)
              })
              .backgroundColor('#FFF')
              .borderRadius(rvp(12))
              .margin({ top: rvp(8) })
            },
            (item: SimpleRoom) => item.id
          )
          Blank().height(rvp(8))
        }
      }
      .width('100%')
      .height('auto')
    }
  }

  build() {
    Column() {
      Refresh({
        refreshing: this.refreshing,
        offset: rvp(80),
        friction: 0.7
      }) {
        Column() {
          Column() {
            this.TabHeader()

            if (this.currentIndex === 0) {
              this.ListContent(
                this.rentedList,
                '你还没有正在租住的房源，去首页看看喜欢的房子吧～',
                false
              )
            } else {
              this.ListContent(
                this.publishedList,
                '你还没有上架房源，去发布一套试试吧～',
                true
              )
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
