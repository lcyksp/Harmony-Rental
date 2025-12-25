// entry/src/main/ets/api/user.ets
import { http } from '../common/utils/Request'
import { LoginResModel, UserModel } from '../viewmodel/UserModel';

/**
 * 获取验证码
 */
export const sendSMSCodeApi = (phone: string): Promise<void> => {
  return http.post<void>('/sendSMSCode', { phone: phone });
}

/**
 * 登录（验证码登录）
 */
export const loginApi = (phone: string, code: string): Promise<LoginResModel> => {
  return http.post<LoginResModel>('/login', { phone: phone, code: code });
}

/**
 * 获取用户信息
 */
export const getUserInfoApi = (): Promise<UserModel> => {
  return http.get<UserModel>('/auth/user/userInfo');
}

/**
 * 注册相关类型
 */

// 单独拆出 user 结构，避免内联类型
export interface RegisterUser {
  id: number;
  nickname: string;
  phone: string;
}

export interface RegisterReq {
  phone: string;
  password: string;
  code: string;
}

export interface RegisterResp {
  token?: string;
  user?: RegisterUser;
  msg?: string;
}

/**
 * 用户注册 API
 */
export function registerApi(data: RegisterReq): Promise<RegisterResp> {
  return http.post<RegisterResp>('/api/register', data);
}

/**
 * ===== 手机号+密码登录相关类型 =====
 */

/**
 * ===== 手机号+密码登录相关类型 =====
 */

// ① 先单独定义 user 结构
export interface LoginPwdUser {
  id: number;
  phone: string;
  nickname: string;
  avatar?: string;
}

// ② 再在 data 里引用这个类型
export interface LoginPwdData {
  token: string;
  user: LoginPwdUser;
}


/**
 * 登录（手机号 + 密码）
 * 后端路由：/api/loginByPwd
 * 注意：因为你的 axios 拦截器已经把 { code, data } 的 data 解出来了，
 * 这里的泛型 T 直接就是 data 这一层（LoginPwdData）。
 */
export function loginByPwdApi(phone: string, password: string): Promise<LoginPwdData> {
  return http.post<LoginPwdData>('/api/loginByPwd', { phone, password });
}
