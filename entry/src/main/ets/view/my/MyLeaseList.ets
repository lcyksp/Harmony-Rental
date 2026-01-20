// entry/src/main/ets/view/my/MyLeaseList.ets
import router from '@ohos.router';
import prompt from '@ohos.prompt';
import { rvp } from '../../common/utils/DeviceScreen';
import {
  RentContractItem,
  getLandlordRentListApi,
  confirmRentApi,
  rejectRentApi,
  confirmQuitApi,
  rejectQuitApi
} from '../../api/rent';

interface UserInfo {
  phone?: string;
  userId?: string;
}

function getStorageString(key: string): string {
  if (!AppStorage.Has(key)) return '';
  const v: string | undefined | null = AppStorage.Get(key) as (string | undefined | null);
  return typeof v === 'string' ? v : '';
}

function getCurrentUserPhone(): string {
  const p1: string = getStorageString('userPhone');
  if (p1.length > 0) return p1;

  if (AppStorage.Has('user')) {
    const u: UserInfo = AppStorage.Get('user') as UserInfo;
    if (typeof u?.phone === 'string' && u.phone.length > 0) {
      AppStorage.setOrCreate('userPhone', u.phone);
      return u.phone;
    }
    if (typeof u?.userId === 'string' && u.userId.length > 0) return u.userId;
  }

  const p2: string = getStorageString('phone');
  if (p2.length > 0) return p2;

  const id: string = getStorageString('userId');
  if (id.length > 0) return id;

  return '';
}

function safeStr(v: string | undefined | null, fallback: string = ''): string {
  return typeof v === 'string' ? v : fallback;
}

function hasText(v: string | undefined | null): boolean {
  return typeof v === 'string' && v.length > 0;
}

// 核心工具：统一后端返回的状态码/字符串
function normalizeStatus(raw: string | undefined | null): string {
  const s: string = (typeof raw === 'string') ? raw.trim() : '';

  if (s === 'pending' || s === 'quit_pending' || s === 'active' || s === 'ended' || s === 'rejected') return s;

  const lower = s.toLowerCase();
  if (lower === 'quit-pending' || lower === 'quitpending' || lower === 'quit_pending') return 'quit_pending';
  if (lower === 'pending' || lower === 'wait_confirm' || lower === 'waitconfirm' || lower === 'to_confirm') return 'pending';
  if (lower === 'active' || lower === 'running' || lower === 'ongoing' || lower === 'effective') return 'active';
  if (lower === 'ended' || lower === 'finish' || lower === 'finished' || lower === 'closed') return 'ended';
  if (lower === 'rejected' || lower === 'reject' || lower === 'refused') return 'rejected';

  if (s === '0') return 'pending';
  if (s === '1') return 'active';
  if (s === '2') return 'quit_pending';
  if (s === '3') return 'ended';
  if (s === '4') return 'rejected';

  return s;
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

@Entry
@Component
struct MyLeaseList {
  @State currentTab: number = 0;  // 0=待确认 1=退租申请 2=生效中 3=全部
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
      console.warn('⚠️ [MyLeaseList] userPhone 为空，不请求 landlord 列表');
      this.list = [];
      return;
    }

    this.loading = true;
    try {
      const arr: RentContractItem[] = await getLandlordRentListApi(this.userPhone);
      this.list = Array.isArray(arr) ? arr : [];
    } catch (e) {
      this.list = [];
      prompt.showToast({ message: '加载失败' });
    } finally {
      this.loading = false;
    }
  }

  private onTabClick(tab: number) {
    if (this.currentTab === tab) return;
    this.currentTab = tab;
  }

  //新增：根据当前 Tab 过滤列表数据
  private getFilteredList(): RentContractItem[] {
    // Tab 3: 全部 -> 直接返回所有
    if (this.currentTab === 3) {
      return this.list;
    }

    let targetStatus = '';
    if (this.currentTab === 0) targetStatus = 'pending';       // 待确认
    else if (this.currentTab === 1) targetStatus = 'quit_pending'; // 退租申请
    else if (this.currentTab === 2) targetStatus = 'active';        // 生效中

    // 过滤数据
    return this.list.filter(item => normalizeStatus(item.status) === targetStatus);
  }

  // === 业务操作函数 ===
  private async onConfirmRent(item: RentContractItem) {
    try {
      await confirmRentApi(item.id, this.userPhone);
      prompt.showToast({ message: '已确认出租' });
      this.loadList(); // 操作成功后刷新列表
    } catch (e) {
      prompt.showToast({ message: '操作失败' });
    }
  }

  private async onRejectRent(item: RentContractItem) {
    try {
      await rejectRentApi(item.id, this.userPhone, '');
      prompt.showToast({ message: '已取消出租' });
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

  //修改：更清晰的卡片渲染逻辑
  @Builder
  LeaseCard(item: RentContractItem) {
    Row() {
      // 1. 左侧图片
      if (hasText(item.coverUrl)) {
        Image(safeStr(item.coverUrl))
          .width(rvp(80))
          .height(rvp(80))
          .borderRadius(rvp(6))
          .objectFit(ImageFit.Cover)
          .margin({ right: rvp(10) });
      } else {
        Column() {
          Text('无图')
            .fontSize(rvp(12))
            .fontColor('#999')
            .textAlign(TextAlign.Center);
        }
        .width(rvp(80))
        .height(rvp(80))
        .borderRadius(rvp(6))
        .backgroundColor('#F3F4F6')
        .justifyContent(FlexAlign.Center)
        .margin({ right: rvp(10) });
      }

      // 2. 中间信息
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

        Text(`状态：${statusText(normalizeStatus(item.status))}`)
          .fontSize(rvp(12))
          .fontColor(statusColor(normalizeStatus(item.status)))
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
      .alignItems(HorizontalAlign.Start);

      // 3. 右侧按钮操作区（核心修改）
      Column() {
        if (normalizeStatus(item.status) === 'pending') {
          // --- 待确认 ---
          Button('确认出租')
            .fontSize(rvp(12))
            .height(rvp(26))
            .width(rvp(64))
            .padding(0)
            .backgroundColor('#22c55e')
            .fontColor('#ffffff')
            .onClick(() => this.onConfirmRent(item));

          Button('取消出租')
            .fontSize(rvp(12))
            .height(rvp(26))
            .width(rvp(64))
            .padding(0)
            .backgroundColor('#ff4b4b')
            .fontColor('#ffffff')
            .margin({ top: rvp(8) })
            .onClick(() => this.onRejectRent(item));

        } else if (normalizeStatus(item.status) === 'quit_pending') {
          // --- 退租申请 ---
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

        } else if (normalizeStatus(item.status) === 'active') {
          // --- 生效中 (无按钮，显示绿色文本) ---
          Text('租约已生效')
            .fontSize(rvp(12))
            .fontColor('#22c55e')
            .fontWeight(FontWeight.Bold);

        } else {
          // --- 其他 (已结束/已拒绝) ---
          Text(statusText(normalizeStatus(item.status)))
            .fontSize(rvp(13))
            .fontWeight(FontWeight.Medium)
            .fontColor(statusColor(normalizeStatus(item.status)));
        }
      }
      .width(rvp(72))
      .alignItems(HorizontalAlign.End);
    }
    .width('100%')
    .constraintSize({ minHeight: rvp(72) })
    .padding(rvp(12))
    .backgroundColor('#FFFFFF')
    .borderRadius(rvp(8))
    .alignItems(VerticalAlign.Top);
  }

  @Builder
  LoadingView() {
    Column() {
      Text('加载中...')
        .fontSize(rvp(14))
        .fontColor('#999')
        .margin({ top: rvp(50) });
    }.width('100%');
  }

  @Builder
  EmptyView(msg: string) {
    Column() {
      Text(msg)
        .fontSize(rvp(14))
        .fontColor('#999')
        .margin({ top: rvp(50) });
    }.width('100%');
  }

  build() {
    Column() {
      // 标题栏
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

      // Tab 栏
      Row() {
        Column() {
          Text('待确认')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 0 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal);
          if (this.currentTab === 0) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) });
          }
        }.onClick(() => this.onTabClick(0)).layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('退租申请')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 1 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal);
          if (this.currentTab === 1) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) });
          }
        }.onClick(() => this.onTabClick(1)).layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('生效中')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 2 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 2 ? FontWeight.Bold : FontWeight.Normal);
          if (this.currentTab === 2) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) });
          }
        }.onClick(() => this.onTabClick(2)).layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('全部')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 3 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 3 ? FontWeight.Bold : FontWeight.Normal);
          if (this.currentTab === 3) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) });
          }
        }.onClick(() => this.onTabClick(3)).layoutWeight(1).alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .padding({ top: rvp(10), bottom: rvp(10) })
      .backgroundColor('#FFFFFF');

      // 列表内容区域
      Column() {
        if (this.loading) {
          this.LoadingView();
        } else {
          // 这里是关键：先获取过滤后的列表
          // 因为 ArkTS 可以在 build 外部执行逻辑，但 ForEach 最好直接处理数组
          // 我们这里利用 TS 的特性，在渲染时动态获取 filtered 数组

          Scroll(this.scroller) {
            Column() {
              ForEach(
                this.getFilteredList(),
                (item: RentContractItem) => {
                  Column() {
                    this.LeaseCard(item);
                  }.margin({ bottom: rvp(10) });
                },
                (item: RentContractItem) => `${item.id}_${this.currentTab}_${item.status}`
              );

              if (this.getFilteredList().length === 0) {
                this.EmptyView('没有相关记录');
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .padding({ left: rvp(12), right: rvp(12), top: rvp(4), bottom: rvp(20) });
          }
          .width('100%')
          .height('100%')
          .align(Alignment.TopStart);
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F7FA');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}