// entry/src/main/ets/api/rent.ets
import { http } from '../common/utils/Request';

export interface RentContractItem {
  id: number
  house_id: string
  tenant_phone: string
  landlord_phone: string
  status: string
  remark?: string
  created_at?: number
  updated_at?: number
  houseTitle?: string
  coverUrl?: string
}
export interface LandlordRentListData {
  list?: RentContractItem[];
}

interface ApiRespWrap<T> {
  code?: number
  message?: string
  data?: T
}

interface RentListData {
  list?: RentContractItem[]
}

// 兼容三种返回：
// 1) 直接数组：RentContractItem[]
// 2) { list: RentContractItem[] }
// 3) { code, data: { list: RentContractItem[] }, message }
type RentListResp = RentContractItem[] | RentListData | ApiRespWrap<RentListData>;

function unwrapRentList(resp: RentListResp): RentContractItem[] {
  // 1) 直接是数组
  if (Array.isArray(resp)) return resp;

  // 2) { list: [...] }
  const directList = (resp as RentListData).list;
  if (Array.isArray(directList)) return directList;

  // 3) { data: { list: [...] } }
  const wrappedList = (resp as ApiRespWrap<RentListData>).data?.list;
  if (Array.isArray(wrappedList)) return wrappedList;

  return [];
}

/** 房东：我租出的（列表） */
export const getLandlordRentListApi = (phone: string): Promise<RentContractItem[]> => {
  return http
    .get<RentListResp>('/auth/rent/landlord-list', { phone })
    .then((resp: RentListResp) => unwrapRentList(resp));
}

/** 房东：确认出租 */
export const confirmRentApi = (id: number, landlordPhone: string): Promise<void> => {
  return http.post<void>('/auth/rent/confirm', { id, landlordPhone });
}

/** 租客：我租到的（生效中） */
export const getMyActiveRentApi = (phone: string): Promise<RentContractItem[]> => {
  return http
    .get<RentListResp>('/auth/rent/my-active', { phone })
    .then((resp: RentListResp) => unwrapRentList(resp));
}

/** 租客：申请退租 */
export const applyQuitApi = (id: number, tenantPhone: string, reason?: string): Promise<void> => {
  return http.post<void>('/auth/rent/quit/apply', { id, tenantPhone, reason: reason ?? '' });
}

/** 房东：同意退租 */
export const confirmQuitApi = (id: number, landlordPhone: string): Promise<void> => {
  return http.post<void>('/auth/rent/quit/confirm', { id, landlordPhone });
}

/** 房东：驳回退租 */
export const rejectQuitApi = (id: number, landlordPhone: string, reason?: string): Promise<void> => {
  return http.post<void>('/auth/rent/quit/reject', { id, landlordPhone, reason: reason ?? '' });
}

/** 租客：下订/创建租约 */
export const createRentApi = (houseId: string, tenantPhone: string, remark?: string): Promise<void> => {
  return http.post<void>('/auth/rent/create', {
    houseId,
    tenantPhone,
    remark: remark ?? ''
  });
}
/** 房东：驳回/取消出租（待确认时） */
export const rejectRentApi = (id: number, landlordPhone: string, reason?: string): Promise<void> => {
  return http.post<void>('/auth/rent/reject', {
    id,
    landlordPhone,
    reason: reason ?? ''
  });
}

