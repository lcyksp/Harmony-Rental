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

interface RentListData {
  list?: RentContractItem[]
}

export const getLandlordRentListApi = (phone: string): Promise<RentContractItem[]> => {
  return http
    .get<RentListData>('/auth/rent/landlord-list', { phone })
    .then((res: RentListData) => Array.isArray(res?.list) ? res.list! : []);
}

export const confirmRentApi = (id: number, landlordPhone: string): Promise<void> => {
  return http.post<void>('/auth/rent/confirm', { id, landlordPhone });
}

export const getMyActiveRentApi = (phone: string): Promise<RentContractItem[]> => {
  return http
    .get<RentListData>('/auth/rent/my-active', { phone })
    .then((res: RentListData) => Array.isArray(res?.list) ? res.list! : []);
}

export const applyQuitApi = (id: number, tenantPhone: string, reason?: string): Promise<void> => {
  return http.post<void>('/auth/rent/quit/apply', { id, tenantPhone, reason: reason ?? '' });
}

export const confirmQuitApi = (id: number, landlordPhone: string): Promise<void> => {
  return http.post<void>('/auth/rent/quit/confirm', { id, landlordPhone });
}

export const rejectQuitApi = (id: number, landlordPhone: string, reason?: string): Promise<void> => {
  return http.post<void>('/auth/rent/quit/reject', { id, landlordPhone, reason: reason ?? '' });
}

export const createRentApi = (houseId: string, tenantPhone: string, remark?: string): Promise<void> => {
  return http.post<void>('/auth/rent/create', {
    houseId,
    tenantPhone,
    remark: remark ?? ''
  })
}
