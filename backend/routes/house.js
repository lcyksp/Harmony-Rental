// backend/routes/house.js
import express from 'express'
import path from 'path'
import { fileURLToPath } from 'url'
import { getDB } from '../db.js'
import { getHost } from '../utils/getHost.js'

const router = express.Router()

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// 从 metaInfo 提取「使用面积」
function extractArea(metaInfo) {
  if (!Array.isArray(metaInfo)) return ''
  const item = metaInfo.find((m) => m.name === '使用面积')
  return item && item.desc ? item.desc : ''
}

// 从 housePicture 取第一张图（原始相对路径，如 "/public/room95.jpg"）
function extractFirstPic(housePicture) {
  if (!Array.isArray(housePicture) || housePicture.length === 0) return ''
  const group = housePicture[0]
  const pics = Array.isArray(group.picList) ? group.picList : []
  if (!pics.length) return ''
  return pics[0]
}

function normStr(v) {
  return typeof v === 'string' ? v : ''
}

function matchRegion(detail, { provinceCode, cityCode, districtCode }) {
  const dProvince = normStr(detail.provinceCode || detail.province_code)
  const dCity = normStr(detail.cityCode || detail.city_code)
  const dDistrict = normStr(detail.districtCode || detail.district_code || detail.areaCode || detail.area_code)

  //区优先
  if (districtCode) return dDistrict === districtCode
  if (cityCode) return dCity === cityCode
  if (provinceCode) return dProvince === provinceCode
  return true
}

/**
 * 首页「周边房源推荐」列表
 * GET /house/nearbyHouses?provinceCode=&cityCode=&districtCode=&limit=8
 */
router.get('/nearbyHouses', async (req, res) => {
  const HOST = getHost(req)

  const provinceCode = normStr(req.query.provinceCode)
  const cityCode = normStr(req.query.cityCode)
  const districtCode = normStr(req.query.districtCode)
  const limit = Number(req.query.limit || 8)

  try {
    const db = await getDB()

    // 先多取一些再过滤，避免过滤后不足
    const fetchN = Math.max(limit * 5, 40)
    const stmt = db.prepare(`SELECT id, data FROM house_info LIMIT ${fetchN}`)

    const list = []

    while (stmt.step()) {
      const row = stmt.getAsObject()
      let detail = {}
      try {
        detail = JSON.parse(row.data || '{}')
      } catch (e) {
        detail = {}
      }

      //按区/市/省过滤
      if (!matchRegion(detail, { provinceCode, cityCode, districtCode })) {
        continue
      }

      const pic = extractFirstPic(detail.housePicture)
      const fullPic = pic && pic.startsWith('http') ? pic : (pic ? HOST + pic : '')

      list.push({
        id: row.id,
        houseTitle: detail.houseTitle || '',
        address: detail.address || '',
        rentPriceUnit: detail.rentPriceUnit || '元/月',
        rentPriceListing: String(detail.rentPriceUnitListing || detail.rentPrice || ''),
        rentArea: extractArea(detail.metaInfo),
        housePicture: fullPic,
        tags: (detail.tags || []).map(t => ({ name: t.name || t }))
      })

      if (list.length >= limit) break
    }

    stmt.free()

    res.json({
      code: 200,
      data: list,
      message: 'success'
    })
  } catch (err) {
    console.error('/nearbyHouses error:', err)
    res.status(500).json({ code: 500, data: null, message: err.message })
  }
})

/**
 * 房源详情
 * GET /house/detail?id=xxx
 */
router.get('/detail', async (req, res) => {
  const HOST = getHost(req)
  const id = req.query.id

  if (!id) {
    return res.status(400).json({
      code: 400,
      data: null,
      message: 'id is required'
    })
  }

  try {
    const db = await getDB()
    const stmt = db.prepare('SELECT id, data FROM house_info WHERE id = ?')
    stmt.bind([id])

    if (!stmt.step()) {
      stmt.free()
      return res.json({ code: 404, data: null, message: 'not found' })
    }

    const row = stmt.getAsObject()
    stmt.free()

    let detail = {}
    try {
      detail = JSON.parse(row.data || '{}')
    } catch (e) {
      console.error('parse house_info.data error:', e)
      return res.status(500).json({
        code: 500,
        data: null,
        message: '房源数据格式错误'
      })
    }

    // 确保有 id
    if (!detail.id) {
      detail.id = String(row.id)
    }

    // 补全图片 URL：housePicture[*].picList
    if (Array.isArray(detail.housePicture)) {
      detail.housePicture = detail.housePicture.map(group => {
        const pics = Array.isArray(group.picList) ? group.picList : []

        const fullPics = pics.map(p => {
          if (typeof p !== 'string') return p

          let v = p.trim()
          if (v.startsWith('http://') || v.startsWith('https://')) return v

          if (v.startsWith('/public/')) {
            // OK
          } else if (v.startsWith('/')) {
            v = '/public' + v
          } else {
            v = '/public/' + v
          }

          return HOST + v
        })

        return { ...group, picList: fullPics }
      })
    } else {
      detail.housePicture = []
    }

    // 其它字段兜底
    detail.metaInfo = detail.metaInfo || []
    detail.rentInfo = detail.rentInfo || []
    detail.rentTerm = detail.rentTerm || {}
    detail.tags = detail.tags || []
    detail.discounts = detail.discounts || []
    detail.householdItem = detail.householdItem || []
    detail.support = detail.support || []

    return res.json({
      code: 200,
      data: detail,
      message: 'success'
    })
  } catch (err) {
    console.error('/detail error:', err)
    return res.status(500).json({
      code: 500,
      data: null,
      message: '内部错误'
    })
  }
})

export default router
