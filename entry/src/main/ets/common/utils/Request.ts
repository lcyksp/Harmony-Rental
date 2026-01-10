// src/main/ets/common/utils/Request.ts
import axios from '@ohos/axios';
import { promptAction } from '@kit.ArkUI';

export interface AnyObject {
  [key: string]: any;
}

// 这里改电脑的局域网 IP + Node 后端端口
const instance = axios.create({
  baseURL: 'http://192.168.3.159:7000',
  timeout: 10000, // 给个超时时间，避免请求挂死
});

// 导出统一的服务端地址和 public 前缀
export const SERVER_URL: string = instance.defaults.baseURL ?? '';
export const PUBLIC_BASE_URL: string = SERVER_URL + '/public/';

/**
 * 请求拦截：这里主要加日志
 */
instance.interceptors.request.use(
  (config: any) => {
    console.log(
      '📤 [HTTP Request] =>',//加个图标只是为了方便找日志来调试
      config.method,
      config.url || config.baseURL,
      'params =',
      JSON.stringify(config.params || {}),
      'data =',
      JSON.stringify(config.data || {}),
    );
    return config;
  },
  (error: any) => {
    console.log('❌ [HTTP Request Error] =>', JSON.stringify(error));
    return Promise.reject(error);
  }
);


/**
 * 响应拦截：同样加日志 + 保留你原来的 code===200 逻辑
 */
instance.interceptors.response.use(
  (response: AnyObject) => {
    console.log(
      '📥 [HTTP Response] =>',
      response.config?.url,
      'status =',
      response.status,
      'data =',
      JSON.stringify(response.data || {})
    );

    // 按你原来的约定：后端统一返回 { code, data, message }
    if (response.data && response.data.code === 200) {
      // 这一行非常关键：后面 http.get() 拿到的就是 data 这一层
      return response.data.data;
    }

    // code 不是 200，弹 toast
    const msg =
      (response.data && response.data.message) ||
        '请求失败 (code != 200)';
    promptAction.showToast({
      message: msg,
    });
    return Promise.reject(response.data);
  },
  (error: any) => {
    console.log('❌ [HTTP Response Error] =>', JSON.stringify(error));
    promptAction.showToast({
      message: error.message || '网络错误',
    });
    return Promise.reject(error);
  }
);

class Request {
  constructor() {
    console.log('初始化 http 实例');
  }

  get<T>(url: string, params?: AnyObject) {
    return instance.get<any, T>(url, { params });
  }

  post<T>(url: string, data?: AnyObject) {
    return instance.post<any, T>(url, data);
  }

  put<T>(url: string, data?: AnyObject) {
    return instance.put<any, T>(url, data);
  }

  delete<T>(url: string, params?: AnyObject) {
    return instance.delete<any, T>(url, { params });
  }
}

export const http = new Request();
