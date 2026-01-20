// entry/src/main/ets/pages/ChatList.ets
import router from '@ohos.router'
import { getMessageListApi, readAllMessagesApi, type MessageItem } from '../api/message'
import { messageStore } from '../store/MessageStore'

class ChatItem {
  id: number = 0
  title: string = ''
  lastMsg: string = ''
  time: string = ''
  unread: boolean = false
  type: string = ''     // system / order / notice
  label: string = ''    // UI显示首字（系 / 订 / 通）
  color: string = ''    // UI显示颜色
}

function addZero(n: number): string {
  return n < 10 ? `0${n}` : `${n}`
}

function formatTime(ts: number): string {
  const d: Date = new Date(ts)
  const now: Date = new Date()
  const sameDay: boolean =
    d.getFullYear() === now.getFullYear() &&
      d.getMonth() === now.getMonth() &&
      d.getDate() === now.getDate()

  if (sameDay) {
    return `${addZero(d.getHours())}:${addZero(d.getMinutes())}`
  }
  return `${addZero(d.getMonth() + 1)}-${addZero(d.getDate())}`
}

function getCurrentUserId(): string {
  if (AppStorage.Has('userPhone')) {
    const v = AppStorage.Get('userPhone') as string
    if (v) return v
  }

  if (AppStorage.Has('user')) {
    const usr = AppStorage.Get('user') as object
    const phone = Reflect.get(usr, 'phone') as string
    if (phone) {
      AppStorage.setOrCreate('userPhone', phone)
      return phone
    }
  }

  return ''
}

//类型 → 标签首字
function typeToLabel(type: string): string {
  if (type === 'system') return '系'
  if (type === 'order' || type === 'reservation') return '订'
  if (type === 'notice') return '通'
  return '信'
}

//类型 → 颜色
function typeToColor(type: string): string {
  if (type === 'system') return '#5AC38F'
  if (type === 'order' || type === 'reservation') return '#FF9900'
  if (type === 'notice') return '#3B82F6'
  return '#999999'
}

@Entry
@Component
struct ChatListPage {
  @State chats: ChatItem[] = []
  @StorageProp('topRectHeight') topRectHeight: number = 0

  aboutToAppear() {
    this.loadMessages()
  }

  private async loadMessages() {
    const userId = getCurrentUserId()

    if (!userId) {
      this.chats = []
      return
    }

    const list = await getMessageListApi(userId)

    const mapped: ChatItem[] = []
    list.forEach((msg: MessageItem) => {
      const item = new ChatItem()
      item.id = msg.id
      item.title = msg.title
      item.lastMsg = msg.content
      item.time = formatTime(msg.created_at)
      item.unread = msg.is_read === 0
      item.type = msg.type
      item.label = typeToLabel(msg.type)
      item.color = typeToColor(msg.type)
      mapped.push(item)
    })

    this.chats = mapped

    await readAllMessagesApi(userId)
    messageStore.clear()
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#333')
          .onClick(() => router.back())
          .layoutWeight(1)

        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Blank().layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topRectHeight + 8, bottom: 8 })
      .backgroundColor('#8FE1A2')

      // 列表
      Scroll() {
        Column() {
          if (this.chats.length === 0) {
            Column() {
              Text('暂无消息')
                .fontSize(14)
                .fontColor('#999')
                .margin({ top: 80 })
            }
            .width('100%')
            .align(Alignment.Center)
          } else {
            ForEach(this.chats, (item: ChatItem) => {
              // 单条消息卡片
              Row({ space: 12 }) {
                // 左侧圆圈
                Column() {
                  Text(item.label)
                    .fontSize(16)
                    .fontColor('#FFF')
                    .fontWeight(FontWeight.Medium)
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .height('100%')
                    .align(Alignment.Center)
                }
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor(item.color)

                // 右侧文字区域
                Column() {
                  // 第一行：类型 + 标题 + 时间
                  Row() {
                    Text('[' + item.label + ']')
                      .fontSize(12)
                      .fontColor('#999')
                      .margin({ right: 4 })

                    // 标题：单行省略号，不会挤到时间
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(item.unread ? FontWeight.Bold : FontWeight.Medium)
                      .fontColor('#333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ right: 8 })
                      .layoutWeight(1)

                    Text(item.time)
                      .fontSize(12)
                      .fontColor('#999')
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)

                  // 第二行：最后一条内容，最多两行
                  Text(item.lastMsg)
                    .fontSize(14)
                    .fontColor('#777')
                    .margin({ top: 4 })
                    .width('100%')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFF')
              .borderRadius(12)
              .margin({ top: 8, left: 12, right: 12 })
            })
          }

          Blank().height(24)
        }
      }
      .backgroundColor('#F7F7F7')
    }
    .width('100%')
    .height('100%')
  }
}
