// backend/routes/home.js
import express from 'express';
import { getHost } from '../utils/getHost.js';

const router = express.Router();

router.get('/info', (req, res) => {
  const HOST = getHost(req);

  // 顶部轮播图：这里仍然用后端图片
  const bannerFiles = ['home_banner_1.jpg', 'home_banner_2.jpg', 'room80.jpg'];
  const banners = bannerFiles.map((file, idx) => {
    const full = `${HOST}/public/${file}`;
    return {
      id: idx + 1,
      name: `推荐好房 ${idx + 1}`,
      imageURL: full,
    };
  });

  // 顶部广告图（如果你有的话，没有也可以给空字符串）
  const adPicture = `${HOST}/public/room24.jpg`;

  // 导航网格：前端已经根据 title 映射本地 nav_* 图标，所以这里只需要 title
  const navList = [
    { id: 1, title: '合租', imageURL: '' },
    { id: 2, title: '独立主卧', imageURL: '' },
    { id: 3, title: '整租1居', imageURL: '' },
    { id: 4, title: '整租2-3居', imageURL: '' },
    { id: 5, title: '小客厅', imageURL: '' },
    { id: 6, title: '大客厅', imageURL: '' },
    { id: 7, title: '短租', imageURL: '' },
    { id: 8, title: '押金0首付', imageURL: '' }
  ];

  // 2 个平铺组件：硅谷家服 + 硅谷智能
  // 前端 TileList 用 title 选本地图片，所以这里只需要 title / sub_title
  const tileList = [
    { id: 1, title: '硅谷家服', sub_title: '搬家·保洁·清洁·维修' },
    { id: 2, title: '硅谷智能', sub_title: '全屋智能家装' }
  ];

  // 4 个计划组件：谷粒 / 精英 / 企业 / English
  // 前端 PlanList 用 title 选本地图片
  const planList = [
    { id: 1, title: '谷粒计划', sub_title: '在校生' },
    { id: 2, title: '精英计划', sub_title: '毕业生' },
    { id: 3, title: '企业计划', sub_title: '打工人' },
    { id: 4, title: 'English', sub_title: 'lao wai' }
  ];

  const data = {
    adPicture,
    bannerList: banners,
    navList,
    tileList,
    planList,
  };

  res.json({
  code: 200,
  data: {
    adPicture,
    bannerList: banners,
    navList,
    tileList,
    planList,   // 确保这里返回了 planList 数据
  },
  message: 'success',
})
});

export default router;
