/**
 *并发症科普页
 * **/
import { showapi_list, showapi_sort } from '../common/Api';
import { contentlist, list, sort, sortKnowledge } from '../common/Inter';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct ComplicationPage {
  @State message: string = 'Hello World';
  @State sortList: list[] = []
  @State contentList: contentlist[] = []
  @State allContentList: contentlist[] = []
  @State currentIndex: number = 0
  @State currentContent: string = ''
  controller: TextInputController = new TextInputController()

  async aboutToAppear(): Promise<void> {
    console.log("Health", "发送医疗分类列表请求")
    let response = await showapi_list() as sort
    console.log("Health", JSON.stringify(response))

    this.sortList = response.showapi_res_body.list
    console.log("Health", JSON.stringify(this.sortList))

    //刚进来时展示出综合资讯内容
    let response1 = await showapi_sort("103", "", 1) as sortKnowledge
    this.allContentList = response1.showapi_res_body.pagebean.contentlist

    this.contentList = this.allContentList

    console.log("Health", JSON.stringify(this.contentList))
  }

  build() {
    Column({ space: 15 }) {
      Row(){
        Image($rawfile('arrow_left.svg')).width(20)
          .onClick(() => {
            router.pushUrl({
              url: "pages/Index"
            })
          })
        Text("医疗科普").fontSize(20)
        Column()
      }.justifyContent(FlexAlign.SpaceBetween).width('90%')
      //搜索框
      Row() {
        Image($rawfile('sousuo.svg')).width(30)
          .onClick(() => {
            this.controller.stopEditing()

            if (this.currentContent != "") {
              //根据关键词搜索，替换contentList
              const contentList: contentlist[] = []

              for (let allContentListElement of this.allContentList) {
                const spilts = allContentListElement.keywords.split("，")

                if (spilts.includes(this.currentContent)) {
                  contentList.push(allContentListElement)
                }
              }

              this.contentList = contentList
            }else {
              this.contentList = this.allContentList
            }
          })

        TextInput({ placeholder: '搜索内容', controller: this.controller, text: this.currentContent })
          .width('80%')
          .placeholderColor(Color.Grey)
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .onChange(value => {
            this.currentContent = value

            if (value == "") {
              this.contentList = this.allContentList
            }
          })

        Text('取消').fontColor('#33B8FF').fontSize(15)
          .onClick(() => {
            this.currentContent = ''

            this.contentList = this.allContentList
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .padding({ right: 10, left: 10 })
      .width('90%')

      if (this.sortList.length != 0) {
        Grid() {
          ForEach(this.sortList, (list: list, index: number) => {
            if (index != 1 && index != this.sortList.length - 2){
              GridItem() {
                Text(list.name)
                  .fontSize(20)
                  .textAlign(TextAlign.Center)
                  .fontColor(Color.Black)
                  .padding({
                    left: 10,
                    right: 10,
                    top: 8,
                    bottom: 8
                  })
              }
              .width(100)
              .borderRadius(15)
              .backgroundColor(index == this.currentIndex ? '#ffe9e9e9' : Color.White)
              .height(50)
              .onClick(async () => {
                this.currentIndex = index
                let response = await showapi_sort(list.id.toString(), "", 1) as sortKnowledge

                console.log("Sort", list.id + list.name)

                console.log("Sort", JSON.stringify(response))

                this.allContentList = response.showapi_res_body.pagebean.contentlist
                this.contentList = this.allContentList
              })
            }
          })
        }
        .rowsTemplate('1fr')
        .columnsGap(10)
        .width('100%')
        .height(50)
        .scrollBar(BarState.Off)

        List({ space: 20 }) {
          ForEach(this.contentList, (content: contentlist, index: number) => {
            ListItem() {
              Column({ space: 15 }) {
                Text(content.title).fontSize(20).fontWeight(FontWeight.Bold)
                Text(content.intro).fontSize(16)
                  .maxLines(4)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row() {
                  Text(content.ctime).fontSize(16)
                }.width('100%').justifyContent(FlexAlign.End)
              }
              .padding({
                left: 8,
                right: 8,
                top: 10,
                bottom: 10
              })
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(Color.White)
              .borderRadius(15)
            }
            .onClick(() => {
              // PersistentStorage.persistProp("tid", content.id)
              router.pushUrl({
                url: "compnent/ComlicationDetailPage",
                params: content
              })
            })
          })
        }.width('95%')
        .scrollBar(BarState.Off)
      }
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}