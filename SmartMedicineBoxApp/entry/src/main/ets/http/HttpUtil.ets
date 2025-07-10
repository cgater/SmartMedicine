// import http from '@ohos.net.http';
//
// /**
//  * 提供HTTP请求工具方法的类。
//  */
// export class HttpUtil {
//   /**
//    * 设置HTTP请求的选项。
//    *
//    * @param method 请求类型，'get' 或 'post'。
//    * @param params 请求的参数，对于GET请求，参数会附加到URL上，对于POST请求，参数包含在请求体中。
//    * @returns 返回配置的HTTP请求选项对象。
//    */
//   private setHttpRequestOptions(method: string, params: any) {
//     return {
//       method: method == 'get' ? http.RequestMethod.GET : http.RequestMethod.POST,
//       header: {
//         'Content-Type': 'application/json',
//         'X-Auth-Token': globalThis.token,
//       },
//       extraData: params,
//       expectDataType: http.HttpDataType.STRING, // 指定返回数据的类型为字符串。
//     }
//   }
//
//   /**
//    * 发起GET请求。
//    *
//    * @param url 接口地址。
//    * @param fn 请求完成后的回调函数，接收从API返回的数据作为参数。
//    */
//   get(url: string, fn: Function) {
//     let httpRequest = http.createHttp();
//     // 发起GET请求，并设置请求选项。
//     httpRequest.request(url, this.setHttpRequestOptions('get', null), (err, data) => {
//       if (!err) {
//         // 从API获取数据，解析结果，并通过回调函数返回。
//         let result = JSON.parse(`${data.result}`)
//         fn(result)
//         // 请求完成后销毁HTTP请求对象。
//         httpRequest.destroy();
//       } else {
//         // 请求出错，打印错误信息，并销毁HTTP请求对象。
//         console.info('error:' + JSON.stringify(err));
//         httpRequest.destroy();
//       }
//     });
//   }
// }