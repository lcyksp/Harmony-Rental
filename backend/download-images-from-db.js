// download-images-from-db.js
// 从 house_info 表中把所有图片路径扫出来，从旧 exe 下载到 backend/public

import axios from 'axios';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { getDB } from './db.js';  // 你项目里已经在用这个

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 旧 exe 的地址（就是以前 6060 端口那个）
const OLD_BASE = 'http://127.0.0.1:6060';

const SAVE_DIR = path.join(__dirname, 'public');

function looksLikeImage(str) {
  if (typeof str !== 'string') return false;
  return /\.(jpe?g|png|gif|webp)$/i.test(str);
}

// 递归遍历对象中的所有字符串字段，收集图片路径
function collectImagesFromObject(obj, set) {
  if (obj == null) return;

  if (typeof obj === 'string') {
    if (looksLikeImage(obj)) {
      set.add(obj); // 比如 "/public/room19.jpg"
    }
    return;
  }

  if (Array.isArray(obj)) {
    for (const item of obj) collectImagesFromObject(item, set);
    return;
  }

  if (typeof obj === 'object') {
    for (const key of Object.keys(obj)) {
      collectImagesFromObject(obj[key], set);
    }
  }
}

async function main() {
  try {
    const db = await getDB();
    const stmt = db.prepare('SELECT data FROM house_info');

    const imgSet = new Set();

    console.log('开始扫描 house_info 表中的图片字段...');
    while (stmt.step()) {
      const row = stmt.getAsObject();
      if (!row.data) continue;
      try {
        const detail = JSON.parse(row.data);
        collectImagesFromObject(detail, imgSet);
      } catch (e) {
        console.error('解析 data 出错：', e.message);
      }
    }
    stmt.free();

    console.log('一共找到图片路径数量：', imgSet.size);

    if (!fs.existsSync(SAVE_DIR)) {
      fs.mkdirSync(SAVE_DIR, { recursive: true });
    }

    for (const rel of imgSet) {
      const url = rel.startsWith('http') ? rel : OLD_BASE + rel;
      const filename = path.basename(rel.split('?')[0]);
      const filepath = path.join(SAVE_DIR, filename);

      console.log(`下载: ${url} -> ${filepath}`);
      try {
        const resp = await axios.get(url, { responseType: 'arraybuffer' });
        fs.writeFileSync(filepath, resp.data);
        console.log('✔ 已保存:', filename);
      } catch (err) {
        console.error('✖ 下载失败:', url, err.message);
      }
    }

    console.log('✅ 所有图片下载流程结束，请查看 backend/public 目录。');
  } catch (err) {
    console.error('脚本运行失败:', err.message);
  }
}

main();
