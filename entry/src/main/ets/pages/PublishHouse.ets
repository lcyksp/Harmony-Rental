// entry/src/main/ets/pages/PublishHouse.ets
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  publishRoomApi,
  PublishRoomPayload,
  HousePicture,
  RentTerm,
  MetaInfoItem
} from '../api/room';

@Entry
@Component
struct PublishHousePage {
  // ===== 当前登录用户（用 token 充当 userId） =====
  @StorageProp('token') token: string = ''
  // 和“我的 / 消息 / 设置”一样，用来垫过状态栏 / 摄像头
  @StorageProp('topRectHeight') topRectHeight: number = 0
  // 当前登录用户手机号（发布时用来绑定房东手机号）
  @StorageProp('userPhone') userPhone: string = ''

  // ===== 基础信息 =====
  @State rentType: string = '整租';
  @State community: string = '';   // 小区名
  @State district: string = '';    // 区县
  @State address: string = '';     // 详细地址

  @State rooms: string = '';       // 几室
  @State halls: string = '';       // 几厅
  @State orientation: string = ''; // 朝向
  @State area: string = '';        // 面积（㎡）

  // ===== 租金信息 =====
  @State price: string = '';       // 价格
  @State payment: string = '季付'; // 付款方式

  // ===== 图片 =====
  @State cover: string = '';       // 图片输入文本（第一张作为封面）

  // ===== 文案 / 区划 =====
  @State title: string = '';       // 自定义标题

  @State provinceCode: string = '34';
  @State cityCode: string = '3408';
  @State areaCode: string = '340803';

  // ===== 租期 / 配置信息（新增） =====
  @State checkInTime: string = '随时入住';         // 入住时间
  @State maxTerm: string = '租期最长1年10个月';    // 最长租期
  @State kitchenText: string = '有';               // 厨房：有 / 无
  @State liftText: string = '有';                  // 电梯：有 / 无
  @State yearBuilt: string = '2022年建成';         // 年代
  @State renovation: string = '精装';              // 装修情况
  @State heating: string = '集体供暖';             // 供暖方式
  @State greenRate: string = '30%';                // 绿化率
  @State protection: string = '房屋空气质量已检测'; // 环保说明
  @State grounding: string = '非首次出租';         // 上架说明

  @State submitting: boolean = false;

  build() {
    Column() {
      // ========== 顶部返回栏 ==========
      Row() {
        // 左：返回
        Text('< 返回')
          .fontSize(16)
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1)

        // 中：标题
        Text('发布房源')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        // 右：占位
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
          // ===== 基础信息 =====
          Text('基础信息')
            .fontSize(14)
            .fontColor('#888888')

          Row() {
            Text('租赁方式：').fontSize(14)

            Radio({ value: '整租', group: 'rentType' })
              .checked(this.rentType === '整租')
              .onChange((checked: boolean) => {
                if (checked) {
                  this.rentType = '整租'
                }
              })
            Text('整租').fontSize(14).margin({ right: 12 })

            Radio({ value: '合租', group: 'rentType' })
              .checked(this.rentType === '合租')
              .onChange((checked: boolean) => {
                if (checked) {
                  this.rentType = '合租'
                }
              })
            Text('合租').fontSize(14)
          }

          TextInput({ placeholder: '小区名称，例如：黄花亭新村' })
            .onChange((v: string) => this.community = v)

          TextInput({ placeholder: '所属区县，例如：大观区' })
            .onChange((v: string) => this.district = v)

          TextInput({ placeholder: '详细地址，例如：龙山路 XX 号' })
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
              if (this.submitting) {
                return
              }
              this.handleSubmit()
            })

          Blank().height(40)
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 40 })
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
    }
  }

  private handleSubmit() {
    if (!this.token || this.token.trim().length === 0) {
      promptAction.showToast({ message: '请先登录后再发布房源' })
      return
    }

    if ((!this.title && (!this.community || !this.rooms || !this.halls)) ||
      !this.price || !this.area || (!this.address && !this.district)) {
      promptAction.showToast({ message: '请至少填写：小区名 / 户型 / 价格 / 面积 / 地址' })
      return
    }

    if (!this.cover) {
      promptAction.showToast({ message: '请至少填写一张图片（文件名或URL）' })
      return
    }

    this.submitting = true

    const houseId: string = 'AQ' + new Date().getTime().toString()

    const autoTitle: string = `${this.rentType || '整租'}·${this.community || '某小区'} ` +
      `${this.rooms || '1'}室${this.halls || '1'}厅` +
      (this.orientation ? ` ${this.orientation}` : '')

    const finalTitle: string = this.title || autoTitle

    const addrCore: string = this.address || ''
    const finalAddress: string = this.district
      ? `${this.district}·${addrCore}`
      : addrCore

    const rawList: string[] = this.cover.split(',')
    const picFileList: string[] = []

    // ★ 数据库只存文件名，不存 URL / IP
    for (let i = 0; i < rawList.length; i++) {
      let s: string = rawList[i].trim()
      if (s.length === 0) {
        continue
      }

      // 如果是完整 URL，先去掉前面的 http://IP:port/public/
      if (s.startsWith('http://') || s.startsWith('https://')) {
        s = s.replace(/^https?:\/\/[^/]+\/public\//, '')
      }

      // 去掉 /public/ 前缀
      if (s.startsWith('/public/')) {
        s = s.substring('/public/'.length)
      }

      // 去掉开头的 '/'
      if (s.startsWith('/')) {
        s = s.substring(1)
      }

      // 到这里 s 必须是纯文件名，例如：room95.jpg
      picFileList.push(s)
    }

    // 兜底：如果上面没解析出任何文件名，再从整串 cover 里取一个
    if (picFileList.length === 0) {
      let fallback: string = this.cover.trim()
      if (fallback.length > 0) {
        if (fallback.startsWith('http://') || fallback.startsWith('https://')) {
          fallback = fallback.replace(/^https?:\/\/[^/]+\/public\//, '')
        }
        if (fallback.startsWith('/public/')) {
          fallback = fallback.substring('/public/'.length)
        }
        if (fallback.startsWith('/')) {
          fallback = fallback.substring(1)
        }
        picFileList.push(fallback)
      }
    }

    let detailJson: PublishRoomPayload = new PublishRoomPayload()
    detailJson.id = houseId
    detailJson.houseTitle = finalTitle
    detailJson.address = finalAddress
    detailJson.rentPriceUnit = '元/月'
    detailJson.ownerId = this.token
    detailJson.status = 'online'

    //新增：把房东手机号一起存进房源数据
    detailJson.landlordPhone = this.userPhone

    let pic: HousePicture = new HousePicture()
    pic.spaceName = '房间'
    pic.picList = picFileList    // ★ 这里只存文件名
    let picList: HousePicture[] = []
    picList.push(pic)
    detailJson.housePicture = picList

    detailJson.tags = []
    detailJson.rentPriceUnitListing = this.price

    let term: RentTerm = new RentTerm()
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
    term.house = this.community || this.district || ''
    detailJson.rentTerm = term

    let metaList: MetaInfoItem[] = []

    let mArea: MetaInfoItem = new MetaInfoItem()
    mArea.name = '使用面积'
    mArea.desc = this.area
    metaList.push(mArea)

    let mOri: MetaInfoItem = new MetaInfoItem()
    mOri.name = '朝向'
    mOri.desc = this.orientation || ''
    metaList.push(mOri)

    let mType: MetaInfoItem = new MetaInfoItem()
    mType.name = '户型'
    mType.desc = `${this.rooms || '1'}室${this.halls || '1'}厅1卫`
    metaList.push(mType)

    let mFloor: MetaInfoItem = new MetaInfoItem()
    mFloor.name = '楼层'
    mFloor.desc = '3/6'
    metaList.push(mFloor)

    detailJson.metaInfo = metaList

    detailJson.hdic_district_name = this.district || ''
    detailJson.rent_area = this.area
    detailJson.payment = this.payment || ''
    detailJson.area_code = this.areaCode
    detailJson.city_code = this.cityCode
    detailJson.province_code = this.provinceCode

    publishRoomApi(detailJson)
      .then(() => {
        // 通知“我发布的房源”页面刷新
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
