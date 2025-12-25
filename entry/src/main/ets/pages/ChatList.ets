// entry/src/main/ets/pages/ChatList.ets
import router from '@ohos.router'

interface ChatItem {
  id: number
  title: string
  lastMsg: string
  time: string
  unread: number
}

@Entry
@Component
struct ChatListPage {
  @StorageProp('topRectHeight') topRectHeight: number = 0

  @State chats: ChatItem[] = [
    { id: 1, title: '系统通知', lastMsg: '欢迎使用谷粒租房～', time: '昨天', unread: 0 },
    { id: 2, title: '客服助手', lastMsg: '有问题可以随时联系我哦', time: '09:12', unread: 2 },
    { id: 3, title: '看房小提示', lastMsg: '记得看房时检查水电气情况～', time: '周二', unread: 0 }
  ]

  build() {
    Column() {

      // ========= 顶部栏（和“我的”页同风格） =========
      Row() {
        // 左：返回
        Text('< 返回')
          .fontSize(16)
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1)

        // 中：标题，真正居中
        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        // 右：占位
        Blank().layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: this.topRectHeight + 8,  // 垫过状态栏 / 摄像头
        bottom: 8
      })
      .backgroundColor('#8FE1A2')

      // ========= 列表区域 =========
      Scroll() {
        Column() {
          ForEach(this.chats, (item: ChatItem) => {
            Row() {
              // 左侧头像
              Column() {
                Text(item.title.substring(0, 1))
                  .fontSize(16)
                  .fontColor('#ffffff')
                  .textAlign(TextAlign.Center)
                  .width(40)
                  .height(40)
                  .backgroundColor('#5AC38F')
                  .borderRadius(20)
              }
              .margin({ right: 12 })

              // 文本区
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .layoutWeight(1)

                  Text(item.time)
                    .fontSize(12)
                    .fontColor('#999999')
                }

                // 小字：宽度撑满 → 跟标题左对齐
                Text(item.lastMsg)
                  .fontSize(14)
                  .fontColor('#777777')
                  .margin({ top: 4 })
                  .width('100%')
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ top: 8, left: 12, right: 12 })
          })

          Blank().height(24)
        }
      }
      .backgroundColor('#F7F7F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}
