/**
 * 定时提醒页
 * **/
import { router } from '@kit.ArkUI'
import { EnvGetApi, get, getToken } from '../common/Api'
import { medicine, result} from '../common/Inter'
import { customDialog, deleteDialog, medicineDialog } from '../views/CustomDialog'

PersistentStorage.persistProp("Medicine", [])

@Entry
@Component
export struct TimerPage {
  @State medicines: medicine[] = []
  @State currentMedicine: medicine = {mark: 0, usage: "", medicine: "", number: 0, timerid: 0, id: 0}
  medicineCustom: CustomDialogController = new CustomDialogController({
    builder: medicineDialog({medicine: this.currentMedicine})
  })
  @State timer: number = 1

  async aboutToAppear(): Promise<void> {
    await this.get()
    //调用获取药品接口
    this.timer = setInterval(async () => {
      await this.get()
    }, 3000)
  }

  async get(){
    const result = await get("http://120.79.223.206:8080/med") as result

    this.medicines = result.data as medicine[]
  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  onPageHide(): void {
    clearInterval(this.timer)
  }

  aboutToRecycle(): void {
    clearInterval(this.timer)
  }

  build() {
    Column({space: 20}){
      if (this.medicines.length != 0){
        Grid(){
          ForEach(this.medicines, (medicine: medicine, index: number) => {
            GridItem(){
              Column({space: 10}){
                Text(medicine.mark.toString()).fontSize(18).margin({left: 5})
                Text("用量: " + (medicine.usage == null ? "" : medicine.usage)).fontSize(18).margin({left: 15})
                  .height(40)
                Row(){
                  Text('药品: ').fontSize(18)
                  Text(medicine.medicine == null ? "" : medicine.medicine).fontSize(18).width('70%')
                    .maxLines(2).textOverflow({overflow: TextOverflow.Ellipsis})
                }.height(40).width('90%').padding({left: 10})
                Row(){
                  Text('修改').fontSize(15).fontColor(Color.Red)
                    .onClick(async () => {
                      this.currentMedicine = medicine
                      this.medicineCustom.open()
                    })
                }.width('90%').justifyContent(FlexAlign.End)
              }.justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
              .width('100%').height('100%')
            }.height(160).width(110)
            .borderRadius(20).backgroundColor(Color.White)
            .onClick(() => {
              router.pushUrl({
                url: "compnent/NewPage",
                params: medicine
              })
            })
          })
        }
        .width('90%')
        .columnsGap(10).rowsGap(10)
        .columnsTemplate('1fr 1fr')
      }
    }
    .padding({top: 15})
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}