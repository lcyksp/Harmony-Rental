import express from 'express'
import { getDB } from '../db.js'

console.log('[region] region router file loaded')

const router = express.Router()

/**
 * health check
 */
router.get('/ping', (req, res) => {
  res.json({ code: 200, message: 'pong' })
})

/**
 * =============================
 * 省列表
 * GET /region/provinces
 * =============================
 */
router.get('/provinces', async (req, res) => {
  try {
    const db = await getDB()
    const stmt = db.prepare(`
      SELECT code, name
      FROM province
      ORDER BY code ASC
    `)

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()
      list.push({
        code: String(row.code),
        name: row.name
      })
    }
    stmt.free()

    res.json({ code: 200, message: 'success', data: { list } })
  } catch (e) {
    console.error('/region/provinces error:', e)
    res.status(500).json({ code: 500, message: 'Internal server error', data: null })
  }
})

/**
 * =============================
 * 市列表
 * GET /region/cities
 *
 * 支持：
 * - ?provinceCode=11   （正式）
 * - ?keyword=北京       （兼容旧逻辑）
 * =============================
 */
router.get('/cities', async (req, res) => {
  try {
    const provinceCode = (req.query.provinceCode || '').toString().trim()
    const keyword = (req.query.keyword || '').toString().trim()
    const db = await getDB()

    let stmt
    if (provinceCode) {
      stmt = db.prepare(`
        SELECT code, name, province_code
        FROM city
        WHERE province_code = ?
        ORDER BY code ASC
      `)
      stmt.bind([provinceCode])
    } else if (keyword) {
      stmt = db.prepare(`
        SELECT code, name, province_code
        FROM city
        WHERE name LIKE ?
        ORDER BY code ASC
        LIMIT 50
      `)
      stmt.bind([`%${keyword}%`])
    } else {
      stmt = db.prepare(`
        SELECT code, name, province_code
        FROM city
        ORDER BY code ASC
        LIMIT 50
      `)
    }

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()
      list.push({
        code: String(row.code),
        name: row.name,
        provinceCode: String(row.province_code)
      })
    }
    stmt.free()

    res.json({ code: 200, message: 'success', data: { list } })
  } catch (e) {
    console.error('/region/cities error:', e)
    res.status(500).json({ code: 500, message: 'Internal server error', data: null })
  }
})

/**
 * =============================
 * 区 / 县列表
 * GET /region/areas?cityCode=1101
 * =============================
 */
router.get('/areas', async (req, res) => {
  try {
    const cityCode = (req.query.cityCode || '').toString().trim()
    if (!cityCode) {
      return res.json({ code: 200, message: 'success', data: { list: [] } })
    }

    const db = await getDB()
    const stmt = db.prepare(`
      SELECT code, name
      FROM area
      WHERE city_code = ?
      ORDER BY code ASC
    `)
    stmt.bind([cityCode])

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()
      list.push({
        code: String(row.code),
        name: row.name
      })
    }
    stmt.free()

    res.json({ code: 200, message: 'success', data: { list } })
  } catch (e) {
    console.error('/region/areas error:', e)
    res.status(500).json({ code: 500, message: 'Internal server error', data: null })
  }
})

export default router
