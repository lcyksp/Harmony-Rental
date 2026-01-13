import { http } from '../common/utils/Request'

export interface CityResolveResp {
  cityName: string
  cityCode: string
  provinceCode: string
}

// GET /regions/resolve?cityName=北京
export const resolveCityCodeApi = (cityName: string): Promise<CityResolveResp> => {
  return http.get<CityResolveResp>('/regions/resolve', { cityName })
}
