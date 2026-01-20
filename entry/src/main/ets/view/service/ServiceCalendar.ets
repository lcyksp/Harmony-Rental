//entry/src/main/ets/view/service/ServiceCalendar.ets
import { rvp } from '../../common/utils/DeviceScreen'
import { Card } from '../../component/Card'
import { CalendarList } from '../../utils/Calendar'
import { ServiceActivityItem } from '../../viewmodel/ServiceModel'

@Component
export struct ServiceCalendar {
  @Prop serviceActivity: ServiceActivityItem
  @State calendarList: string[] = CalendarList

  /**
   * 标题
   **/
  @Builder
  title() {
    Row() {
      Text('服务日历')
        .fontSize(16)
        .fontColor(Color.Black)
        .fontWeight(700)
      Row({ space: rvp(10) }) {
        Text('全部服务')
          .fontSize(rvp(12))
          .fontColor(Color.Gray)
        Image($r('app.media.arrow_right'))
          .height(rvp(9))
          .fillColor($r('app.color.gray'))
      }
    }
    .width('100%')
    .padding(rvp(8))
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 日期
   */
  @Builder
  monthList() {
    Row() {
      ForEach(this.calendarList, (item: string, index: number) => {
        Text() {
          Span(item)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(700)
          Span('月').fontSize(12).fontColor($r('app.color.gray_second'))
        }
        .padding(rvp(6))
        .borderRadius(rvp(4))
        .backgroundColor(index == 2 ? '#CDFFD9' : '')
      })
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding(rvp(8))
  }

  /**
   * 内容
   * Builder 内不要写 let/const 语句，改成传参
   */
  @Builder
  content(act?: ServiceActivityItem) {
    Column({ space: rvp(8) }) {
      // 名称
      Text(act?.name ?? '')
        .fontSize(14)
        .fontWeight(700)

      Row({ space: rvp(8) }) {

        Image(act?.img ?? $r('app.media.arrow_right'))
          .width(rvp(100))
          .height(rvp(100))
          .borderRadius(rvp(4))

        Column({ space: rvp(8) }) {
          Text(act?.title ?? '')
            .fontSize(14)
            .fontWeight(500)

          Text(act?.subTitle ?? '')
            .fontSize(12)
            .fontWeight(500)
        }
      }

      Text('立即参与')
        .borderRadius(rvp(8))
        .fontSize(12)
        .fontWeight(500)
        .padding({ left: rvp(11), right: rvp(11), top: rvp(5), bottom: rvp(5) })
        .backgroundColor('#CDFFD9')
        .position({ right: rvp(16), bottom: rvp(8) })
    }
  }

  build() {
    Column() {
      Card({ cardPadding: 0 }) {
        this.title()
        this.monthList()
        // 在 build 里传入参数
        this.content(this.serviceActivity)
      }
    }
    .width('100%')
  }
}
