// entry/src/main/ets/pages/MyRentList.ets
import router from '@ohos.router';
import prompt from '@ohos.prompt';
import { rvp } from '../common/utils/DeviceScreen';
import { RentContractItem, getMyActiveRentApi, applyQuitApi } from '../api/rent';

interface UserInfo {
  phone?: string;
  userId?: string;
}

function getCurrentUserPhone(): string {
  // ✅ 登录页写入的是 userPhone（你 LoginPhone.ets 里就是 AppStorage.set('userPhone', data.user.phone)）
  if (AppStorage.Has('userPhone')) {
    const p = AppStorage.Get('userPhone') as string
    if (p && p.length > 0) return p
  }

  // 兜底：从 user 里取 phone
  if (AppStorage.Has('user')) {
    const u = AppStorage.Get('user') as UserInfo
    if (u?.phone && u.phone.length > 0) {
      AppStorage.setOrCreate('userPhone', u.phone)
      return u.phone
    }
    if (u?.userId && u.userId.length > 0) return u.userId
  }

  if (AppStorage.Has('userId')) {
    const id = AppStorage.Get('userId') as string
    if (id && id.length > 0) return id
  }

  return ''
}

function safeStr(v: string | undefined | null, fallback: string = ''): string {
  return typeof v === 'string' ? v : fallback;
}

function hasText(v: string | undefined | null): boolean {
  return typeof v === 'string' && v.length > 0;
}

@Entry
@Component
struct MyRentList {
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
      const list: RentContractItem[] = await getMyActiveRentApi(this.userPhone);
      this.list = [...list];
    } catch (e) {
      this.list = [];
      prompt.showToast({ message: '加载失败' });
    } finally {
      this.loading = false;
    }
  }

  private async onQuit(item: RentContractItem) {
    try {
      await applyQuitApi(item.id, this.userPhone, '');
      prompt.showToast({ message: '已提交退租申请' });
      this.loadList();
    } catch (e) {
      prompt.showToast({ message: '操作失败' });
    }
  }

  @Builder RentCard(item: RentContractItem) {
    Row() {
      if (hasText(item.coverUrl)) {
        Image(safeStr(item.coverUrl))
          .width(rvp(80))
          .height(rvp(80))
          .borderRadius(rvp(6))
          .objectFit(ImageFit.Cover)
          .margin({ right: rvp(10) });
      } else {
        Column() { Text('无图').fontSize(rvp(12)).fontColor('#999').textAlign(TextAlign.Center) }
        .width(rvp(80))
        .height(rvp(80))
        .borderRadius(rvp(6))
        .backgroundColor('#F3F4F6')
        .justifyContent(FlexAlign.Center)
        .margin({ right: rvp(10) });
      }

      Column() {
        Text(safeStr(item.houseTitle, '房源名称'))
          .fontSize(rvp(15))
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: rvp(6) });

        Text(`房东：${safeStr(item.landlord_phone, '-')}`)
          .fontSize(rvp(12))
          .fontColor('#555555')
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

      Column() {
        Button('退租')
          .fontSize(rvp(12))
          .height(rvp(26))
          .width(rvp(56))
          .padding(0)
          .backgroundColor('#ff4b4b')
          .fontColor('#ffffff')
          .onClick(() => this.onQuit(item));
      }
      .width(rvp(60))
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
      Row() {
        Text('< 返回')
          .fontSize(rvp(16))
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1);
        Text('我租到的房')
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

      Column() {
        if (this.loading) {
          this.LoadingView()
        } else if ((this.list?.length ?? 0) === 0) {
          this.EmptyView('暂无租约')
        } else {
          List({ space: rvp(10), scroller: this.scroller }) {
            ForEach(this.list, (item: RentContractItem) => {
              ListItem() { this.RentCard(item) }
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
