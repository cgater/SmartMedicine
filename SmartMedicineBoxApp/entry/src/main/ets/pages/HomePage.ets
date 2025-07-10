/**
 * 首页
 * **/

import { LengthMetrics, router } from '@kit.ArkUI';
import { get } from '../common/Api';
import { card, homeTimer, http_result, medicine, result, timer, userContent } from '../common/Inter';
import { ImgList } from '../common/list';
import { formatDateTime, getMinutesDifference, parseTimerStr } from '../common/utils';

@Entry
@Component
export struct HomePage {
  @State homeTimers: homeTimer[] = []

  @State timer: number = 1

  async aboutToAppear(): Promise<void> {
    this.timer = setInterval(async () => {
      await this.get()
    }, 3000)
  }

  // aboutToDisappear(): void {
  //   clearInterval(this.timer)
  // }
  //
  // onPageHide(): void {
  //   clearInterval(this.timer)
  // }

  async get(){
    //获取所有的定时，展示相差半小时的定时
    const result = await get("http://120.79.223.206:8080/med") as result

    const medicines: medicine[] = result.data as medicine[]

    const hometimers: homeTimer[] = []

    for (let medicinesElement of medicines) {
      console.log("Home", JSON.stringify(medicinesElement))

      let result = await get("http://120.79.223.206:8080/getTimer/" + medicinesElement.id) as result

      const timers: timer[] = result.data as timer[]

      for (let timersElement of timers) {
        console.log("Home", JSON.stringify(timersElement))

        if (timersElement.date == formatDateTime(new Date()).split(" ")[0]) {
          const date = parseTimerStr(timersElement.time)

          const minutes = getMinutesDifference(date)

          console.log("Home", JSON.stringify(minutes))

          if (minutes <= 30 && minutes >= 0) {
            const homeTimer: homeTimer = {
              notes: "",
              medicine: "",
              time: "",
              mark: 0
            }

            homeTimer.notes = timersElement.notes
            homeTimer.time = timersElement.date+ " " + timersElement.time
            homeTimer.medicine = medicinesElement.medicine
            homeTimer.mark = medicinesElement.mark

            hometimers.push(homeTimer)
          }
        }
      }
    }

    this.homeTimers = hometimers
  }

  build() {
    Column({space: 5}) {
      //上
      Row() {
        Column().width(20)
        Text('智能药盒监测系统')
          .fontSize(23)
          .padding({ bottom: 10 })
      }.height(36)
      .width('90%').justifyContent(FlexAlign.Center)

      //下
      Scroll() {
        Column({ space: 10 }) {
          //轮播图
          Swiper() {
            Image($rawfile('swp1.jpg'))
              .width('90%')
              .height('180').onClick(() => {
              router.pushUrl({
                url: 'compnent/Swp1Page',
                params: ImgList[4]
              })
            })
            Image($rawfile('swp2.jpg'))
              .width('90%')
              .height('180').onClick(() => {
              router.pushUrl({
                url: 'compnent/Swp2Page',
                params: ImgList[5]
              })
            })
            Image($rawfile('swp3.jpg'))
              .width('90%')
              .height('180').onClick(() => {
              router.pushUrl({
                url: 'compnent/Swp3Page',
                params: ImgList[6]
              })
            })
            Image($rawfile('swp4.jpg'))
              .width('90%')
              .height('180').onClick(() => {
              router.pushUrl({
                url: 'compnent/Swp4Page',
                params: ImgList[7]
              })
            })
          }
          .width('91%')
          .autoPlay(true)
          .displayArrow({
            showBackground: true,
            isSidebarMiddle: true,
            backgroundSize: 24,
            backgroundColor: Color.White,
            arrowSize: 18,
            arrowColor: Color.Blue
          }, false)
          .borderRadius(15)

          //滑动功能区
          Grid() {
            // GridItem() {
            //   Column({ space: 7 }) {
            //     Image($rawfile('sun_max.svg')).width(45)
            //     Text('传感器控制').fontColor(Color.Black)
            //   }
            //   .onClick(() => {
            //     clearInterval(this.timer)
            //     router.pushUrl({
            //       url: 'compnent/TempPage'
            //     })
            //   })
            // }.width(100)

            GridItem() {
              Column({ space: 7 }) {
                Image($rawfile('person_filled_viewfinder.svg')).width(45)
                Text('数据大屏').fontColor(Color.Black)
              }
              .onClick(() => {
                router.pushUrl({
                  url: 'compnent/DataPage'
                })
              })
            }.width(100)

            GridItem() {
              Column({ space: 7 }) {
                Image($rawfile('doc_plaintext.svg')).width(45)
                Text('并发症科普').fontColor(Color.Black)
              }
              .onClick(() => {
                router.pushUrl({
                  url: 'compnent/ComplicationPage'
                })
              })
            }.width(100)

            GridItem() {
              Column({ space: 7 }) {
                Image($rawfile('message_on_message.svg')).width(45)
                Text('AI解答').fontColor(Color.Black)
              }.onClick(() => {
                router.pushUrl({ url: 'compnent/AIPage' })
              })
            }.width(100)
          }
          .rowsTemplate('1fr')
          .columnsGap(33)
          .layoutDirection(GridDirection.Row)
          .scrollBar(BarState.Off)
          .height(80)

          if (this.homeTimers.length != 0){
            Column(){
              List({space: 15}){
                ForEach(this.homeTimers, (homeTimer: homeTimer) => {
                  ListItem(){
                    Row(){
                      //左侧，展示该定时的位置信息
                      Column({space: 15}){
                        Text(homeTimer.mark.toString()).fontSize(20)
                        Text(homeTimer.medicine).fontSize(20)
                      }.width('30%').padding(10).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                      .border({width: {right: 1}, color: Color.Black })

                      //右侧，展示定时信息
                      Column({space: 15}){
                        Text(homeTimer.time).fontSize(20).fontWeight(FontWeight.Bold)
                        Text(homeTimer.notes).fontSize(20)
                      }.width('70%').alignItems(HorizontalAlign.Center)
                    }.padding({top: 15, bottom: 15})
                    .width('100%')
                  }.width('100%').backgroundColor(Color.White).borderRadius(15)
                })
              }
            }.width('90%')
          }else {
            Text("暂无临近定时").fontSize(20).fontWeight(FontWeight.Bold)
              .margin({top: 40})
          }
        }.padding({ bottom: 90 })
      }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }.backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}