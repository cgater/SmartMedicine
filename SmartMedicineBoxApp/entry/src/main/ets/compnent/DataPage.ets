import { webview } from '@kit.ArkWeb'
import { window } from '@kit.ArkUI'
import { getCurrentLocation } from '../common/utils'

const context: Context = getContext(this)

@Entry
@Component
export struct DataPage {
  private controller: webview.WebviewController = new webview.WebviewController()

  aboutToAppear(): void {
    getCurrentLocation()

    try {
      window.getLastWindow(context).then((win) => {
        win.setPreferredOrientation(window.Orientation.LANDSCAPE)
      })
    }catch (err){
      console.error('设置横屏失败:', err)
    }
  }

  aboutToDisappear(): void {
    try {
      window.getLastWindow(context).then((win) => {
        win.setPreferredOrientation(window.Orientation.PORTRAIT)
      })
    }catch (err){
      console.error('恢复竖屏失败:', err)
    }
  }

  build() {
    Column(){
      Web({src: $rawfile('echarts/views/index.html'), controller: this.controller})
        .height('100%')
        .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}