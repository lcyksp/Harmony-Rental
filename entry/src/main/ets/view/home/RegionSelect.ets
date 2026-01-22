// entry/src/main/ets/view/home/RegionSelect.ets
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import http from '@ohos.net.http'
import { PUBLIC_BASE_URL } from '../../common/utils/Request'

interface CityOption {
  name: string
  //兼容：后端可能返回 code 或 cityCode
  code?: string
  cityCode?: string
  provinceCode: string
}

interface CityListData {
  list: CityOption[]
}

interface CityListResp {
  code: number
  message: string
  data: CityListData
}

@Entry
@Component
export struct RegionSelect {
  @StorageProp('topRectHeight') topRectHeight: number = 0

  @State keyword: string = ''
  @State list: CityOption[] = []
  @State loading: boolean = false

  private timerId: number = 0

  aboutToAppear(): void {
    this.fetchCities('')
  }

  private getApiBaseUrl(): string {
    const base: string = (PUBLIC_BASE_URL || '').replace(/\/+$/, '')
    // 去掉结尾的 /public
    return base.replace(/\/public$/i, '')
  }

  private buildApiUrl(path: string): string {
    const apiBase: string = this.getApiBaseUrl().replace(/\/+$/, '')
    const p: string = path.startsWith('/') ? path : `/${path}`
    return `${apiBase}${p}`
  }

  private safeParseCityResp(text: string): CityListResp | null {
    try {
      const obj: CityListResp = JSON.parse(text) as CityListResp
      if (!obj || typeof obj.code !== 'number' || !obj.data || !Array.isArray(obj.data.list)) {
        return null
      }
      return obj
    } catch (e) {
      return null
    }
  }

  //统一取城市 code（兼容两种字段）
  private pickCityCode(item: CityOption): string {
    return (item.code ?? item.cityCode ?? '').toString()
  }

  private async fetchCities(keyword: string): Promise<void> {
    this.loading = true
    const client: http.HttpRequest = http.createHttp()

    const kw: string = encodeURIComponent(keyword.trim())
    const url: string = this.buildApiUrl(
      kw ? `/region/cities?keyword=${kw}&limit=50` : '/region/cities?limit=50'
    )

    try {
      const resp: http.HttpResponse = await client.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' }
      })

      let raw: string = ''
      if (typeof resp.result === 'string') raw = resp.result
      else raw = JSON.stringify(resp.result)

      // HTTP 非 200
      if (resp.responseCode !== 200) {
        this.list = []
        promptAction.showToast({ message: `请求失败：HTTP ${resp.responseCode}` })
        return
      }

      const parsed: CityListResp | null = this.safeParseCityResp(raw)
      if (parsed && parsed.code === 200) {
        // ✅ 用新数组触发 @State 刷新
        this.list = [...parsed.data.list]
        console.info(`[RegionSelect] parsed list length=${this.list.length}`)
      } else {
        this.list = []
        promptAction.showToast({ message: '城市数据加载失败（返回结构/业务码不对）' })
      }
    } catch (e) {
      this.list = []
      promptAction.showToast({ message: '请求异常：检查 BASE_URL / 网络权限 / 后端是否可达' })
    } finally {
      client.destroy()
      this.loading = false
    }
  }

  private onKeywordChange(v: string): void {
    this.keyword = v

    if (this.timerId) {
      clearTimeout(this.timerId)
      this.timerId = 0
    }

    this.timerId = setTimeout(() => {
      this.fetchCities(this.keyword)
    }, 250)
  }

  private chooseCity(item: CityOption): void {
    const cityCode: string = this.pickCityCode(item)
    if (!cityCode) {
      promptAction.showToast({ message: '城市编码为空：请检查后端返回字段（code/cityCode）' })
      return
    }

    AppStorage.setOrCreate('currentCityName', item.name)
    AppStorage.setOrCreate('currentProvinceCode', item.provinceCode)
    AppStorage.setOrCreate('currentCityCode', cityCode)
    AppStorage.setOrCreate('currentDistrictCode', '')
    AppStorage.setOrCreate('needReloadHomeRooms', true)

    promptAction.showToast({ message: `已切换到 ${item.name}` })
    router.back()
  }

  build() {
    Column() {
      Row() {
        Text('选择地区').fontSize(18).fontWeight(700)
        Text('取消').fontSize(14).onClick(() => router.back())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Row() {
        TextInput({ placeholder: '搜索城市（如：北京）', text: this.keyword })
          .onChange((v: string) => this.onKeywordChange(v))
          .width('100%')
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.loading) {
        Text('加载中...').fontSize(12).fontColor('#999999')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      List() {
        ForEach(this.list, (item: CityOption) => {
          ListItem() {
            Row() { Text(item.name).fontSize(16) }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
          }.onClick(() => this.chooseCity(item))
        }, (item: CityOption) => this.pickCityCode(item)) //key 改成兼容 code/cityCode
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.topRectHeight })
    .backgroundColor('#F5F6F7')
  }
}
