import { router } from '@kit.ArkUI';

@Entry
@Component
struct Swp3Page {
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

      Image($rawfile('swp3.jpg')).width(340)
      Text('口服降糖药健康用药指南\n' +
        '\n' +
        '亲爱的糖友，正确使用口服降糖药是有效控制血糖的关键。请您务必严格遵循医嘱，按时按量服用药物，' +
        '切勿自行增减剂量或突然停药，如遇漏服请及时咨询医生或药师。 请记住，药物需要配合健康的生活方式才能发挥' +
        '最佳效果，坚持合理饮食（控制主食与糖分）、规律运动、戒烟限酒至关重要。同时，您需要了解并警惕低血糖的' +
        '症状（如心慌、手抖、出汗、头晕、饥饿感），随身携带糖果或饼干以备急需。规律监测血糖（包括空腹和餐后）并' +
        '定期复诊（检查糖化血红蛋白等指标）必不可少，以便医生评估治疗效果和调整方案。最后，就诊时请务必告知医生您' +
        '正在使用的所有其他药物（包括慢性病药和保健品），以避免潜在的药物相互作用。规范用药、配合健康管理，助您稳' +
        '稳控糖，迈向更健康的生活！').margin({left:5,right:5}).fontSize(17)
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}