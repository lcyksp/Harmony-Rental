import express from 'express'
import { getDB } from '../db.js'

console.log('[region] region router file loaded ✅')

const router = express.Router()

router.get('/ping', (req, res) => {
  console.log('[region] GET /region/ping hit ✅')
  res.json({ code: 200, message: 'pong' })
})

// GET /region/cities?keyword=北
router.get('/cities', async (req, res) => {
  console.log('[region] GET /region/cities hit ✅', req.query)
  try {
    const keyword = (req.query.keyword || '').toString().trim()
    const db = await getDB()

    let stmt
    if (keyword) {
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
        name: row.name,
        cityCode: String(row.code),
        provinceCode: String(row.province_code)
      })
    }
    stmt.free()

    return res.json({ code: 200, message: 'success', data: { list } })
  } catch (e) {
    console.error('/region/cities error:', e)
    return res.status(500).json({ code: 500, message: 'Internal server error', data: null })
  }
})

export default router
