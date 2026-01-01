// backend/routes/reservations.js
import express from 'express'
import { getDB } from '../db.js'
import { addMessage, MESSAGE_TYPES } from './messages.js'

const router = express.Router()

/**
 * 根据房源 ID 查询房东手机号
 * 目前你的 house_info 结构是：
 *   id TEXT PRIMARY KEY,
 *   data TEXT, ...  // data 里是一个 JSON 字符串
 *
 * 以后你只要在 data 这个 JSON 里多存一个字段：
 *   { ..., "landlordPhone": "13700000000" }
 * 或者 { ..., "ownerPhone": "13700000000" }
 * 这里就可以自动读到。
 */
async function getLandlordPhoneByHouseId(db, houseId) {
  try {
    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?')
    const row = stmt.get([houseId])
    stmt.free && stmt.free()

    if (!row || !row.data) {
      return ''
    }

    let obj
    try {
      obj = JSON.parse(row.data)
    } catch (e) {
      console.error('解析 house_info.data 失败:', e)
      return ''
    }

    const phone =
      obj.landlordPhone ||   // 推荐以后用这个字段
      obj.ownerPhone ||      // 或者用这个
      obj.phone ||           // 如果JSON里已有 phone
      ''

    return phone ? String(phone) : ''
  } catch (e) {
    console.error('getLandlordPhoneByHouseId error:', e)
    return ''
  }
}

/**
 * POST /auth/house/reservation
 * 创建预约
 * body: { roomId, date, userName, remark, phone, landlordPhone? }
 */
router.post('/reservation', async (req, res) => {
  try {
    const {
      roomId,
      date,
      userName,
      remark,
      phone: currentUserPhone,
      landlordPhone: landlordPhoneFromBody
    } = req.body || {}

    if (!roomId || !date || !phone) {
      return res.status(400).json({ error: '缺少必要参数' })
    }

    const db = await getDB()

    // === 不能预约过去的日期 ===
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
      roomId,          // house_id（house_info.id）
      date,
      userName || '',
      remark || ''
    ])
    stmt.free && stmt.free()

    if (typeof db.saveToDisk === 'function') {
      db.saveToDisk()
    }

    // === 2. 确定房东手机号（优先用前端传的，其次从 house_info 里查） ===
    let landlordPhone = landlordPhoneFromBody || ''
    if (!landlordPhone) {
      landlordPhone = await getLandlordPhoneByHouseId(db, roomId)
    }

    const remarkText = remark ? `备注：${remark}` : '备注：无'

    const extra = JSON.stringify({
      roomId,
      date,
      landlordPhone,
      tenantPhone: phone,
      remark
    })

    // 2-1 租客：预约提交成功（你用租客手机号登录应看到这个）
    addMessage(
      phone,
      MESSAGE_TYPES.ORDER,
      '预约提交成功',
      landlordPhone
        ? `您已提交 ${date} 的看房预约，房东电话：${landlordPhone}，${remarkText}`
        : `您已提交 ${date} 的看房预约，${remarkText}`,
      extra
    )

    // 2-2 房东：收到新的预约（只有拿到房东手机号才发）
    if (landlordPhone) {
      addMessage(
        landlordPhone,
        MESSAGE_TYPES.ORDER,
        '收到新的看房预约',
        `${userName || phone}（电话：${phone}）预约了 ${date} 的看房，${remarkText}`,
        extra
      )
    } else {
      console.warn(
        '[reservation] 预约时未找到房东手机号，房东通知消息没有发送，houseId =',
        roomId
      )
    }

    return res.json({ message: '预约提交成功' })
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
    const remarkText = row.comment ? `备注：${row.comment}` : '备注：无'

    // 2. 删除预约记录
    const delSql = 'DELETE FROM reservation WHERE id = ?'
    const delStmt = db.prepare(delSql)
    delStmt.run([id])
    delStmt.free && delStmt.free()

    if (typeof db.saveToDisk === 'function') {
      db.saveToDisk()
    }

    // 3. 查房东手机号（同样：先看 house_info）
    const landlordPhone = await getLandlordPhoneByHouseId(db, houseId)

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
      `您已成功取消 ${date} 的看房预约，${remarkText}`,
      extra
    )

    // 房东：预约被取消（如果查到了房东）
    if (landlordPhone) {
      addMessage(
        landlordPhone,
        MESSAGE_TYPES.ORDER,
        '看房预约已被取消',
        `${userName || phone}（电话：${phone}）取消了 ${date} 的看房预约，${remarkText}`,
        extra
      )
    } else {
      console.warn(
        '[reservation] 取消预约时未找到房东手机号，房东通知消息没有发送，houseId =',
        houseId
      )
    }

    return res.json({ message: '取消预约成功' })
  } catch (error) {
    console.error('cancel reservation error: ', error)
    return res.status(500).json({ error: 'Internal server error' })
  }
})

export default router
