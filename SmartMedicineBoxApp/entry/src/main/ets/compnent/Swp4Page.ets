import { router } from '@kit.ArkUI';

@Entry
@Component
struct Swp4Page {
  @State message: string = 'Hello World';

  build() {
    Column({ space: 20 }) {

      //顶部标题区
      Row() {
        Image($rawfile('arrow_left.svg')).width(22)
          .onClick(() => {
            router.back()
          })
        Text('详情').fontSize(22).fontWeight(FontWeight.Bold)
        Text('')
      }.width('90%').justifyContent(FlexAlign.SpaceBetween)

      Image($rawfile('swp4.jpg')).width(340)
      Text('科室用药提醒：安全服药，健康守护\n' +
        '\n' +
        '认清药名，看清剂量： 每次服药前，请仔细核对药盒/药袋上的药名、剂量和服用方法。不同药物外观可能相似，切勿凭印象服用。如有疑问，随时询问医护人员。\n' +
        '\n' +
        '按时按次，规律服用： 严格按照医嘱的时间（如饭前、饭后、睡前）和次数服药。设定手机闹钟、使用分格药盒是避免遗忘或错服的好帮手。\n' +
        '\n' +
        '完整疗程，勿擅调整： 请服完医生开具的整个疗程药物，即使感觉好转，也切勿自行停药、减量或加量。这关乎治疗效果和预防复发。\n' +
        '\n' +
        '精准用药是康复的基石。让我们共同努力，守护您的用药安全！').margin({left:5,right:5}).fontSize(17)
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}