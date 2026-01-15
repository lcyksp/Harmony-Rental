// entry/src/main/ets/pages/admin/AdminRoomJsonEdit.ets
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { adminGetRoomDetailApi, adminUpdateRoomApi } from '../../api/adminRooms'

interface AdminRoomJsonEditParams {
  id?: string
}

@Entry
@Component
struct AdminRoomJsonEdit {
  @State roomId: string = ''
  @State jsonText: string = ''
  @State loading: boolean = false

  private getToken(): string {
    return AppStorage.Has('token') ? (AppStorage.Get('token') as string) : ''
  }

  aboutToAppear(): void {
    const role: string = AppStorage.Has('userRole') ? (AppStorage.Get('userRole') as string) : ''
    if (role !== 'admin') {
      promptAction.showToast({ message: '无管理员权限', duration: 2000 })
      router.back()
      return
    }

    const params = router.getParams() as AdminRoomJsonEditParams
    this.roomId = params.id ? params.id : ''

    if (!this.roomId) {
      promptAction.showToast({ message: '缺少房源 id', duration: 2000 })
      router.back()
      return
    }

    this.loadDetail()
  }

  private async loadDetail(): Promise<void> {
    const token: string = this.getToken()
    this.loading = true
    try {
      const obj: Object = await adminGetRoomDetailApi(this.roomId, token)
      this.jsonText = JSON.stringify(obj, null, 2)
    } catch (e) {
      promptAction.showToast({ message: '加载详情失败', duration: 2000 })
    } finally {
      this.loading = false
    }
  }

  private async save(): Promise<void> {
    const token: string = this.getToken()
    if (!token) {
      promptAction.showToast({ message: '未登录', duration: 2000 })
      return
    }

    let obj: Object
    try {
      obj = JSON.parse(this.jsonText) as Object
    } catch (e) {
      promptAction.showToast({ message: 'JSON 格式错误', duration: 2000 })
      return
    }

    this.loading = true
    try {
      await adminUpdateRoomApi(this.roomId, obj, token)
      promptAction.showToast({ message: '保存成功', duration: 1500 })
      router.back()
    } catch (e) {
      promptAction.showToast({ message: '保存失败', duration: 2000 })
    } finally {
      this.loading = false
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('房源 JSON 编辑（管理员）')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Button('保存').onClick(() => this.save())
      }
      .padding(12)

      Text(`ID：${this.roomId}`)
        .fontSize(12)
        .fontColor('#666')
        .padding({ left: 12, right: 12 })

      TextArea({ text: this.jsonText, placeholder: '请输入 JSON' })
        .onChange((v: string) => this.jsonText = v)
        .width('100%')
        .layoutWeight(1)
        .padding(12)
    }
    .width('100%')
    .height('100%')
  }
}
