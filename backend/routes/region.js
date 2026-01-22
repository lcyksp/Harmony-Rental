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
        name: row.name,
        cityCode: String(row.code),
        provinceCode: String(row.province_code)
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
    const limit = Math.max(parseInt(String(req.query.limit || '50'), 10) || 50, 1)

    const db = await getDB()

    let stmt
    if (provinceCode) {
      //只取“市级”（4位码）；直辖市会把“市辖区”转成“北京市/天津市…”
      stmt = db.prepare(`
        SELECT
          c.code AS code,
          CASE
            WHEN c.name = '市辖区' AND p.name IS NOT NULL THEN p.name
            ELSE c.name
          END AS name,
          c.province_code AS province_code
        FROM city c
        LEFT JOIN province p ON p.code = c.province_code
        WHERE c.province_code = ?
          AND LENGTH(CAST(c.code AS TEXT)) = 4
        ORDER BY CAST(c.code AS INTEGER) ASC
      `)
      stmt.bind([provinceCode])
    } else if (keyword) {
      //keyword 同时查 city.name 和 province.name；依然只取 4 位码
      stmt = db.prepare(`
        SELECT
          c.code AS code,
          CASE
            WHEN c.name = '市辖区' AND p.name IS NOT NULL THEN p.name
            ELSE c.name
          END AS name,
          c.province_code AS province_code
        FROM city c
        LEFT JOIN province p ON p.code = c.province_code
        WHERE LENGTH(CAST(c.code AS TEXT)) = 4
          AND (c.name LIKE ? OR p.name LIKE ?)
        ORDER BY CAST(c.code AS INTEGER) ASC
        LIMIT ?
      `)
      stmt.bind([`%${keyword}%`, `%${keyword}%`, limit])
    } else {
      //默认列表：只给 4 位码城市；直辖市名称转换
      stmt = db.prepare(`
        SELECT
          c.code AS code,
          CASE
            WHEN c.name = '市辖区' AND p.name IS NOT NULL THEN p.name
            ELSE c.name
          END AS name,
          c.province_code AS province_code
        FROM city c
        LEFT JOIN province p ON p.code = c.province_code
        WHERE LENGTH(CAST(c.code AS TEXT)) = 4
        ORDER BY CAST(c.code AS INTEGER) ASC
        LIMIT ?
      `)
      stmt.bind([limit])
    }

    const list = []
    while (stmt.step()) {
      const row = stmt.getAsObject()
      list.push({
        code: String(row.code),
        name: String(row.name),
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
