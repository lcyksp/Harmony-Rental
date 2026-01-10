// entry/src/main/ets/api/room.ets
import { http } from '../common/utils/Request';
import { RoomListModel, SearchParams } from '../viewmodel/RoomListModel';
import type { RoomDetailModel } from '../viewmodel/RoomDetailModel';

// 子结构类型
export class HousePicture {
  spaceName: string = '';
  picList: string[] = [];
}

export class TagItem {
  name: string = '';
}

export class RentTerm {
  checkInTime: string = '';
  term: string = '';
  kitchen: string = '';
  lift: string = '';
  seeTime: string = '';
  year: string = '';
  renovation: string = '';
  grounding: string = '';
  heating: string = '';
  green: string = '';
  protection: string = '';
  house: string = '';
}

export class MetaInfoItem {
  name: string = '';
  desc: string = '';
}

// 发布房源完整入参
export class PublishRoomPayload {
  id?: string;
  ownerId: string = '';
  landlordPhone?: string = '';

  houseTitle: string = '';
  address: string = '';
  rentPriceUnit: string = '';

  housePicture: HousePicture[] = [];
  tags: TagItem[] = [];

  rentPriceUnitListing: string = '';
  rentTerm: RentTerm = new RentTerm();
  metaInfo: MetaInfoItem[] = [];

  hdic_district_name: string = '';
  rent_area: string = '';
  payment: string = '';
  area_code: string = '';
  city_code: string = '';
  province_code: string = '';
  status?: string;
}

// ====== 请求体 / 请求参数类型 ======
class OwnerIdParam {
  ownerId: string = '';
}

class TenantIdParam {
  tenantId: string = '';
}

class DeleteRoomParam {
  id: string = '';
}

// （后面下单用）
export class CreateOrderPayload {
  tenantId: string = '';
  tenantName: string = '';
  tenantPhone: string = '';
  remark: string = '';
}

class OwnerOrdersParam {
  ownerId: string = '';
  status: string = '';
}

class EmptyBodyParam {
}

// 我租的 / 我发布的 卡片用的精简结构
export class SimpleRoom {
  id: string = '';
  title: string = '';
  price: string = '';
  address: string = '';
  // “我发布的”用来画小红点：有多少条待处理订单（后端可以不传，默认 0）
  pendingOrderCount: number = 0;
}

export interface SimpleRoomListModel {
  list: SimpleRoom[];
  total: number;
}

// 订单列表结构（“我发布的 → 订单列表”、“我租到的”可共用）
export class RoomOrder {
  id: string = '';       // 订单 id
  roomId: string = '';   // 房源 id
  status: string = '';   // pending / confirmed / ended / cancelled
  tenantId: string = '';
  tenantName: string = '';
  tenantPhone: string = '';
  remark: string = '';
  createdAt: number = 0;

  roomTitle: string = '';
  roomAddress: string = '';
}

export class RoomOrderListModel {
  list: RoomOrder[] = [];
  total: number = 0;
}

// ------- 通用响应壳（为了兼容不同 http.get 写法）-------
class ApiSimpleRoomListResp {
  // 直接返回 data 的情况：{ list, total }
  list?: SimpleRoom[];
  total?: number;

  // 标准壳子：{ code, data:{ list, total }, message }
  code?: number;
  data?: SimpleRoomListModel;
  message?: string;
}

// 订单列表也走类似的壳
class ApiRoomOrderListResp {
  list?: RoomOrder[];
  total?: number;

  code?: number;
  data?: RoomOrderListModel;
  message?: string;
}

// =============================
// 房源列表 - GET /rooms
// =============================
export const getRoomListApi = (param: SearchParams): Promise<RoomListModel> => {
  // http.get 内部已经做了 { code, data, message } 的解包
  return http.get<RoomListModel>('/rooms', param);
};

// =============================
// 房源详情 - GET /rooms/:id
// =============================
export const getRoomDetailApi = (id: string): Promise<RoomDetailModel> => {
  return http.get<RoomDetailModel>(`/rooms/${id}`);
};

// =============================
// 发布房源 - POST /rooms
// =============================
export const publishRoomApi = (
  payload: PublishRoomPayload
): Promise<RoomDetailModel> => {
  return http.post<RoomDetailModel>('/rooms', payload);
};

// =============================
// 我发布的房源列表（只返回 online）
// GET /rooms/my/published?ownerId=xxx
// =============================
export const getMyPublishedRoomsApi = (ownerId: string): Promise<SimpleRoom[]> => {
  const param = new OwnerIdParam();
  param.ownerId = ownerId;

  return http
    .get<ApiSimpleRoomListResp>('/rooms/my/published', param)
    .then((res: ApiSimpleRoomListResp) => {
      let list: SimpleRoom[] = [];

      if (res.list !== undefined && Array.isArray(res.list)) {
        list = res.list;
      } else if (
        res.data !== undefined &&
          res.data.list !== undefined &&
        Array.isArray(res.data.list)
      ) {
        list = res.data.list;
      }

      // 再保险一层：把 id 统一成 string，过滤掉空 id
      const normalized: SimpleRoom[] = [];

      for (const item of list) {
        const hasId: boolean = item.id !== undefined && item.id !== null;
        const safeId: string = hasId ? String(item.id) : '';

        if (!safeId) {
          continue;
        }

        const room = new SimpleRoom();
        room.id = safeId;
        room.title = item.title;
        room.price = item.price;
        room.address = item.address;
        // 后端如果已经算好了 pendingOrderCount，这里顺带带上；否则默认 0
        room.pendingOrderCount = item.pendingOrderCount !== undefined
          ? item.pendingOrderCount
          : 0;

        normalized.push(room);
      }

      console.log(
        '[getMyPublishedRoomsApi] result list length =',
        normalized.length.toString()
      );
      console.log('[API] getMyPublishedRoomsApi ownerId =', ownerId);

      return normalized;
    });
};

// =============================
// 我租到的房源列表
// GET /rooms/my/rented?tenantId=xxx
// =============================
export const getMyRentedRoomsApi = (
  tenantId: string
): Promise<SimpleRoom[]> => {
  const param = new TenantIdParam();
  param.tenantId = tenantId;

  return http
    .get<ApiSimpleRoomListResp>('/rooms/my/rented', param)
    .then((res: ApiSimpleRoomListResp) => {
      let list: SimpleRoom[] = [];

      if (res.list !== undefined && Array.isArray(res.list)) {
        list = res.list;
      } else if (
        res.data !== undefined &&
          res.data.list !== undefined &&
        Array.isArray(res.data.list)
      ) {
        list = res.data.list;
      }

      console.log(
        '[getMyRentedRoomsApi] result list length =',
        list.length.toString()
      );
      console.log('[API] getMyRentedRoomsApi tenantId =', tenantId);

      return list;
    });
};

// =============================
// 删除 / 下架房源 - POST /rooms/delete
// =============================
export const deleteRoomApi = (roomId: string): Promise<void> => {
  const body = new DeleteRoomParam();
  body.id = roomId;
  return http.post<void>('/rooms/delete', body);
};

// =============================
// （租客）提交“我要租”订单 - POST /rooms/:id/orders
// =============================
export const createRoomOrderApi = (
  roomId: string,
  payload: CreateOrderPayload
): Promise<void> => {
  // 调用方务必传入 new CreateOrderPayload()，这样就不会触发 untyped obj literal
  return http.post<void>(`/rooms/${roomId}/orders`, payload);
};

// =============================
// （房东）查看自己的订单列表
// GET /rooms/my/orders?ownerId=xxx&status=pending
// =============================
export const getOwnerOrdersApi = (
  ownerId: string,
  status: string = 'pending'
): Promise<RoomOrder[]> => {
  const param = new OwnerOrdersParam();
  param.ownerId = ownerId;
  param.status = status;

  return http
    .get<ApiRoomOrderListResp>('/rooms/my/orders', param)
    .then((res: ApiRoomOrderListResp) => {
      let list: RoomOrder[] = [];

      if (res.list !== undefined && Array.isArray(res.list)) {
        list = res.list;
      } else if (
        res.data !== undefined &&
          res.data.list !== undefined &&
        Array.isArray(res.data.list)
      ) {
        list = res.data.list;
      }

      console.log(
        '[getOwnerOrdersApi] result list length =',
        list.length.toString()
      );
      console.log(
        '[API] getOwnerOrdersApi ownerId =',
        ownerId,
        ' status =',
        status
      );

      return list;
    });
};

// =============================
// （房东）确认出租 - POST /rooms/orders/:orderId/confirm
// =============================
export const confirmOrderApi = (orderId: string): Promise<void> => {
  const body = new EmptyBodyParam();
  return http.post<void>(`/rooms/orders/${orderId}/confirm`, body);
};

// =============================
// （租客/房东）退租 - POST /rooms/orders/:orderId/terminate
// =============================
export const terminateOrderApi = (orderId: string): Promise<void> => {
  const body = new EmptyBodyParam();
  return http.post<void>(`/rooms/orders/${orderId}/terminate`, body);
};

// =============================
// 预约看房 - POST /auth/house/reservation
// =============================

// ReservationPage 使用的参数类型
export interface ReservationParams {
  houseId: string;   // 房源 id
  name: string;      // 联系人姓名
  phone: string;     // 联系电话
  date: string;      // 看房时间
  comment?: string;  // 备注
}

// 预约接口真正发给后端的 payload 结构
class ReservationPayload {
  roomId: string = '';
  date: string = '';
  userName: string = '';
  remark: string = '';
  phone: string = '';
}

// 原始预约 API：把前端参数转成后端需要的字段
export const reservationApi = (params: ReservationParams): Promise<void> => {
  // ✅ 用显式的 class，避免 ArkTS 不允许“裸对象”
  const payload = new ReservationPayload();
  payload.roomId = params.houseId;
  payload.date = params.date;
  payload.userName = params.name;
  payload.remark = params.comment ?? '';
  payload.phone = params.phone;

  console.info('reservationApi payload => ', JSON.stringify(payload));

  // ✅ 你的 http.post 只有 1～2 个参数，这里只传 url + body
  return http.post<void>('/auth/house/reservation', payload);
};

// 提供给页面调用的别名函数（方便以后扩展）
export const createReservationApi = (params: ReservationParams): Promise<void> => {
  return reservationApi(params);
};
