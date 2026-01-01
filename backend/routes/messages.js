// backend/routes/messages.js
import express from 'express'

const router = express.Router()

/**
 * 消息类型枚举（给其它模块用）
 */
export const MESSAGE_TYPES = {
  SYSTEM: 'system',
  ORDER: 'order',
  NOTICE: 'notice'
}

/**
 * 内存消息存储结构：
 * {
 *   '13800000000': [
 *      { id, userId, type, title, content, created_at, is_read, extra }
 *   ]
 * }
 */
const messageStore = Object.create(null)
let globalMsgId = 1

function nowTs() {
  return Date.now()
}

/**
 * 第一次使用某个用户时：初始化 + 自动塞一条“系统欢迎消息”
 */
function ensureUserMessages(userId) {
  const key = String(userId)
  if (!messageStore[key]) {
    messageStore[key] = []

    // 默认系统欢迎消息（绿色）
    messageStore[key].push({
      id: globalMsgId++,
      userId: key,
      type: MESSAGE_TYPES.SYSTEM,
      title: '欢迎使用租房 App',
      content: '欢迎使用租房 App，本页面会显示系统通知和预约消息。',
      created_at: nowTs(),
      is_read: 0,
      extra: ''
    })
  }
  return messageStore[key]
}

/**
 * 给某个用户新增一条消息（给 reservations.js 等地方调用）
 */
export function addMessage(userId, type, title, content, extra = '') {
  const list = ensureUserMessages(userId)

  list.push({
    id: globalMsgId++,
    userId: String(userId),
    type,               // system / order / notice / reservation...
    title,
    content,
    created_at: nowTs(),
    is_read: 0,
    extra
  })
}

/**
 * 获取用户消息列表
 */
function getUserMessages(userId) {
  return ensureUserMessages(userId)
}

/**
 * 从请求里抽 userId / phone / uid
 * （尽量兼容前端可能用的字段名）
 */
function pickUserId(req) {
  const q = req.query || {}
  const b = req.body || {}

  const userId =
    q.userId ||
    q.user_id ||
    q.uid ||
    q.phone ||
    b.userId ||
    b.user_id ||
    b.uid ||
    b.phone ||
    ''

  console.log('[message] pickUserId =>', userId)
  return userId
}

/**
 * GET /auth/message/unreadCount
 */
router.get('/unreadCount', (req, res) => {
  try {
    const userId = pickUserId(req)
    console.log('[message] /unreadCount userId =', userId)

    if (!userId) {
      return res.json({
        code: 200,
        data: { count: 0 },
        message: 'ok'
      })
    }

    const list = getUserMessages(userId)
    const count = list.filter(m => m.is_read === 0).length

    return res.json({
      code: 200,
      data: { count },
      message: 'ok'
    })
  } catch (err) {
    console.error('[message] /unreadCount error:', err)
    return res.status(500).json({
      code: 500,
      message: 'Internal server error'
    })
  }
})

/**
 * GET /auth/message/list
 */
router.get('/list', (req, res) => {
  try {
    const userId = pickUserId(req)
    console.log('[message] /list userId =', userId)

    if (!userId) {
      // 如果真的拿不到，就返回空列表，避免 500
      return res.json({
        code: 200,
        data: { list: [] },
        message: 'ok'
      })
    }

    const list = getUserMessages(userId)
      .slice()
      .sort((a, b) => b.created_at - a.created_at || b.id - a.id)

    return res.json({
      code: 200,
      data: { list },
      message: 'ok'
    })
  } catch (err) {
    console.error('[message] /list error:', err)
    return res.status(500).json({
      code: 500,
      message: 'Internal server error'
    })
  }
})

/**
 * POST /auth/message/readAll
 */
router.post('/readAll', (req, res) => {
  try {
    const userId = pickUserId(req)
    console.log('[message] /readAll userId =', userId)

    if (userId) {
      const list = getUserMessages(userId)
      list.forEach(m => {
        m.is_read = 1
      })
    }

    return res.json({
      code: 200,
      data: { success: true },
      message: 'ok'
    })
  } catch (err) {
    console.error('[message] /readAll error:', err)
    return res.status(500).json({
      code: 500,
      message: 'Internal server error'
    })
  }
})

export default router
