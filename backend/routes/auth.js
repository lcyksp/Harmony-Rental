// routes/auth.js
import express from 'express';
import crypto from 'crypto';
import { getDB } from '../db.js';

const router = express.Router();

function hashPwd(pwd) {
  return crypto.createHash('sha256').update(pwd).digest('hex');
}

router.post('/register', async (req, res) => {
  const { phone, password, code } = req.body;

  // 1. 基础校验
  if (!phone || !password || !code) {
    return res.json({
      code: 400,
      message: '手机号、密码、验证码不能为空'
    });
  }

  // 手机号格式
  if (!/^1[3-9]\d{9}$/.test(phone)) {
    return res.json({
      code: 401,
      message: '手机号格式不正确'
    });
  }

  // 验证码：6 位数字即可
  if (!/^\d{6}$/.test(code)) {
    return res.json({
      code: 402,
      message: '验证码必须是 6 位数字'
    });
  }

  const db = await getDB();

  // 2. 查用户是否已存在
  const exists = db.exec(
    `SELECT id FROM users WHERE phone='${phone}'`
  );

  if (exists.length > 0 && exists[0].values.length > 0) {
    return res.json({
      code: 403,
      message: '手机号已注册'
    });
  }

  // 3. 写入数据库（带 role/status）
  db.run(
    `INSERT INTO users (phone, password, nickname, role, status)
     VALUES (?, ?, ?, ?, ?)`,
    [phone, hashPwd(password), '用户' + phone.slice(-4), 'user', 1]
  );

  db.saveToDisk();

  // 4. 再查一次用户信息（拿到 id、phone、nickname）
  const rows = db.exec(
    `SELECT id, phone, nickname FROM users WHERE phone='${phone}'`
  );

  let user = null;
  if (rows.length > 0 && rows[0].values.length > 0) {
    const u = rows[0].values[0]; // [id, phone, nickname]
    user = {
      id: u[0],
      phone: u[1],
      nickname: u[2]
    };
  }

  // 5. 生成一个简单 token
  const token = 'mock-token-' + phone;

  // 6. 按照你 axios 拦截器的约定返回
  return res.json({
    code: 200,
    message: '注册成功',
    data: {
      token,
      user
    }
  });
});

// 登录（手机号/管理员账号 + 密码）
router.post('/loginByPwd', async (req, res) => {
  const { phone, password } = req.body;

  console.log('[loginByPwd] body = ', req.body);
  console.log('[login] input pwd =', password);
  console.log('[login] hash  pwd =', hashPwd(password || ''));

  if (!phone || !password) {
    return res.json({ code: 400, message: '账号和密码不能为空' });
  }

  const isPhone = /^1[3-9]\d{9}$/.test(phone);

  const db = await getDB();

  let rows;
  try {
    rows = db.exec(`
      SELECT id, phone, password, nickname, role, status
      FROM users
      WHERE phone='${phone}'
    `);
  } catch (e) {
    console.log('[loginByPwd] SQL error =', e);
    return res.json({ code: 500, message: '数据库字段缺失，请先执行迁移SQL' });
  }

  if (!rows.length || !rows[0].values.length) {
    return res.json({ code: 402, message: '账号不存在' });
  }

  const userRow = rows[0].values[0];
  console.log('[login] db    pwd =', userRow[2]);

  let dbPwd = userRow[2];

  if (dbPwd.length !== 64 || !/^[0-9a-f]+$/.test(dbPwd)) {
    // 说明以前存的是明文密码，可以考虑做一次迁移
    dbPwd = hashPwd(dbPwd);
    const db = await getDB();
    db.run(`UPDATE users SET password=? WHERE id=?`, [dbPwd, userRow[0]]);
    db.saveToDisk();
  }

  const pwdHash = hashPwd(password);

  if (userRow[2] !== pwdHash) {
    return res.json({ code: 403, message: '密码错误' });
  }

  const role = userRow[4] || 'user';
  const status = userRow[5] ?? 1;

  if (status !== 1) {
    return res.json({ code: 405, message: '账号已被禁用' });
  }

  // 如果不是手机号登录，只允许管理员账号
  if (!isPhone && role !== 'admin') {
    return res.json({ code: 401, message: '账号格式不正确' });
  }

  const token = 'mock-token-' + phone;

  return res.json({
    code: 200,
    message: '登录成功',
    data: {
      token,
      user: {
        id: userRow[0],
        phone: userRow[1],
        nickname: userRow[3],
        avatar: '',
        role
      }
    }
  });
});

export default router;
