// backend/routes/reservations.js
import express from 'express'
import { getDB } from '../db.js'

const router = express.Router()

/**
 * POST /auth/house/reservation
 * （实际路径 = app.js 的前缀 '/auth/house' + 这里的 '/reservation'）
 *
 * body: { roomId, date, userName, remark, phone }
 */
router.post('/reservation', async (req, res) => {
  try {
    const { roomId, date, userName, remark, phone } = req.body || {}

    if (!roomId || !date || !phone) {
      return res.status(400).json({ error: '缺少必要参数' })
    }

    const db = await getDB()

    // 👉 如果你还想保留“不能预约过去的日期”，保留下面这段；
    //    如果完全不想限制，直接删掉这段 if 块都可以。
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const target = new Date(date)
    if (isNaN(target.getTime())) {
      return res.status(400).json({ error: '日期格式不正确' })
    }
    target.setHours(0, 0, 0, 0)

    if (target < today) {
      return res.status(400).json({ error: '不能预约过去的日期' })
    }

    // ❌ 不再做“同一用户 / 同一房源 / 同一天限制”
    // 直接插一条记录
    const sql = `
      INSERT INTO reservation (user_id, house_id, date, name, comment)
      VALUES (?, ?, ?, ?, ?)
    `
    const stmt = db.prepare(sql)
    stmt.run([
      phone,
      roomId,
      date,
      userName || '',
      remark || ''
    ])

    if (typeof db.saveToDisk === 'function') {
      db.saveToDisk()
    }

    // 明确返回 200 + message
    return res.json({ message: '预约成功' })
  } catch (error) {
    console.error('create reservation error: ', error)
    return res.status(500).json({ error: 'Internal server error' })
  }
})

export default router
