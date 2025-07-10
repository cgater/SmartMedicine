import { router } from '@kit.ArkUI';
import { showapi_sort_detail } from '../common/Api';
import { contentlist, detail, item } from '../common/Inter';

@Entry
@Component
struct ComlicationDetailPage {
  @State message: string = 'Hello World';
  // @StorageProp("tid") tid: string = ""
  @State tid: contentlist = router.getParams() as contentlist
  @State content: item[] = []

  async aboutToAppear(): Promise<void> {
    // this.tid = router.getParams() as string
    console.log("Detail", JSON.stringify(this.tid))
    let response = await showapi_sort_detail(this.tid.id) as detail

    console.log("Detail", JSON.stringify(response))

    this.content.push(response.showapi_res_body.item)
  }

  build() {
    Column({space: 20}){
      Row(){
        Image($rawfile('arrow_left.svg')).width(20)
          .onClick(() => {
            AppStorage.clear()
            router.back()
          })
      }.width('90%').justifyContent(FlexAlign.Start)
      Scroll(){
        if (this.content.length != 0){
          Column({space: 15}){
            Row(){
              Text(this.content[0].title).fontSize(20).fontWeight(FontWeight.Bold)
            }.width('100%').justifyContent(FlexAlign.Center)
            Row({space: 10}){
              Text(this.content[0].tname).fontSize(15)
              Text(this.content[0].media_name).fontSize(15)
            }.justifyContent(FlexAlign.Center).width('100%')
            Text(this.content[0].intro).fontSize(20).lineHeight(35)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .width('90%')
        }
      }
      .scrollBar(BarState.Off)
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}