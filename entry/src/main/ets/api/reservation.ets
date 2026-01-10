// entry/src/main/ets/api/reservation.ets
import { http } from '../common/utils/Request';

// 一条预约记录（租客/房东通用）
export interface ReservationItem {
  id: number;
  houseId: string;
  date: string;
  name: string;
  comment: string;
  status?: string;

  // 租客视角
  userId?: string;
  // 房东视角：后端把 user_id 映射成 tenantPhone
  tenantPhone?: string;
  landlordPhone?: string;  // ✅ 新增：房东电话（租客端显示用）

  // 房源信息
  houseTitle?: string;
  coverUrl?: string;

  // 兜底图片字段（如果以后你想用，可以在前端用这些）
  roomMainPic?: string;
  mainPic?: string;
}

// 列表 data 结构
interface ReservationListData {
  list?: ReservationItem[];
}

// 通用列表响应结构
interface ReservationListApiResp {
  code?: number;
  data?: ReservationListData;
  list?: ReservationItem[];    // 兼容旧格式 { list: [...] }
}

// 列表请求参数
class ReservationListParam {
  userId?: string; // 租客视角
  phone?: string;  // 房东视角
}

// 取消预约请求参数（租客）
class CancelReservationParam {
  id: number = 0;
  phone: string = '';
}

// 房东同意/驳回参数
class DecisionParam {
  id: number = 0;
  landlordPhone: string = '';
  action: 'accept' | 'reject' = 'accept';
}

// =================== API 实现 ===================

// 租客：获取“我约看的”列表
export const getReservationListApi = (userId: string): Promise<ReservationItem[]> => {
  const param = new ReservationListParam();
  param.userId = userId;

  return http
    .get<ReservationListApiResp>('/auth/house/reservation/list', param)
    .then((res: ReservationListApiResp): ReservationItem[] => {
      if (res && res.data && res.data.list) {
        return res.data.list;
      }
      if (res && res.list) {
        return res.list;
      }
      return [];
    });
};

// 房东：获取“约看我的”列表
export const getLandlordReservationListApi = (phone: string): Promise<ReservationItem[]> => {
  const param = new ReservationListParam();
  param.phone = phone;

  return http
    .get<ReservationListApiResp>('/auth/house/reservation/landlord-list', param)
    .then((res: ReservationListApiResp): ReservationItem[] => {
      if (res && res.data && res.data.list) {
        return res.data.list;
      }
      if (res && res.list) {
        return res.list;
      }
      return [];
    });
};

// 租客：取消预约
export const cancelReservationApi = (id: number, phone: string): Promise<void> => {
  const body = new CancelReservationParam();
  body.id = id;
  body.phone = phone;

  return http.post<void>('/auth/house/reservation/cancel', body);
};

// 房东：同意/驳回预约
export const decisionReservationApi = (
  id: number,
  landlordPhone: string,
  action: 'accept' | 'reject'
): Promise<void> => {
  const body = new DecisionParam();
  body.id = id;
  body.landlordPhone = landlordPhone;
  body.action = action;

  return http.post<void>('/auth/house/reservation/decision', body);
};
