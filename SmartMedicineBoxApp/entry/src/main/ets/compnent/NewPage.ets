import { Prompt, router } from '@kit.ArkUI'
import { del, EnvGetApi, get, getToken } from '../common/Api'
import { http_result, medicine, result, temp, tempe, timer } from '../common/Inter'
import { customDialog, deleteDialog, timerDialog } from '../views/CustomDialog'
import { faceDetector } from '@kit.CoreVisionKit'
import { formatDateTime, getMinutesDifference, parseTimerStr } from '../common/utils'

/**
 * 具体定时页面
 * **/

@Entry
@Component
struct HealthPage {
  //药盒标识
  @State medicine: medicine = router.getParams() as medicine

  @State timers: timer[] = []
  @State checkColor: string = '#ff6c7475'
  @State flags: boolean[] = []
  @State isDelete: boolean = false
  @State isAdd: boolean = false
  addCustom: CustomDialogController = new CustomDialogController({
    builder: timerDialog({isAdd: this.isAdd, medid: this.medicine.id, mark: this.medicine.mark})
  })
  @State isAll: boolean = false
  @State getTimer: number = 0
  @State getFlagTimer: number = 0
  @State isOut: boolean[] = []

  async aboutToAppear(): Promise<void> {
    await this.get()
    // //通过标识从数据库获取对应的定时
    this.getTimer = setInterval(async () => {
      await this.get()
    }, 3000)

    this.getFlagTimer = setInterval(() => {
      this.getFLags()
    }, 3000)
  }

  async get(){
    let result = await get("http://120.79.223.206:8080/getTimer/" + this.medicine.id) as result

    this.timers = result.data as timer[]

    const isOut: boolean[] = []

    for (let timersElement of this.timers) {
      if (timersElement.date === formatDateTime(new Date()).split(" ")[0]) {
        const date = parseTimerStr(timersElement.time)

        const minutes = getMinutesDifference(date)

        console.log("Detail", minutes)

        if (minutes < 0) {
          isOut.push(true)
        }else {
          isOut.push(false)
        }
      }else if (timersElement.date < formatDateTime(new Date()).split(" ")[0]){
        isOut.push(true)
      }else {
        isOut.push(false)
      }
    }

    this.isOut = isOut
  }

  getFLags(){
    this.flags = []

    for (let i = 0; i < this.timers.length; i++) {
      this.flags.push(false)
    }
  }

  @Builder
  MyMenu(){
    Menu() {
      MenuItem({ content: "删除" })
        .onClick(() => {
          this.isDelete = true
          clearInterval(this.getFlagTimer)
        })
      MenuItem({ content: "添加" })
        .onClick(async () => {
          this.addCustom.open()
        })
    }
  }

  build() {
    Column({ space: 20 }) {
      Row() {
        if (this.isDelete){
          Text(this.isAll ? '全不选' : '全选').fontSize(20)
            .width(60)
            .onClick(() => {
              clearInterval(this.getFlagTimer)
              this.isAll = !this.isAll
              for (let i = 0; i < this.flags.length; i++) {
                this.flags[i] = this.isAll
              }
            })
          Text('选择项目').fontSize(20)
          Text('取消').fontSize(20)
            .onClick(() => {
              this.isDelete = false
            })
        }else {
          Image($rawfile('arrow_left.svg')).width(20)
            .onClick(() => {
              router.back()
            })
          Column(){
            Text(this.medicine.mark.toString() + "-" + (this.medicine.medicine == null ? "" : this.medicine.medicine)).fontSize(25)
              .maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
          }.width('70%')
          Text('选择').fontSize(25)
            .onClick(() => {
              this.isDelete = false
            })
            .bindMenu(this.MyMenu)
        }
      }.width('95%').justifyContent(FlexAlign.SpaceAround)
      .height(50)

      Stack({ alignContent: Alignment.Bottom }) {
        List({space: 15}) {
          ForEach(this.timers, (time: timer, index: number) => {
            ListItem() {
              Stack({ alignContent: Alignment.TopEnd }) {
                Column({ space: 10 }) {
                  Text(time.date + " " + time.time).fontSize(25).fontWeight(FontWeight.Bold)
                  Text(time.notes).fontSize(20)
                }
                .width('100%')
                .backgroundColor(this.isOut[index] ? '#cccc' : Color.White)
                .borderRadius(15)
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)
                .padding({ top: 10, bottom: 10 })

                if (this.isDelete) {
                  Checkbox().shape(CheckBoxShape.ROUNDED_SQUARE).unselectedColor(this.checkColor)
                    .select(this.flags[index])
                    .margin({ right: 10, top: 7 })
                }
              }
            }.width('100%')
            .onClick(() => {
              if (this.isDelete) {
                this.flags[index] = !this.flags[index]
              }
            })
          })
        }.width('90%').height('100%')
        .scrollBar(BarState.Off)

        if (this.flags?.includes(true)) {
          Column() {
            Text('删除').fontSize(25)
          }
          .margin({bottom: 70})
          .height(50)
          .backgroundColor('#ffeeeeee')
          .borderRadius(15)
          .justifyContent(FlexAlign.Center)
          .width('90%')
          .onClick(async () =>{
            for (let i = 0; i < this.flags.length; i++) {
              if (this.flags[i]) {
                let id = this.timers[i].id

                //调用接口，通过id删除timer
                const result = await del("http://120.79.223.206:8080/delTimer/" + id) as result
              }
            }

            this.isDelete = false
            this.getFlagTimer = setInterval(() => {
              this.getFLags()
            }, 3000)
          })
        }
      }
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}