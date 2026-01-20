// backend/db.js
import fs from 'fs';
import path from 'path';
import initSqlJs from 'sql.js';

const DB_FILE = path.join(process.cwd(), 'sqlite.db');

let dbPromise = null;

export async function getDB() {
  console.log('[DB_FILE]=', DB_FILE)
  if (!dbPromise) {
    dbPromise = (async () => {
      const SQL = await initSqlJs({
        locateFile: (file) => `node_modules/sql.js/dist/${file}`,
      });

      let db;
      if (fs.existsSync(DB_FILE)) {
        const fileBuffer = fs.readFileSync(DB_FILE);
        db = new SQL.Database(new Uint8Array(fileBuffer));
      } else {
        db = new SQL.Database();

        // --- 原有房源表 ---
        db.run(`
          CREATE TABLE IF NOT EXISTS house_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
          );
        `);

        // --- 新增用户表 ---
        db.run(`
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT UNIQUE,
            password TEXT,
            nickname TEXT
          );
        `);

        const data = db.export();
        fs.writeFileSync(DB_FILE, Buffer.from(data));
      }

      // 每次启动都确保表存在（用户表）
      db.run(`
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT UNIQUE,
          password TEXT,
          nickname TEXT
        );
      `);

      // 预约表
      db.run(`
        CREATE TABLE IF NOT EXISTS reservation (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          house_id TEXT NOT NULL,
          date TEXT NOT NULL,
          name TEXT,
          comment TEXT
        );
      `);

      // 如果只是想保留索引（方便查），但不唯一：
      db.run(`
        CREATE INDEX IF NOT EXISTS idx_reservation_user_house
          ON reservation(user_id, house_id);
      `);

      // 消息表（消息管家用）
      db.run(`
        CREATE TABLE IF NOT EXISTS message (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,     -- 收消息的人（手机号）
          type TEXT NOT NULL,        -- 消息类型：reservation / system / rent 等
          title TEXT NOT NULL,       -- 标题
          content TEXT NOT NULL,     -- 内容
          created_at TEXT NOT NULL,  -- 创建时间 ISO 字符串
          is_read INTEGER NOT NULL DEFAULT 0, -- 0 未读 1 已读
          extra TEXT                 -- 扩展 JSON，例如房源信息
        );
      `);

      // 根据用户和已读状态建索引，方便查未读消息
      db.run(`
        CREATE INDEX IF NOT EXISTS idx_message_user
          ON message(user_id, is_read);
      `);

      db.saveToDisk = () => {
        const data = db.export();
        fs.writeFileSync(DB_FILE, Buffer.from(data));
      };

      return db;
    })();
  }
  return dbPromise;
}
