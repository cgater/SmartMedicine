import { router, SelectOptions } from '@kit.ArkUI';
import { ai } from '../common/Api';
import { Deepseek, Message, Response } from '../common/Inter';

PersistentStorage.persistProp("messageList", null)
PersistentStorage.persistProp("responseList", null)

@Entry
@Component
struct AIPage {
  @StorageLink("messageList") messageList: string[] = [] || undefined
  @StorageLink("responseList") responseList: string[] = [] || undefined
  @State currentContent: string = ''
  @State sendContent: string = ''
  @State flag: boolean = true
  controller: TextInputController = new TextInputController();

  aboutToAppear(): void {
    if (this.messageList == undefined) {
      this.messageList = []
    }
    if (this.responseList == undefined) {
      this.responseList = []
    }
  }

  build() {
    Column() {
      Stack({alignContent: Alignment.Bottom}) {
        Column({space: 10}) {
          Row() {
            Image($rawfile('arrow_left.svg')).width('10%')
              .onClick(() => {
                router.back()
              })
            Text("AI界面").fontSize(30)
            Column()
          }.width('100%').justifyContent(FlexAlign.SpaceBetween)

          //聊天内容
          List({space: 15}){
            ForEach(this.messageList, (message: string, index: number) => {
              ListItem(){
                Column(){
                  Text(message).backgroundColor(Color.White).fontSize(20)
                    .padding({left: 8, right: 8, top: 5, bottom: 5})
                    .borderRadius(5)
                }.width('100%').alignItems(HorizontalAlign.End)
              }.width('100%')

              ListItem(){
                if (this.responseList.length > index) {
                  Column(){
                    Text(this.responseList[index]).backgroundColor(Color.White).fontSize(20)
                      .padding({left: 8, right: 8, top: 5, bottom: 5})
                  }.width('100%').alignItems(HorizontalAlign.Start)
                }else {
                  Column(){
                    Image($rawfile('loading.gif')).height('100%')
                  }.width('100%').height('6%').alignItems(HorizontalAlign.Start)
                }
              }.width('100%')
            })
          }.width('100%').height('90%')
          .scrollBar(BarState.Off).padding({bottom: 30})
        }.height('100%')
        .width('90%').alignItems(HorizontalAlign.Center)

        Row({ space: 15 }) {
          Column() {
            TextInput({ placeholder: '请输入内容...', controller: this.controller, text: this.currentContent }).backgroundColor(Color.White)
              .width('70%')
              .onChange(value => {
                this.currentContent = value
              })
          }.backgroundColor(Color.White)

          Text('发送').width('20%')
            .height('70%').textAlign(TextAlign.Center).backgroundColor(this.flag && this.currentContent != '' ? '#fff6f6f6': Color.White)
            .onClick(async () => {
              if (this.flag && this.currentContent != '') {
                //在响应出来前都不能编辑
                this.flag = false
                this.messageList.push(this.currentContent)
                this.sendContent = this.currentContent
                console.log("AIAI点击发送")
                this.controller.stopEditing()
                console.log("AIAI停止编辑")
                this.currentContent = ''
                console.log("AIAI清楚文本")

                //ai接口
                console.log("AIAI发送ai请求")

                let response = await ai(this.sendContent) as Response

                console.log("AIAIresponse", JSON.stringify(response))

                if (response != null) {
                  this.responseList.push(response.choices[0].message.content)
                  this.flag = true
                }
              }
            })
        }.width('90%').height('8%')
        .justifyContent(FlexAlign.Center)
      }
    }.alignItems(HorizontalAlign.Center)
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}