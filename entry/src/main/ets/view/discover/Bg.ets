// entry/src/main/ets/view/discover/Bg.ets
import { rvp } from '../../common/utils/DeviceScreen'

@Component
export default struct Bg {
  @StorageProp('topRectHeight')
  topRectHeight: number = 0

  build() {
    Image($r('app.media.discover_bg'))
      .width('100%')
      .height(rvp(280) + this.topRectHeight)
      .objectFit(ImageFit.Fill)
  }
}