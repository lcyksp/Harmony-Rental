// entry/src/main/ets/api/roomDetail.ets
import { http } from '../common/utils/Request'
import type { RoomDetailModel } from '../viewmodel/RoomDetailModel'

/**
 * 获取房间详情
 */
export const getRoomDetailApi = (id: string): Promise<RoomDetailModel> => {
  // 和你原来的保持一致
  return http.get<RoomDetailModel>('/house/detail', { id })
}

/**
 * 新增：预约看房 - 请求参数
 * 对应接口：POST /auth/house/reservation
 */
export interface CreateReservationParams {
  houseId: string        // 房源id（详情页的 id）
  name: string           // 联系人姓名
  phone: string          // 联系电话
  visitTime: string      // 看房时间（字符串，如：2025-01-10 14:30）
  remark?: string        // 备注（可选）
}

/**
 * 新增：预约看房
 */
export const createReservationApi = (
  data: CreateReservationParams
): Promise<void> => {
  return http.post<void>('/auth/house/reservation', data)
}

/**
 * 新增：预约记录返回结构（可以根据你 Apifox 里实际字段再补充）
 * 对应接口：GET /auth/house/history
 */
export interface ReservationRecord {
  id: string             // 预约id
  houseId: string        // 房源id
  visitTime: string      // 看房时间
  status: string | number // 预约状态（待确认 / 已完成 等）
  createTime?: string    // 创建时间（可选）
  // 需要更多字段可以继续加
}

/**
 * 新增：获取我的预约记录列表
 */
export const getReservationHistoryApi = (): Promise<ReservationRecord[]> => {
  return http.get<ReservationRecord[]>('/auth/house/history', {})
}
