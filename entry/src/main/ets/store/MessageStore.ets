// entry/src/main/ets/store/MessageStore.ets
import { getUnreadCountApi } from '../api/message';

const KEY_HAS_UNREAD_MESSAGE: string = 'hasUnreadMessage';

// 确保 hasUnreadMessage 在 AppStorage 里有初始值
function ensureHasUnreadInit() {
  if (!AppStorage.Has(KEY_HAS_UNREAD_MESSAGE)) {
    AppStorage.SetOrCreate(KEY_HAS_UNREAD_MESSAGE, false);
  }
}

@Observed
export class MessageStore {
  // 不再用 @StorageProp，改为操作 AppStorage 里的 hasUnreadMessage
  async refresh(userId: string) {
    ensureHasUnreadInit();
    try {
      const count = await getUnreadCountApi(userId);
      AppStorage.Set(KEY_HAS_UNREAD_MESSAGE, count > 0); // 只关心有没有
    } catch (err) {
      console.error('[MessageStore] refresh error: ', JSON.stringify(err));
    }
  }

  clear() {
    ensureHasUnreadInit();
    AppStorage.Set(KEY_HAS_UNREAD_MESSAGE, false);
  }

  // 如果需要在代码里读当前状态，可以用这个 getter
  get hasUnread(): boolean {
    ensureHasUnreadInit();
    return AppStorage.Get(KEY_HAS_UNREAD_MESSAGE) as boolean;
  }
}

export const messageStore = new MessageStore();

// ================== 以下是你原来的“本地消息列表”逻辑 ==================

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
function ensureInitMessages() {
  if (!AppStorage.Has(KEY_ALL_MESSAGES)) {
    AppStorage.SetOrCreate(KEY_ALL_MESSAGES, new Array<ChatMessage>())
  }
  if (!AppStorage.Has(KEY_UNREAD_COUNT)) {
    AppStorage.SetOrCreate(KEY_UNREAD_COUNT, 0)
  }
}

export function getAllMessages(): ChatMessage[] {
  ensureInitMessages()
  return AppStorage.Get(KEY_ALL_MESSAGES) as ChatMessage[]
}

function setAllMessages(list: ChatMessage[]) {
  AppStorage.Set(KEY_ALL_MESSAGES, list)
}

export function getUnreadCount(): number {
  ensureInitMessages()
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
