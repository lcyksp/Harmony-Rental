// src/main/ets/common/utils/Request.ts
import axios from '@ohos/axios'
import { promptAction } from '@kit.ArkUI'

export interface AnyObject {
  [key: string]: any
}

const instance = axios.create({
  baseURL: 'http://192.168.1.104:7000',
  timeout: 10000,
  // ✅ 无论 200/400/500 都走 response 成功回调，从而必定打印 📥
  validateStatus: () => true,
})

// 导出统一的服务端地址和 public 前缀
export const SERVER_URL: string = instance.defaults.baseURL ?? ''
export const PUBLIC_BASE_URL: string = SERVER_URL + '/public/'

/**
 * 请求拦截：加日志
 * ✅ 保持 any，避免 axios InternalAxiosRequestConfig 类型兼容问题
 */
instance.interceptors.request.use(
  (config: any) => {
    console.info(
      '📤 [HTTP Request] =>',
      (config.method || '').toUpperCase(),
      config.url || config.baseURL,
      'params =',
      JSON.stringify(config.params || {}),
      'data =',
      JSON.stringify(config.data || {}),
    )
    // ✅ 自动注入登录 token（管理员接口也会自动带上）
    const token: string = AppStorage.Has('token') ? (AppStorage.Get('token') as string) : ''
    if (token && token.length > 0) {
      if (!config.headers) {
        config.headers = {}
      }
      if (!config.headers.Authorization) {
        config.headers.Authorization = `Bearer ${token}`
      }
    }

    return config
  },
  (error: any) => {
    console.error('❌ [HTTP Request Error] =>', error?.message || '', JSON.stringify(error))
    return Promise.reject(error)
  }
)

/**
 * 响应拦截：无论 httpStatus 是多少，都在这里打印并按 {code} 决定成功失败
 * ✅ 关键修复：成功时只返回 response.data.data，不再把 {list,total} 拍扁成 list[]
 */
instance.interceptors.response.use(
  (response: AnyObject) => {
    console.info(
      '📥 [HTTP Response] =>',
      (response.config?.method || '').toUpperCase(),
      response.config?.url,
      'httpStatus =',
      response.status,
      'data =',
      JSON.stringify(response.data || {})
    )

    // 后端统一返回 { code, data, message }
    if (response.data && response.data.code === 200) {
      // ✅ 改回去：原样返回 data（可能是 {list,total} / 数组 / 对象）
      return response.data.data
    }

    const msg =
      response.data?.message ||
        `请求失败 http=${response.status}`

    promptAction.showToast({ message: msg })
    return Promise.reject(response.data)
  },
  (error: any) => {
    // validateStatus 已经让大多数错误走上面；这里兜底处理：超时/断网等
    const msg = error?.message || '网络错误'
    console.error('❌ [HTTP Response Error] =>', msg, JSON.stringify(error))
    promptAction.showToast({ message: msg })
    return Promise.reject(error)
  }
)

class Request {
  get<T>(url: string, params?: AnyObject, config?: AnyObject) {
    return instance.get<any, T>(url, { params, ...(config || {}) })
  }

  post<T>(url: string, data?: AnyObject, config?: AnyObject) {
    return instance.post<any, T>(url, data, config || {})
  }

  put<T>(url: string, data?: AnyObject, config?: AnyObject) {
    return instance.put<any, T>(url, data, config || {})
  }

  delete<T>(url: string, params?: AnyObject, config?: AnyObject) {
    return instance.delete<any, T>(url, { params, ...(config || {}) })
  }
}

export const http = new Request()

