// backend/routes/reservations.js
import express from 'express'
import { getDB } from '../db.js'
import { addMessage, MESSAGE_TYPES } from './messages.js'
import { getHost } from '../utils/getHost.js'  // ✅ 新增：自动获取 http(s)://host

const router = express.Router()

const RES_STATUS = {
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled'
}

/**
 * 根据房源 ID 查询房东手机号
 */
async function getLandlordPhoneByHouseId(db, houseId) {
  try {
    if (!houseId) return ''

    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?')
    stmt.bind([houseId])

    if (!stmt.step()) {
      stmt.free()
      return ''
    }

    const row = stmt.getAsObject()
    stmt.free()

    if (!row || !row.data) return ''

    let obj = {}
    try {
      obj = JSON.parse(row.data)
    } catch (e) {
      console.error('解析 house_info.data 失败:', e)
      return ''
    }

    let phone =
      obj.landlordPhone ||
      obj.ownerPhone ||
      obj.phone ||
      ''

    // 兼容老数据，从 ownerId 里抠 11 位手机号
    if (!phone && typeof obj.ownerId === 'string') {
      const m = obj.ownerId.match(/(\d{11})$/)
      if (m) phone = m[1]
    }

    return phone || ''
  } catch (e) {
    console.error('getLandlordPhoneByHouseId error:', e)
    return ''
  }
}

/**
 * 获取房源标题 & 封面图
 * ✅ 改动：传入 req，把 /public/xxx.jpg 统一拼成绝对地址
 */
function getHouseSummary(db, houseId, req) {
  try {
    if (!houseId) return { title: '', coverUrl: '' }

    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?')
    stmt.bind([houseId])

    if (!stmt.step()) {
      stmt.free()
      return { title: '', coverUrl: '' }
    }

    const row = stmt.getAsObject()
    stmt.free()

    let obj = {}
    try {
      obj = JSON.parse(row.data)
    } catch (e) {
      console.error('parse data error:', e)
      return { title: '', coverUrl: '' }
    }

    const title = obj.houseTitle || obj.title || ''

    let firstPic = ''
    if (Array.isArray(obj.housePicture)) {
      if (
        obj.housePicture.length > 0 &&
        Array.isArray(obj.housePicture[0].picList) &&
        obj.housePicture[0].picList.length > 0
      ) {
        firstPic = obj.housePicture[0].picList[0]
      }
    } else if (typeof obj.housePicture === 'string' && obj.housePicture) {
      firstPic = obj.housePicture
    }

    // 兜底：有些房源可能用 roomMainPic / mainPic 存首页图
    if (!firstPic && typeof obj.roomMainPic === 'string' && obj.roomMainPic) {
      firstPic = obj.roomMainPic
    }
    if (!firstPic && typeof obj.mainPic === 'string' && obj.mainPic) {
      firstPic = obj.mainPic
    }

    let coverUrl = ''
    if (firstPic) {
      // 已经是绝对地址，直接返回
      if (firstPic.startsWith('http')) {
        coverUrl = firstPic
      } else {
        // 统一成 /public/xxx
        const publicPath = firstPic.startsWith('/public/')
          ? firstPic
          : '/public/' + firstPic.replace(/^\//, '')

        // ✅ 关键：拼成绝对地址
        coverUrl = req ? (getHost(req) + publicPath) : publicPath
      }
    }

    return { title, coverUrl }
  } catch (e) {
    console.error('getHouseSummary error:', e)
    return { title: '', coverUrl: '' }
  }
}

/**
 * 创建预约（租客）
 * POST /auth/house/reservation
 */
router.post('/reservation', async (req, res) => {
  try {
    const {
      roomId,
      date,
      userName,
      remark,
      phone,
      landlordPhone: landlordPhoneFromBody
    } = req.body || {}

    if (!roomId || !date || !phone) {
      return res.status(400).json({ code: 400, message: '缺少必要参数' })
    }

    const db = await getDB()

    // 插入预约，初始状态 pending
    const stmt = db.prepare(`
      INSERT INTO reservation (user_id, house_id, date, name, comment, status)
      VALUES (?, ?, ?, ?, ?, ?)
    `)
    stmt.run([
      phone,
      roomId,
      date,
      userName || '',
      remark || '',
      RES_STATUS.PENDING
    ])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()

    // 查房东手机号
    let landlordPhone = landlordPhoneFromBody || ''
    if (!landlordPhone) {
      landlordPhone = await getLandlordPhoneByHouseId(db, roomId)
    }

    // 房源摘要 ✅ 传入 req
    const { title: houseTitle, coverUrl } = getHouseSummary(db, roomId, req)
    const remarkText = remark ? `备注：${remark}` : '备注：无'

    const extra = JSON.stringify({
      roomId,
      date,
      landlordPhone,
      tenantPhone: phone,
      remark,
      houseTitle,
      coverUrl
    })

    // 租客消息
    addMessage(
      phone,
      MESSAGE_TYPES.ORDER,
      '预约提交成功',
      `您已提交 ${date} 看房预约，${houseTitle ? `房源：${houseTitle}，` : ''}${remarkText}`,
      extra
    )

    // 房东消息
    if (landlordPhone) {
      addMessage(
        landlordPhone,
        MESSAGE_TYPES.ORDER,
        '收到新的看房预约',
        `${userName || phone}（电话：${phone}）预约了 ${date} 的房源「${houseTitle || '房源'}」，${remarkText}`,
        extra
      )
    } else {
      console.warn('[reservation] 未找到房东手机号，预约消息仅发送给租客，houseId=', roomId)
    }

    return res.json({
      code: 200,
      data: null,
      message: '预约提交成功'
    })
  } catch (e) {
    console.error('create reservation error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 租客视角：我的约看列表
 * GET /auth/house/reservation/list?userId=xxx
 */
router.get('/reservation/list', async (req, res) => {
  try {
    const userId = req.query.userId || req.query.phone
    if (!userId) {
      return res.status(400).json({ code: 400, message: '缺少 userId' })
    }

    const db = await getDB()
    const stmt = db.prepare(`
      SELECT id, user_id AS userId, house_id AS houseId, date, name, comment, status
      FROM reservation
      WHERE user_id = ?
      ORDER BY date DESC, id DESC
    `)
    stmt.bind([userId])

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()

      // ✅ 封面/标题（绝对地址）
      const { title: houseTitle, coverUrl } = getHouseSummary(db, row.houseId, req)

      // ✅ 房东电话：租客端用于双向联系
      const landlordPhone = await getLandlordPhoneByHouseId(db, row.houseId)

      list.push({
        ...row,
        houseTitle,
        coverUrl,
        landlordPhone
      })
    }
    stmt.free()

    return res.json({
      code: 200,
      data: { list },
      message: 'ok'
    })
  } catch (e) {
    console.error('get reservation list error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 房东视角：约看我的列表
 * GET /auth/house/reservation/landlord-list?phone=房东手机号
 */
router.get('/reservation/landlord-list', async (req, res) => {
  try {
    const phone = req.query.phone
    if (!phone) {
      return res.status(400).json({ code: 400, message: '缺少 phone' })
    }

    const db = await getDB()

    // 先把所有预约拉出来，再根据房源的房东手机号过滤
    const stmt = db.prepare(`
      SELECT id,
             user_id AS tenantPhone,
             house_id AS houseId,
             date,
             name,
             comment,
             status
      FROM reservation
      ORDER BY date DESC, id DESC
    `)

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()

      // 根据 houseId 反查房东手机号
      const landlordPhone = await getLandlordPhoneByHouseId(db, row.houseId)
      if (landlordPhone !== phone) {
        continue
      }

      // ✅ 传入 req，使 coverUrl 变成绝对地址
      const { title: houseTitle, coverUrl } = getHouseSummary(db, row.houseId, req)

      list.push({
        ...row,
        houseTitle,
        coverUrl
      })
    }
    stmt.free()

    return res.json({
      code: 200,
      data: { list },
      message: 'ok'
    })
  } catch (error) {
    console.error('get landlord reservation list error:', error)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 取消预约（租客操作）
 * POST /auth/house/reservation/cancel
 */
router.post('/reservation/cancel', async (req, res) => {
  try {
    const { id, phone } = req.body || {}
    if (!id || !phone) {
      return res.status(400).json({ code: 400, message: '缺少必要参数' })
    }

    const db = await getDB()

    const qStmt = db.prepare(`
      SELECT id, house_id, date, name, comment, status
      FROM reservation
      WHERE id = ? AND user_id = ?
    `)
    qStmt.bind([id, phone])

    if (!qStmt.step()) {
      qStmt.free()
      return res.status(404).json({ code: 404, message: '预约不存在' })
    }

    const row = qStmt.getAsObject()
    qStmt.free()

    const houseId = row.house_id
    const { title: houseTitle } = getHouseSummary(db, houseId, req)

    // 不删记录，只改状态，方便双方看到历史
    const uStmt = db.prepare(`
      UPDATE reservation SET status = ? WHERE id = ?
    `)
    uStmt.run([RES_STATUS.CANCELLED, id])
    uStmt.free()

    if (db.saveToDisk) db.saveToDisk()

    const landlordPhone = await getLandlordPhoneByHouseId(db, houseId)

    const extra = JSON.stringify({
      roomId: houseId,
      date: row.date,
      reservationId: id,
      houseTitle
    })

    const remarkText = row.comment ? `备注：${row.comment}` : '备注：无'

    // 租客消息
    addMessage(
      phone,
      MESSAGE_TYPES.ORDER,
      '取消预约成功',
      `已取消 ${row.date} 房源「${houseTitle || '房源'}」的看房预约，${remarkText}`,
      extra
    )

    // 房东消息
    if (landlordPhone) {
      addMessage(
        landlordPhone,
        MESSAGE_TYPES.ORDER,
        '看房预约已被取消',
        `${row.name || phone}（电话：${phone}）取消了 ${row.date} 房源「${houseTitle || '房源'}」的预约，${remarkText}`,
        extra
      )
    }

    return res.json({
      code: 200,
      data: null,
      message: '取消预约成功'
    })
  } catch (e) {
    console.error('cancel reservation error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 房东同意 / 驳回预约
 * POST /auth/house/reservation/decision
 * body: { id, landlordPhone, action: 'accept' | 'reject' }
 */
router.post('/reservation/decision', async (req, res) => {
  try {
    const { id, landlordPhone, action } = req.body || {}
    if (!id || !landlordPhone || !['accept', 'reject'].includes(action)) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()

    const qStmt = db.prepare(`
      SELECT id, user_id AS tenantPhone, house_id, date, name, comment, status
      FROM reservation
      WHERE id = ?
    `)
    qStmt.bind([id])

    if (!qStmt.step()) {
      qStmt.free()
      return res.status(404).json({ code: 404, message: '预约不存在' })
    }

    const row = qStmt.getAsObject()
    qStmt.free()

    const realLandlordPhone = await getLandlordPhoneByHouseId(db, row.house_id)
    if (realLandlordPhone !== landlordPhone) {
      return res
        .status(403)
        .json({ code: 403, message: '无权操作该预约' })
    }

    const { title: houseTitle } = getHouseSummary(db, row.house_id, req)

    const newStatus =
      action === 'accept' ? RES_STATUS.ACCEPTED : RES_STATUS.REJECTED

    const uStmt = db.prepare(`
      UPDATE reservation SET status = ? WHERE id = ?
    `)
    uStmt.run([newStatus, id])
    uStmt.free()

    if (db.saveToDisk) db.saveToDisk()

    const extra = JSON.stringify({
      roomId: row.house_id,
      date: row.date,
      reservationId: id,
      houseTitle
    })

    const remarkText = row.comment ? `备注：${row.comment}` : '备注：无'

    // 给租客发消息
    if (action === 'accept') {
      addMessage(
        row.tenantPhone,
        MESSAGE_TYPES.ORDER,
        '预约已通过',
        `房东已同意你在 ${row.date} 看房源「${houseTitle || '房源'}」，${remarkText}`,
        extra
      )
    } else {
      addMessage(
        row.tenantPhone,
        MESSAGE_TYPES.ORDER,
        '预约未通过',
        `房东未同意你在 ${row.date} 看房源「${houseTitle || '房源'}」，${remarkText}`,
        extra
      )
    }

    // 房东自己也来一条结果（可选）
    addMessage(
      landlordPhone,
      MESSAGE_TYPES.ORDER,
      action === 'accept' ? '已同意看房预约' : '已驳回看房预约',
      `${row.name || row.tenantPhone} 在 ${row.date} 的预约已标记为「${
        action === 'accept' ? '已同意' : '已驳回'
      }」，${remarkText}`,
      extra
    )

    return res.json({
      code: 200,
      data: null,
      message: '操作成功'
    })
  } catch (e) {
    console.error('decision reservation error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

export default router
