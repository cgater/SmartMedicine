/**
 * 登录页
 * **/

import { router } from '@kit.ArkUI';
import { getToken } from '../common/Api';
import { user, userInfor } from '../common/Inter';
import { existDialog } from '../views/CustomDialog';

PersistentStorage.persistProp('userList', null)

@Entry
@Component
struct LoginPage {
  @State message: string = 'Hello World';
  @StorageLink('userList') userInforPer: userInfor[] = []
  @State flag: boolean = false
  @State bindVisible: boolean = false
  @State user: user = {
    userName: '',
    passwd: '',
    passwdAgain: ''
  }
  @State color: string[] = ['#ff6c7475', '#ff6c7475']
  custom?: CustomDialogController = new CustomDialogController({
    builder: existDialog({content: '该用户不存在'})
  })

  async aboutToAppear() {
    console.log('user' + JSON.stringify(this.userInforPer))
  }

  build() {
    Column({space: 35}){
      Column({space: 30}){
        Column({space: 20}){
          Image($rawfile('login.svg')).width(50)
          Text('智能药盒').fontWeight(FontWeight.Bold).fontSize(25)
          Text('您的智能健康服药小助手').fontColor(Color.Grey)
        }
        Column({space: 15}){
          TextInput({placeholder: '用户名'}).width('90%').height(55)
            .placeholderColor(this.color[0])
            .backgroundColor(Color.White).fontColor(Color.Grey)
            .onChange(value => {
              if (value != '') {
                this.color[0] = '#ff6c7475'
              }
              this.user.userName = value
            })
          TextInput({placeholder: '密码'}).type(InputType.Password).width('90%').height(55)
            .placeholderColor(this.color[1])
            .backgroundColor(Color.White).fontColor(Color.Grey)
            .onChange(value => {
              if (value != '') {
                this.color[1] = '#ff6c7475'
              }
              this.user.passwd = value
            })
        }
        Row(){
          Text('忘记密码')
            .onClick(() => {
              router.pushUrl({
                url: 'compnent/ForgotPage'
              })
            })
        }.justifyContent(FlexAlign.End).width('80%')
        Button('登录').fontColor(Color.White).fontSize(20).width('90%').height(60)
          .backgroundColor('#33B8FF').borderRadius(10)
          .onClick(() => {
            // if (this.user.userName != '' && this.user.passwd != '') {
            //   if (this.userInforPer != undefined || this.userInforPer != null) {
            //     for(let userInfor of this.userInforPer){
            //       if (userInfor.userName == this.user.userName) {
            //         this.flag = true
            //         if (userInfor.passwd == this.user.passwd) {
            //           AppStorage.setOrCreate('CurrentUser', userInfor)
            //           router.pushUrl({
            //             url: 'pages/Index'
            //           })
            //         }else {
            //           AlertDialog.show({
            //             message: '密码错误'
            //           })
            //         }
            //       }
            //     }
            //     if (!this.flag) {
            //       this.custom?.open()
            //     }
            //   }else {
            //     this.custom?.open()
            //   }
            // }else {
            //   this.color[0] = '#ffea2525'
            //   this.color[1] = '#ffea2525'
            // }
            router.pushUrl({url:'pages/Index'})
          })
      }
      Column({space: 15}){
        Row() {
          Divider().width('25%').border({ width: 0.05, color: Color.Black })
          Text('其他登录方式').fontSize(15)
          Divider().width('25%').border({ width: 0.05, color: Color.Black })
        }.width('85%').justifyContent(FlexAlign.SpaceBetween)
        Image($rawfile('huawei.png')).width('15%')
          .bindPopup(this.bindVisible, {
            message: '功能还未开发',
            placement: Placement.Top
          })
          .onClick(() => {
            this.bindVisible = !this.bindVisible
          })
      }
      Row(){
        Text('没有账户？').fontColor(Color.Grey)
        Text('注册').fontWeight(FontWeight.Bold)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/RegisterPage'
            })
          })
      }.width('40%').justifyContent(FlexAlign.SpaceBetween)
    }
    .padding({bottom: 40})
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({width: '100%', height: '100%'})
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}