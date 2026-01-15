## Rental-硅谷租房（完成品）

### 介绍
本项目为本人毕业设计作品，实现了一个完整的 租房业务系统，采用 前后端分离架构，包含前端页面展示与后端接口服务，主要用于学习与展示项目工程结构、业务流程及前后端协作方式。

项目涵盖租房常见业务场景，如房源浏览、房源详情、预约看房、登录与个人中心等。


### 资料

1. 后端服务器
2. md文档
3. 数据库文件
4. 相关图片资源
5. 项目前端代码

### 目录结构
某些`工具类`与`组件`没有用到
```
├── AppScope                    HarmonyOS 应用配置
│   ├── app.json5
│   └── resources               应用资源文件
│
├── entry                       前端主模块
│   ├── api                     接口封装
│   ├── common                  公共资源
│   │   ├── constants           全局常量
│   │   ├── image               公共图片
│   │   └── utils               工具类
│   │       ├── DeviceScreen.ets
│   │       ├── GlobalContext.ets
│   │       └── Request.ts
│   │
│   ├── component               公共组件
│   ├── pages                   页面入口
│   │   ├── Index.ets
│   │   ├── login
│   │   └── rentRoom
│   │
│   ├── view                    业务页面
│   │   ├── home
│   │   ├── roomList
│   │   ├── roomDetail
│   │   ├── bookRoomList
│   │   ├── discover
│   │   ├── my
│   │   └── service
│   │
│   └── viewmodel               视图模型（MVVM）
│
├── backend                     后端服务
│   ├── app.js                  服务入口
│   ├── controllers             接口控制层
│   ├── db.js                   数据源配置
│   ├── download-images.js      图片处理脚本
│   └── nearby_raw.json         示例数据
│
└── README.md

```
### 技术栈
#### 前端
HarmonyOS

ArkTS

ArkUI

MVVM 架构

网络请求统一封装（Request）
#### 后端
Node.js

Express

RESTful API

本地 JSON / 数据源模拟

### 已实现功能
首页房源展示

房源列表

房源详情页

预约看房列表

登录（手机号 + 验证码页面）

我的 / 发现 / 服务 等页面模块

### 运行说明
1.在entry/src/main/ets/common/utils/Request.ts第10行修改本机IP地址

2.在backend内双击启动“服务器.bat”启动后台服务器

3.进入编译器并打开模拟器运行项目