import { router } from '@kit.ArkUI'

@Component
export struct headerView1{
  @Prop title: string = ''

  build() {
    Row(){
      Image($rawfile('arrow_left.svg')).width(20)
        .onClick(() => {
          router.back()
        })
      Text(this.title).fontSize(20)
      Column(){}.width(10)
    }.justifyContent(FlexAlign.SpaceBetween).width('90%')
  }
}