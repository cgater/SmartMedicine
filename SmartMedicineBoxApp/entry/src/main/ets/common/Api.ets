import { http } from '@kit.NetworkKit';
import { Deepseek } from './Inter';
import App from '@system.app';
import { uri } from '@kit.ArkTS';

let request = http.createHttp()

let endpoint = 'https://058d1cde62.st1.iotda-app.cn-east-3.myhuaweicloud.com'
let projectId = '8dde34d0ef7a48ecb5119b21594e4c69'
let productId = '67bd21b74c58cc795ad57bce'

// let urlHeader = endpoint + '/v5/iot/' + projectId + '/products/' + productId
let urlHeader =
  "https://18489969ec.st1.iotda-app.cn-north-4.myhuaweicloud.com/v5/iot/5f543e3a-8e5f-4cad-8dba-6c76b22f857d/devices/6852dccc32771f177b436a43_TEST1/shadow"

let token = ''

let apiKey = "sk-5afe21e360cf416285d134b96ef895db"
let aiurl = "https://api.deepseek.com/v1/chat/completions"

let list = "90-86"
let sort = "90-87"
let detail = "90-88"
let appKey = "c7f97Eb710934761945B5D1B4Ff5Ba56"
// "C8d89d1cE40849bFA0E64C5b64A8be3c"

let showapi_url = "https://route.showapi.com/"

export async function getToken() {
  let response = await request.request('https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens', {
    method: http.RequestMethod.POST,
    header: { "Content-Type": "application/json" },
    extraData: '{ \n' +
      '    "auth": { \n' +
      '        "identity": { \n' +
      '            "methods": [ \n' +
      '                "password" \n' +
      '            ], \n' +
      '            "password": { \n' +
      '                "user": { \n' +
      '                    "name": "cagter", \n' +
      '                    "password": "tqf198224", \n' +
      '                    "domain": { \n' +
      '                        "name": "lgy_openharmony" \n' +
      '                    } \n' +
      '                } \n' +
      '            } \n' +
      '        }, \n' +
      '        "scope": { \n' +
      '            "project": { \n' +
      '                "name": "af-north-1" \n' +
      '            } \n' +
      '        } \n' +
      '    } \n' +
      '}'
  })

  token = response.header['x-subject-token']
}

let url =
  "https://18489969ec.st1.iotda-app.cn-north-4.myhuaweicloud.com/v5/iot/cf9edf6334604519adf4b49f045f9371/devices/6856868c32771f177b445b37_Medicine_box/shadow"

export async function EnvGetApi() {
  await getToken()
  let response = await request.request(url, {
    method: http.RequestMethod.GET,
    header: { "Content-Type": "application/json", "X-Auth-Token": token }
  })
  return JSON.parse(response.result.toString())
}

let messageUrl = "https://18489969ec.st1.iotda-app.cn-north-4.myhuaweicloud.com:443/v5/iot/fa9655a9d1e641e58f689999715e4f62/devices/6856868c32771f177b445b37_Medicine_box/messages"

export async function messageUp(param: object){
  await getToken()
  let response = await request.request(messageUrl, {
    method: http.RequestMethod.POST,
    header: { "Content-Type": "application/json", "X-Auth-Token": token },
    extraData: {
      "message": param
    }
  })

  console.log("Message", response.result.toString())

  return JSON.parse(response.result.toString())
}

export async function ai(content: string) {
  let response = await request.request(aiurl, {
    method: http.RequestMethod.POST,
    header: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`
    },
    extraData: {
      "model": "deepseek-chat",
      "max_tokens": 1000,
      "messages": [
        { "role": "system", "content": `You are a helpful assistant.` },
        { "role": "user", "content": content }
      ],
      "temperature": 0.7
    }
  })

  return JSON.parse(response.result.toString())
}

//医疗列表
export async function showapi_list() {
  let response = await request.request(showapi_url + list + "?appKey=" + appKey, {
    method: http.RequestMethod.POST,
    header: {
      "Content-Type": "application/x-www-form-urlencoded"
    }
  })

  console.log("Health", response)

  return JSON.parse(response.result.toString())
}

export async function showapi_sort(id: string, key: string, page: number) {
  let response =
    await request.request(showapi_url + sort + "?appKey=" + appKey + "&key=" + key + "&page=" + page + "&tid=" + id, {
      method: http.RequestMethod.POST,
      header: {
        "Content-Type": "application/x-www-form-urlencoded",
      }
    })

  console.log("Sort", response)

  return JSON.parse(response.result.toString())
}

export async function showapi_sort_detail(id: string) {
  let response = await request.request(showapi_url + detail + "?appKey=" + appKey, {
    method: http.RequestMethod.POST,
    header: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    extraData: "id=" + id
  })

  console.log("Detail", JSON.stringify(response))

  return JSON.parse(response.result.toString())
}

export async function get(url: string){
  let response = await request.request(url,{
    method: http.RequestMethod.GET
  })

  console.log("Medicine", JSON.stringify(response.result))

  return JSON.parse(response.result.toString())
}

export async function update(url: string, param: object){
  let response = await request.request(url,{
    method: http.RequestMethod.POST,
    header: {
      "Content-Type": "application/json",
    },
    extraData: param
  })

  return JSON.parse(response.result.toString())
}

export async function del(url: string){
  let response = await request.request(url, {
    method: http.RequestMethod.DELETE
  })

  return JSON.parse(response.result.toString())
}

let commandUrl = "https://18489969ec.st1.iotda-app.cn-north-4.myhuaweicloud.com:443/v5/iot/fa9655a9d1e641e58f689999715e4f62/devices/6856868c32771f177b445b37_Medicine_box/commands"

export async function commandUp(param: object){
  await getToken()
  let response = await request.request(commandUrl, {
    method: http.RequestMethod.POST,
    header: { "Content-Type": "application/json", "X-Auth-Token": token },
    extraData: param
  })

  console.log("CommandUp", JSON.stringify(response))

  return JSON.parse(response.result.toString())
}