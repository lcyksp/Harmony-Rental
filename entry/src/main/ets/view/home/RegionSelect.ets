// entry/src/main/ets/view/home/RegionSelect.ets
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import http from '@ohos.net.http'
import { PUBLIC_BASE_URL } from '../../common/utils/Request'

interface CityOption {
  name: string
  cityCode: string
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

  private async fetchCities(keyword: string): Promise<void> {
    this.loading = true
    const client: http.HttpRequest = http.createHttp()

    const kw: string = encodeURIComponent(keyword.trim())
    const url: string = this.buildApiUrl(
      kw ? `/region/cities?keyword=${kw}&limit=50` : '/region/cities?limit=50'
    )

    console.info(`[RegionSelect] PUBLIC_BASE_URL=${PUBLIC_BASE_URL}`)
    console.info(`[RegionSelect] API_BASE=${this.getApiBaseUrl()}`)
    console.info(`[RegionSelect] Request URL=${url}`)

    try {
      const resp: http.HttpResponse = await client.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' }
      })

      console.info(`[RegionSelect] HTTP responseCode=${resp.responseCode}`)

      let raw: string = ''
      if (typeof resp.result === 'string') raw = resp.result
      else raw = JSON.stringify(resp.result)

      const preview: string = raw.length > 200 ? raw.slice(0, 200) + '...' : raw
      console.info(`[RegionSelect] Body preview=${preview}`)

      // 如果是 404/500，直接提示更明确
      if (resp.responseCode !== 200) {
        this.list = []
        promptAction.showToast({ message: `请求失败：HTTP ${resp.responseCode}` })
        return
      }

      const parsed: CityListResp | null = this.safeParseCityResp(raw)
      if (parsed && parsed.code === 200) {
        this.list = parsed.data.list
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
    AppStorage.setOrCreate('currentCityName', item.name)
    AppStorage.setOrCreate('currentProvinceCode', item.provinceCode)
    AppStorage.setOrCreate('currentCityCode', item.cityCode)
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
        }, (item: CityOption) => item.cityCode)
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
