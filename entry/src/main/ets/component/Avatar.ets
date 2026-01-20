// entry/src/main/ets/component/Avatar.ets
/**
 * 头像组件
 */
@Component
export struct Avatar {
  @Link src: string
  @Prop avatarSize: number = 20
  @Prop radius: number = 0

  build() {
    Image(this.src || $r('app.media.avatar_unlogin'))
      .width(this.avatarSize)
      .height(this.avatarSize)
      .borderRadius(this.radius)
      .objectFit(ImageFit.Fill)
  }
}