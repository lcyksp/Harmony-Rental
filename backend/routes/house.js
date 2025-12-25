// backend/routes/house.js
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { getDB } from '../db.js';
import { getHost } from '../utils/getHost.js';

const router = express.Router();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 从 metaInfo 提取「使用面积」
function extractArea(metaInfo) {
  if (!Array.isArray(metaInfo)) return '';
  const item = metaInfo.find((m) => m.name === '使用面积');
  return item && item.desc ? item.desc : '';
}

// 从 housePicture 取第一张图（原始相对路径，如 "/public/room95.jpg"）
function extractFirstPic(housePicture) {
  if (!Array.isArray(housePicture) || housePicture.length === 0) return '';
  const group = housePicture[0];
  const pics = Array.isArray(group.picList) ? group.picList : [];
  if (!pics.length) return '';
  return pics[0];
}

/**
 * 首页「周边房源推荐」列表
 * GET /house/nearbyHouses
 */
router.get('/nearbyHouses', async (req, res) => {
  const HOST = getHost(req);

  try {
    const db = await getDB();
    const stmt = db.prepare('SELECT id, data FROM house_info LIMIT 8');

    const list = [];

    while (stmt.step()) {
      const row = stmt.getAsObject();
      const detail = JSON.parse(row.data || '{}');

      const pic = extractFirstPic(detail.housePicture);
      const fullPic = pic && pic.startsWith('http') ? pic : (pic ? HOST + pic : '');

      list.push({
        id: row.id,
        houseTitle: detail.houseTitle || '',
        address: detail.address || '',
        rentPriceUnit: detail.rentPriceUnit || '元/月',
        rentPriceListing: String(detail.rentPriceUnitListing || detail.rentPrice || ''),
        rentArea: extractArea(detail.metaInfo),
        housePicture: fullPic,
        tags: (detail.tags || []).map(t => ({ name: t.name || t })),
      });
    }

    stmt.free();

    res.json({
      code: 200,
      data: list,
      message: 'success',
    });
  } catch (err) {
    console.error('/nearbyHouses error:', err);
    res.status(500).json({ code: 500, data: null, message: err.message });
  }
});

/**
 * 房源详情
 * GET /house/detail?id=xxx
 */
router.get('/detail', async (req, res) => {
  const HOST = getHost(req);
  const id = req.query.id;

  if (!id) {
    return res.status(400).json({
      code: 400,
      data: null,
      message: 'id is required',
    });
  }

  try {
    const db = await getDB();
    const stmt = db.prepare('SELECT id, data FROM house_info WHERE id = ?');
    stmt.bind([id]);

    if (!stmt.step()) {
      stmt.free();
      return res.json({ code: 404, data: null, message: 'not found' });
    }

    const row = stmt.getAsObject();
    stmt.free();

    let detail = {};
    try {
      detail = JSON.parse(row.data || '{}');
    } catch (e) {
      console.error('parse house_info.data error:', e);
      return res.status(500).json({
        code: 500,
        data: null,
        message: '房源数据格式错误',
      });
    }

    // 确保有 id
    if (!detail.id) {
      detail.id = String(row.id);
    }

    // 补全图片 URL：housePicture[*].picList
    if (Array.isArray(detail.housePicture)) {
      detail.housePicture = detail.housePicture.map(group => {
        const pics = Array.isArray(group.picList) ? group.picList : [];

        const fullPics = pics.map(p => {
          if (typeof p !== 'string') {
            return p;
          }

          let v = p.trim();

          // 已经是完整 URL，直接返回
          if (v.startsWith('http://') || v.startsWith('https://')) {
            return v;
          }

          // 统一处理成以 /public/ 开头的相对路径
          if (v.startsWith('/public/')) {
            // OK，保持不变
          } else if (v.startsWith('/')) {
            // '/room2.jpg' -> '/public/room2.jpg'
            v = '/public' + v;
          } else {
            // 'room2.jpg' -> '/public/room2.jpg'
            v = '/public/' + v;
          }

          // 拼上 HOST
          return HOST + v;
        });

        return {
          ...group,
          picList: fullPics,
        };
      });
    } else {
      detail.housePicture = [];
    }


    // 其它字段兜底，防止前端 undefined 报错
    detail.metaInfo = detail.metaInfo || [];
    detail.rentInfo = detail.rentInfo || [];
    detail.rentTerm = detail.rentTerm || {};
    detail.tags = detail.tags || [];
    detail.discounts = detail.discounts || [];
    detail.householdItem = detail.householdItem || [];
    detail.support = detail.support || [];

    return res.json({
      code: 200,
      data: detail,
      message: 'success',
    });
  } catch (err) {
    console.error('/detail error:', err);
    return res.status(500).json({
      code: 500,
      data: null,
      message: '内部错误',
    });
  }
});

export default router;
