// download-images.js - ESM 版本，适配 "type": "module"
import axios from 'axios';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const OLD_BASE = 'http://127.0.0.1:6060';          // 旧 exe 监听端口
const SAVE_DIR = path.join(__dirname, 'public');   // 直接放到 backend/public

// 简单判断一个字符串是不是图片路径
function looksLikeImage(str) {
  if (typeof str !== 'string') return false;
  return str.includes('.jpg') || str.includes('.jpeg') || str.includes('.png');
}

// 递归收集对象里所有看起来像图片路径的字符串
function collectImagesFromObject(obj, set) {
  if (obj == null) return;

  if (typeof obj === 'string') {
    if (looksLikeImage(obj)) {
      set.add(obj);
    }
    return;
  }

  if (Array.isArray(obj)) {
    for (const item of obj) {
      collectImagesFromObject(item, set);
    }
    return;
  }

  if (typeof obj === 'object') {
    for (const key of Object.keys(obj)) {
      collectImagesFromObject(obj[key], set);
    }
    return;
  }
}

async function main() {
  try {
    console.log('请求旧服务器 /house/nearbyHouses ...');
    const res = await axios.get(OLD_BASE + '/house/nearbyHouses');
    console.log('HTTP 状态码:', res.status);

    // 把原始响应写出来方便你用编辑器查看结构
    const rawPath = path.join(__dirname, 'nearby_raw.json');
    fs.writeFileSync(rawPath, JSON.stringify(res.data, null, 2), 'utf8');
    console.log('已写入 nearby_raw.json（在 backend 目录）');

    // 找到真正的房源数组
    let houses;
    if (Array.isArray(res.data)) {
      houses = res.data;
      console.log('res.data 是数组，长度 =', houses.length);
    } else if (Array.isArray(res.data.data)) {
      houses = res.data.data;
      console.log('res.data.data 是数组，长度 =', houses.length);
    } else {
      console.log('❗没有直接找到数组，res.data 的 key 有:', Object.keys(res.data));
      console.log('请打开 nearby_raw.json 看看结构，然后把其中一条房源贴给我。');
      return;
    }

    // 收集所有图片路径
    const imgSet = new Set();
    collectImagesFromObject(houses, imgSet);

    console.log('识别出的“疑似图片路径”数量:', imgSet.size);
    if (imgSet.size === 0) {
      console.log('❗没有发现任何 .jpg/.png 字符串，请打开 nearby_raw.json 发一小段给我。');
      return;
    }

    // 确保保存目录存在
    if (!fs.existsSync(SAVE_DIR)) {
      fs.mkdirSync(SAVE_DIR, { recursive: true });
    }

    // 下载所有图片
    for (const rel of imgSet) {
      const url = rel.startsWith('http') ? rel : OLD_BASE + rel;
      const filename = path.basename(rel.split('?')[0]); // 去掉 ? 参数
      const filepath = path.join(SAVE_DIR, filename);

      console.log(`正在下载: ${url} -> ${filepath}`);
      try {
        const resp = await axios.get(url, { responseType: 'arraybuffer' });
        fs.writeFileSync(filepath, resp.data);
        console.log(`✔ 已保存: ${filename}`);
      } catch (err) {
        console.error(`✖ 下载失败: ${url}`, err.message);
      }
    }

    console.log('✅ 图片下载流程结束，请查看 backend/public 目录。');
  } catch (err) {
    console.error('脚本运行失败:', err.message);
  }
}

main();
