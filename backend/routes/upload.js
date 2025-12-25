// backend/routes/upload.js
import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';

const router = express.Router();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 上传目录：public/upload
const uploadDir = path.join(__dirname, '..', 'public', 'upload');

// 配置 multer
const storage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, uploadDir);
  },
  filename(req, file, cb) {
    // 简单一点：时间戳 + 原后缀
    const ext = path.extname(file.originalname) || '.jpg';
    const basename = Date.now().toString();
    cb(null, basename + ext);
  }
});

const upload = multer({ storage });

/**
 * 图片上传：POST /upload
 * form-data 中 key = file, value = 图片文件
 */
router.post('/', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      code: 400,
      data: null,
      message: '未收到文件'
    });
  }

  // 构造可访问 URL
  const url = `${req.protocol}://${req.headers.host}/public/upload/${req.file.filename}`;

  res.json({
    code: 200,
    data: { url },
    message: '上传成功'
  });
});

export default router;
