import express from 'express'
import { getDB } from '../db.js'

const router = express.Router()

/**
 * ✅ 确保 footprint 表存在（只会建一次）
 * 和你现有 ON CONFLICT(user_id, house_id) 完全匹配
 */
function ensureFootprintTable(db) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS footprint (
      user_id TEXT NOT NULL,
      house_id TEXT NOT NULL,
      viewed_at INTEGER NOT NULL,
      snapshot TEXT,
      PRIMARY KEY (user_id, house_id)
    );
  `)
}

// 从 house_info 里拼一个快照（可选，但推荐）
function getHouseSnapshot(db, houseId, req) {
  try {
    const q = db.prepare(`SELECT data FROM house_info WHERE id = ?`)
    q.bind([houseId])
    if (!q.step()) {
      q.free()
      return null
    }
    const row = q.getAsObject()
    q.free()

    const data = row?.data ? JSON.parse(row.data) : {}
    const title = data?.title || data?.houseTitle || data?.name || ''
    const price = data?.price || data?.rent || ''
    const address = data?.address || data?.location || ''
    const pics = data?.pics || data?.images || data?.coverUrl || []

    let coverUrl = ''
    if (typeof pics === 'string') {
      coverUrl = pics
    } else if (Array.isArray(pics) && pics.length > 0) {
      coverUrl = pics[0]
    } else if (typeof data?.coverUrl === 'string') {
      coverUrl = data.coverUrl
    }

    return { houseId, title, price, address, coverUrl }
  } catch (e) {
    return null
  }
}

/**
 * 1) 写入足迹（同一房源只保留一条，更新时间）
 * POST /auth/footprint/add
 */
router.post('/footprint/add', async (req, res) => {
  try {
    const { userId, houseId } = req.body || {}
    if (!userId || !houseId) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()
    ensureFootprintTable(db) // ✅ 关键

    const now = Date.now()
    const snapshot = getHouseSnapshot(db, houseId, req)
    const snapStr = snapshot ? JSON.stringify(snapshot) : ''

    const stmt = db.prepare(`
      INSERT INTO footprint (user_id, house_id, viewed_at, snapshot)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id, house_id)
      DO UPDATE SET viewed_at=excluded.viewed_at, snapshot=excluded.snapshot
    `)
    stmt.run([String(userId), String(houseId), now, snapStr])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()
    return res.json({ code: 200, message: 'ok', data: null })
  } catch (e) {
    console.error('footprint add error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 2) 获取足迹列表
 * GET /auth/footprint/list
 */
router.get('/footprint/list', async (req, res) => {
  try {
    const userId = req.query.userId
    const limit = Number(req.query.limit || 50)
    if (!userId) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()
    ensureFootprintTable(db) // ✅ 关键

    const q = db.prepare(`
      SELECT user_id, house_id, viewed_at, snapshot
      FROM footprint
      WHERE user_id = ?
      ORDER BY viewed_at DESC
      LIMIT ?
    `)
    q.bind([String(userId), limit])

    const list = []
    while (q.step()) {
      const r = q.getAsObject()
      list.push({
        userId: r.user_id,
        houseId: r.house_id,
        viewedAt: Number(r.viewed_at || 0),
        snapshot: r.snapshot ? JSON.parse(r.snapshot) : null
      })
    }
    q.free()

    return res.json({ code: 200, message: 'ok', data: list })
  } catch (e) {
    console.error('footprint list error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 3) 删除单条足迹
 */
router.post('/footprint/remove', async (req, res) => {
  try {
    const { userId, houseId } = req.body || {}
    if (!userId || !houseId) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()
    ensureFootprintTable(db) // ✅ 关键

    const stmt = db.prepare(`DELETE FROM footprint WHERE user_id=? AND house_id=?`)
    stmt.run([String(userId), String(houseId)])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()
    return res.json({ code: 200, message: 'ok', data: null })
  } catch (e) {
    console.error('footprint remove error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * 4) 清空足迹
 */
router.post('/footprint/clear', async (req, res) => {
  try {
    const { userId } = req.body || {}
    if (!userId) {
      return res.status(400).json({ code: 400, message: '参数错误' })
    }

    const db = await getDB()
    ensureFootprintTable(db) // ✅ 关键

    const stmt = db.prepare(`DELETE FROM footprint WHERE user_id=?`)
    stmt.run([String(userId)])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()
    return res.json({ code: 200, message: 'ok', data: null })
  } catch (e) {
    console.error('footprint clear error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

export default router
