// backend/app.js
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import rentRouter from './routes/rent.js'
import uploadRouter from './routes/upload.js';
import roomsRouter from './routes/rooms.js';
import homeRouter from './routes/home.js';
import houseRouter from './routes/house.js';
import authRouter from './routes/auth.js';
import footprintRouter from './routes/footprint.js'
import reservationsRouter from './routes/reservations.js';
import messagesRouter from './routes/messages.js'
import regionRouter from './routes/region.js'
import adminRouter from './routes/admin.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// 简易用户信息接口：GET /auth/user/userInfo
app.get('/auth/user/userInfo', (req, res) => {
  const phoneFromClient = req.query.phone || req.query.userId;

  if (!phoneFromClient) {
    return res.status(401).json({
      code: 401,
      data: null,
      message: '缺少 phone 或 userId'
    });
  }

  const user = {
    id: 1,
    phone: String(phoneFromClient),
    nickname: '测试用户',
    avatar: '',
    role: 'landlord' // 暂时写死角色，后面你可以接真用户表
  };

  res.json({
    code: 200,
    data: user,
    message: 'ok'
  });
});

/**
 * 服务页信息：GET /service/info
 * 用来喂“服务”tab 里的数据，先返回一些假的配置，避免 404
 */
app.get('/service/info', (req, res) => {
  res.json({
    code: 200,
    data: {
      // 这里随便写点字段，前端一般只判断 code === 200 就行
      plans: [],
      tips: '服务信息（测试数据）'
    },
    message: 'ok'
  })
})

/**
 * 发现页信息：GET /discover/info
 * 喂“发现”tab 的数据，先占个位
 */
app.get('/discover/info', (req, res) => {
  res.json({
    code: 200,
    data: {
      banners: [],
      activities: [],
      tips: '发现页信息（测试数据）'
    },
    message: 'ok'
  })
})

app.use((req, res, next) => {
  console.log(`[REQ] ${req.method} ${req.originalUrl}`)
  next()
})

app.use(cors());
app.use(bodyParser.json());
app.use(express.json()); 

// 关键：把 backend/public 暴露成 /public
app.use('/public', express.static(path.join(__dirname, 'public')));

// 对应前端 /home/info
app.use('/home', homeRouter);

// 对应前端 /house/nearbyHouses
app.use('/house', houseRouter);

// 房源列表 / 详情
app.use('/rooms', roomsRouter);

//房源上传
app.use('/upload', uploadRouter);

//用户注册登录API
app.use('/api', authRouter);

//用户预约
app.use('/auth/house', reservationsRouter);

//嗯哼？
app.use('/auth/house', reservationsRouter)

// ⭐ 消息相关 API
app.use('/auth/message', messagesRouter)

//住房
app.use('/auth', rentRouter)

//足迹
app.use('/auth', footprintRouter)

//定位
app.use('/region', regionRouter)
console.log('[app] /region router mounted ✅')

//管理员
app.use('/api/admin', adminRouter);

app.use((req, res) => {
  console.log(`[404] ${req.method} ${req.originalUrl}`)
  res.status(404).json({ code: 404, message: 'Not Found' })
})

const PORT = 7000;
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});