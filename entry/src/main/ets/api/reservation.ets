// entry/src/main/ets/api/reservation.ets
import { http } from '../common/utils/Request';

// 一条预约记录
export interface ReservationItem {
  id: number;
  userId?: string;
  houseId: number;
  date: string;
  name: string;
  comment: string;
}

// 列表响应
export interface ReservationListResp {
  list: ReservationItem[];
}

// 约看列表请求参数
class ReservationListParam {
  userId: string = '';
}

// 取消预约请求参数
class CancelReservationParam {
  id: number = 0;
  phone: string = '';
}

// =================== API 实现 ===================

// 获取当前用户的约看列表
export const getReservationListApi = (userId: string): Promise<ReservationItem[]> => {
  const param = new ReservationListParam();
  param.userId = userId;

  return http
    .get<ReservationListResp>('/auth/house/reservation/list', param)
    .then((res: ReservationListResp) => res.list ?? []);
};

// 取消预约
export const cancelReservationApi = (id: number, phone: string): Promise<void> => {
  const body = new CancelReservationParam();
  body.id = id;
  body.phone = phone;

  return http.post<void>('/auth/house/reservation/cancel', body);
};
