// entry/src/main/ets/view/home/Ad.ets
import { rvp } from '../../common/utils/DeviceScreen'
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'  // ⭐ 用来弹 toast 看点击有没有触发

@Component
export struct Ad {
  // 后端传进来的广告图片
  @Prop adPicture: string = ''

  // 整个广告卡片
  @Builder
  OwnerCard() {
    Column({ space: rvp(12) }) {
      // 顶部图片区域
      if (this.adPicture && this.adPicture.length > 0) {
        Image(this.adPicture)
          .width('100%')
          .height(rvp(90))
          .objectFit(ImageFit.Cover)
          .borderRadius(rvp(12))
      } else {
        Stack() {}
        .width('100%')
        .height(rvp(90))
        .backgroundColor('#F5F5F5')
        .borderRadius(rvp(12))
      }

      // 底部：文案 + 按钮
      Row() {
        Column() {
          Text('我要成为业主')
            .fontSize(rvp(14))
            .fontWeight(FontWeight.Medium)

          Text('一键发布房源')
            .fontSize(rvp(11))
            .fontColor('#888888')
            .margin({ top: rvp(4) })
        }
        .layoutWeight(1)

        Button('立即发布')
          .type(ButtonType.Capsule)
          .height(rvp(40))
          .fontSize(rvp(14))
          .padding({ left: rvp(12), right: rvp(12) })
          .backgroundColor('#00C368')
          .fontColor('#FFFFFF')
          .onClick(() => {

            try {
              router.pushUrl({
                // ⭐【关键】这里的 url 必须和 module.json5 里的页面路径一模一样
                // 例如 module.json5 里写的是 "src/main/ets/pages/publish/PublishHouse"
                // 那这里就要写 'pages/publish/PublishHouse'
                url: 'pages/PublishHouse'
              })
            } catch (err) {
              // ⭐ 如果路由失败，会在日志里看到具体原因
              console.error('[Ad] router.pushUrl error = ' + JSON.stringify(err))
              promptAction.showToast({ message: '跳转失败，请检查路由配置' })
            }
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .padding({
      left: rvp(12),
      right: rvp(12),
      top: rvp(12),
      bottom: rvp(12)
    })
    .backgroundColor('#FFFFFF')
    .borderRadius(rvp(12))
    .shadow({
      radius: rvp(8),
      color: '#19000000',
      offsetX: 0,
      offsetY: rvp(2)
    })
  }

  build() {
    Column() {
      this.OwnerCard()
    }
    .width('100%')
    .padding({
      left: rvp(16),
      right: rvp(16),
      top: rvp(12),
      bottom: rvp(12)
    })
  }
}
