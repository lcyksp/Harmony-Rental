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

export const addFootprintApi = (userId: string, houseId: string): Promise<void> => {
  return http.post<void>('/auth/footprint/add', { userId, houseId })
}

export const getFootprintListApi = (userId: string, limit: number = 50): Promise<FootprintItem[]> => {
  return http.get<FootprintItem[]>('/auth/footprint/list', { userId, limit })
}

export const removeFootprintApi = (userId: string, houseId: string): Promise<void> => {
  return http.post<void>('/auth/footprint/remove', { userId, houseId })
}

export const clearFootprintApi = (userId: string): Promise<void> => {
  return http.post<void>('/auth/footprint/clear', { userId })
}
