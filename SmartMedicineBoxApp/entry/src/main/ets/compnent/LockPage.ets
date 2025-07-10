import { inputMethod } from '@kit.IMEKit'
import { Prompt, router } from '@kit.ArkUI'
import { command, http_result, lock, temp } from '../common/Inter'
import { commandUp, EnvGetApi, get } from '../common/Api'

PersistentStorage.persistProp("lock", "")

@Entry
@Component
export struct LockPage {
  @State codeList: string[] = ['', '', '', '', '', '']

  @State lock: string = ''

  @State time: number = -1
  
  @StorageLink("lock") lockStr: string = ""

  @State temp: temp = {
    Temp: "0℃",
    Humi: "0％",
    Light: "",
    Alarm: "",
    Mode: "",
    Fan: "",
    Lock: ""
  }

  @State isLock: boolean = false

  private textConfig: inputMethod.TextConfig = {
    inputAttribute: {
      textInputType: inputMethod.TextInputType.NUMBER,
      enterKeyType: inputMethod.EnterKeyType.GO
    }
  }

  @State flag: boolean = false

  private timerId: number = 0

  private inputController: inputMethod.InputMethodController = inputMethod.getController()

  async aboutToAppear(): Promise<void> {
    await this.get()

    setInterval(async () => {
      await this.get()
    }, 2000)
  }

  async get(){
    //获取安全锁，如果不为null，则显示已存在安全锁
    this.flag = this.lockStr === "" ? false : true

    console.log("LOCK", this.flag)

    let response = await EnvGetApi() as http_result
    console.log("Result", JSON.stringify(response))

    this.temp = response.shadow[0].reported.properties as temp

    console.log("LOCK", JSON.stringify(this.temp))

    this.isLock = this.temp.Lock === "ON" ? true : false
  }

  async attach(){
    await this.inputController.attach(true, this.textConfig)
  }

  detach(){
    this.inputController.off('insertText')
    this.inputController.off('deleteLeft')
  }

  listen(){
    this.inputController.on('insertText', (text: string) => {
      if (this.lock.length >= 6 || text == '' || isNaN(Number(text))) {
        //如果键盘输入的非数字或代码累积长度超过6
        return
      }

      this.time++
      if (this.time > 5) {
        this.time = 5
      }else if (this.time <= 5){
        this.codeList[this.time] = text
      }

      this.lock += text
    })

    this.inputController.on('deleteLeft', () => {
      if (this.time <= -1) {
        this.time = 0
      }else if (this.time > -1){
        this.codeList[this.time] = ''
      }
      this.time--

      this.lock = this.lock.substring(0, this.lock.length - 1)//左闭右开
    })
  }

  async commandUp(param: object){
    let command: command = {
      service_id: "Sensor",
      command_name: "Lock",
      paras: param
    }

    console.log("CommandUp", JSON.stringify(command))

    await commandUp(command)
  }

  build() {
    if (this.flag && this.isLock){
      Column({space: 25}){
        Text("设备已开锁").fontSize(30)
        Text("关锁").width('30%').height(50)
          .borderRadius(20)
          .textAlign(TextAlign.Center)
          .backgroundColor(Color.White)
          .fontSize(25)
          .onClick(async () => {
            let lock: lock = {lock: "OFF"}

            await this.commandUp(lock)
          })
      }
      .justifyContent(FlexAlign.Center)
      .backgroundImage($rawfile('back.jpg'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }else {
      Column({space: 40}){
        Column({space: 20}){
          Text(this.flag ? "已设置安全锁, 请开锁" : "未设置安全锁")
          Row({space: 10}){
            ForEach(this.codeList, (code: string, index: number) => {
              Text(code).width(50).height(50).border({width: 1, color: Color.Black, radius: 10})
                .textAlign(TextAlign.Center)
            })
          }
        }.width('100%').alignItems(HorizontalAlign.Center)
        .onClick(async () => {
          this.detach()
          //在可视范围内唤起
          await this.attach()

          this.listen()
        })

        Button('确认').backgroundColor(Color.White).width('90%')
          .fontColor(Color.Black)
          .height(50)
          .onClick(async () => {
            if (this.lock.length == 6) {
              console.log("Medicine", this.lock)

              //上传到iot中
              if (!this.flag) {
                this.lockStr = this.lock
              }else {
                console.log("LOCK", this.lock)
                console.log("LOCK", this.lockStr)
                if (this.lock === this.lockStr) {
                  console.log("CommandUp安全锁输入成功")
                  let lock: lock = {lock: "ON"}

                  await this.commandUp(lock)

                  await this.get()
                }else {
                  Prompt.showToast({
                    message: "安全锁输入错误",
                    duration: 3000
                  })
                }
              }

              this.lock = ""
              this.time = -1
              this.codeList = ['', '', '', '', '', '']
            }
          })
      }
      .padding({bottom: 70})
      .justifyContent(FlexAlign.Center)
      .backgroundImage($rawfile('back.jpg'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
  }
}