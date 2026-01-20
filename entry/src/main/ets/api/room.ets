// entry/src/main/ets/api/room.ets
import { http } from '../common/utils/Request'
import { RoomListModel, SearchParams } from '../viewmodel/RoomListModel'
import type { RoomDetailModel } from '../viewmodel/RoomDetailModel'
import type { ProvinceItem, CityItem, DistrictItem } from '../viewmodel/RoomListModel'

// 子结构类型
export class HousePicture {
  spaceName: string = ''
  picList: string[] = []
}

export class TagItem {
  name: string = ''
}

export class RentTerm {
  checkInTime: string = ''
  term: string = ''
  kitchen: string = ''
  lift: string = ''
  seeTime: string = ''
  year: string = ''
  renovation: string = ''
  grounding: string = ''
  heating: string = ''
  green: string = ''
  protection: string = ''
  house: string = ''
}

export class MetaInfoItem {
  name: string = ''
  desc: string = ''
}

// 发布房源完整入参
export class PublishRoomPayload {
  id?: string
  ownerId: string = ''
  landlordPhone?: string = ''

  houseTitle: string = ''
  address: string = ''
  rentPriceUnit: string = ''

  housePicture: HousePicture[] = []
  tags: TagItem[] = []

  rentPriceUnitListing: string = ''
  rentTerm: RentTerm = new RentTerm()
  metaInfo: MetaInfoItem[] = []

  hdic_district_name: string = ''
  rent_area: string = ''
  payment: string = ''
  area_code: string = ''
  city_code: string = ''
  province_code: string = ''
  status?: string
}

// ====== 请求体 / 请求参数类型 ======
class OwnerIdParam {
  ownerId: string = ''
}

class TenantIdParam {
  tenantId: string = ''
}

class DeleteRoomParam {
  id: string = ''
}

// （后面下单用）
export class CreateOrderPayload {
  tenantId: string = ''
  tenantName: string = ''
  tenantPhone: string = ''
  remark: string = ''
}

class OwnerOrdersParam {
  ownerId: string = ''
  status: string = ''
}

class EmptyBodyParam {}

// 我租的 / 我发布的 卡片用的精简结构（补齐我发布的字段）
export class SimpleRoom {
  id: string = ''
  title: string = ''
  price: string = ''
  address: string = ''

  // “我发布的”用来画小红点：有多少条待处理订单（后端可以不传，默认 0）
  pendingOrderCount: number = 0

  //“我发布的”页面需要
  status: string = 'online' // online / offline
  imageList: string[] = []  // 封面列表（第一张即可）
  province: string = ''
  city: string = ''
  district: string = ''
}

export interface SimpleRoomListModel {
  list: SimpleRoom[]
  total: number
}

// 订单列表结构（“我发布的 → 订单列表”、“我租到的”可共用）
export class RoomOrder {
  id: string = ''       // 订单 id
  roomId: string = ''   // 房源 id
  status: string = ''   // pending / confirmed / ended / cancelled
  tenantId: string = ''
  tenantName: string = ''
  tenantPhone: string = ''
  remark: string = ''
  createdAt: number = 0

  roomTitle: string = ''
  roomAddress: string = ''
}

export class RoomOrderListModel {
  list: RoomOrder[] = []
  total: number = 0
}

// ------- 通用响应壳（为了兼容不同 http.get 写法）-------
class ApiSimpleRoomListResp {
  // 直接返回 data 的情况：{ list, total }
  list?: SimpleRoom[]
  total?: number

  // 标准壳子：{ code, data:{ list, total }, message }
  code?: number
  data?: SimpleRoomListModel
  message?: string
}

// 订单列表也走类似的壳
class ApiRoomOrderListResp {
  list?: RoomOrder[]
  total?: number

  code?: number
  data?: RoomOrderListModel
  message?: string
}

// =============================
//“我的房源(全部 online+offline)”返回 item 结构（避免 any）
// =============================
interface MyRoomItemRaw {
  id?: string | number | null
  houseTitle?: string | null
  title?: string | null

  rentPriceListing?: string | number | null
  rentPriceUnitListing?: string | number | null
  rentPrice?: string | number | null
  price?: string | number | null

  address?: string | null
  location?: string | null
  districtName?: string | null

  coverUrl?: string | null
  imageUrl?: string | null
  housePicture?: string | null
  housePictureUrl?: string | null

  status?: string | null

  province?: string | null
  city?: string | null
  district?: string | null
  district_name?: string | null
  hdic_district_name?: string | null
}

//拆出来，避免 arkts-no-obj-literals-as-type
class ApiMyRoomsData {
  list: MyRoomItemRaw[] = []
  total: number = 0
}

class ApiMyRoomsResp {
  list?: MyRoomItemRaw[]
  total?: number

  code?: number
  data?: ApiMyRoomsData
  message?: string
}

// =============================
// 房源列表 - GET /rooms
// =============================
export const getRoomListApi = (param: SearchParams): Promise<RoomListModel> => {
  // http.get 内部已经做了 { code, data, message } 的解包
  return http.get<RoomListModel>('/rooms', param)
}

// =============================
// 房源详情 - GET /rooms/:id
// =============================
export const getRoomDetailApi = (id: string): Promise<RoomDetailModel> => {
  return http.get<RoomDetailModel>(`/rooms/${id}`)
}

// =============================
// 发布房源 - POST /rooms
// =============================
export const publishRoomApi = (payload: PublishRoomPayload): Promise<RoomDetailModel> => {
  return http.post<RoomDetailModel>('/rooms', payload)
}

// =============================
// 我发布的房源列表（只返回 online）
// GET /rooms/my/published?ownerId=xxx
// =============================
export const getMyPublishedRoomsApi = (ownerId: string): Promise<SimpleRoom[]> => {
  const param = new OwnerIdParam()
  param.ownerId = ownerId

  return http.get<ApiSimpleRoomListResp>('/rooms/my/published', param).then((res: ApiSimpleRoomListResp) => {
    let list: SimpleRoom[] = []

    if (res.list !== undefined && Array.isArray(res.list)) {
      list = res.list
    } else if (res.data !== undefined && res.data.list !== undefined && Array.isArray(res.data.list)) {
      list = res.data.list
    }

    const normalized: SimpleRoom[] = []

    for (const item of list) {
      const hasId: boolean = item.id !== undefined && item.id !== null
      const safeId: string = hasId ? String(item.id) : ''
      if (!safeId) continue

      const room = new SimpleRoom()
      room.id = safeId
      room.title = item.title
      room.price = item.price
      room.address = item.address
      room.pendingOrderCount = item.pendingOrderCount !== undefined ? item.pendingOrderCount : 0

      // 兼容：如果后端给了也带上，不给就默认值
      room.status = item.status !== undefined ? item.status : 'online'
      room.imageList = Array.isArray(item.imageList) ? item.imageList : []
      room.province = item.province !== undefined ? item.province : ''
      room.city = item.city !== undefined ? item.city : ''
      room.district = item.district !== undefined ? item.district : ''

      normalized.push(room)
    }

    console.log('[getMyPublishedRoomsApi] result list length =', normalized.length.toString())
    console.log('[API] getMyPublishedRoomsApi ownerId =', ownerId)

    return normalized
  })
}

// =============================
// 我发布的房源列表（返回 online + offline 全部）
// GET /rooms/my?ownerId=xxx
// =============================
export const getMyRoomsApi = (ownerId: string): Promise<SimpleRoom[]> => {
  const param = new OwnerIdParam()
  param.ownerId = ownerId

  return http.get<ApiMyRoomsResp>('/rooms/my', param).then((res: ApiMyRoomsResp) => {
    let list: MyRoomItemRaw[] = []

    if (res.list !== undefined && Array.isArray(res.list)) {
      list = res.list
    } else if (res.data !== undefined && Array.isArray(res.data.list)) {
      list = res.data.list
    }

    const normalized: SimpleRoom[] = []

    for (const it of list) {
      const id: string = it?.id !== undefined && it?.id !== null ? String(it.id) : ''
      if (!id) continue

      const room = new SimpleRoom()
      room.id = id

      room.title = String((it.houseTitle ?? it.title ?? '') || '')

      const p = it.rentPriceListing ?? it.rentPriceUnitListing ?? it.rentPrice ?? it.price ?? ''
      room.price = String(p ?? '')

      const addr = it.address ?? it.location ?? it.districtName ?? ''
      room.address = String(addr ?? '')

      const cover = it.coverUrl ?? it.imageUrl ?? it.housePictureUrl ?? it.housePicture ?? ''
      const coverStr = String(cover ?? '')
      room.imageList = coverStr ? [coverStr] : []

      room.status = String(it.status ?? 'online')

      room.province = String(it.province ?? '')
      room.city = String(it.city ?? '')
      room.district = String(it.district ?? it.district_name ?? it.hdic_district_name ?? '')

      normalized.push(room)
    }

    return normalized
  })
}

// =============================
// 我租到的房源列表
// GET /rooms/my/rented?tenantId=xxx
// =============================
export const getMyRentedRoomsApi = (tenantId: string): Promise<SimpleRoom[]> => {
  const param = new TenantIdParam()
  param.tenantId = tenantId

  return http.get<ApiSimpleRoomListResp>('/rooms/my/rented', param).then((res: ApiSimpleRoomListResp) => {
    let list: SimpleRoom[] = []

    if (res.list !== undefined && Array.isArray(res.list)) {
      list = res.list
    } else if (res.data !== undefined && res.data.list !== undefined && Array.isArray(res.data.list)) {
      list = res.data.list
    }

    console.log('[getMyRentedRoomsApi] result list length =', list.length.toString())
    console.log('[API] getMyRentedRoomsApi tenantId =', tenantId)

    return list
  })
}

// =============================
// 删除 / 下架房源 - POST /rooms/delete
// =============================
export const deleteRoomApi = (roomId: string): Promise<void> => {
  const body = new DeleteRoomParam()
  body.id = roomId
  return http.post<void>('/rooms/delete', body)
}

// =============================
//下架 - POST /rooms/:id/offline
// =============================
export const offShelfRoomApi = (id: string): Promise<void> => {
  const body = new EmptyBodyParam()
  return http.post<void>(`/rooms/${id}/offline`, body)
}

// =============================
//上架 - POST /rooms/:id/online
// =============================
export const onShelfRoomApi = (id: string): Promise<void> => {
  const body = new EmptyBodyParam()
  return http.post<void>(`/rooms/${id}/online`, body)
}

// =============================
// （租客）提交“我要租”订单 - POST /rooms/:id/orders
// =============================
export const createRoomOrderApi = (roomId: string, payload: CreateOrderPayload): Promise<void> => {
  return http.post<void>(`/rooms/${roomId}/orders`, payload)
}

// =============================
// （房东）查看自己的订单列表
// GET /rooms/my/orders?ownerId=xxx&status=pending
// =============================
export const getOwnerOrdersApi = (ownerId: string, status: string = 'pending'): Promise<RoomOrder[]> => {
  const param = new OwnerOrdersParam()
  param.ownerId = ownerId
  param.status = status

  return http.get<ApiRoomOrderListResp>('/rooms/my/orders', param).then((res: ApiRoomOrderListResp) => {
    let list: RoomOrder[] = []

    if (res.list !== undefined && Array.isArray(res.list)) {
      list = res.list
    } else if (res.data !== undefined && res.data.list !== undefined && Array.isArray(res.data.list)) {
      list = res.data.list
    }

    console.log('[getOwnerOrdersApi] result list length =', list.length.toString())
    console.log('[API] getOwnerOrdersApi ownerId =', ownerId, ' status =', status)

    return list
  })
}

// =============================
// （房东）确认出租 - POST /rooms/orders/:orderId/confirm
// =============================
export const confirmOrderApi = (orderId: string): Promise<void> => {
  const body = new EmptyBodyParam()
  return http.post<void>(`/rooms/orders/${orderId}/confirm`, body)
}

// =============================
// （租客/房东）退租 - POST /rooms/orders/:orderId/terminate
// =============================
export const terminateOrderApi = (orderId: string): Promise<void> => {
  const body = new EmptyBodyParam()
  return http.post<void>(`/rooms/orders/${orderId}/terminate`, body)
}

// =============================
// 预约看房 - POST /auth/house/reservation
// =============================

// ReservationPage 使用的参数类型
export interface ReservationParams {
  houseId: string  // 房源 id
  name: string     // 联系人姓名
  phone: string    // 联系电话
  date: string     // 看房时间
  comment?: string // 备注
}

// 预约接口真正发给后端的 payload 结构
class ReservationPayload {
  roomId: string = ''
  date: string = ''
  userName: string = ''
  remark: string = ''
  phone: string = ''
}

// 原始预约 API：把前端参数转成后端需要的字段
export const reservationApi = (params: ReservationParams): Promise<void> => {
  const payload = new ReservationPayload()
  payload.roomId = params.houseId
  payload.date = params.date
  payload.userName = params.name
  payload.remark = params.comment ?? ''
  payload.phone = params.phone

  console.info('reservationApi payload => ', JSON.stringify(payload))
  return http.post<void>('/auth/house/reservation', payload)
}

// 提供给页面调用的别名函数（方便以后扩展）
export const createReservationApi = (params: ReservationParams): Promise<void> => {
  return reservationApi(params)
}

// =============================
// 省 / 市 / 区（区域）接口
// =============================

// 这里用你的后端接口：/region/provinces /region/cities /region/areas
// 如果你后端路径不同，把字符串改掉即可

// 避免 arkts-no-obj-literals-as-types：不要在参数位置写 { provinceCode: string } 这种类型
class ProvinceQuery {}

class CityQuery {
  provinceCode: string = ''
}

class AreaQuery {
  cityCode: string = ''
}

//给对外 API 使用的参数类型（同样用 class，别用对象字面量类型）
export class CityApiParam {
  provinceCode: string = ''
}

export class AreaApiParam {
  cityCode: string = ''
}

export const getProvinceApi = (): Promise<ProvinceItem[]> => {
  return http.get<ProvinceItem[]>('/region/provinces', new ProvinceQuery())
}

export const getCityApi = (param: CityApiParam): Promise<CityItem[]> => {
  const q = new CityQuery()
  q.provinceCode = param.provinceCode
  return http.get<CityItem[]>('/region/cities', q)
}

export const getAreaApi = (param: AreaApiParam): Promise<DistrictItem[]> => {
  const q = new AreaQuery()
  q.cityCode = param.cityCode
  return http.get<DistrictItem[]>('/region/areas', q)
}
