import { geoLocationManager } from '@kit.LocationKit'

export interface LocatedCity {
  cityName: string
  provinceName: string
}

// ✅ 抽成命名类型，避免 “对象字面量作为类型声明”
interface GeoAddressSimple {
  locality?: string
  subAdministrativeArea?: string
  administrativeArea?: string
}

/**
 * 纯工具函数：
 * 已知 latitude / longitude → 解析城市名
 * ❗不处理权限、不接触 Context
 */
export async function resolveCityFromLocation(
  latitude: number,
  longitude: number
): Promise<LocatedCity> {
  const list: Array<GeoAddressSimple> = await geoLocationManager.getAddressesFromLocation({
    latitude,
    longitude,
    maxItems: 1
  }) as Array<GeoAddressSimple>

  let cityName = ''
  let provinceName = ''

  if (Array.isArray(list) && list.length > 0) {
    const addr: GeoAddressSimple = list[0]
    cityName = addr.locality ?? addr.subAdministrativeArea ?? ''
    provinceName = addr.administrativeArea ?? ''
  }

  return { cityName, provinceName }
}
