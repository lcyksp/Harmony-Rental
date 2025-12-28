// entry/src/main/ets/api/book.ets

import { http } from '../common/utils/Request'
import { BookRoomItem, ReserveRoomParams } from '../viewmodel/BookRoomModel'

interface ReservationPayload {
  roomId: string;
  date: string;
  userName: string;
  remark: string;
  phone: string;
}
/**
 * 提交预约
 * 前端字段  ->  后端字段
 * houseId  ->  roomId
 * name     ->  userName
 * comment  ->  remark
 * date     ->  date
 */
export const reservationApi = (params: ReserveRoomParams): Promise<void> => {
  const payload: ReservationPayload = {
    roomId: params.houseId,
    date: params.date,
    userName: params.name,
    remark: params.comment ?? '',
    phone: params.phone
  }

  console.info('reservationApi payload => ', JSON.stringify(payload))

  return http.post<void>('/auth/house/reservation', payload)
}
/**
 * 获取预约租房列表（约看记录）
 */
export const getBookRentRoomListApi = (): Promise<BookRoomItem[]> => {
  return http.get<BookRoomItem[]>('/auth/house/history')
}
