// backend/routes/reservations.js
import express from 'express'
import { getDB } from '../db.js'
import { addMessage, MESSAGE_TYPES } from './messages.js'  // 使用内存消息系统

const router = express.Router()

/**
 * POST /auth/house/reservation
 * 创建预约
 * body: { roomId, date, userName, remark, phone }
 */
router.post('/reservation', async (req, res) => {
  try {
    const { roomId, date, userName, remark, phone } = req.body || {}

    if (!roomId || !date || !phone) {
      return res.status(400).json({ error: '缺少必要参数' })
    }

    const db = await getDB()

    // 不能预约过去的日期
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

    // === 1. 插入预约记录 ===
    const sql = `
      INSERT INTO reservation (user_id, house_id, date, name, comment)
      VALUES (?, ?, ?, ?, ?)
    `
    const stmt = db.prepare(sql)
    stmt.run([
      phone,           // user_id（租客手机号）
      roomId,          // house_id
      date,
      userName || '',
      remark || ''
    ])
    stmt.free && stmt.free()

    if (typeof db.saveToDisk === 'function') {
      db.saveToDisk()
    }

    // === 2. 推送消息（内存消息系统：租客 + 房东） ===
    const extra = JSON.stringify({ roomId, date })

    // 2-1 租客：预约成功（橙色）
    addMessage(
      phone,
      MESSAGE_TYPES.ORDER,
      '预约成功',
      `你已成功预约 ${date} 看房`,
      extra
    )

    // 2-2 房东：收到新的预约
    const landlordPhone = '13800000000' // TODO：以后从房源表查真实房东手机号
    addMessage(
      landlordPhone,
      MESSAGE_TYPES.ORDER,
      '收到新的看房预约',
      `${userName || phone} 预约了 ${date} 的看房`,
      extra
    )

    return res.json({ message: '预约成功' })
  } catch (error) {
    console.error('create reservation error: ', error)
    return res.status(500).json({ error: 'Internal server error' })
  }
})

/**
 * GET /auth/house/reservation/list
 * 查询某个用户的预约列表（给“约看”页面用）
 * query: ?userId=手机号 或 ?phone=手机号
 */
router.get('/reservation/list', async (req, res) => {
  try {
    const q = req.query || {}
    const userId = q.userId || q.phone

    if (!userId) {
      return res.status(400).json({ code: 400, message: '缺少 userId/phone' })
    }

    const db = await getDB()

    const sql = `
      SELECT
        id,
        user_id    AS userId,
        house_id   AS houseId,
        date,
        name,
        comment
      FROM reservation
      WHERE user_id = ?
      ORDER BY date DESC, id DESC
    `
    const stmt = db.prepare(sql)
    const rows = stmt.all([userId])
    stmt.free && stmt.free()

    return res.json({
      code: 200,
      data: { list: rows || [] },
      message: 'ok'
    })
  } catch (error) {
    console.error('get reservation list error: ', error)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * POST /auth/house/reservation/cancel
 * 取消预约
 * body: { id, phone }
 */
router.post('/reservation/cancel', async (req, res) => {
  try {
    const { id, phone } = req.body || {}

    if (!id || !phone) {
      return res.status(400).json({ error: '缺少必要参数（id / phone）' })
    }

    const db = await getDB()

    // 1. 查出这条预约记录，校验是否属于当前用户
    const querySql = `
      SELECT id, user_id, house_id, date, name, comment
      FROM reservation
      WHERE id = ? AND user_id = ?
    `
    const queryStmt = db.prepare(querySql)
    const row = queryStmt.get([id, phone])
    queryStmt.free && queryStmt.free()

    if (!row) {
      return res.status(404).json({ error: '预约不存在或无权限取消' })
    }

    const houseId = row.house_id
    const date = row.date
    const userName = row.name || ''

    // 2. 删除预约记录
    const delSql = 'DELETE FROM reservation WHERE id = ?'
    const delStmt = db.prepare(delSql)
    delStmt.run([id])
    delStmt.free && delStmt.free()

    if (typeof db.saveToDisk === 'function') {
      db.saveToDisk()
    }

    // 3. 推送取消预约消息：租客 + 房东
    const extra = JSON.stringify({
      roomId: houseId,
      date,
      reservationId: id
    })

    // 租客：取消成功
    addMessage(
      phone,
      MESSAGE_TYPES.ORDER,
      '取消预约成功',
      `你已成功取消 ${date} 的看房预约`,
      extra
    )

    // 房东：预约被取消
    const landlordPhone = '13800000000'
    addMessage(
      landlordPhone,
      MESSAGE_TYPES.ORDER,
      '看房预约已被取消',
      `${userName || phone} 取消了 ${date} 的看房预约`,
      extra
    )

    return res.json({ message: '取消预约成功' })
  } catch (error) {
    console.error('cancel reservation error: ', error)
    return res.status(500).json({ error: 'Internal server error' })
  }
})

export default router
