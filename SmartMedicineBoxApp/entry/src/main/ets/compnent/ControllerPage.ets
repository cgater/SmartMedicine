import { router } from '@kit.ArkUI'
import { commandUp, EnvGetApi, getToken, messageUp } from '../common/Api'
import { alarm, cold, command, Fan, http_result, light, mode, temp, tempe } from '../common/Inter'
import { tempOn } from '../common/list'

@Entry
@Component
export struct ControllerPage {
  @State temp: temp = {
    Temp: "0℃",
    Humi: "0％",
    Light: "",
    Alarm: "",
    Mode: "",
    Fan: "",
    Lock: ""
  }

  @State isMode: boolean = this.temp.Mode === "ON" ? true : false

  @State flagImg: boolean[] = [false, false, false]

  private timerId: number = 0

  async aboutToAppear(): Promise<void> {
    // 立即获取一次数据
    await this.get()

    // 设置定时器，每秒获取一次
    this.timerId = setInterval(async () => {
      await this.get()
    }, 4000)
  }

  aboutToDisappear(): void {
    // 清除定时器
    if (this.timerId) {
      clearInterval(this.timerId)
      this.timerId = 0
    }
  }

  async get(){
    let response = await EnvGetApi() as http_result
    console.log("Result", JSON.stringify(response))

    this.temp = response.shadow[0].reported.properties as temp

    console.log("ShowApi", JSON.stringify(this.temp))

    this.isMode = this.temp.Mode === "ON" ? true : false

    this.flagImg[0] = this.temp.Light === "ON" ? true : false
    this.flagImg[1] = this.temp.Alarm === "ON" ? true : false
    this.flagImg[2] = this.temp.Fan === "ON" ? true : false
  }

  async commandUp(param: object, command_name: string){
    let command: command = {
      service_id: "Sensor",
      command_name: command_name,
      paras: param
    }

    console.log("CommandUp", JSON.stringify(command))

    await commandUp(command)
  }

  build() {
    Column({space: 25}){
      Row(){
        Text(this.isMode ? "自动" : "手动").fontWeight(FontWeight.Bold)
          .fontSize(25)
          .onClick(async () => {
            this.isMode = !this.isMode
            let mode: mode = {mode: this.isMode ? "ON" : "OFF"}

            await this.commandUp(mode, "Mode")
          })
      }.width('90%').justifyContent(FlexAlign.End)

      Row(){
        Row({space: 15}){
          Row(){
            Text("温度").fontSize(20)
            Text(this.temp.Temp).fontSize(25).fontWeight(FontWeight.Bolder)
          }.width('90%').justifyContent(FlexAlign.SpaceAround)
        }.width('47%').backgroundColor(Color.White).borderRadius(15)
        .shadow({
          radius: 8,
          color: Color.Gray,
          offsetX: 2,
          offsetY: 2
        })
        .height(65)

        Row(){
          Row(){
            Text("湿度").fontSize(20)
            Text(this.temp.Humi).fontSize(25).fontWeight(FontWeight.Bolder)
          }.width('90%').justifyContent(FlexAlign.SpaceAround)
        }.width('47%')
        .backgroundColor(Color.White).borderRadius(15)
        .shadow({
          radius: 8,
          color: Color.Gray,
          offsetX: 2,
          offsetY: 2
        })
        .height(65)
      }.width('95%').justifyContent(FlexAlign.SpaceAround)

      Row(){
        Row({space: 15}){
          Row(){
            Text("LED").fontSize(20)
            Image($rawfile(this.flagImg[0] ? tempOn[0].on : tempOn[0].off)).width(25)
          }.width('90%').justifyContent(FlexAlign.SpaceAround)
        }.width('47%').backgroundColor(Color.White).borderRadius(15)
        .shadow({
          radius: 8,
          color: Color.Gray,
          offsetX: 2,
          offsetY: 2
        })
        .onClick(async () => {
          if (this.temp.Mode === "OFF") {
            this.flagImg[0] = !this.flagImg[0]
            //发送命令给硬件
            let light: light = {light: this.flagImg[0] ? "ON" : "OFF"}

            await this.commandUp(light, "Light")
          }else {
            AlertDialog.show({
              message: "该模式为自动模式，不允许修改"
            })
          }
        })
        .height(60)

        Row(){
          Row(){
            Text("蜂鸣器").fontSize(20)
            Image($rawfile(this.flagImg[1] ? tempOn[1].on : tempOn[1].off)).width(25)
          }.width('90%').justifyContent(FlexAlign.SpaceAround)
        }.width('47%')
        .backgroundColor(Color.White).borderRadius(15)
        .shadow({
          radius: 8,
          color: Color.Gray,
          offsetX: 2,
          offsetY: 2
        })
        .onClick(async () => {
          if (this.temp.Mode === "OFF"){
            this.flagImg[1] = !this.flagImg[1]
            //发送命令给硬件
            let alarm: alarm = {
              alarm: this.flagImg[1] ? "ON" : "OFF"
            }
            await this.commandUp(alarm, "Alarm")
          }else {
            AlertDialog.show({
              message: "该模式为自动模式，不允许修改"
            })
          }
        })
        .height(60)
      }.width('95%').justifyContent(FlexAlign.SpaceAround)

      Row(){
        Row(){
          Row(){
            Text("风扇").fontSize(20)
            Image($rawfile(this.flagImg[2] ? tempOn[2].on : tempOn[2].off)).width(25)
          }.width('90%').justifyContent(FlexAlign.SpaceAround)
        }.width('47%')
        .backgroundColor(Color.White).borderRadius(15)
        .shadow({
          radius: 8,
          color: Color.Gray,
          offsetX: 2,
          offsetY: 2
        })
        .onClick(async () => {
          if (this.temp.Mode === "OFF"){
            this.flagImg[2] = !this.flagImg[2]
            //发送命令给硬件
            let fan: Fan = {
              fan: this.flagImg[2] ? "ON" : "OFF"
            }
            await this.commandUp(fan, "Fan")
          }else {
            AlertDialog.show({
              message: "该模式为自动模式，不允许修改"
            })
          }
        })
        .height(60)
      }.width('100%').justifyContent(FlexAlign.Center)
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}