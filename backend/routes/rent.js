import express from 'express'
import { getDB } from '../db.js'
import { addMessage, MESSAGE_TYPES } from './messages.js'
import { getHost } from '../utils/getHost.js'

const router = express.Router()

const RENT_STATUS = {
  PENDING: 'pending',
  ACTIVE: 'active',
  QUIT_PENDING: 'quit_pending',
  ENDED: 'ended',
  REJECTED: 'rejected'
}

/**
 * 根据房源 ID 查房东手机号（和 reservation 完全一致）
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
      return ''
    }

    return (
      obj.landlordPhone ||
      obj.ownerPhone ||
      obj.phone ||
      ''
    )
  } catch (e) {
    return ''
  }
}

/**
 * 获取房源标题 & 封面（绝对地址）
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
      return { title: '', coverUrl: '' }
    }

    const title = obj.houseTitle || obj.title || ''

    let pic =
      obj.mainPic ||
      obj.roomMainPic ||
      (Array.isArray(obj.housePicture) &&
        obj.housePicture[0]?.picList?.[0]) ||
      ''

    let coverUrl = ''
    if (pic) {
      if (pic.startsWith('http')) {
        coverUrl = pic
      } else {
        const path = pic.startsWith('/public/')
          ? pic
          : '/public/' + pic.replace(/^\//, '')
        coverUrl = req ? getHost(req) + path : path
      }
    }

    return { title, coverUrl }
  } catch (e) {
    return { title: '', coverUrl: '' }
  }
}

function setHouseRentStatus(db, houseId, status, activeContractId = null) {
  const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?')
  stmt.bind([houseId])
  if (!stmt.step()) {
    stmt.free()
    return false
  }
  const row = stmt.getAsObject()
  stmt.free()

  let obj = {}
  try { obj = JSON.parse(row.data) } catch (e) { obj = {} }

  obj.rentStatus = status
  if (activeContractId) obj.activeContractId = activeContractId
  else delete obj.activeContractId

  const u = db.prepare('UPDATE house_info SET data = ? WHERE id = ?')
  u.run([JSON.stringify(obj), houseId])
  u.free()
  return true
}


/**
 * ===============================
 * 1️⃣ 租客：我要租 / 就要这间了
 * POST /auth/rent/create
 * ===============================
 */
router.post('/rent/create', async (req, res) => {
  try {
    const { houseId, tenantPhone, remark } = req.body || {}
    if (!houseId || !tenantPhone) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()

    const landlordPhone = await getLandlordPhoneByHouseId(db, houseId)
    if (!landlordPhone) {
      return res.status(400).json({ code: 400, message: '未找到房东信息' })
    }

    // ✅ 允许多人/多次下订：不做防重复拦截

    const now = Date.now()

    const stmt = db.prepare(`
      INSERT INTO rent_contract
      (house_id, tenant_phone, landlord_phone, status, remark, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `)
    stmt.run([
      houseId,
      tenantPhone,
      landlordPhone,
      RENT_STATUS.PENDING,
      remark || '',
      now,
      now
    ])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()

    const { title, coverUrl } = getHouseSummary(db, houseId, req)

    const extra = JSON.stringify({
      houseId,
      tenantPhone,
      landlordPhone,
      houseTitle: title,
      coverUrl
    })

    // 🔔 给房东发消息（红点来源）
    addMessage(
      landlordPhone,
      MESSAGE_TYPES.ORDER,
      '收到新的租房申请',
      `${tenantPhone} 申请租用房源「${title || '房源'}」`,
      extra
    )

    // 给租客一个回执
    addMessage(
      tenantPhone,
      MESSAGE_TYPES.ORDER,
      '已提交租房申请',
      `你已申请租用房源「${title || '房源'}」，等待房东确认`,
      extra
    )

    return res.json({ code: 200, message: '提交成功', data: null })
  } catch (e) {
    console.error('rent create error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * ===============================
 * 2️⃣ 房东：我租出的（全部）
 * GET /auth/rent/landlord-list?phone=xxx
 * ===============================
 */
router.get('/rent/landlord-list', async (req, res) => {
  try {
    const phone = req.query.phone
    const status = req.query.status
    if (!phone) {
      return res.status(400).json({ code: 400, message: '缺少 phone' })
    }

    const db = await getDB()
    // ✅ 可选 status 过滤（方便前端 tab 精确查询）
    const sql = status
      ? `SELECT * FROM rent_contract WHERE landlord_phone = ? AND status = ? ORDER BY created_at DESC`
      : `SELECT * FROM rent_contract WHERE landlord_phone = ? ORDER BY created_at DESC`

    const stmt = db.prepare(sql)
    status ? stmt.bind([phone, status]) : stmt.bind([phone])

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()
      const { title, coverUrl } = getHouseSummary(db, row.house_id, req)

      list.push({
        ...row,
        // ✅ 兼容前端 camelCase
        houseId: row.house_id,
        tenantPhone: row.tenant_phone,
        landlordPhone: row.landlord_phone,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        houseTitle: title,
        coverUrl
      })
    }
    stmt.free()

    return res.json({ code: 200, data: { list }, message: 'ok' })
  } catch (e) {
    console.error('rent landlord list error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

router.post('/rent/confirm', async (req, res) => {
  try {
    const { id, landlordPhone } = req.body || {}
    if (!id || !landlordPhone) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()

    // 1) 查合同
    const q = db.prepare(`SELECT * FROM rent_contract WHERE id = ?`)
    q.bind([id])

    if (!q.step()) {
      q.free()
      return res.status(404).json({ code: 404, message: '订单不存在' })
    }

    const row = q.getAsObject()
    q.free()

    if (row.landlord_phone !== landlordPhone) {
      return res.status(403).json({ code: 403, message: '无权操作' })
    }

    // ✅ 合租模式：不检查 house_info.data.rentStatus

    // 3) 更新合同为 active
    const now = Date.now()
    const u = db.prepare(`
      UPDATE rent_contract
      SET status = ?, updated_at = ?
      WHERE id = ?
    `)
    u.run([RENT_STATUS.ACTIVE, now, id])
    u.free()

    // ✅ 合租模式：不修改 house_info 的 rentStatus

    if (db.saveToDisk) db.saveToDisk()

    // 5) 发消息给租客
    const { title, coverUrl } = getHouseSummary(db, row.house_id, req)
    const extra = JSON.stringify({
      houseId: row.house_id,
      houseTitle: title,
      coverUrl,
      contractId: id
    })

    addMessage(
      row.tenant_phone,
      MESSAGE_TYPES.ORDER,
      '房东已确认出租',
      `房源「${title || '房源'}」已确认出租给你`,
      extra
    )

    return res.json({ code: 200, message: '已确认出租', data: null })
  } catch (e) {
    console.error('rent confirm error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * ===============================
 * 4️⃣ 租客：我租到的（生效中）
 * GET /auth/rent/my-active?phone=xxx
 * ===============================
 */
router.get('/rent/my-active', async (req, res) => {
  try {
    const phone = req.query.phone
    if (!phone) {
      return res.status(400).json({ code: 400, message: '缺少 phone' })
    }

    const db = await getDB()
    const stmt = db.prepare(`
      SELECT *
      FROM rent_contract
      WHERE tenant_phone = ?
        AND status = ?
      ORDER BY updated_at DESC
    `)
    stmt.bind([phone, RENT_STATUS.ACTIVE])

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()
      const { title, coverUrl } = getHouseSummary(db, row.house_id, req)
      list.push({
        ...row,
        // ✅ 兼容前端 camelCase
        houseId: row.house_id,
        tenantPhone: row.tenant_phone,
        landlordPhone: row.landlord_phone,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        houseTitle: title,
        coverUrl
      })
    }
    stmt.free()

    return res.json({ code: 200, data: { list }, message: 'ok' })
  } catch (e) {
    console.error('rent my-active error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * ===============================
 * 5️⃣ 租客：申请退租
 * POST /auth/rent/quit/apply
 * ===============================
 */
router.post('/rent/quit/apply', async (req, res) => {
  try {
    const { id, tenantPhone, reason } = req.body || {}
    if (!id || !tenantPhone) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()

    const q = db.prepare('SELECT * FROM rent_contract WHERE id = ?')
    q.bind([id])
    if (!q.step()) {
      q.free()
      return res.status(404).json({ code: 404, message: '合同不存在' })
    }
    const row = q.getAsObject()
    q.free()

    if (row.tenant_phone !== tenantPhone || row.status !== RENT_STATUS.ACTIVE) {
      return res.status(403).json({ code: 403, message: '无权操作' })
    }

    const now = Date.now()
    const u = db.prepare(`
      UPDATE rent_contract
      SET status = ?, updated_at = ?, remark = ?
      WHERE id = ?
    `)
    u.run([RENT_STATUS.QUIT_PENDING, now, reason || '', id])
    u.free()

    if (db.saveToDisk) db.saveToDisk()

    // 通知房东
    addMessage(
      row.landlord_phone,
      MESSAGE_TYPES.ORDER,
      '收到退租申请',
      `租客 ${tenantPhone} 申请退租`,
      JSON.stringify({ contractId: id, houseId: row.house_id })
    )

    return res.json({ code: 200, message: '已提交退租申请', data: null })
  } catch (e) {
    console.error('rent quit apply error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * ===============================
 * 6️⃣ 房东：同意退租
 * POST /auth/rent/quit/confirm
 * ===============================
 */
router.post('/rent/quit/confirm', async (req, res) => {
  try {
    const { id, landlordPhone } = req.body || {}
    if (!id || !landlordPhone) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()
    const q = db.prepare('SELECT * FROM rent_contract WHERE id = ?')
    q.bind([id])

    if (!q.step()) {
      q.free()
      return res.status(404).json({ code: 404, message: '合同不存在' })
    }

    const row = q.getAsObject()
    q.free()

    if (row.landlord_phone !== landlordPhone || row.status !== RENT_STATUS.QUIT_PENDING) {
      return res.status(403).json({ code: 403, message: '无权操作' })
    }

    const now = Date.now()
    const u = db.prepare(`
      UPDATE rent_contract
      SET status = ?, updated_at = ?
      WHERE id = ?
    `)
    u.run([RENT_STATUS.ENDED, now, id])
    u.free()

    // ✅ 合租模式：退租不修改 house_info 的 rentStatus

    if (db.saveToDisk) db.saveToDisk()

    addMessage(
      row.tenant_phone,
      MESSAGE_TYPES.ORDER,
      '退租已通过',
      '房东已同意你的退租申请',
      JSON.stringify({ contractId: id })
    )

    return res.json({ code: 200, message: '已同意退租', data: null })
  } catch (e) {
    console.error('rent quit confirm error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * ===============================
 * 7️⃣ 房东：驳回退租
 * POST /auth/rent/quit/reject
 * ===============================
 */
router.post('/rent/quit/reject', async (req, res) => {
  try {
    const { id, landlordPhone } = req.body || {}
    if (!id || !landlordPhone) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()
    const q = db.prepare('SELECT * FROM rent_contract WHERE id = ?')
    q.bind([id])

    if (!q.step()) {
      q.free()
      return res.status(404).json({ code: 404, message: '合同不存在' })
    }

    const row = q.getAsObject()
    q.free()

    if (row.landlord_phone !== landlordPhone || row.status !== RENT_STATUS.QUIT_PENDING) {
      return res.status(403).json({ code: 403, message: '无权操作' })
    }

    const now = Date.now()
    const u = db.prepare(`
      UPDATE rent_contract
      SET status = ?, updated_at = ?
      WHERE id = ?
    `)
    u.run([RENT_STATUS.ACTIVE, now, id])
    u.free()

    if (db.saveToDisk) db.saveToDisk()

    addMessage(
      row.tenant_phone,
      MESSAGE_TYPES.ORDER,
      '退租被驳回',
      '房东驳回了你的退租申请',
      JSON.stringify({ contractId: id })
    )

    return res.json({ code: 200, message: '已驳回退租', data: null })
  } catch (e) {
    console.error('rent quit reject error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

export default router
