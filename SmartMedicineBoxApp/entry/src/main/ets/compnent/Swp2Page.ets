import { router } from '@kit.ArkUI';

@Entry
@Component
struct Swp2Page {
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

      Image($rawfile('swp2.jpg')).width(340)
      Text('警惕“沉默杀手”：静脉血栓栓塞症（VTE）防治须知\n' +
        '\n' +
        '静脉血栓栓塞症（VTE），包括深静脉血栓（DVT）和肺栓塞（PE），可能悄然发生，后果严重。预防是关键，行动靠大家！\n' +
        '\n' +
        '高危人群请注意： 长期卧床、住院或手术后患者、久坐久站（如长途旅行、办公）、孕妇、服用雌激素、肿瘤患者、肥胖及有家族史者更需警惕。\n' +
        '\n' +
        '有效预防这样做：\n' +
        '\n' +
        '动起来！ 避免长时间静止。卧床或术后在医生指导下尽早活动肢体、翻身；坐长途车/飞机时，每小时起身走动几分钟，或活动脚踝（勾脚尖、绷脚背）。\n' +
        '\n' +
        '穿对袜： 必要时遵医嘱使用梯度压力弹力袜（抗栓袜）。\n')
        .margin({left:5,right:5}).fontSize(17)
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}