// entry/src/main/ets/store/MessageStore.ets

// 单条消息结构
export interface ChatMessage {
  id: string
  sessionId: string      // 会话 id：system / butler / landlord_xxx ...
  content: string
  createdAt: number
  read: boolean
  type?: string          // 'text' | 'reservation' 等
}

// 预约消息的入参结构
export interface ReservationPayload {
  roomId: number | string
  roomTitle: string
  date: string
  timeRange: string
}

// 存储键名
const KEY_ALL_MESSAGES: string = 'allMessages'
const KEY_UNREAD_COUNT: string = 'unreadCount'

// 保证 AppStorage 里有初始值
function ensureInit() {
  if (!AppStorage.Has(KEY_ALL_MESSAGES)) {
    AppStorage.SetOrCreate(KEY_ALL_MESSAGES, new Array<ChatMessage>())
  }
  if (!AppStorage.Has(KEY_UNREAD_COUNT)) {
    AppStorage.SetOrCreate(KEY_UNREAD_COUNT, 0)
  }
}

export function getAllMessages(): ChatMessage[] {
  ensureInit()
  return AppStorage.Get(KEY_ALL_MESSAGES) as ChatMessage[]
}

function setAllMessages(list: ChatMessage[]) {
  AppStorage.Set(KEY_ALL_MESSAGES, list)
}

export function getUnreadCount(): number {
  ensureInit()
  return AppStorage.Get(KEY_UNREAD_COUNT) as number
}

function setUnreadCount(count: number) {
  AppStorage.Set(KEY_UNREAD_COUNT, count)
}

// 对外：新增一条消息（会自动更新未读数）
export function addMessage(msg: ChatMessage) {
  const all: ChatMessage[] = getAllMessages()
  all.push(msg)
  setAllMessages(all)

  if (!msg.read) {
    const unread: number = getUnreadCount()
    setUnreadCount(unread + 1)
  }
}

// 对外：把某个会话的消息标记为已读（同时减少未读数）
export function markSessionRead(sessionId: string) {
  const all: ChatMessage[] = getAllMessages()
  let unread: number = getUnreadCount()
  let changed: boolean = false

  all.forEach((m: ChatMessage) => {
    if (m.sessionId === sessionId && !m.read) {
      m.read = true
      unread = Math.max(0, unread - 1)
      changed = true
    }
  })

  if (changed) {
    setAllMessages(all)
    setUnreadCount(unread)
  }
}

// 预约管家会话 id
export const SESSION_ID_BUTLER: string = 'butler'

// 从“立即预约”那边调用，往预约管家会话里塞一条消息
export function pushReservationMessage(payload: ReservationPayload) {
  const msg: ChatMessage = {
    id: `${Date.now()}`,
    sessionId: SESSION_ID_BUTLER,
    content: `预约看房：${payload.roomTitle}，时间：${payload.date} ${payload.timeRange}`,
    createdAt: Date.now(),
    read: false,
    type: 'reservation'
  }
  addMessage(msg)
}
