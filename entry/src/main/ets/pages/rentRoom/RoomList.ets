// entry/src/main/ets/pages/rentRoom/RoomList.ets
import { router } from '@kit.ArkUI'
import { NavBar } from '../../component/NavBar'
import { ListContent } from '../../view/roomList/ListContent'
import { rvp } from '../../common/utils/DeviceScreen'
import type { SearchParams } from '../../viewmodel/RoomListModel'

// ❌ 不再自己定义 SearchParams，这里用 viewmodel 里的那个

@Entry
@Component
export struct RoomList {
  // 对 ListContent 暴露完整搜索参数
  @Provide searchParams: SearchParams = {
    page: 1,
    limit: 10,
    provinceCode: '',
    cityCode: '',
    districtCode: '',
    minRent: '',
    maxRent: '',
    paymentType: '',
    orderBy: 'area',
    orderType: '',
    navTitle: '',
    roomType: undefined,
    // ⭐ 新增关键词字段，跟 SearchParams 保持一致
    keyword: ''
  }

  // 顶部搜索框绑定的关键字
  @State keyword: string = ''

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object> | undefined
    console.info('[RoomList] router params = ' + JSON.stringify(params))

    // navTitle（从首页 tab 传来的）
    if (params && typeof params['navTitle'] === 'string') {
      this.searchParams.navTitle = params['navTitle'] as string
    }

    // ⭐ 关键：把路由里的 keyword 写回搜索框 & searchParams
    if (params && typeof params['keyword'] === 'string') {
      const kw = params['keyword'] as string
      this.keyword = kw              // 顶部输入框回显“东莞”
      this.searchParams.keyword = kw // 提供给 ListContent 使用
    } else {
      this.keyword = ''
      this.searchParams.keyword = ''
    }

    console.info('[RoomList] searchParams = ' + JSON.stringify(this.searchParams))
  }


  // 点击“搜索”按钮
  private onSearchByKeyword() {
    const kw: string = this.keyword.trim()

    // 用路由刷当前页面，并把 navTitle / keyword 带过去
    router.replaceUrl({
      url: 'pages/rentRoom/RoomList',
      params: {
        navTitle: this.searchParams.navTitle ?? '',
        keyword: kw
      }
    })

    console.info('[RoomList] onSearchByKeyword keyword = ' + kw)
  }

  build() {
    Column() {
      // 顶部导航栏
      NavBar({ title: '房源列表' })

      // 顶部关键字搜索区域
      Row() {
        TextInput({
          text: this.keyword,
          placeholder: '请输入城市/小区/学校等'
        })
          .height(rvp(32))
          .layoutWeight(1)
          .fontSize(14)
          .onChange((value: string) => {
            this.keyword = value
          })

        Button('搜索', { type: ButtonType.Normal })
          .height(rvp(32))
          .margin({ left: rvp(8) })
          .onClick(() => {
            this.onSearchByKeyword()
          })
      }
      .padding({ left: rvp(16), right: rvp(16), top: rvp(8), bottom: rvp(8) })

      // 下面保留你原来的筛选栏（如果有的话）
      // ...

      // 房源列表内容（内部通过 @Consume<SearchParams> 拿 searchParams）
      ListContent()
    }
    .width('100%')
    .height('100%')
  }
}
