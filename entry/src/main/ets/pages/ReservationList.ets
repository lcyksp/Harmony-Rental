// entry/src/main/ets/pages/ReservationList.ets
import router from '@ohos.router';
import prompt from '@ohos.prompt';
import {
  getReservationListApi,
  getLandlordReservationListApi,
  cancelReservationApi,
  decisionReservationApi,
  ReservationItem
} from '../api/reservation';
import { rvp } from '../common/utils/DeviceScreen'

// ================== 工具函数 (保持不变) ==================

interface UserInfo {
  phone?: string;
  userId?: string;
}

function getCurrentUserPhone(): string {
  if (AppStorage.Has('phone')) {
    const p = AppStorage.Get('phone') as string;
    if (p && p.length > 0) return p;
  }
  if (AppStorage.Has('user')) {
    const u = AppStorage.Get('user') as UserInfo;
    if (u && u.phone && u.phone.length > 0) return u.phone;
    if (u && u.userId && u.userId.length > 0) return u.userId;
  }
  if (AppStorage.Has('userId')) {
    const id = AppStorage.Get('userId') as string;
    if (id && id.length > 0) return id;
  }
  return '';
}

function statusText(status?: string): string {
  switch (status) {
    case 'accepted': return '已同意';
    case 'rejected': return '已驳回';
    case 'cancelled': return '已取消';
    case 'pending':
    default: return '待确认';
  }
}

function statusColor(status?: string): string {
  switch (status) {
    case 'accepted': return '#22c55e'; // 绿色
    case 'rejected': return '#ef4444'; // 红色
    case 'cancelled': return '#9ca3af'; // 灰色
    case 'pending':
    default: return '#f59e0b'; // 橙色
  }
}

// ================== 页面组件 ==================

@Entry
@Component
struct ReservationListPage {
  @State currentTab: number = 0; // 0=我约看的 1=约看我的
  @State myReservations: ReservationItem[] = [];
  @State landlordReservations: ReservationItem[] = [];
  @State loadingMy: boolean = false;
  @State loadingLandlord: boolean = false;
  @StorageProp('topRectHeight') topRectHeight: number = 0;

  private userPhone: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.userPhone = getCurrentUserPhone();
    this.loadMyList();
    this.loadLandlordList();
  }

  // ... (loadMyList, loadLandlordList, cancelReservation, onDecision 逻辑保持不变，为节省篇幅省略，请直接使用上面的逻辑，或者保留你原有的) ...
  // 为了确保代码完整可运行，这里还是放上简化的逻辑:
  private async loadMyList() {
    if (!this.userPhone) return;
    this.loadingMy = true;
    try {
      this.myReservations = await getReservationListApi(this.userPhone);
    } catch (e) { console.error(e); } finally { this.loadingMy = false; }
  }

  private async loadLandlordList() {
    if (!this.userPhone) return;
    this.loadingLandlord = true;
    try {
      this.landlordReservations = await getLandlordReservationListApi(this.userPhone);
    } catch (e) { console.error(e); } finally { this.loadingLandlord = false; }
  }

  private async cancelReservation(item: ReservationItem) {
    try {
      await cancelReservationApi(item.id, this.userPhone);
      prompt.showToast({ message: '取消成功' });
      this.loadMyList();
    } catch (e) { prompt.showToast({ message: '取消失败' }); }
  }

  private async onDecision(item: ReservationItem, action: 'accept' | 'reject') {
    try {
      await decisionReservationApi(item.id, this.userPhone, action);
      prompt.showToast({ message: '操作成功' });
      this.loadLandlordList();
    } catch (e) { prompt.showToast({ message: '操作失败' }); }
  }


  // ============== 核心修改：全新布局的 ReservationCard ==============
  @Builder ReservationCard(item: ReservationItem) {
    Row() {
      // --- 1. 左侧：图片 ---
      if (item.coverUrl && item.coverUrl.length > 0) {
        Image(item.coverUrl)
          .width(rvp(80)) // 图片稍微加大一点，匹配右侧高度
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

      // --- 2. 中间：信息流 (垂直堆叠) ---
      Column() {
        // 标题
        Text(item.houseTitle || '房源名称')
          .fontSize(rvp(15))
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: rvp(6) });

        // 日期
        Text(item.date)
          .fontSize(rvp(12))
          .fontColor('#555555')
          .margin({ bottom: rvp(2) });

        // 姓名 (如果有)
        if (item.name) {
          Text(item.name)
            .fontSize(rvp(12))
            .fontColor('#555555')
            .margin({ bottom: rvp(2) });
        }

        // 电话 (区分Tab显示)
        // 如果是房东端(Tab=1)，显示租客电话；如果是租客端(Tab=0)，通常不需要显示自己电话，或者显示房东电话(如果接口有)
        // 这里按照你的需求：显示电话
        if (this.currentTab === 1 && item.tenantPhone && item.tenantPhone.length > 0) {
          Text(item.tenantPhone)
            .fontSize(rvp(12))
            .fontColor('#555555')
            .margin({ bottom: rvp(2) });
        } else if (this.currentTab === 0 && item.landlordPhone && item.landlordPhone.length > 0) {
          Text(item.landlordPhone)
            .fontSize(rvp(12))
            .fontColor('#555555')
            .margin({ bottom: rvp(2) });
        }

        // 备注
        if (item.comment && item.comment.length > 0) {
          Text(`备注：${item.comment}`)
            .fontSize(rvp(12))
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%');
        }
      }
      .layoutWeight(1) // 关键：占满中间剩余空间
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start) // 内容靠上对齐

      // --- 3. 右侧：操作区 (固定在右边) ---
      Column() {
        if (this.currentTab === 0) {
          // ====== 我约看的 ======
          if (item.status !== 'cancelled') {
            // 取消按钮
            Button('取消')
              .fontSize(rvp(12))
              .height(rvp(26))
              .width(rvp(56)) // 固定宽度，整齐
              .padding(0)
              .backgroundColor('#FF6666')
              .fontColor('#FFFFFF')
              .onClick(() => this.cancelReservation(item));
          } else {
            // 状态文字
            Text(statusText(item.status))
              .fontSize(rvp(13))
              .fontWeight(FontWeight.Medium)
              .fontColor(statusColor(item.status));
          }
        } else {
          // ====== 约看我的 ======
          if (item.status === 'pending' || !item.status) {
            // 垂直排列两个按钮，利用高度空间
            Button('同意')
              .fontSize(rvp(12))
              .height(rvp(26))
              .width(rvp(56))
              .padding(0)
              .backgroundColor('#22c55e')
              .fontColor('#ffffff')
              .margin({ bottom: rvp(8) }) // 按钮间距
              .onClick(() => this.onDecision(item, 'accept'));

            Button('驳回')
              .fontSize(rvp(12))
              .height(rvp(26))
              .width(rvp(56))
              .padding(0)
              .backgroundColor('#ff4b4b')
              .fontColor('#ffffff')
              .onClick(() => this.onDecision(item, 'reject'));

          } else {
            // 已处理的状态文字，垂直居中显示
            Text(statusText(item.status))
              .fontSize(rvp(13))
              .fontWeight(FontWeight.Medium)
              .fontColor(statusColor(item.status))
              .textAlign(TextAlign.End);
          }
        }
      }
      .width(rvp(60))
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Start)   
      .margin({ left: rvp(4) })

    }
    .width('100%')
    // 如果内容很多，高度会自适应；设置最小高度保证美观
    .constraintSize({ minHeight: rvp(72) })
    .padding(rvp(12))
    .backgroundColor('#FFFFFF')
    .borderRadius(rvp(8))
    .alignItems(VerticalAlign.Top); // 整体内容顶部对齐 (防止图片跑偏)
  }

  // ============== Build 方法 (结构保持不变，使用List) ==============
  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Text('< 返回')
          .fontSize(rvp(16))
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1);
        Text('约看记录')
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
      .backgroundColor('#8FE1A2');

      // 2. Tab 切换栏
      Row() {
        Column() {
          Text('我约看的')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 0 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          if (this.currentTab === 0) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
          }
        }
        .onClick(() => this.currentTab = 0)
        .layoutWeight(1).alignItems(HorizontalAlign.Center);

        Column() {
          Text('约看我的')
            .fontSize(rvp(15))
            .fontColor(this.currentTab === 1 ? '#2AB673' : '#666666')
            .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          if (this.currentTab === 1) {
            Divider().strokeWidth(3).color('#2AB673').width(rvp(20)).margin({ top: rvp(4) })
          }
        }
        .onClick(() => this.currentTab = 1)
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .padding({ top: rvp(10), bottom: rvp(10) })
      .backgroundColor('#FFFFFF');

      // 3. 列表区域
      Column() {
        if (this.currentTab === 0) {
          if (this.loadingMy) {
            this.LoadingView()
          } else if (this.myReservations.length === 0) {
            this.EmptyView('暂无约看记录')
          } else {
            List({ space: rvp(10), scroller: this.scroller }) {
              ForEach(this.myReservations, (item: ReservationItem) => {
                ListItem() { this.ReservationCard(item) }
              }, (item: ReservationItem) => item.id.toString())
            }
            .width('100%').layoutWeight(1)
            .padding({ left: rvp(12), right: rvp(12), top: rvp(10), bottom: rvp(20) })
            .edgeEffect(EdgeEffect.Spring)
          }
        } else {
          if (this.loadingLandlord) {
            this.LoadingView()
          } else if (this.landlordReservations.length === 0) {
            this.EmptyView('暂无被约记录')
          } else {
            List({ space: rvp(10), scroller: this.scroller }) {
              ForEach(this.landlordReservations, (item: ReservationItem) => {
                ListItem() { this.ReservationCard(item) }
              }, (item: ReservationItem) => item.id.toString())
            }
            .width('100%').layoutWeight(1)
            .padding({ left: rvp(12), right: rvp(12), top: rvp(10), bottom: rvp(20) })
            .edgeEffect(EdgeEffect.Spring)
          }
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F7FA') // 浅灰背景，突出白色卡片
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }

  @Builder LoadingView() {
    Column() { Text('加载中...').fontSize(rvp(14)).fontColor('#999').margin({ top: rvp(50) }) }.width('100%')
  }

  @Builder EmptyView(msg: string) {
    Column() { Text(msg).fontSize(rvp(14)).fontColor('#999').margin({ top: rvp(50) }) }.width('100%')
  }
}