// entry/src/main/ets/api/adminRooms.ts
import { http } from '../common/utils/Request'

export interface AdminRoomListItem {
  id: string
  houseTitle: string
  address: string
  rentPriceListing: string
  rentPriceUnit: string
  housePicture: string
  status: string
}

export interface AdminRoomListData {
  list: AdminRoomListItem[]
  total: number
}

export interface RoomsListParams {
  keyword?: string
  status: string
}

export interface IdParams {
  id: string
}

export interface EmptyBody {
}

function buildRoomsListParams(keyword: string, status: string): RoomsListParams {
  const st: string = status && status.length > 0 ? status : 'all'
  const kw: string = keyword ? keyword.trim() : ''
  if (kw.length > 0) {
    const p: RoomsListParams = { keyword: kw, status: st }
    return p
  }
  const p: RoomsListParams = { status: st }
  return p
}

// ===== 对外 API =====

// 管理员：房源搜索列表（GET /rooms/admin/list）
export async function adminListRoomsApi(keyword: string, status: string, _token: string): Promise<AdminRoomListData> {
  const params: RoomsListParams = buildRoomsListParams(keyword, status)
  return http.get<AdminRoomListData>('/rooms/admin/list', params as never)
}

// 管理员：获取详情（复用 GET /house/detail?id=xxx）
export async function adminGetRoomDetailApi(id: string, _token: string): Promise<object> {
  const params: IdParams = { id }
  return http.get<object>('/house/detail', params as never)
}

// 管理员：保存 JSON（PUT /rooms/admin/:id）
export async function adminUpdateRoomApi(roomId: string, dataObj: object, _token: string): Promise<void> {
  await http.put<object>(`/rooms/admin/${encodeURIComponent(roomId)}`, dataObj as never)
}

// 管理员：删除（DELETE /rooms/admin/:id）
export async function adminDeleteRoomApi(roomId: string, _token: string): Promise<void> {
  const params: EmptyBody = {}
  await http.delete<object>(`/rooms/admin/${encodeURIComponent(roomId)}`, params as never)
}

// 上下架（POST /rooms/:id/online|offline）
export async function adminSetRoomOnlineApi(roomId: string, online: boolean, _token: string): Promise<void> {
  const body: EmptyBody = {}
  const path: string = online
    ? `/rooms/${encodeURIComponent(roomId)}/online`
    : `/rooms/${encodeURIComponent(roomId)}/offline`
  await http.post<object>(path, body as never)
}
