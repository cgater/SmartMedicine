/**
 * tabs页面控制
 * **/

import { HomePage } from "./HomePage"
import { router } from '@kit.ArkUI'
import { TimerPage } from '../compnent/TimerPage'
import  {LogPage } from '../compnent/LogPage'
import { DataPage } from "../compnent/DataPage"
import { LockPage } from "../compnent/LockPage"
import { ControllerPage } from "../compnent/ControllerPage"

interface iconContent{
  text: string,
  image: string
}

export const icons: iconContent[] = [{text: '首页', image: 'house.svg'}, {text: '提醒', image: 'zixun.svg'}
  , {text: '传感控制', image: 'sun_max_.svg'}, {text: '安全锁', image: 'person_filled_viewfinder_gray.svg'}]

export const currentIcon: string[] = ['house_fill.svg', 'zixun_fill.svg', 'sun_max.svg', 'person_filled_viewfinder.svg']


@Entry
@Component
struct Index {
  @State message: string = 'Hello World'
  @State currentIndex: number = 0
  @State showTabBar: boolean = true

  @Builder
  tabBarContent(item: iconContent, index: number){
    Column({space: 5}){
      Image($rawfile(this.currentIndex == index ? currentIcon[index] : item.image)).width(30)
      Text(item.text)
    }
  }

  build() {
    Column() {
      Stack({alignContent: Alignment.Bottom}){
        Tabs({barPosition: BarPosition.End}){
          ForEach(icons,(icon: iconContent, index: number) => {
            TabContent(){
              if (index == 0) {
                HomePage()
              }else if (index == 1){
                TimerPage()
              }else if (index == 2){
                ControllerPage()
              }else {
                LockPage()
              }
            }.tabBar(this.tabBarContent(icon, index))
          })
        }.onChange(index => {
          this.currentIndex = index
        })
      }
    }
    .backgroundImage($rawfile('back.jpg'))
    .backgroundImageSize({width: '100%', height: '100%'})
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .height('100%')
    .backgroundColor(Color.White)
  }
}