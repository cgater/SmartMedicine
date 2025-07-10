/**
 * 注册页
 * **/

import { router } from '@kit.ArkUI';
import { customDialog, existDialog } from '../views/CustomDialog';
import { user, userInfor } from '../common/Inter';
import { content } from '../common/list';

PersistentStorage.persistProp('userList', null)

@Entry
@Component
struct RegisterPage {
  @State message: string = 'Hello World';
  @State flag: boolean = false
  @State existFlag: boolean = false
  @StorageLink('userList') userInforPer: userInfor[] = []
  custom: CustomDialogController = new CustomDialogController({
    builder: customDialog({content: content[0]}),
  })
  custom2: CustomDialogController = new CustomDialogController({
    builder: existDialog({content: '该用户已存在'})
  })
  @State user: user = {
    userName: '',
    passwd: '',
    passwdAgain: ''
  }
  @State color: string = '#ff6c7475'
  @State placeColor: string[] = ['#ff6c7475', '#ff6c7475', '#ff6c7475']
  @State checkColor: string = '#ff6c7475'

  build() {
    Column({space: 30}){
      Column({space: 30}){
        Column({space: 20}){
          Row(){
            Image($rawfile('arrow_left.svg')).width(20)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/LoginPage'
                })
              })
          }.justifyContent(FlexAlign.Start).width('90%')
          Image($rawfile('addUser.svg')).width(50)
          Text('注册账号').fontWeight(FontWeight.Bold).fontSize(25)
          Text('填写以下信息，开启安全健康用药之旅').fontColor(Color.Grey)
        }
        Column({space: 15}){
          TextInput({placeholder: '用户名...'}).width('90%').height(50)
            .fontColor('#ff6c7475').placeholderColor(this.placeColor[0])
            .backgroundColor(Color.White)
            .onChange(value => {
              this.user.userName = value
              if (this.user.userName != '') {
                this.placeColor[0] = '#ff6c7475'
              }
            })
          TextInput({placeholder: '密码...'}).type(InputType.Password).width('90%').height(50)
            .fontColor('#ff6c7475').placeholderColor(this.placeColor[1])
            .backgroundColor(Color.White)
            .onChange(value => {
              this.user.passwd = value
              if (this.user.passwd != '') {
                this.placeColor[1] = '#ff6c7475'
              }
            })
          TextInput({placeholder: '再次输入密码...'}).type(InputType.Password).width('90%').height(50)
            .fontColor(this.color).placeholderColor(this.placeColor[2])
            .backgroundColor(Color.White)
            .onChange(value => {
              this.user.passwdAgain = value
              if (this.user.passwdAgain != this.user.passwd && this.user.passwdAgain != '') {
                this.color = '#ffea2525'
                this.placeColor[2] = '#ff6c7475'
              }else{
                this.color = '#ff6c7475'
              }
            })
        }
        Button('注册').fontColor(Color.White).fontSize(20).width('90%').height(50)
          .backgroundColor('#33B8FF').borderRadius(10)
          .onClick(() => {
            if (this.user.userName != '') {
              if (this.user.passwd != '' && this.user.passwdAgain != '') {
                if (this.color == '#ff6c7475') {
                  if (this.flag) {
                    if (this.userInforPer != null || this.userInforPer != undefined) {
                      for (let userInfor of this.userInforPer){
                        if (userInfor.userName == this.user.userName) {
                          this.existFlag = true
                          this.custom2.open()
                          router.pushUrl({
                            url: 'pages/LoginPage'
                          })
                        }
                      }
                      if (!this.existFlag) {
                        // this.custom1.open()
                        console.log(JSON.stringify(this.user))
                        AppStorage.setOrCreate('user', JSON.stringify(this.user))
                      }
                    }else {
                      // this.custom1.open()
                      console.log(JSON.stringify(this.user))
                      AppStorage.setOrCreate('user', JSON.stringify(this.user))
                    }
                  }else{
                    this.checkColor = '#ffea2525'
                  }
                }
              }else {
                this.placeColor[1] = '#ffea2525'
                this.placeColor[2] = '#ffea2525'
              }
            }else {
              this.placeColor[0] = '#ffea2525'
            }
          })
      }
      Row(){
        Row({space:2}){
          Checkbox().shape(CheckBoxShape.ROUNDED_SQUARE).unselectedColor(this.checkColor)
            .onChange(() => {
              this.flag = !this.flag
              this.checkColor = '#ff6c7475'
            })
          Text('注册即表示同意')
          Text('《用户隐私政策》').fontColor('#33B8FF')
            .onClick(() => {
              this.custom.open()
            })
        }
      }.width('90%').justifyContent(FlexAlign.Start)
    }
    .backgroundImageSize({width: '100%', height: '100%'})
    .backgroundImage($rawfile('back.jpg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .height('100%')
    .width('100%')
  }
}