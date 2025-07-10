import { router } from '@kit.ArkUI';

@Entry
@Component
struct Swp1Page {
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

      Image($rawfile('swp1.jpg')).width(340)
      Text('你真的会“按时”吃降糖药吗？别让血糖悄悄失控！\n' +
        '\n' +
        '亲爱的糖友，“按时吃药”四个字看似简单，却是稳住血糖的生命线！随意停药、漏服或自行调整剂量，会让血糖像过' +
        '山车一样起伏，加速伤害血管和神经，大大增加心梗、中风、肾病、失明等严重并发症的风险！ 药物需要在体内保' +
        '持稳定的浓度才能有效工作，一次“忘记”就可能让几天的努力白费。请把服药当作每日最重要的“健康约会”——设定' +
        '手机闹钟、使用分装药盒、将药放在显眼处（如餐桌），用工具战胜遗忘。万一漏服，切勿凭感觉加倍补吃，应立即咨' +
        '询医生或药师。记住：每一次按时服药，都是在为未来的健康“储蓄”。坚持下去，稳稳的血糖和更自由的生活，就是对' +
        '你自律最好的回报！').margin({left:5,right:5}).fontSize(17)
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}