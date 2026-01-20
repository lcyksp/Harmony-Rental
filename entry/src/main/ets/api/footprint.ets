// entry/src/main/ets/api/footprint.ets
import { http } from '../common/utils/Request'

export interface FootprintSnapshot {
  houseId: string
  title: string
  priceText: string
  address: string
  coverUrl: string
}

export interface FootprintItem {
  userId: string
  houseId: string
  viewedAt: number
  snapshot: FootprintSnapshot | null
}

// 同时支持 phone + userId（后端经常二选一/两者都要）
export interface FootprintAuth {
  phone?: string
  userId?: string
}

// 请求参数/Body：这里只会传 string/number，不需要 any
type ReqParams = Record<string, string | number>

// 后端可能返回：数组 或 {list:[]} 或 {records:[]}
interface FootprintListWrap {
  list?: FootprintItem[]
  records?: FootprintItem[]
}
type FootprintListResp = FootprintItem[] | FootprintListWrap

function buildAuthParams(auth: FootprintAuth): ReqParams {
  const p: ReqParams = {}
  if (auth.phone && auth.phone.length > 0) {
    p.phone = auth.phone
    return p //有 phone 就不传 userId，避免 userId=1 这种脏值干扰
  }
  if (auth.userId && auth.userId.length > 0) p.userId = auth.userId
  return p
}

function normalizeList(resp: FootprintListResp): FootprintItem[] {
  if (resp instanceof Array) return resp
  if (resp.list instanceof Array) return resp.list
  if (resp.records instanceof Array) return resp.records
  return []
}

//添加足迹：同时带 phone/userId 更稳（houseId 必带）
export const addFootprintApi = (auth: FootprintAuth, houseId: string): Promise<void> => {
  const body: ReqParams = buildAuthParams(auth)
  body.houseId = houseId
  return http.post<void>('/auth/footprint/add', body)
}

//获取足迹：同时带 phone/userId + page/size + limit(兼容)
export const getFootprintListApi = async (auth: FootprintAuth, size: number = 50): Promise<FootprintItem[]> => {
  const params: ReqParams = buildAuthParams(auth)

  params.page = 1
  params.size = size
  params.limit = size // 兼容老后端

  const data: FootprintListResp = await http.get<FootprintListResp>('/auth/footprint/list', params)
  return normalizeList(data)
}

//删除单条：带 phone/userId + houseId
export const removeFootprintApi = (auth: FootprintAuth, houseId: string): Promise<void> => {
  const body: ReqParams = buildAuthParams(auth)
  body.houseId = houseId
  return http.post<void>('/auth/footprint/remove', body)
}

//清空：带 phone/userId
export const clearFootprintApi = (auth: FootprintAuth): Promise<void> => {
  const body: ReqParams = buildAuthParams(auth)
  return http.post<void>('/auth/footprint/clear', body)
}
