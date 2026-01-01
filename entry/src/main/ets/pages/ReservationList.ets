import router from '@ohos.router';
import prompt from '@ohos.prompt';
import {
  getReservationListApi,
  cancelReservationApi,
  ReservationItem
} from '../api/reservation';

// 简单的用户结构，只取 phone
interface UserInfo {
  phone?: string;
}

// 从 AppStorage 里拿当前用户手机号
function getCurrentUserPhone(): string {
  if (AppStorage.Has('userPhone')) {
    const v = AppStorage.Get('userPhone') as string;
    if (v && v.length > 0) {
      return v;
    }
  }

  if (AppStorage.Has('user')) {
    const usr = AppStorage.Get('user') as UserInfo;
    if (usr.phone && usr.phone.length > 0) {
      AppStorage.setOrCreate('userPhone', usr.phone);
      return usr.phone;
    }
  }

  return '';
}

@Entry
@Component
struct ReservationListPage {
  @State reservations: ReservationItem[] = [];
  @State loading: boolean = false;
  @StorageProp('topRectHeight') topRectHeight: number = 0;

  aboutToAppear() {
    this.loadList();
  }

  private async loadList() {
    const phone: string = getCurrentUserPhone();
    if (!phone) {
      this.reservations = [];
      return;
    }

    try {
      this.loading = true;
      const list: ReservationItem[] = await getReservationListApi(phone);
      this.reservations = list;
    } catch (err) {
      // 这里不用 any，直接当成 object 处理即可
      console.error('[ReservationList] loadList error:', err as object);
      prompt.showToast({ message: '获取预约列表失败' });
    } finally {
      this.loading = false;
    }
  }

  private async cancelReservation(item: ReservationItem) {
    const phone: string = getCurrentUserPhone();
    if (!phone) {
      prompt.showToast({ message: '用户信息异常，无法取消' });
      return;
    }

    try {
      await cancelReservationApi(item.id, phone);
      prompt.showToast({ message: '取消预约成功' });
      this.loadList();
    } catch (err) {
      console.error('[ReservationList] cancelReservation error:', err as object);
      prompt.showToast({ message: '取消预约失败' });
    }
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#333333')
          .onClick(() => router.back())
          .layoutWeight(1);

        Text('约看记录')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1);

        Blank().layoutWeight(1);
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: this.topRectHeight + 8,
        bottom: 8
      })
      .backgroundColor('#8FE1A2');

      // 列表区域
      Scroll() {
        Column() {
          if (this.loading) {
            Column() {
              Text('加载中...')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 80 });
            }
            .width('100%')
            .align(Alignment.Center);
          } else if (this.reservations.length === 0) {
            Column() {
              Text('暂无约看记录')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 80 });
            }
            .width('100%')
            .align(Alignment.Center);
          } else {
            ForEach(
              this.reservations,
              (item: ReservationItem, index: number) => {
                Column() {
                  Row() {
                    Column() {
                      Text(item.date)
                        .fontSize(16)
                        .fontColor('#333333');

                      if (item.name && item.name.length > 0) {
                        Text(item.name)
                          .fontSize(14)
                          .fontColor('#666666')
                          .margin({ top: 4 });
                      }
                    }
                    .layoutWeight(1);

                    Button('取消预约')
                      .fontSize(14)
                      .height(32)
                      .padding({ left: 12, right: 12 })
                      .borderRadius(16)
                      .backgroundColor('#FF6666')
                      .fontColor('#FFFFFF')
                      .onClick(() => {
                        this.cancelReservation(item);
                      });
                  }

                  if (item.comment && item.comment.length > 0) {
                    Text(item.comment)
                      .fontSize(13)
                      .fontColor('#999999')
                      .margin({ top: 6 })
                      .width('100%');
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .margin({ top: 8, left: 12, right: 12 });
              },
              // 唯一 key，避免 ArkUI 报警告
              (item: ReservationItem, index: number) => item.id.toString()
            );
          }

          Blank().height(24);
        }
      }
      .backgroundColor('#F7F7F7');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7');
  }
}
