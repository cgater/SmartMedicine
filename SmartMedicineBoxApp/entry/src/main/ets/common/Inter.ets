export interface user{
  userName: string,
  passwd: string,
  passwdAgain: string
}

export interface userInfor{
  userName: string,
  passwd: string,
  name: string,
  gender: string,
  birth: string,
  school: string,
  id: string
}

export interface card{
  userName: string
  name: string,
  content: string,
  image: string,
  type: string[],
  sayTime: number,
  loveTime: number,
  sayContent: userContent[]
}

export interface userContent{
  name: string,
  content: string
}

export interface address{
  userName: string,
  contactPerson: string,
  phone: number,
  nowAddress: string
}

export interface repairCard{
  userName: string,
  content: string,
  image: string
}

export interface report{
  cardIndex: number,
  content: string[]
}

export interface Img{
  url:string,
  msg:string
}

export interface chatContents{
  index: number,
  contents: string[]
}

export interface fan{
  fanStatus: boolean,
  fanOnLine: boolean,
  fanLplv: string
}
export interface http_result{
  device_id: string,
  shadow: shadows[]
}

export interface shadows{
  service_id: string,
  desired: desireds,
  reported: reporteds,
  version: number
}

export interface desireds{
  properties: string,
  event_time: string
}

export interface reporteds{
  properties: object,
  event_time: string
}

export interface tempe{
  temp: string
}

export interface Deepseek{
  model: string,
  messages: Message[],
  temperature: number,
  max_tokens: number
}

export interface Message{
  role: string,
  content: string
}

export interface Response{
  id: string,
  object: string,
  created: number,
  model: string,
  choices: Choice[]
}

export interface Choice{
  index: number,
  message: Message,
  finish_reason: string
}

//医疗分类
export interface sort{
  showapi_res_code: number,
  showapi_res_error: string,
  showapi_res_id: string,
  showapi_res_body: showapi_res_body
}

export interface showapi_res_body{
  list: list[],
  ret_code: number
}

export interface list{
  id: number,
  name: string
}

//医疗某分类的知识科普
export interface sortKnowledge{
  showapi_res_error: string,
  showapi_fee_num: number,
  showapi_res_code: number,
  showapi_res_id: string,
  showapi_res_body: showapi_sort_body
}

export interface showapi_sort_body{
  ret_code: string,
  remark: string,
  pagebean: pagebean
}

export interface pagebean{
  allPages: number,
  contentlist: contentlist[],
  currentPage: number,
  allNum: number,
  maxResult: number
}

export interface contentlist{
  id: string,
  title: string,
  keywords: string,
  tname: string,
  media_name: string,
  tid: string,
  wapurl: string,
  ctime: string,
  intro: string,
  url: string
}


//医疗某分类某知识科普详情
export interface detail{
  showapi_res_error: string,
  showapi_fee_num: number,
  showapi_res_code: number,
  showapi_res_id: string,
  showapi_res_body: showapi_res_body_detail
}

export interface showapi_res_body_detail{
  ret_code: string,
  remark: string,
  item: item
}

export interface item{
  id: string,
  content: string,
  title: string,
  keywords: string,
  stitle: string,
  img: string,
  tname: string,
  media_name: string,
  tid: string,
  ctime: string,
  intro: string
}

export interface temp{
  Temp: string,
  Humi: string,
  Light: string,
  Alarm: string,
  Mode: string,
  Fan: string,
  Lock: string
}

export interface  tempImg{
  on: string,
  off: string
}

export interface timer{
  id: number,
  time: string,
  date: string,
  notes: string
  medid: number
}

export interface medicine{
  id: number,
  mark: number,
  usage: string,
  medicine: string,
  number: number,
  timerid: number
}

export interface cold{
  isCold: boolean
}

export interface result{
  code: number,
  msg: string,
  data: object
}

export interface homeTimer{
  time: string,
  mark: number,
  medicine: string,
  notes: string
}

export interface command{
  service_id: string,
  command_name: string,
  paras: object
}

export interface light{
  light: string
}

export interface alarm{
  alarm: string
}

export interface mode{
  mode: string
}

export interface Fan{
  fan: string
}

export interface time{
  time: number
}

export interface lock{
  lock: string
}