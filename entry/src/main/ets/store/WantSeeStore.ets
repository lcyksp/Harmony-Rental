// entry/src/main/ets/store/WantSeeStore.ets
// 想看房源的最小信息，先只存 id，后面需要再扩展字段
export class WantSeeItem {
  id: string = ''        // 房源ID
  title: string = ''     // 标题：整租·华茂1958C区 1室1厅 南
  cover: string = ''     // 封面图 url 或者本地资源名
  priceText: string = '' // 价格文案：1100 元/月
  location: string = ''  // 区域文案：大观区·菱湖
}

// AppStorage 的 key
const WANT_SEE_KEY: string = 'wantSeeIds';

// 初始化全局存储
if (!AppStorage.Has(WANT_SEE_KEY)) {
  AppStorage.SetOrCreate<WantSeeItem[]>(WANT_SEE_KEY, []);
}

// 获取完整列表
export function getWantSeeList(): WantSeeItem[] {
  const list = AppStorage.Get<WantSeeItem[]>(WANT_SEE_KEY);
  return Array.isArray(list) ? list : [];
}

// 是否在想看中
export function isInWantSee(id: string): boolean {
  if (!id) {
    return false;
  }
  const list = getWantSeeList();
  return list.some((item: WantSeeItem) => item.id === id);
}

// 切换：如果已存在就删掉，否则就加进去
// 返回值：true 表示当前是「已想看」，false 表示「未想看」
export function toggleWantSee(
  id: string,
  meta?: Partial<WantSeeItem>
): boolean {
  if (!id) return false;

  const list = getWantSeeList();
  const idx = list.findIndex((item: WantSeeItem) => item.id === id);

  if (idx >= 0) {
    // 取消想看
    const newList = [...list];
    newList.splice(idx, 1);
    AppStorage.Set<WantSeeItem[]>(WANT_SEE_KEY, newList);
    return false;
  } else {
    // 加入想看：把 meta 一起存进去
    const item: WantSeeItem = {
      id,
      title: meta?.title ?? '',
      cover: meta?.cover ?? '',
      priceText: meta?.priceText ?? '',
      location: meta?.location ?? '',
    };
    const newList = [...list, item];
    AppStorage.Set<WantSeeItem[]>(WANT_SEE_KEY, newList);
    return true;
  }
}
