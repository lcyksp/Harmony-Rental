import express from 'express';
import { getDB } from '../db.js';

const router = express.Router();

/** 从请求头取 token: Authorization: Bearer mock-token-xxx */
function getTokenPhone(req) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : auth;
  if (!token.startsWith('mock-token-')) return '';
  return token.replace('mock-token-', '').trim();
}

/** 管理员鉴权中间件（最简版） */
async function requireAdmin(req, res, next) {
  const phone = getTokenPhone(req);
  if (!phone) return res.status(401).json({ code: 401, message: '未登录' });

  const db = await getDB();
  const rows = db.exec(`SELECT role, status FROM users WHERE phone='${phone}'`);
  if (!rows.length || !rows[0].values.length) {
    return res.status(401).json({ code: 401, message: '无效登录' });
  }
  const [role, status] = rows[0].values[0];
  if ((status ?? 1) !== 1) return res.status(403).json({ code: 403, message: '账号已禁用' });
  if (role !== 'admin') return res.status(403).json({ code: 403, message: '无管理员权限' });

  req.adminPhone = phone;
  next();
}

/** ========== 用户 CRUD ========== */

/** 查：分页列表（可按 phone/nickname 模糊搜索） */
router.get('/users', requireAdmin, async (req, res) => {
  const page = Math.max(parseInt(req.query.page || '1', 10), 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit || '10', 10), 1), 100);
  const q = (req.query.q || '').toString().trim();

  const offset = (page - 1) * limit;
  const db = await getDB();

  const where = q ? `WHERE phone LIKE '%${q}%' OR nickname LIKE '%${q}%'` : '';
  const totalRows = db.exec(`SELECT COUNT(*) FROM users ${where}`);
  const total = totalRows?.[0]?.values?.[0]?.[0] ?? 0;

  const rows = db.exec(`
    SELECT id, phone, nickname, role, status
    FROM users
    ${where}
    ORDER BY id DESC
    LIMIT ${limit} OFFSET ${offset}
  `);

  const list = (rows?.[0]?.values || []).map(v => ({
    id: v[0],
    phone: v[1],
    nickname: v[2],
    role: v[3],
    status: v[4]
  }));

  return res.json({ code: 200, message: 'ok', data: { page, limit, total, list } });
});

/** 增：创建用户（最简：只支持手机号 + 6位数字密码） */
router.post('/users', requireAdmin, async (req, res) => {
  const { phone, password, nickname, role, status } = req.body || {};
  if (!phone || !password) return res.json({ code: 400, message: 'phone/password 不能为空' });
  if (!/^1[3-9]\d{9}$/.test(phone)) return res.json({ code: 400, message: '手机号格式不正确' });
  if (!/^\d{6}$/.test(password)) return res.json({ code: 400, message: '密码必须 6 位数字' });

  // 复用你 auth.js 的 sha256：这里为了不循环引用，直接在前端/你原 register 逻辑里创建也行
  // 为了最省事：直接调用 register 接口创建普通用户即可；这里先不做“新增用户”也没问题
  return res.json({ code: 501, message: '为简化实现：请先用注册接口创建用户，再用下面接口改角色/状态' });
});

/** 改：更新用户（nickname/role/status） */
router.put('/users/:id', requireAdmin, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const { nickname, role, status } = req.body || {};
  if (!id) return res.json({ code: 400, message: 'id 不合法' });

  const fields = [];
  const params = [];

  if (nickname !== undefined) { fields.push('nickname=?'); params.push(String(nickname)); }
  if (role !== undefined) { fields.push('role=?'); params.push(String(role)); }
  if (status !== undefined) { fields.push('status=?'); params.push(Number(status)); }

  if (!fields.length) return res.json({ code: 400, message: '没有可更新字段' });

  const db = await getDB();
  db.run(`UPDATE users SET ${fields.join(',')} WHERE id=?`, [...params, id]);
  db.saveToDisk();

  return res.json({ code: 200, message: '更新成功' });
});

/** 删：删除用户 */
router.delete('/users/:id', requireAdmin, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!id) return res.json({ code: 400, message: 'id 不合法' });

  const db = await getDB();
  db.run(`DELETE FROM users WHERE id=?`, [id]);
  db.saveToDisk();

  return res.json({ code: 200, message: '删除成功' });
});

// ========== 房源 CRUD（house_info） ==========

// 生成一个接近你库里现有风格的 id（AQ + 时间戳 + 随机）
function genHouseId() {
  return 'AQ' + Date.now() + Math.floor(Math.random() * 1000000);
}

// 从 data(JSON)里提取/回填用于筛选的列
function deriveHouseColumnsFromData(dataObj) {
  const meta = Array.isArray(dataObj?.metaInfo) ? dataObj.metaInfo : [];

  const getMetaDesc = (name) => {
    const hit = meta.find(x => x?.name === name);
    return (hit?.desc ?? '').toString();
  };

  const rentArea = (dataObj?.rentArea ?? getMetaDesc('使用面积') ?? '').toString(); // 例如 "58.00"
  const payment = (dataObj?.rentTerm ?? dataObj?.payment ?? '').toString();         // 例如 "季付"
  const districtName = (dataObj?.districtName ?? dataObj?.hdicDistrictName ?? '').toString();

  // 你表里 rent_price_unit_listing 存的是数字字符串，如 "600"
  const rentPriceListing =
    (dataObj?.rentPriceUnitListing ?? dataObj?.rentPrice ?? '').toString().replace(/[^\d]/g, '') || '0';

  // 地区编码你表里用 province/city/area_code
  const provinceCode = (dataObj?.provinceCode ?? '').toString();
  const cityCode = (dataObj?.cityCode ?? '').toString();
  const areaCode = (dataObj?.areaCode ?? '').toString();

  return {
    rentArea,
    payment,
    districtName,
    rentPriceListing,
    provinceCode,
    cityCode,
    areaCode
  };
}

/**
 * 查：房源分页列表
 * 支持：provinceCode/cityCode/districtCode/minRent/maxRent/paymentType/q
 */
router.get('/rooms', requireAdmin, async (req, res) => {
  const page = Math.max(parseInt(req.query.page || '1', 10), 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit || '10', 10), 1), 100);
  const offset = (page - 1) * limit;

  const provinceCode = (req.query.provinceCode || '').toString().trim();
  const cityCode = (req.query.cityCode || '').toString().trim();
  const districtCode = (req.query.districtCode || '').toString().trim();
  const paymentType = (req.query.paymentType || '').toString().trim();
  const q = (req.query.q || '').toString().trim();

  const minRent = (req.query.minRent || '').toString().trim();
  const maxRent = (req.query.maxRent || '').toString().trim();

  const where = [];
  if (provinceCode) where.push(`province_code='${provinceCode}'`);
  if (cityCode) where.push(`city_code='${cityCode}'`);
  if (districtCode) where.push(`area_code='${districtCode}'`);
  if (paymentType) where.push(`payment='${paymentType}'`);
  if (q) where.push(`(hdic_district_name LIKE '%${q}%' OR data LIKE '%${q}%')`);

  if (minRent) where.push(`CAST(rent_price_unit_listing AS INTEGER) >= ${parseInt(minRent, 10) || 0}`);
  if (maxRent) where.push(`CAST(rent_price_unit_listing AS INTEGER) <= ${parseInt(maxRent, 10) || 0}`);

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

  const db = await getDB();

  const totalRows = db.exec(`SELECT COUNT(*) FROM house_info ${whereSql}`);
  const total = totalRows?.[0]?.values?.[0]?.[0] ?? 0;

  const rows = db.exec(`
    SELECT id, data, hdic_district_name, rent_price_unit_listing, rent_area, payment,
           province_code, city_code, area_code
    FROM house_info
    ${whereSql}
    ORDER BY id DESC
    LIMIT ${limit} OFFSET ${offset}
  `);

  const list = (rows?.[0]?.values || []).map(v => {
    let dataObj = null;
    try { dataObj = JSON.parse(v[1] || '{}'); } catch (e) {}
    return {
      id: v[0],
      data: dataObj, // 前端直接渲染用
      hdicDistrictName: v[2],
      rentPriceUnitListing: v[3],
      rentArea: v[4],
      payment: v[5],
      provinceCode: v[6],
      cityCode: v[7],
      areaCode: v[8],
    };
  });

  return res.json({ code: 200, message: 'ok', data: { page, limit, total, list } });
});

/** 查：单条详情 */
router.get('/rooms/:id', requireAdmin, async (req, res) => {
  const id = (req.params.id || '').toString().trim();
  if (!id) return res.json({ code: 400, message: 'id 不能为空' });

  const db = await getDB();
  const rows = db.exec(`SELECT id, data FROM house_info WHERE id='${id}'`);
  if (!rows.length || !rows[0].values.length) return res.json({ code: 404, message: '房源不存在' });

  const row = rows[0].values[0];
  let dataObj = null;
  try { dataObj = JSON.parse(row[1] || '{}'); } catch (e) {}

  return res.json({ code: 200, message: 'ok', data: { id: row[0], data: dataObj } });
});

/**
 * 增：新增房源
 * body 支持两种：
 * 1) { data: { ... } }  推荐
 * 2) 直接传 JSON（也行，但我这里按 data 优先）
 */
router.post('/rooms', requireAdmin, async (req, res) => {
  const raw = req.body || {};
  const dataObj = raw.data ?? raw;

  if (!dataObj || typeof dataObj !== 'object') {
    return res.json({ code: 400, message: 'data 不能为空' });
  }

  const db = await getDB();

  const id = (dataObj.id || '').toString().trim() || genHouseId();
  dataObj.id = id;

  const derived = deriveHouseColumnsFromData(dataObj);
  const dataStr = JSON.stringify(dataObj);

  // 插入
  db.run(
    `INSERT INTO house_info
      (id, data, hdic_district_name, rent_price_unit_listing, rent_area, payment, area_code, city_code, province_code)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      dataStr,
      derived.districtName,
      derived.rentPriceListing,
      derived.rentArea,
      derived.payment,
      derived.areaCode,
      derived.cityCode,
      derived.provinceCode
    ]
  );

  db.saveToDisk();
  return res.json({ code: 200, message: '新增成功', data: { id } });
});

/**
 * 改：更新房源（推荐整包更新 data）
 * body: { data: {...} } 或直接 {...}
 */
router.put('/rooms/:id', requireAdmin, async (req, res) => {
  const id = (req.params.id || '').toString().trim();
  if (!id) return res.json({ code: 400, message: 'id 不能为空' });

  const raw = req.body || {};
  const incoming = raw.data ?? raw;
  if (!incoming || typeof incoming !== 'object') {
    return res.json({ code: 400, message: 'data 不能为空' });
  }

  const db = await getDB();

  // 先取旧的 data，做合并（这样前端只改部分字段也行）
  const oldRows = db.exec(`SELECT data FROM house_info WHERE id='${id}'`);
  if (!oldRows.length || !oldRows[0].values.length) return res.json({ code: 404, message: '房源不存在' });

  let oldObj = {};
  try { oldObj = JSON.parse(oldRows[0].values[0][0] || '{}'); } catch (e) {}

  const nextObj = { ...oldObj, ...incoming, id };
  const derived = deriveHouseColumnsFromData(nextObj);

  db.run(
    `UPDATE house_info
     SET data=?,
         hdic_district_name=?,
         rent_price_unit_listing=?,
         rent_area=?,
         payment=?,
         area_code=?,
         city_code=?,
         province_code=?
     WHERE id=?`,
    [
      JSON.stringify(nextObj),
      derived.districtName,
      derived.rentPriceListing,
      derived.rentArea,
      derived.payment,
      derived.areaCode,
      derived.cityCode,
      derived.provinceCode,
      id
    ]
  );

  db.saveToDisk();
  return res.json({ code: 200, message: '更新成功' });
});

/**
 * 删：删除房源（并清理关联表，避免脏数据）
 */
router.delete('/rooms/:id', requireAdmin, async (req, res) => {
  const id = (req.params.id || '').toString().trim();
  if (!id) return res.json({ code: 400, message: 'id 不能为空' });

  const db = await getDB();

  // 先删关联（可选但建议）
  db.run(`DELETE FROM reservation WHERE house_id=?`, [id]);
  db.run(`DELETE FROM rent_contract WHERE house_id=?`, [id]);
  db.run(`DELETE FROM rental_orders WHERE room_id=?`, [id]);

  // 再删主表
  db.run(`DELETE FROM house_info WHERE id=?`, [id]);

  db.saveToDisk();
  return res.json({ code: 200, message: '删除成功' });
});


export default router;
