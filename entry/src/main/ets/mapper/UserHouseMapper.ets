import { UserHouse } from '../store/UserHouseStore'
import { RoomRecommendItem, TagItem } from '../viewmodel/HomeModel'

export function mapUserHouseToRecommend(h: UserHouse): RoomRecommendItem {
  const item: RoomRecommendItem = {
    // RoomRecommendItem 定义里就这几个字段，全部按它来
    id: h.id.toString(),
    houseTitle: h.title,
    address: h.address,
    housePicture: h.cover,
    rentArea: h.area.toString(),          // 如果需要“㎡”可以改成 `${h.area}㎡`
    rentPriceListing: h.price.toString(), // 显示价格
    rentPriceUnit: '元/月',               // 你也可以换成后端实际单位
    tags: [] as TagItem[]                 // 暂时没有标签数据，用空数组
  }

  return item
}
