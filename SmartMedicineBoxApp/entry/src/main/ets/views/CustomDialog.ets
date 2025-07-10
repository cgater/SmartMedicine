import { Prompt, router } from '@kit.ArkUI'
import { card, command, medicine, result, temp, time, timer, userContent, userInfor } from '../common/Inter'
import { timeList } from '../common/list'
import { faceDetector } from '@kit.CoreVisionKit'
import { formatDateTime } from '../common/utils'
import { commandUp, update } from '../common/Api'

@CustomDialog
export struct customDialog{
  custom?: CustomDialogController
  @Prop content: string

  build() {
    Column(){
      Text('用户隐私协议').fontWeight(FontWeight.Bold).fontSize(20).margin({top: 20})
      Scroll(){
        Text(this.content).lineHeight(30)
      }.width('90%').padding({right: 8}).margin({bottom: 35, top: 10})
    }
    .justifyContent(FlexAlign.Center).padding(10).height('70%').padding({bottom: 20})
  }
}

@CustomDialog
export struct deleteDialog{
  custom?: CustomDialogController
  @Link numbers: timer[]
  index: number = AppStorage.get("index") as number

  build() {
    Column({space: 20}){
      if (this.numbers.length != 0 ){
        Row(){
          Text("是否要删除").fontSize(20)
          // Text(this.numbers[this.index].name).fontColor(Color.Red).fontSize(25)
        }
      }

      Row(){
        Button("取消")
          .onClick(() => {
            this.custom?.close()
          })
        Button("确认")
          .onClick(() => {
            this.numbers.splice(this.index, 1)
            this.custom?.close()
          })
      }.width('80%').justifyContent(FlexAlign.SpaceAround)
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center).padding(10).height('30%').padding({bottom: 20})
  }
}

@CustomDialog
export struct timerDialog{
  custom?: CustomDialogController
  @Link isAdd: boolean
  @Prop medid: number
  @Prop mark: number
  @State content: timer = {
    id: 0,
    time: "",
    date: "",
    notes: "",
    medid: 0
  }
  @State selectTime: Date = new Date()

  aboutToAppear(): void {
    const spilts = formatDateTime(this.selectTime)
    this.content.time = spilts[1]
    this.content.date = spilts[0]
  }

  appendTime(): number{
    let splits = this.content.time.split(":").map(Number)

    return this.mark * 10000 + splits[0] * 100 + splits[1]
  }

  build() {
    Column({space: 15}){
      Row({space: 15}){
        Text('备注')
        TextInput({placeholder: "请输入该定时的用途"})
          .width('80%')
          .onChange((value) => {
            this.content.notes = value
          })
      }.width('80%')
      Row({space: 15}){
        Text('时间')
        TextInput({placeholder: "请选择时间", text: formatDateTime(this.selectTime)})
          .type(InputType.Number)
          .width('80%')
            // .backgroundColor(Color.White)
          .onClick(() => {
            this.getUIContext().showDatePickerDialog({
              start: new Date(),
              end: new Date(2100,11,31),
              selected: this.selectTime,
              lunar: false,
              onDateAccept: (date: Date) => {
                this.getUIContext().showTimePickerDialog({
                  format: TimePickerFormat.HOUR_MINUTE_SECOND,
                  useMilitaryTime: false,
                  selected: this.selectTime,
                  onAccept: (time: TimePickerResult) => {
                    this.selectTime = new Date(
                      date.getFullYear(),
                      date.getMonth(),
                      date.getDate(),
                      time.hour,
                      time.minute
                    )
                    const spilts = formatDateTime(this.selectTime).split(" ")
                    this.content.time = spilts[1]
                    this.content.date = spilts[0]
                  }
                })
              }
            })
          })
      }.width('80%')
      Row(){
        Button("取消")
          .onClick(() => {
            this.custom?.close()
          })
        Button("确认")
          .onClick(async () => {
            this.content.medid = this.medid
            //调用添加定时的接口
            if (this.content.time != "0" && this.content.date != "2") {
              let response = await update("http://120.79.223.206:8080/addTimer", this.content) as result

              if (response.code == 200) {
                //如果添加成功则调用一下方法
                this.isAdd = true

                //暂时将最新的时间数据上传给iot，日期默认为今天
                let time: time = {time: this.appendTime()}

                let command: command = {
                  service_id: "Sensor",
                  command_name: "Time",
                  paras: time
                }

                console.log("CommandUp", JSON.stringify(command))

                await commandUp(command)

                Prompt.showToast({
                  message: "该功能为测试阶段，只能定时最新的时间且日期默认为今日",
                  duration: 5000
                })

                this.custom?.close()
              }
            }else {
              AlertDialog.show({
                message: "请重新选择日期"
              })
            }
          })
      }.width('80%').justifyContent(FlexAlign.SpaceAround)
      .margin({top: 15})
    }
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center).padding(10).height('40%').padding({bottom: 20})
  }
}

@CustomDialog
export struct medicineDialog{
  custom?: CustomDialogController
  @Prop medicine: medicine

  build() {
    Column({space: 15}){
      Row({space: 15}){
        Text('药品')
        TextInput({placeholder: "请输入该位置的药品名", text: this.medicine.medicine})
          .width('80%')
          .onChange((value) => {
            this.medicine.medicine = value
          })
      }.width('80%')
      Row({space: 15}){
        Text('用量')
        TextInput({placeholder: "请输入该药品的用量", text: this.medicine.usage})
          .width('80%')
          .onChange((value) => {
            this.medicine.usage = value
          })
      }.width('80%')
      Row(){
        Button("取消")
          .onClick(() => {
            this.custom?.close()
          })
        Button("确认")
          .onClick(async () => {
            //调用接口修改对应标志位的药品数据
            let result = await update("http://120.79.223.206:8080/updMed", this.medicine) as result

            console.log("MedicineAdd", JSON.stringify(result))

            if (result.code === 200) {
              this.custom?.close()
            }
          })
      }.width('80%').justifyContent(FlexAlign.SpaceAround)
      .margin({top: 15})
    }
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center).padding(10).height('40%').padding({bottom: 20})
  }
}

@CustomDialog
export struct existDialog{
  custom?: CustomDialogController
  @Prop content: string

  build() {
    Column(){
      Text(this.content).fontColor('#ffea2525')
    }.justifyContent(FlexAlign.Center).padding({top: 20, bottom: 20})
  }
}

