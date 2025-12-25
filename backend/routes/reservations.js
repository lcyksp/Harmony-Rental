import express from 'express';
import { initDB } from '../db.js';
const router = express.Router();

// 创建预约
router.post('/', async (req, res) => {
  const db = await initDB();
  const { roomId, date, userName, remark } = req.body;

  // 时间冲突检查
  const conflict = await db.get(
    `SELECT * FROM reservation WHERE house_id = ? AND date = ?`, 
    [roomId, date]
  );
  if (conflict) return res.status(409).json({ error: "时间冲突" });

  await db.run(
    `INSERT INTO reservation (house_id, date, name, comment) VALUES (?, ?, ?, ?)`,
    [roomId, date, userName, remark]
  );

  res.json({ message: "预约成功" });
});

export default router;
