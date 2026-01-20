import express from 'express'
import { getDB } from '../db.js'

const router = express.Router()

function getTableColumns(db, tableName) {
  try {
    const r = db.exec(`PRAGMA table_info(${tableName});`)
    if (!r || r.length === 0) return []
    const cols = r[0].columns
    const nameIdx = cols.indexOf('name')
    if (nameIdx < 0) return []
    return r[0].values.map(row => String(row[nameIdx]))
  } catch {
    return []
  }
}

/**
 *确保 footprint 表存在 + 兼容旧驼峰字段(如果你之前建过 houseId/viewedAt 之类)
 */
function ensureFootprintTable(db) {
  const ddl = `
    CREATE TABLE IF NOT EXISTS footprint (
      user_id TEXT NOT NULL,
      house_id TEXT NOT NULL,
      viewed_at INTEGER NOT NULL,
      snapshot TEXT,
      PRIMARY KEY (user_id, house_id)
    );
  `
  db.exec(ddl)

  const cols = getTableColumns(db, 'footprint')
  const ok = cols.includes('user_id') && cols.includes('house_id') && cols.includes('viewed_at') && cols.includes('snapshot')
  if (ok) return

  // 旧表可能是驼峰字段
  const userCol = cols.includes('user_id') ? 'user_id' : (cols.includes('userId') ? 'userId' : '')
  const houseCol = cols.includes('house_id') ? 'house_id' : (cols.includes('houseId') ? 'houseId' : '')
  const timeCol = cols.includes('viewed_at') ? 'viewed_at' : (cols.includes('viewedAt') ? 'viewedAt' : '')
  const snapCol = cols.includes('snapshot') ? 'snapshot' : ''

  if (!userCol || !houseCol || !timeCol) {
    db.exec(`DROP TABLE IF EXISTS footprint;`)
    db.exec(ddl)
    return
  }

  db.exec(`
    CREATE TABLE IF NOT EXISTS footprint_v2 (
      user_id TEXT NOT NULL,
      house_id TEXT NOT NULL,
      viewed_at INTEGER NOT NULL,
      snapshot TEXT,
      PRIMARY KEY (user_id, house_id)
    );
  `)

  const selSnap = snapCol ? snapCol : "''"
  db.exec(`
    INSERT OR REPLACE INTO footprint_v2 (user_id, house_id, viewed_at, snapshot)
    SELECT ${userCol}, ${houseCol}, ${timeCol}, ${selSnap}
    FROM footprint;
  `)

  db.exec(`DROP TABLE footprint;`)
  db.exec(`ALTER TABLE footprint_v2 RENAME TO footprint;`)
}

function getAuthFromQuery(req) {
  const phone = String(req.query?.phone || '').trim()
  const userId = String(req.query?.userId || '').trim()
  return { phone, userId }
}

function getAuthFromBody(req) {
  const phone = String(req.body?.phone || '').trim()
  const userId = String(req.body?.userId || '').trim()
  return { phone, userId }
}

//足迹用户主键：永远优先 phone（最稳定）
function pickUserKey(phone, userId) {
  return phone || userId || ''
}

//如果同时带 phone+userId 且不同：把旧 userId 的记录迁移到 phone（不丢历史）
function migrateUserIdToPhone(db, phone, userId) {
  if (!phone || !userId || phone === userId) return
  const stmt = db.prepare(`UPDATE footprint SET user_id=? WHERE user_id=?`)
  stmt.run([phone, userId])
  stmt.free()
}

// 从 house_info 里拼快照
function normalizeCoverPath(v) {
  const s = String(v || '').trim()
  if (!s) return ''

  // http(s) 直接返回
  if (s.startsWith('http://') || s.startsWith('https://')) return s

  // 以 / 开头（/public/xx.jpg 或 /xx.jpg）直接返回
  if (s.startsWith('/')) return s

  // public/xx.jpg -> /public/xx.jpg
  if (s.startsWith('public/')) return '/' + s

  // 纯文件名 room11.jpg -> /public/room11.jpg（你们一般静态资源在 /public）
  return '/public/' + s
}

function firstImageFromAny(x) {
  // x 可能是 string / array<string> / array<object>
  if (!x) return ''
  if (typeof x === 'string') return normalizeCoverPath(x)

  if (Array.isArray(x) && x.length > 0) {
    const first = x[0]
    if (typeof first === 'string') return normalizeCoverPath(first)
    if (first && typeof first === 'object') {
      // 常见对象字段
      return normalizeCoverPath(first.url || first.imageUrl || first.imageURL || first.src || first.path || '')
    }
  }
  return ''
}

function firstPicFromHousePicture(hp) {
  if (!Array.isArray(hp)) return ''

  for (const item of hp) {
    if (!item || typeof item !== 'object') continue

    // 兼容多种 key：picList / pic_list / pics / images / list
    const picList =
      item.picList || item.pic_list || item.pics || item.images || item.list || []

    const got = firstImageFromAny(picList)
    if (got) return got
  }
  return ''
}

function getHouseSnapshot(db, houseId) {
  try {
    const q = db.prepare(`SELECT data FROM house_info WHERE id = ?`)
    q.bind([houseId])
    if (!q.step()) {
      q.free()
      return null
    }
    const row = q.getAsObject()
    q.free()

    const data = row && row.data ? JSON.parse(row.data) : {}

    const title = data?.title || data?.houseTitle || data?.name || ''

    let priceText = data?.priceText || ''
    if (!priceText) {
      const p1 = data?.rentPriceListing || data?.rentPrice || data?.price || ''
      const u1 = data?.rentPriceUnit || data?.rentPriceUnitListing || ''
      if (p1) priceText = `${p1}${u1}`
    }

    const address = data?.address || data?.location || ''

    // 1) 直接字段（兼容下划线/大小写）
    let coverUrl =
      firstImageFromAny(data?.coverUrl) ||
      firstImageFromAny(data?.cover_url) ||
      firstImageFromAny(data?.imageUrl) ||
      firstImageFromAny(data?.imageURL) ||
      firstImageFromAny(data?.imgUrl) ||
      firstImageFromAny(data?.thumbnail)

    // 2) pics/images（可能是 string 或数组或对象数组）
    if (!coverUrl) {
      coverUrl = firstImageFromAny(data?.pics || data?.images || data?.pictureList || data?.picList)
    }

    // 3)兜底：housePicture / house_picture
    if (!coverUrl) {
      coverUrl =
        firstPicFromHousePicture(data?.housePicture) ||
        firstPicFromHousePicture(data?.house_picture) ||
        firstPicFromHousePicture(data?.housePictures) ||
        firstPicFromHousePicture(data?.house_pictures)
    }

    return {
      houseId: String(houseId),
      title: String(title || ''),
      priceText: String(priceText || ''),
      address: String(address || ''),
      coverUrl: String(coverUrl || '')
    }
  } catch {
    return null
  }
}

/**
 * POST /auth/footprint/add
 */
router.post('/footprint/add', async (req, res) => {
  try {
    const { phone, userId } = getAuthFromBody(req)
    const houseId = req.body?.houseId
    const userKey = pickUserKey(phone, userId)

    if (!userKey || !houseId) {
      return res.status(401).json({ code: 401, data: null, message: '缺少 phone 或 userId / houseId' })
    }

    const db = await getDB()
    ensureFootprintTable(db)

    //迁移：把旧 userId 的记录合并到 phone
    migrateUserIdToPhone(db, phone, userId)

    const now = Date.now()
    const snapshot = getHouseSnapshot(db, String(houseId))
    const snapStr = snapshot ? JSON.stringify(snapshot) : ''

    const stmt = db.prepare(`
      INSERT INTO footprint (user_id, house_id, viewed_at, snapshot)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id, house_id)
      DO UPDATE SET viewed_at=excluded.viewed_at, snapshot=excluded.snapshot
    `)

    //写入也统一用 phone 优先（稳定）
    const writeKey = pickUserKey(phone, userId)
    stmt.run([String(writeKey), String(houseId), now, snapStr])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()
    return res.json({ code: 200, message: 'ok', data: null })
  } catch (e) {
    console.error('footprint add error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * GET /auth/footprint/list
 */
router.get('/footprint/list', async (req, res) => {
  try {
    const { phone, userId } = getAuthFromQuery(req)
    const userKey = pickUserKey(phone, userId)
    const limit = Number(req.query?.limit || req.query?.size || 50)

    if (!userKey) {
      return res.status(401).json({ code: 401, data: null, message: '缺少 phone 或 userId' })
    }

    const db = await getDB()
    ensureFootprintTable(db)

    //读取前也做一次迁移（只要你带了 phone+userId 就能把旧数据合并）
    migrateUserIdToPhone(db, phone, userId)

    const q = db.prepare(`
      SELECT user_id, house_id, viewed_at, snapshot
      FROM footprint
      WHERE user_id = ?
      ORDER BY viewed_at DESC
      LIMIT ?
    `)
    q.bind([String(userKey), limit])

    const list = []
    while (q.step()) {
      const r = q.getAsObject()
      let snap = null
      try {
        snap = r.snapshot ? JSON.parse(r.snapshot) : null
      } catch {
        snap = null
      }
      list.push({
        userId: String(r.user_id || ''),
        houseId: String(r.house_id || ''),
        viewedAt: Number(r.viewed_at || 0),
        snapshot: snap
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
 * POST /auth/footprint/remove
 */
router.post('/footprint/remove', async (req, res) => {
  try {
    const { phone, userId } = getAuthFromBody(req)
    const userKey = pickUserKey(phone, userId)
    const houseId = req.body?.houseId

    if (!userKey || !houseId) {
      return res.status(401).json({ code: 401, data: null, message: '缺少 phone 或 userId / houseId' })
    }

    const db = await getDB()
    ensureFootprintTable(db)
    migrateUserIdToPhone(db, phone, userId)

    const stmt = db.prepare(`DELETE FROM footprint WHERE user_id=? AND house_id=?`)
    stmt.run([String(userKey), String(houseId)])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()
    return res.json({ code: 200, message: 'ok', data: null })
  } catch (e) {
    console.error('footprint remove error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

/**
 * POST /auth/footprint/clear
 */
router.post('/footprint/clear', async (req, res) => {
  try {
    const { phone, userId } = getAuthFromBody(req)
    const userKey = pickUserKey(phone, userId)

    if (!userKey) {
      return res.status(401).json({ code: 401, data: null, message: '缺少 phone 或 userId' })
    }

    const db = await getDB()
    ensureFootprintTable(db)
    migrateUserIdToPhone(db, phone, userId)

    const stmt = db.prepare(`DELETE FROM footprint WHERE user_id=?`)
    stmt.run([String(userKey)])
    stmt.free()

    if (db.saveToDisk) db.saveToDisk()
    return res.json({ code: 200, message: 'ok', data: null })
  } catch (e) {
    console.error('footprint clear error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error' })
  }
})

export default router
