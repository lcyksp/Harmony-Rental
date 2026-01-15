// backend/routes/rooms.js
import express from 'express';
import { getDB } from '../db.js';

const router = express.Router();

/**
 * 确保订单表存在（为了后面 /rooms/:id/orders 不报错）
 */
function ensureOrdersTable(db) {
  db.run(
    `CREATE TABLE IF NOT EXISTS rental_orders (
      id TEXT PRIMARY KEY,
      room_id TEXT NOT NULL,
      owner_id TEXT NOT NULL,
      tenant_id TEXT NOT NULL,
      tenant_name TEXT,
      tenant_phone TEXT,
      remark TEXT,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )`
  );
}

// 简单的订单 id 生成
function genOrderId() {
  return 'O' + Date.now();
}

/**
 * 租客提交“我要租”订单：POST /rooms/:id/orders
 */
router.post('/:id/orders', async (req, res) => {
  try {
    const roomId = req.params.id;
    const db = await getDB();
    ensureOrdersTable(db);

    // 1. 查房源，拿 ownerId
    const stmt = db.prepare('SELECT id, data FROM house_info WHERE id = ?');
    stmt.bind([roomId]);

    if (!stmt.step()) {
      stmt.free();
      return res.status(404).json({ code: 404, data: null, message: '房源不存在' });
    }

    const row = stmt.getAsObject();
    stmt.free();

    let detail = {};
    try {
      detail = row.data ? JSON.parse(row.data) : {};
    } catch (e) {
      console.error('parse house_info.data error:', e);
    }

    const ownerId = detail.ownerId;
    if (!ownerId) {
      return res.status(400).json({ code: 400, data: null, message: '房源缺少 ownerId，无法创建订单' });
    }

    // 2. 从 body 里拿租客信息
    const body = req.body || {};
    const tenantId = body.tenantId;
    if (!tenantId) {
      return res.status(400).json({ code: 400, data: null, message: '缺少租客 tenantId' });
    }

    const tenantName = body.tenantName || '';
    const tenantPhone = body.tenantPhone || '';
    const remark = body.remark || '';

    const now = Date.now();
    const orderId = genOrderId();

    db.run(
      `INSERT INTO rental_orders (
        id, room_id, owner_id, tenant_id,
        tenant_name, tenant_phone, remark,
        status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [orderId, roomId, ownerId, tenantId, tenantName, tenantPhone, remark, 'pending', now, now]
    );

    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    return res.json({ code: 200, data: { id: orderId }, message: '预约成功，等待房东确认' });
  } catch (err) {
    console.error('POST /rooms/:id/orders error:', err);
    return res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 把相对路径转成绝对 URL
 */
function toAbsoluteUrl(req, path) {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  const baseUrl = `${req.protocol}://${req.headers.host}`;
  if (!path.startsWith('/')) path = '/' + path;
  return baseUrl + path;
}

/**
 * 统一图片路径到 /public/xxx 的形式
 */
function normalizePicForPublic(path) {
  if (!path) return '';

  if (path.startsWith('http://') || path.startsWith('https://')) {
    try {
      const u = new URL(path);
      path = u.pathname || '';
    } catch (e) {
      path = path.replace(/^https?:\/\/[^/]+/, '');
    }
  }

  if (path.startsWith('/public/')) return path;

  if (path.startsWith('public/')) {
    path = path.substring('public/'.length);
  }

  if (!path.startsWith('/')) {
    path = '/public/' + path;
  } else {
    path = '/public' + path;
  }

  return path;
}

/**
 * 把一条 row(id, data) 解析成前端需要的 item
 */
function mapRowToItem(req, row) {
  let detail = {};
  try {
    detail = row.data ? JSON.parse(row.data) : {};
  } catch (e) {
    console.error('parse house_info.data error:', e);
  }

  // ① 封面图
  let firstPic = '';
  if (Array.isArray(detail.housePicture) && detail.housePicture.length > 0) {
    const g = detail.housePicture[0];
    if (g && Array.isArray(g.picList) && g.picList.length > 0) {
      firstPic = g.picList[0];
    }
  }
  if (!firstPic && typeof detail.housePicture === 'string') {
    firstPic = detail.housePicture;
  }

  const picPathInPublic = normalizePicForPublic(firstPic);
  const housePictureUrl = picPathInPublic ? toAbsoluteUrl(req, picPathInPublic) : '';

  // ② 价格
  const price =
    detail.rentPriceListing ??
    detail.rentPriceUnitListing ??
    detail.rentPrice ??
      '';

  // ③ 面积
  let area = null;
  if (detail.rentArea != null && detail.rentArea !== '') area = detail.rentArea;
  else if (detail.area != null && detail.area !== '') area = detail.area;
  else if (detail.houseArea != null && detail.houseArea !== '') area = detail.houseArea;

  if ((area == null || area === '') && Array.isArray(detail.metaInfo)) {
    const areaMeta = detail.metaInfo.find(info => info && info.name === '使用面积');
    if (areaMeta && areaMeta.desc != null && areaMeta.desc !== '') {
      area = areaMeta.desc;
    }
  }

  const ownerId = detail.ownerId || null;
  const status = detail.status || 'online';

  const item = {
    id: detail.id || row.id || null,
    houseTitle: detail.houseTitle || detail.title || '',
    rentPriceListing: String(price || ''),
    rentPriceUnit: detail.rentPriceUnit || '元/月',
    rentArea: String(area || ''),
    address: detail.address || detail.location || detail.districtName || '',
    housePicture: housePictureUrl,
    tags: detail.tags || detail.tagList || [],

    // 兼容旧字段
    title: detail.title || '',
    location: detail.location || '',
    rentPrice: price,
    area: area,
    imageUrl: housePictureUrl,
    coverUrl: housePictureUrl,

    ownerId,
    status,

    ...detail
  };

  return { item, detail };
}

/**
 * 房源列表：GET /rooms
 * 支持 keyword 关键词搜索（标题 / 地址 / 区域 等）
 * 只返回 online
 */
router.get('/', async (req, res) => {
  try {
    const db = await getDB();
    const rawKeyword = req.query.keyword;
    const keyword = typeof rawKeyword === 'string' ? rawKeyword.trim() : '';

    const list = [];
    const stmt = db.prepare('SELECT id, data FROM house_info');
    const kwLower = keyword ? keyword.toLowerCase() : '';

    while (stmt.step()) {
      const row = stmt.getAsObject();
      const { item, detail } = mapRowToItem(req, row);

      const status = detail.status || 'online';
      if (status !== 'online') continue;

      if (kwLower) {
        const haystack = (
          (item.houseTitle || '') + ' ' +
            (item.title || '') + ' ' +
            (item.address || '') + ' ' +
            (item.location || '') + ' ' +
            (detail.districtName || '') + ' ' +
            (detail.schoolName || '')
        ).toLowerCase();
        if (!haystack.includes(kwLower)) continue;
      }

      list.push(item);
    }

    stmt.free();

    res.json({ code: 200, data: { list, total: list.length }, message: 'success' });
  } catch (err) {
    console.error('GET /rooms error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 我的房源：GET /rooms/my?ownerId=xxx
 */
router.get('/my', async (req, res) => {
  try {
    const ownerId = req.query.ownerId;
    if (!ownerId) return res.status(400).json({ code: 400, data: null, message: '缺少 ownerId' });

    const db = await getDB();
    const stmt = db.prepare('SELECT id, data FROM house_info');

    const list = [];
    while (stmt.step()) {
      const row = stmt.getAsObject();
      const { item, detail } = mapRowToItem(req, row);
      const rowOwnerId = detail.ownerId || null;
      if (rowOwnerId === ownerId) list.push(item);
    }

    stmt.free();
    res.json({ code: 200, data: { list, total: list.length }, message: 'success' });
  } catch (err) {
    console.error('GET /rooms/my error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 我发布的房源（已上架，用于“我发布的”轮播）
 * GET /rooms/my/published?ownerId=xxx
 */
router.get('/my/published', async (req, res) => {
  try {
    const ownerId = req.query.ownerId;
    if (!ownerId) return res.status(400).json({ code: 400, data: null, message: '缺少 ownerId' });

    const db = await getDB();
    const stmt = db.prepare('SELECT id, data FROM house_info');

    const list = [];
    while (stmt.step()) {
      const row = stmt.getAsObject();
      const { item, detail } = mapRowToItem(req, row);

      const rowOwnerId = detail.ownerId || null;
      const status = detail.status || 'online';

      if (rowOwnerId === ownerId && status === 'online') {
        const priceStr = item.rentPriceListing || String(item.rentPrice ?? '') || '';
        list.push({
          id: String(row.id),
          title: item.houseTitle || item.title || '',
          price: priceStr,
          address: item.address || item.location || ''
        });
      }
    }

    stmt.free();
    res.json({ code: 200, data: { list, total: list.length }, message: 'success' });
  } catch (err) {
    console.error('GET /rooms/my/published error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 我租到的房源：当前先返回空
 * GET /rooms/my/rented?tenantId=xxx
 */
router.get('/my/rented', async (req, res) => {
  try {
    const tenantId = req.query.tenantId;
    if (!tenantId) return res.status(400).json({ code: 400, data: null, message: '缺少 tenantId' });

    res.json({ code: 200, data: { list: [], total: 0 }, message: 'success' });
  } catch (err) {
    console.error('GET /rooms/my/rented error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 房源新增：POST /rooms
 */
router.post('/', async (req, res) => {
  try {
    const db = await getDB();
    const payload = req.body || {};

    if (!payload || !payload.houseTitle) {
      return res.status(400).json({ code: 400, data: null, message: 'houseTitle 不能为空' });
    }

    const clientId = payload.id && String(payload.id).trim();
    const newId = clientId || ('U' + Date.now());

    const ownerId = payload.ownerId || payload.phone || null;
    const status = payload.status || 'online';
    const landlordPhone = payload.landlordPhone || null;

    const merged = { ...payload, id: newId, ownerId, landlordPhone, status };
    const dataStr = JSON.stringify(merged);

    db.run(
      `INSERT INTO house_info (
        id, data, hdic_district_name, rent_price_unit_listing, rent_area, payment,
        area_code, city_code, province_code
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        newId,
        dataStr,
        merged.hdic_district_name || null,
        merged.rentPriceUnitListing || null,
        merged.rent_area || null,
        merged.payment || null,
        merged.area_code || null,
        merged.city_code || null,
        merged.province_code || null
      ]
    );

    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    return res.json({ code: 200, data: { id: newId }, message: '发布成功' });
  } catch (err) {
    console.error('POST /rooms error:', err);
    return res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 删除 / 下架房源：POST /rooms/delete （保留你原逻辑：下架）
 */
router.post('/delete', async (req, res) => {
  try {
    const { id } = req.body || {};
    if (!id || id === 'null' || id === 'undefined') {
      return res.status(400).json({ code: 400, data: null, message: '缺少或非法的房源 id' });
    }

    const db = await getDB();
    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?');
    stmt.bind([id]);

    if (!stmt.step()) {
      stmt.free();
      return res.status(404).json({ code: 404, data: null, message: '房源不存在' });
    }

    const row = stmt.getAsObject();
    stmt.free();

    let detail = {};
    try { detail = row.data ? JSON.parse(row.data) : {}; } catch (e) {}

    detail.status = 'offline';
    db.run('UPDATE house_info SET data = ? WHERE id = ?', [JSON.stringify(detail), id]);

    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    res.json({ code: 200, data: null, message: '房源已下架' });
  } catch (err) {
    console.error('POST /rooms/delete error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 房源下架：POST /rooms/:id/offline
 */
router.post('/:id/offline', async (req, res) => {
  try {
    const id = req.params.id;
    const db = await getDB();

    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?');
    stmt.bind([id]);

    if (!stmt.step()) {
      stmt.free();
      return res.status(404).json({ code: 404, data: null, message: '房源不存在' });
    }

    const row = stmt.getAsObject();
    stmt.free();

    let detail = {};
    try { detail = row.data ? JSON.parse(row.data) : {}; } catch (e) {}

    detail.status = 'offline';
    db.run('UPDATE house_info SET data = ? WHERE id = ?', [JSON.stringify(detail), id]);

    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    res.json({ code: 200, data: null, message: '房源已下架' });
  } catch (err) {
    console.error('POST /rooms/:id/offline error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

/**
 * 房源上架：POST /rooms/:id/online
 */
router.post('/:id/online', async (req, res) => {
  try {
    const id = req.params.id;
    const db = await getDB();

    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?');
    stmt.bind([id]);

    if (!stmt.step()) {
      stmt.free();
      return res.status(404).json({ code: 404, data: null, message: '房源不存在' });
    }

    const row = stmt.getAsObject();
    stmt.free();

    let detail = {};
    try { detail = row.data ? JSON.parse(row.data) : {}; } catch (e) {}

    detail.status = 'online';
    db.run('UPDATE house_info SET data = ? WHERE id = ?', [JSON.stringify(detail), id]);

    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    res.json({ code: 200, data: null, message: '房源已上架' });
  } catch (err) {
    console.error('POST /rooms/:id/online error:', err);
    res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

// ======================= 管理员接口（仅此一套） =======================

function getTokenPhone(req) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : auth;
  if (!token.startsWith('mock-token-')) return '';
  return token.replace('mock-token-', '').trim();
}

async function requireAdmin(req, res, next) {
  try {
    const phone = getTokenPhone(req);
    if (!phone) return res.status(401).json({ code: 401, data: null, message: '未登录' });

    const db = await getDB();
    const rows = db.exec(`SELECT role, status FROM users WHERE phone='${phone}'`);
    if (!rows.length || !rows[0].values.length) {
      return res.status(401).json({ code: 401, data: null, message: '无效登录' });
    }

    const role = rows[0].values[0][0];
    const status = rows[0].values[0][1];

    if ((status ?? 1) !== 1) return res.status(403).json({ code: 403, data: null, message: '账号已禁用' });
    if (role !== 'admin') return res.status(403).json({ code: 403, data: null, message: '无管理员权限' });

    next();
  } catch (e) {
    console.error('requireAdmin error:', e);
    return res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
}

// 管理员：房源全量列表 + 搜索 + 状态筛选
// GET /rooms/admin/list?keyword=&status=all|online|offline
router.get('/admin/list', requireAdmin, async (req, res) => {
  try {
    const db = await getDB();
    const keyword = typeof req.query.keyword === 'string' ? req.query.keyword.trim().toLowerCase() : '';
    const statusFilter = typeof req.query.status === 'string' ? req.query.status.trim() : 'all';

    const list = [];
    const stmt = db.prepare('SELECT id, data FROM house_info');

    while (stmt.step()) {
      const row = stmt.getAsObject();
      const { item, detail } = mapRowToItem(req, row);

      const status = detail.status || 'online';
      if (statusFilter !== 'all' && status !== statusFilter) continue;

      if (keyword) {
        const hay = (
          (item.houseTitle || '') + ' ' +
            (item.address || '') + ' ' +
            (detail.districtName || '') + ' ' +
            (detail.schoolName || '') + ' ' +
          String(row.id || '')
        ).toLowerCase();
        if (!hay.includes(keyword)) continue;
      }

      item.status = status;
      list.push(item);
    }

    stmt.free();
    return res.json({ code: 200, data: { list, total: list.length }, message: 'success' });
  } catch (e) {
    console.error('GET /rooms/admin/list error:', e);
    return res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

// 管理员：更新房源 JSON（合并写回 house_info.data）
// PUT /rooms/admin/:id
router.put('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const id = req.params.id;
    const incoming = req.body || {};

    if (!id) return res.json({ code: 400, data: null, message: 'id 不能为空' });
    if (!incoming || typeof incoming !== 'object') {
      return res.json({ code: 400, data: null, message: 'body 不能为空' });
    }

    const db = await getDB();
    const stmt = db.prepare('SELECT data FROM house_info WHERE id = ?');
    stmt.bind([id]);

    if (!stmt.step()) {
      stmt.free();
      return res.json({ code: 404, data: null, message: '房源不存在' });
    }

    const row = stmt.getAsObject();
    stmt.free();

    let oldData = {};
    try { oldData = row.data ? JSON.parse(row.data) : {}; } catch { oldData = {}; }

    const nextData = { ...oldData, ...incoming, id };

    db.run('UPDATE house_info SET data = ? WHERE id = ?', [JSON.stringify(nextData), id]);
    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    return res.json({ code: 200, data: null, message: '更新成功' });
  } catch (e) {
    console.error('PUT /rooms/admin/:id error:', e);
    return res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

// 管理员：真删除（并清理关联）
// DELETE /rooms/admin/:id
router.delete('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const id = req.params.id;
    if (!id) return res.json({ code: 400, data: null, message: 'id 不能为空' });

    const db = await getDB();
    try { db.run('DELETE FROM reservation WHERE house_id = ?', [id]); } catch {}
    try { db.run('DELETE FROM rent_contract WHERE house_id = ?', [id]); } catch {}
    try { db.run('DELETE FROM rental_orders WHERE room_id = ?', [id]); } catch {}

    db.run('DELETE FROM house_info WHERE id = ?', [id]);
    if (typeof db.saveToDisk === 'function') db.saveToDisk();

    return res.json({ code: 200, data: null, message: '删除成功' });
  } catch (e) {
    console.error('DELETE /rooms/admin/:id error:', e);
    return res.status(500).json({ code: 500, data: null, message: '内部错误' });
  }
});

export default router;
