import router from '@ohos.router';
import prompt from '@ohos.prompt';
import { rvp } from '../common/utils/DeviceScreen';
import {
  RentContractItem,
  getLandlordRentListApi,
  confirmRentApi,
  confirmQuitApi,
  rejectQuitApi
} from '../api/rent';

interface UserInfo {
  phone?: string;
  userId?: string;
}

function getCurrentUserPhone(): string {
  // 1) 你工程登录后真正存的是 userPhone
  if (AppStorage.Has('userPhone')) {
    const p = AppStorage.Get('userPhone') as string
    if (p && p.length > 0) return p
  }

  // 2) 兜底：从 user 对象里取 phone（ChatList.ets 同款写法）
  if (AppStorage.Has('user')) {
    const usr = AppStorage.Get('user') as object
    const phone = Reflect.get(usr, 'phone') as string
    if (phone && phone.length > 0) {
      AppStorage.setOrCreate('userPhone', phone)
      return phone
    }
    const userId = Reflect.get(usr, 'userId') as string
    if (userId && userId.length > 0) return userId
  }

  // 3) 最后兜底：userId
  if (AppStorage.Has('userId')) {
    const id = AppStorage.Get('userId') as string
    if (id && id.length > 0) return id
  }

  return ''
}

function statusText(status?: string): string {
  switch (status) {
    case 'pending': return '待确认';
    case 'active': return '生效中';
    case 'quit_pending': return '退租申请中';
    case 'ended': return '已结束';
    case 'rejected': return '已拒绝';
    default: return status || '';
  }
}

function statusColor(status?: string): string {
  switch (status) {
    case 'active': return '#22c55e';
    case 'rejected': return '#ef4444';
    case 'ended': return '#9ca3af';
    case 'quit_pending': return '#f59e0b';
    case 'pending':
    default: return '#f59e0b';
  }
}

// ✅ 关键：兜底（防止 coverUrl/remark 不是 string 或 undefined 导致 .length 崩）
function safeStr(v: string | undefined | null, fallback: string = ''): string {
  return typeof v === 'string' ? v : fallback;
}

function hasText(v: string | undefined | null): boolean {
  return typeof v === 'string' && v.length > 0;
}

@Entry
@Component
struct MyLeaseList {
  @State currentTab: number = 0; // 0=待确认 1=退租申请 2=生效中 3=全部
  @State list: RentContractItem[] = [];
  @State loading: boolean = false;
  @StorageProp('topRectHeight') topRectHeight: number = 0;

  private userPhone: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.userPhone = getCurrentUserPhone();
    this.loadList();
  }

  private async loadList() {
    if (!this.userPhone) {
      this.list = [];
      return;
    }
    this.loading = true;
    try {
      const data = await getLandlordRentListApi(this.userPhone);
      // ✅ 防止接口返回非数组导致后续 length/filter 崩
      this.list = Array.isArray(data) ? data : [];
    } catch (e) {
      prompt.showToast({ message: '加载失败' });
      this.list = [];
    } finally {
      this.loading = false;
    }
  }

  private get filtered(): RentContractItem[] {
    const arr: RentContractItem[] = Array.isArray(this.list) ? this.list : [];
    if (this.currentTab === 0) return arr.filter(it => it.status === 'pending');
    if (this.currentTab === 1) return arr.filter(it => it.status === 'quit_pending');
    if (this.currentTab === 2) return arr.filter(it => it.status === 'active');
    return arr;
  }

  private async onConfirmRent(item: RentContractItem) {
    try {
      await confirmRentApi(item.id, this.userPhone);
      prompt.showToast({ message: '已确认出租' });
      this.loadList();
    } catch (e) {
      prompt.showToast({ message: '操作失败' });
    }
  }

  private async onConfirmQuit(item: RentContractItem) {
    try {
      await confirmQuitApi(item.id, this.userPhone);
      prompt.showToast({ message: '已同意退租' });
      this.loadList();
    } catch (e) {
      prompt.showToast({ message: '操作失败' });
    }
  }

  private async onRejectQuit(item: RentContractItem) {
    try {
      await rejectQuitApi(item.id, this.userPhone, '');
      prompt.showToast({ message: '已驳回退租' });
      this.loadList();
    } catch (e) {
      prompt.showToast({ message: '操作失败' });
    }
  }

  // ✅ Builder 里不要写 const/let；也不要 item.xxx.length
  @Builder LeaseCard(item: RentContractItem) {
    Row() {
      // --- 1. 图片 ---
      if (hasText(item.coverUrl)) {
        Image(safeStr(item.coverUrl))
          .width(rvp(80))
          .height(rvp(80))
          .borderRadius(rvp(6))
          .objectFit(ImageFit.Cover)
          .margin({ right: rvp(10) });
      } else {
        Column() {
          Text('无图').fontSize(rvp(12)).fontColor('#999').textAlign(TextAlign.Center)
        }
        .width(rvp(80))
        .height(rvp(80))
        .borderRadius(rvp(6))
        .backgroundColor('#F3F4F6')
        .justifyContent(FlexAlign.Center)
        .margin({ right: rvp(10) });
      }

      // --- 2. 信息 ---
      Column() {
        Text(safeStr(item.houseTitle, '房源名称'))
          .fontSize(rvp(15))
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: rvp(6) });

        Text(`租客：${safeStr(item.tenant_phone, '-')}`)
          .fontSize(rvp(12))
          .fontColor('#555555')
          .margin({ bottom: rvp(2) });

        Text(`状态：${statusText(safeStr(item.status))}`)
          .fontSize(rvp(12))
          .fontColor(statusColor(safeStr(item.status)))
          .margin({ bottom: rvp(2) });

        if (hasText(item.remark)) {
          Text(`备注：${safeStr(item.remark)}`)
            .fontSize(rvp(12))
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%');
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      // --- 3. 操作区 ---
      Column() {
        if (item.status === 'pending') {
          Button('确认出租')
            .fontSize(rvp(12))
            .height(rvp(26))
            .width(rvp(64))
            .padding(0)
            .backgroundColor('#22c55e')
            .fontColor('#ffffff')
            .onClick(() => this.onConfirmRent(item));
        } else if (item.status === 'quit_pending') {
          Button('同意退租')
            .fontSize(rvp(12))
            .height(rvp(26))
            .width(rvp(64))
            .padding(0)
            .backgroundColor('#22c55e')
            .fontColor('#ffffff')
            .margin({ bottom: rvp(8) })
            .onClick(() => this.onConfirmQuit(item));

          Button('驳回')
            .fontSize(rvp(12))
            .height(rvp(26))
            .width(rvp(64))
            .padding(0)
            .backgroundColor('#ff4b4b')
            .fontColor('#ffffff')
            .onClick(() => this.onRejectQuit(item));
        } else {
          Text(statusText(safeStr(item.status)))
            .fontSize(rvp(13))
            .fontWeight(FontWeight.Medium)
            .fontColor(statusColor(safeStr(item.status)));
        }
      }
      .width(rvp(72))
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Start)
      .margin({ left: rvp(4) })
    }
    .width('100%')
    .constraintSize({ minHeight: rvp(72) })
    .padding(rvp(12))
    .backgroundColor('#FFFFFF')
    .borderRadius(rvp(8))
    .alignItems(VerticalAlign.Top);
  }

  @Builder LoadingView() {
    Column() { Text('加载中...').fontSize(rvp(14)).fontColor('#999').margin({ top: rvp(50) }) }.width('100%')
  }

  @Builder EmptyView(msg: string) {
    Column() { Text(msg).fontSize(rvp(14)).fontColor('#999').margin({ top: rvp(50) }) }.width('100%')
  }

  build() {
    Column() {
      // 顶部
      Row() {
        Text('< 返回')
          .fontSize(rvp(16))
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1);
        Text('租出的房')
          .fontSize(rvp(18))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(2);
        Blank().layoutWeight(1);
      }
      .width('100%')
      .padding({
        left: rvp(16), right: rvp(16),
        top: this.topRectHeight + rvp(10), bottom: rvp(10)
      })
      .backgroundColor('#FFFFFF');

      // Tab
      Row() {
        Column() {
          Text('待确认')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 0 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          if (this.currentTab === 0) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
          }
        }.onClick(() => this.currentTab = 0).layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('退租申请')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 1 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          if (this.currentTab === 1) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
          }
        }.onClick(() => this.currentTab = 1).layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('生效中')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 2 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 2 ? FontWeight.Bold : FontWeight.Normal)
          if (this.currentTab === 2) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
          }
        }.onClick(() => this.currentTab = 2).layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('全部')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 3 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 3 ? FontWeight.Bold : FontWeight.Normal)
          if (this.currentTab === 3) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
          }
        }.onClick(() => this.currentTab = 3).layoutWeight(1).alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .padding({ top: rvp(10), bottom: rvp(10) })
      .backgroundColor('#FFFFFF');

      // 列表
      Column() {
        if (this.loading) {
          this.LoadingView()
        } else if ((this.filtered?.length ?? 0) === 0) { // ✅ 防止 length 崩
          this.EmptyView('暂无记录')
        } else {
          List({ space: rvp(10), scroller: this.scroller }) {
            ForEach(this.filtered, (item: RentContractItem) => {
              ListItem() { this.LeaseCard(item) }
            }, (it: RentContractItem) => it.id.toString())
          }
          .width('100%').layoutWeight(1)
          .padding({ left: rvp(12), right: rvp(12), top: rvp(10), bottom: rvp(20) })
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F7FA')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
