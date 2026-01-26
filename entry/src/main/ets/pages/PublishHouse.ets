// entry/src/main/ets/pages/PublishHouse.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import http from '@ohos.net.http'
import { PUBLIC_BASE_URL } from '../common/utils/Request'
import {
  publishRoomApi,
  PublishRoomPayload,
  HousePicture,
  RentTerm,
  MetaInfoItem
} from '../api/room'

/** ===== 城市检索返回结构 ===== */
interface RegionListData<T> {
  list: T[]
}
interface RegionResp<T> {
  code: number
  message: string
  data: RegionListData<T>
}

/** 后端 /region/cities 可能返回的字段形态（兼容 code / cityCode / province_code 等） */
interface CityOptionRaw {
  code?: string
  cityCode?: string
  name?: string
  provinceCode?: string
  province_code?: string
}

interface CityOption {
  code: string
  name: string
  provinceCode: string
}

/** /region/cities params */
interface CityQueryParams {
  keyword: string
  limit: number
}

@Entry
@Component
struct PublishHousePage {
  // ===== 当前登录用户（用 token 充当 userId） =====
  @StorageProp('token') token: string = ''
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @StorageProp('userPhone') userPhone: string = ''

  // ===== 基础信息 =====
  @State rentType: string = '整租'
  @State community: string = ''   // 小区名

  //改造：只精确到市（城市由“搜索选择”产生）
  @State cityName: string = ''    // 城市显示名
  @State address: string = ''     // 详细地址（可为空）

  @State rooms: string = ''
  @State halls: string = ''
  @State orientation: string = ''
  @State area: string = ''

  // ===== 租金信息 =====
  @State price: string = ''
  @State payment: string = '季付'

  // ===== 图片 =====
  @State cover: string = ''

  // ===== 文案 / 区划 =====
  @State title: string = ''

  // 选中城市后会更新这些 code（默认保留）
  @State provinceCode: string = '34'
  @State cityCode: string = '3408'

  // ===== 租期 / 配置信息 =====
  @State checkInTime: string = '随时入住'
  @State maxTerm: string = '租期最长1年10个月'
  @State kitchenText: string = '有'
  @State liftText: string = '有'
  @State yearBuilt: string = '2022年建成'
  @State renovation: string = '精装'
  @State heating: string = '集体供暖'
  @State greenRate: string = '30%'
  @State protection: string = '房屋空气质量已检测'
  @State grounding: string = '非首次出租'

  @State submitting: boolean = false

  // ===== 城市选择弹层 =====
  @State showCityPicker: boolean = false
  @State cityKeyword: string = ''
  @State cityLoading: boolean = false
  @State cityList: CityOption[] = []
  private cityTimerId: number = 0

  /** ===== URL helper：把 PUBLIC_BASE_URL 的 /public 去掉，得到 API base ===== */
  private getApiBaseUrl(): string {
    const base: string = (PUBLIC_BASE_URL || '').replace(/\/+$/, '')
    return base.replace(/\/public$/i, '')
  }

  private buildApiUrl(path: string): string {
    const apiBase: string = this.getApiBaseUrl().replace(/\/+$/, '')
    const p: string = path.startsWith('/') ? path : `/${path}`
    return `${apiBase}${p}`
  }

  private safeParseResp<T>(text: string): RegionResp<T> | null {
    try {
      const obj: RegionResp<T> = JSON.parse(text) as RegionResp<T>
      if (!obj || typeof obj.code !== 'number' || !obj.data || !Array.isArray(obj.data.list)) return null
      return obj
    } catch (e) {
      return null
    }
  }

  private toCityOptionList(raw: CityOptionRaw[]): CityOption[] {
    const out: CityOption[] = []
    for (let i = 0; i < raw.length; i++) {
      const r: CityOptionRaw = raw[i]
      const code: string = String(r.code ?? r.cityCode ?? '').trim()
      const name: string = String(r.name ?? '').trim()
      const provinceCode: string = String(r.provinceCode ?? r.province_code ?? '').trim()
      if (!code || !name) continue
      out.push({ code, name, provinceCode })
    }
    return out
  }

  // ========== 城市：打开/搜索/选择 ==========
  private openCityPicker(): void {
    this.showCityPicker = true
    this.cityKeyword = ''
    this.cityList = []
    this.fetchCities({ keyword: '', limit: 50 })
  }

  private closeCityPicker(): void {
    this.showCityPicker = false
  }

  private onCityKeywordChange(v: string): void {
    this.cityKeyword = v

    if (this.cityTimerId) {
      clearTimeout(this.cityTimerId)
      this.cityTimerId = 0
    }

    this.cityTimerId = setTimeout(() => {
      this.fetchCities({ keyword: this.cityKeyword, limit: 50 })
    }, 250)
  }

  private async fetchCities(p: CityQueryParams): Promise<void> {
    this.cityLoading = true
    const client: http.HttpRequest = http.createHttp()

    const kw: string = encodeURIComponent((p.keyword || '').trim())
    const url: string = this.buildApiUrl(
      kw ? `/region/cities?keyword=${kw}&limit=${p.limit}` : `/region/cities?limit=${p.limit}`
    )

    try {
      const resp: http.HttpResponse = await client.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' }
      })

      let raw: string = ''
      if (typeof resp.result === 'string') raw = resp.result
      else raw = JSON.stringify(resp.result)

      if (resp.responseCode !== 200) {
        this.cityList = []
        promptAction.showToast({ message: `城市请求失败：HTTP ${resp.responseCode}` })
        return
      }

      const parsed: RegionResp<CityOptionRaw> | null = this.safeParseResp<CityOptionRaw>(raw)
      if (parsed && parsed.code === 200) {
        this.cityList = this.toCityOptionList(parsed.data.list)
      } else {
        this.cityList = []
        promptAction.showToast({ message: '城市数据解析失败' })
      }
    } catch (e) {
      this.cityList = []
      promptAction.showToast({ message: '城市请求异常：检查 BASE_URL/网络/后端' })
    } finally {
      client.destroy()
      this.cityLoading = false
    }
  }

  private chooseCity(item: CityOption): void {
    this.cityName = item.name
    this.cityCode = item.code
    if (item.provinceCode) this.provinceCode = item.provinceCode
    this.closeCityPicker()
  }

  // ========== 弹层 UI ==========
  @Builder
  CityPickerView() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.closeCityPicker())

      Column() {
        Row() {
          Text('选择城市').fontSize(16).fontWeight(FontWeight.Medium)
          Text('关闭').fontSize(14).fontColor('#666').onClick(() => this.closeCityPicker())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        TextInput({ placeholder: '输入关键字（如：北京）', text: this.cityKeyword })
          .onChange((v: string) => this.onCityKeywordChange(v))
          .width('100%')
          .height(40)
          .backgroundColor('#F6F7F8')
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .margin({ left: 16, right: 16, bottom: 8 })

        if (this.cityLoading) {
          Text('加载中...').fontSize(12).fontColor('#999')
            .padding({ left: 16, right: 16, bottom: 8 })
        }

        List() {
          ForEach(this.cityList, (it: CityOption) => {
            ListItem() {
              Row() {
                Text(it.name).fontSize(16)
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
            }.onClick(() => this.chooseCity(it))
          }, (it: CityOption) => it.code)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('70%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .clip(true)
      .onClick(() => {})
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack() {
      Column() {
        // ========== 顶部返回栏 ==========
        Row() {
          Text('< 返回')
            .fontSize(16)
            .fontColor('#333333')
            .onClick(() => router.back())
            .layoutWeight(1)

          Text('发布房源')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)

          Blank().layoutWeight(1)
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: this.topRectHeight + 8,
          bottom: 8
        })
        .backgroundColor('#8FE1A2')

        // ========== 表单主体 ==========
        Scroll() {
          Column({ space: 16 }) {
            Text('基础信息')
              .fontSize(14)
              .fontColor('#888888')

            Row() {
              Text('租赁方式：').fontSize(14)

              Radio({ value: '整租', group: 'rentType' })
                .checked(this.rentType === '整租')
                .onChange((checked: boolean) => { if (checked) this.rentType = '整租' })
              Text('整租').fontSize(14).margin({ right: 12 })

              Radio({ value: '合租', group: 'rentType' })
                .checked(this.rentType === '合租')
                .onChange((checked: boolean) => { if (checked) this.rentType = '合租' })
              Text('合租').fontSize(14)
            }

            TextInput({ placeholder: '小区名称，例如：黄花亭新村' })
              .onChange((v: string) => this.community = v)

            //城市（点击打开搜索选择）
            Row() {
              Text(this.cityName ? this.cityName : '选择城市（点击搜索）')
                .fontSize(14)
                .fontColor(this.cityName ? '#333333' : '#999999')
                .layoutWeight(1)
              Text('选择').fontSize(14).fontColor('#2F7DFF')
            }
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .onClick(() => this.openCityPicker())

            TextInput({ placeholder: '详细地址，例如：龙山路 XX 号（可不填）' })
              .onChange((v: string) => this.address = v)

            Row({ space: 12 }) {
              TextInput({ placeholder: '几室，例如：3' })
                .width('45%')
                .onChange((v: string) => this.rooms = v)

              TextInput({ placeholder: '几厅，例如：1' })
                .width('45%')
                .onChange((v: string) => this.halls = v)
            }

            TextInput({ placeholder: '朝向，例如：南 北' })
              .onChange((v: string) => this.orientation = v)

            TextInput({ placeholder: '使用面积，单位㎡' })
              .type(InputType.Number)
              .onChange((v: string) => this.area = v)

            // ===== 租金信息 =====
            Text('租金信息')
              .fontSize(14)
              .fontColor('#888888')
              .margin({ top: 16 })

            TextInput({ placeholder: '价格，单位元/月，例如：600' })
              .type(InputType.Number)
              .onChange((v: string) => this.price = v)

            TextInput({ placeholder: '付款方式，例如：押一付一 / 季付' })
              .onChange((v: string) => this.payment = v)

            // ===== 租期与配置信息 =====
            Text('租期与配置信息')
              .fontSize(14)
              .fontColor('#888888')
              .margin({ top: 16 })

            TextInput({ placeholder: '入住时间，例如：随时入住' })
              .onChange((v: string) => this.checkInTime = v)

            TextInput({ placeholder: '最长租期，例如：租期最长1年10个月' })
              .onChange((v: string) => this.maxTerm = v)

            Row({ space: 12 }) {
              TextInput({ placeholder: '厨房：有 / 无' })
                .width('45%')
                .onChange((v: string) => this.kitchenText = v)

              TextInput({ placeholder: '电梯：有 / 无' })
                .width('45%')
                .onChange((v: string) => this.liftText = v)
            }

            TextInput({ placeholder: '年份，例如：2022年建成' })
              .onChange((v: string) => this.yearBuilt = v)

            TextInput({ placeholder: '装修情况，例如：精装' })
              .onChange((v: string) => this.renovation = v)

            TextInput({ placeholder: '供暖方式，例如：集体供暖' })
              .onChange((v: string) => this.heating = v)

            TextInput({ placeholder: '绿化率，例如：30%' })
              .onChange((v: string) => this.greenRate = v)

            TextInput({ placeholder: '环保说明，例如：房屋空气质量已检测' })
              .onChange((v: string) => this.protection = v)

            TextInput({ placeholder: '上架说明，例如：非首次出租' })
              .onChange((v: string) => this.grounding = v)

            // ===== 图片 =====
            Text('图片')
              .fontSize(14)
              .fontColor('#888888')
              .margin({ top: 16 })

            Text('支持多张图片，用逗号分隔，第一张将作为封面')
              .fontSize(12)
              .fontColor('#999999')

            TextInput({ placeholder: '图片 URL 或文件名，例如：room95.jpg,room37.jpg' })
              .onChange((v: string) => this.cover = v)

            // ===== 自定义标题 =====
            Text('自定义标题（可不填，默认自动生成）')
              .fontSize(12)
              .fontColor('#999999')

            TextInput({ placeholder: '例如：整租·黄花亭新村 3室1厅 南/北' })
              .onChange((v: string) => this.title = v)

            Button(this.submitting ? '发布中…' : '提交发布')
              .margin({ top: 24, bottom: 24 })
              .onClick(() => {
                if (this.submitting) return
                this.handleSubmit()
              })

            Blank().height(40)
          }
          .padding({ left: 20, right: 20, top: 20, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
      }

      // 弹层：城市
      if (this.showCityPicker) {
        this.CityPickerView()
      }
    }
  }

  private handleSubmit(): void {
    if (!this.token || this.token.trim().length === 0) {
      promptAction.showToast({ message: '请先登录后再发布房源' })
      return
    }

    //只精确到市：必须选城市
    if (!this.cityCode || this.cityCode.trim().length === 0) {
      promptAction.showToast({ message: '请选择城市' })
      return
    }

    // 原校验：小区/户型/价格/面积/地址 至少要填
    if ((!this.title && (!this.community || !this.rooms || !this.halls)) ||
      !this.price || !this.area) {
      promptAction.showToast({ message: '请至少填写：小区名 / 户型 / 价格 / 面积' })
      return
    }

    if (!this.cover) {
      promptAction.showToast({ message: '请至少填写一张图片（文件名或URL）' })
      return
    }

    this.submitting = true

    const houseId: string = 'AQ' + new Date().getTime().toString()

    const autoTitle: string =
      `${this.rentType || '整租'}·${this.community || '某小区'} ` +
        `${this.rooms || '1'}室${this.halls || '1'}厅` +
        (this.orientation ? ` ${this.orientation}` : '')

    const finalTitle: string = this.title || autoTitle

    //地址组合：城市 + 详细地址（如果用户不填详细地址，也至少能看到城市）
    const addrCore: string = (this.address || '').trim()
    const finalAddress: string = addrCore
      ? `${this.cityName || ''}·${addrCore}`.replace(/^·/, '')
      : (this.cityName || '')

    // 图片解析：数据库只存文件名
    const rawList: string[] = this.cover.split(',')
    const picFileList: string[] = []

    for (let i = 0; i < rawList.length; i++) {
      let s: string = rawList[i].trim()
      if (s.length === 0) continue

      if (s.startsWith('http://') || s.startsWith('https://')) {
        s = s.replace(/^https?:\/\/[^/]+\/public\//, '')
      }
      if (s.startsWith('/public/')) s = s.substring('/public/'.length)
      if (s.startsWith('/')) s = s.substring(1)

      picFileList.push(s)
    }

    if (picFileList.length === 0) {
      let fallback: string = this.cover.trim()
      if (fallback.length > 0) {
        if (fallback.startsWith('http://') || fallback.startsWith('https://')) {
          fallback = fallback.replace(/^https?:\/\/[^/]+\/public\//, '')
        }
        if (fallback.startsWith('/public/')) fallback = fallback.substring('/public/'.length)
        if (fallback.startsWith('/')) fallback = fallback.substring(1)
        picFileList.push(fallback)
      }
    }

    const detailJson: PublishRoomPayload = new PublishRoomPayload()
    detailJson.id = houseId
    detailJson.houseTitle = finalTitle
    detailJson.address = finalAddress
    detailJson.rentPriceUnit = '元/月'
    detailJson.ownerId = this.token
    detailJson.status = 'online'
    detailJson.landlordPhone = this.userPhone

    const pic: HousePicture = new HousePicture()
    pic.spaceName = '房间'
    pic.picList = picFileList
    const picList: HousePicture[] = []
    picList.push(pic)
    detailJson.housePicture = picList

    detailJson.tags = []
    detailJson.rentPriceUnitListing = this.price

    const term: RentTerm = new RentTerm()
    term.checkInTime = this.checkInTime || '随时入住'
    term.term = this.maxTerm || '租期可协商'
    term.kitchen = this.kitchenText || '有'
    term.lift = this.liftText || '有'
    term.seeTime = '可随时看房'
    term.year = this.yearBuilt || ''
    term.renovation = this.renovation || ''
    term.grounding = this.grounding || '非首次出租'
    term.heating = this.heating || ''
    term.green = this.greenRate || ''
    term.protection = this.protection || ''
    term.house = this.community || this.cityName || ''
    detailJson.rentTerm = term

    const metaList: MetaInfoItem[] = []

    const mArea: MetaInfoItem = new MetaInfoItem()
    mArea.name = '使用面积'
    mArea.desc = this.area
    metaList.push(mArea)

    const mOri: MetaInfoItem = new MetaInfoItem()
    mOri.name = '朝向'
    mOri.desc = this.orientation || ''
    metaList.push(mOri)

    const mType: MetaInfoItem = new MetaInfoItem()
    mType.name = '户型'
    mType.desc = `${this.rooms || '1'}室${this.halls || '1'}厅1卫`
    metaList.push(mType)

    const mFloor: MetaInfoItem = new MetaInfoItem()
    mFloor.name = '楼层'
    mFloor.desc = '3/6'
    metaList.push(mFloor)

    detailJson.metaInfo = metaList

    //只精确到市：区县字段先置空（兼容旧后端字段）
    detailJson.hdic_district_name = ''
    detailJson.rent_area = this.area
    detailJson.payment = this.payment || ''

    // 旧字段 area_code 先留空，避免后端没改时报错
    detailJson.area_code = ''

    detailJson.city_code = this.cityCode
    detailJson.province_code = this.provinceCode

    publishRoomApi(detailJson)
      .then(() => {
        AppStorage.set('needReloadMyRooms', true)
        promptAction.showToast({ message: '发布成功' })
        router.back()
      })
      .catch((err: Error) => {
        console.error('publishRoomApi error', JSON.stringify(err))
        promptAction.showToast({ message: '发布失败，请稍后重试' })
      })
      .finally(() => {
        this.submitting = false
      })
  }
}
