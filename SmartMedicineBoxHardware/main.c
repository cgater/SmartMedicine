// C语言原生头文件
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
// LiteOS相关头文件
#include "los_task.h"
#include "los_queue.h"
#include "los_mux.h"
// 系统头文件
#include "ohos_init.h"
#include "cmsis_os.h"
#include "config_network.h"
// 官方自带驱动头文件
#include "iot_i2c.h"
#include "iot_gpio.h"
#include "iot_adc.h"
#include "iot_pwm.h"
#include "iot_errno.h"
#include "iot_uart.h"
// 传感器读取数据头文件
#include "include/lcd.h"
#include "include/sensor.h"
#include "include/ds1302.h"
#include "hx711.h"
// 环形Buffer头文件
#include "fifo.h"
// 云服务所需头文件
#include "MQTTClient.h"
#include "cJSON.h"
#include "cmsis_os2.h"

#define PCA9548A_UART_ID  EUART0_M0 // IO扩展模块串口ID
#define Voice_UART_ID     EUART2_M1 // 语音模块串口ID

#define BEEP_PWM          EPWMDEV_PWM5_M0 // 蜂鸣器PWM
#define SG90_PWM          EPWMDEV_PWM6_M0 // SG90舵机PWM

#define Fan_Pin           GPIO0_PB6 // 风扇控制引脚
#define Light_Pin         GPIO0_PB7 // 紫光灯控制引脚

#define KEY_ADC_CHANNEL 7  // 按键对应的ADC通道

#define WIFI_SSID         "OnePlus13" // WIFI名字
#define WIFI_PASSWORD     "a12345678" // WIFI密码

#define Sensor_DataLength 10 // 传感器数据长度
#define Sensor_MsgSize    sizeof(e_iot_data) // 每条消息长度
#define STRING_MAXSIZE    128 // 

static struct tagFifo UART_FIFO = 
{
    .max = FIFO_MAX_UNIT,
    .read = 0,
    .write = 0,
};

static UINT32 Sensor_QueueID = 0; // 传感器数据传输消息队列ID
static UINT32 LCD_QueueID = 0; // LCD数据传输消息队列ID

static unsigned int Sensor_Count; //传感器定时触发

//------------------互斥锁-------------------//
static unsigned int Alarm_StatusMux;
static unsigned int Fan_StatusMux;
static unsigned int Light_StatusMux;
static unsigned int Time_StatusMux;
static unsigned int Mode_StatusMux;
static unsigned int Lock_StatusMux;
static unsigned int Flag_StatusMux;
static unsigned int Buzz_FlagMux;
static unsigned int Timed_StatusMux;
static unsigned int Manual_Alarm_Mux; // 手动警报状态互斥锁
//------------------互斥锁-------------------//

//------------------公共资源------------------//
static unsigned char Alarm_Status = 0; // 0:无报警 1:手不在药格 2:定时到/手拿开
static unsigned char Fan_Status = 0;
static unsigned char Light_Status = 0;
static unsigned char Mode_Status = 1;
static unsigned char Lock_Status = 0;
static unsigned char Flag_Status = 0;
static unsigned char Buzz_Flag = 0;
static unsigned int Timed = 0; // 11239 拆分 1-药盒 12-时 39-分  
static unsigned char Timed_flag = 0;
static unsigned char Manual_Alarm_Status = 0; // 手动警报状态
//------------------公共资源------------------//

//------------------云服务-------------------//
#define MQTT_DEVICES_PWD "3d7dea123d9a8c1c97ee14eacbfc8aa4c392fbd72221faa8abc2954a230e9a75"

#define HOST_ADDR "18489969ec.st1.iotda-device.cn-north-4.myhuaweicloud.com"
#define USERNAME "6856868c32771f177b445b37_Medicine_box"
#define DEVICE_ID "6856868c32771f177b445b37_Medicine_box_0_0_2025070713"

#define PUBLISH_TOPIC "$oc/devices/" USERNAME "/sys/properties/report"
#define SUBCRIB_TOPIC                                                          \
  "$oc/devices/" USERNAME "/sys/commands/#" /// request_id={request_id}"
#define RESPONSE_TOPIC                                                         \
  "$oc/devices/" USERNAME "/sys/commands/response" /// request_id={request_id}"

#define MAX_BUFFER_LENGTH 512
#define MAX_STRING_LENGTH 64

static unsigned char sendBuf[MAX_BUFFER_LENGTH];
static unsigned char readBuf[MAX_BUFFER_LENGTH];

Network network;
MQTTClient client;

static char mqtt_devid[64]=DEVICE_ID;
static char mqtt_username[64]=USERNAME;
static char mqtt_pwd[72]=MQTT_DEVICES_PWD;
static char mqtt_hostaddr[64]=HOST_ADDR;

static char publish_topic[128] = PUBLISH_TOPIC;
static char subcribe_topic[128] = SUBCRIB_TOPIC;
static char response_topic[128] = RESPONSE_TOPIC;

static unsigned int mqttConnectFlag = 0;

typedef struct
{
    double temp;
    double humi;
    unsigned char Time[3];
    unsigned char Alarm;
    unsigned char Light;
    unsigned char Fan;
    unsigned char Mode;
    unsigned char Lock;
    unsigned char Flag;
    unsigned int Timed;
} e_iot_data;
//------------------云服务-------------------//

//---------------云服务相关函数---------------//
void send_msg_to_mqtt(e_iot_data *iot_data) {
  int rc;
  MQTTMessage message;
  char payload[MAX_BUFFER_LENGTH] = {0};
  char str[MAX_STRING_LENGTH] = {0};

  if (mqttConnectFlag == 0) {
    printf("mqtt not connect\n");
    return;
  }
  
  cJSON *root = cJSON_CreateObject();
  if (root != NULL) {
    cJSON *serv_arr = cJSON_AddArrayToObject(root, "services");
    cJSON *arr_item = cJSON_CreateObject();
    cJSON_AddStringToObject(arr_item, "service_id", "Sensor");
    cJSON *pro_obj = cJSON_CreateObject();
    cJSON_AddItemToObject(arr_item, "properties", pro_obj);

    memset(str, 0, MAX_BUFFER_LENGTH);

    //温度数据
    sprintf(str,"%5.2f℃",iot_data->temp,str);
    cJSON_AddStringToObject(pro_obj,"Temp",str);

    //湿度数据
    sprintf(str,"%5.2f%%",iot_data->humi,str);
    cJSON_AddStringToObject(pro_obj,"Humi",str);

    //警报状态
    if(iot_data->Alarm > 0) 
    {
      cJSON_AddStringToObject(pro_obj,"Alarm","ON");
    } 
    else 
    {
      cJSON_AddStringToObject(pro_obj,"Alarm","OFF");
    }

    //风扇状态
    if(iot_data->Fan == 1) {
      cJSON_AddStringToObject(pro_obj,"Fan","ON");
    }
    else {
      cJSON_AddStringToObject(pro_obj,"Fan","OFF");
    }

    //紫光灯状态
    if(iot_data->Light == 1) {
      cJSON_AddStringToObject(pro_obj,"Light","ON");
    }
    else {
      cJSON_AddStringToObject(pro_obj,"Light","OFF");
    }

    //模式状态
    if(iot_data->Mode == 1) {
      cJSON_AddStringToObject(pro_obj,"Mode","ON");
    }
    else {
      cJSON_AddStringToObject(pro_obj,"Mode","OFF");
    }

    //锁状态
    if(iot_data->Lock == 1) {
      cJSON_AddStringToObject(pro_obj,"Lock","ON");
    }
    else {
      cJSON_AddStringToObject(pro_obj,"Lock","OFF");
    }

    cJSON_AddItemToArray(serv_arr, arr_item);

    char *palyload_str = cJSON_PrintUnformatted(root);
    strcpy(payload, palyload_str);

    cJSON_free(palyload_str);
    cJSON_Delete(root);
  }

  message.qos = 0;
  message.retained = 0;
  message.payload = payload;
  message.payloadlen = strlen(payload);

  sprintf(publish_topic,"$oc/devices/%s/sys/properties/report",mqtt_devid);
  if ((rc = MQTTPublish(&client, publish_topic, &message)) != 0) {
    printf("MQTT发布的返回代码:%d\n", rc);
    mqttConnectFlag = 0;
  }
}

void Set_Alarm_State(cJSON *root) {
    cJSON *para_obj = NULL;
    cJSON *status_obj = NULL;
    char *value = NULL;
    para_obj = cJSON_GetObjectItem(root, "paras");
    status_obj = cJSON_GetObjectItem(para_obj, "alarm");
    
    if (status_obj != NULL) {
      value = cJSON_GetStringValue(status_obj);
      LOS_MuxPend(Manual_Alarm_Mux, LOS_WAIT_FOREVER);
      if (!strcmp(value, "ON")) {
        Manual_Alarm_Status = 1;
      } else if (!strcmp(value, "OFF")) {
        Manual_Alarm_Status = 0;
      }
      LOS_MuxPost(Manual_Alarm_Mux);
    }
}

void Set_Fan_State(cJSON *root) {
    cJSON *para_obj = NULL;
    cJSON *status_obj = NULL;
    char *value = NULL;
    para_obj = cJSON_GetObjectItem(root, "paras");
    status_obj = cJSON_GetObjectItem(para_obj, "fan");
    LOS_MuxPend(Mode_StatusMux,LOS_WAIT_FOREVER);
    LOS_MuxPend(Fan_StatusMux,LOS_WAIT_FOREVER);
    if (status_obj != NULL) {
      value = cJSON_GetStringValue(status_obj);
      if(Mode_Status == 0)
      {
        if (!strcmp(value, "ON")) {
          Fan_Status = 1;
        } else if (!strcmp(value, "OFF")) {
          Fan_Status = 0;
        }
      }
    }
    LOS_MuxPost(Mode_StatusMux);
    LOS_MuxPost(Fan_StatusMux);
}

void Set_Light_State(cJSON *root) {
    cJSON *para_obj = NULL;
    cJSON *status_obj = NULL;
    char *value = NULL;
    para_obj = cJSON_GetObjectItem(root, "paras");
    status_obj = cJSON_GetObjectItem(para_obj, "light");
    LOS_MuxPend(Mode_StatusMux,LOS_WAIT_FOREVER);
    LOS_MuxPend(Light_StatusMux,LOS_WAIT_FOREVER);
    if (status_obj != NULL) {
      value = cJSON_GetStringValue(status_obj);
      if(Mode_Status == 0)
      {
        if (!strcmp(value, "ON")) {
          Light_Status = 1;
        } else if (!strcmp(value, "OFF")) {
          Light_Status = 0;
        }
      }
    }
    LOS_MuxPost(Mode_StatusMux);
    LOS_MuxPost(Light_StatusMux);
}

void Set_Lock_State(cJSON *root) {
    cJSON *para_obj = NULL;
    cJSON *status_obj = NULL;
    char *value = NULL;
    para_obj = cJSON_GetObjectItem(root, "paras");
    status_obj = cJSON_GetObjectItem(para_obj, "lock");
    LOS_MuxPend(Mode_StatusMux,LOS_WAIT_FOREVER);
    LOS_MuxPend(Lock_StatusMux,LOS_WAIT_FOREVER);
    if (status_obj != NULL) {
      value = cJSON_GetStringValue(status_obj);
      if (!strcmp(value, "ON")) {
        Lock_Status = 1;
      } else if (!strcmp(value, "OFF")) {
        Lock_Status = 0;
      }
    }
    LOS_MuxPost(Mode_StatusMux);
    LOS_MuxPost(Lock_StatusMux);
}

void Set_Time_State(cJSON *root) {
    cJSON *para_obj = NULL;
    cJSON *status_obj = NULL;
    int time_value = 0;
    para_obj = cJSON_GetObjectItem(root, "paras");
    status_obj = cJSON_GetObjectItem(para_obj, "time");
    LOS_MuxPend(Time_StatusMux,LOS_WAIT_FOREVER);
    if (status_obj != NULL) {
      if (cJSON_IsNumber(status_obj)) {
          time_value = status_obj->valueint;
          Timed = time_value;
          LOS_MuxPend(Flag_StatusMux,LOS_WAIT_FOREVER);
          Flag_Status = 1;
          LOS_MuxPost(Flag_StatusMux);
          LOS_MuxPend(Timed_StatusMux,LOS_WAIT_FOREVER);
          Timed_flag = 1;
          LOS_MuxPost(Timed_StatusMux);
      }
    }
    LOS_MuxPost(Time_StatusMux);
}

void Set_Mode_State(cJSON *root) {
    cJSON *para_obj = NULL;
    cJSON *status_obj = NULL;
    char *value = NULL;
    para_obj = cJSON_GetObjectItem(root, "paras");
    status_obj = cJSON_GetObjectItem(para_obj, "mode");
    LOS_MuxPend(Mode_StatusMux,LOS_WAIT_FOREVER);
    if (status_obj != NULL) {
      value = cJSON_GetStringValue(status_obj);
      if (!strcmp(value, "ON")) {
        Mode_Status = 1;
      } else if (!strcmp(value, "OFF")) {
        Mode_Status = 0;
      }
      LOS_MuxPend(Light_StatusMux,LOS_WAIT_FOREVER);
      Light_Status = 0;
      LOS_MuxPost(Light_StatusMux);
    }
    LOS_MuxPost(Mode_StatusMux);
}

void mqtt_message_arrived(MessageData *data) {
  int rc;
  cJSON *root = NULL;
  cJSON *cmd_name = NULL;
  char *cmd_name_str = NULL;
  char *request_id_idx = NULL;
  char request_id[40] = {0};
  MQTTMessage message;
  char payload[MAX_BUFFER_LENGTH];
  
  char rsptopic[128] = {0};

  printf("Message arrived on topic %.*s: %.*s\n",
         data->topicName->lenstring.len, data->topicName->lenstring.data,
         data->message->payloadlen, data->message->payload);

  request_id_idx = strstr(data->topicName->lenstring.data, "request_id=");
  strncpy(request_id, request_id_idx + 11, 36);

  sprintf(rsptopic, "%s/request_id=%s", response_topic, request_id);

  message.qos = 0;
  message.retained = 0;
  message.payload = payload;
  sprintf(payload, "{ \
    \"result_code\": 0, \
    \"response_name\": \"COMMAND_RESPONSE\", \
    \"paras\": { \
        \"result\": \"success\" \
    } \
    }");
  message.payloadlen = strlen(payload);

  if ((rc = MQTTPublish(&client, rsptopic, &message)) != 0) {
    printf("Return code from MQTT publish is %d\n", rc);
    mqttConnectFlag = 0;
  }

  root = cJSON_ParseWithLength(data->message->payload, data->message->payloadlen);
  if (root != NULL) {
    cmd_name = cJSON_GetObjectItem(root, "command_name");
    if (cmd_name != NULL) {
      cmd_name_str = cJSON_GetStringValue(cmd_name);
      if(!strcmp(cmd_name_str,"Alarm")) {
       Set_Alarm_State(root); 
      }
      else if(!strcmp(cmd_name_str,"Fan")) {
        Set_Fan_State(root);
      }
      else if(!strcmp(cmd_name_str,"Light")) {
        Set_Light_State(root);
      }
      else if(!strcmp(cmd_name_str,"Time")) {
        Set_Time_State(root);
      }
      else if(!strcmp(cmd_name_str,"Mode")) {
        Set_Mode_State(root);
      }
      else if(!strcmp(cmd_name_str,"Lock")) {
        Set_Lock_State(root);
      }
    }
  }
  cJSON_Delete(root);
}

int wait_message() {
  uint8_t rec = MQTTYield(&client, 5000);
  if (rec != 0) {
    mqttConnectFlag = 0;
  }
  if (mqttConnectFlag == 0) {
    return 0;
  }
  return 1;
}

void mqtt_init() {
  int rc;

  printf("MQTT开始运行...\n");

  NetworkInit(&network);

begin:
  printf("网络连接中...\n");
  NetworkConnect(&network, HOST_ADDR, 1883);
  printf("MQTT客户端正在初始化...\n");
  MQTTClientInit(&client, &network, 2000, sendBuf, sizeof(sendBuf), readBuf,
                 sizeof(readBuf));

  MQTTString clientId = MQTTString_initializer;
  clientId.cstring = mqtt_devid;

  MQTTString userName = MQTTString_initializer;
  userName.cstring = mqtt_username;

  MQTTString password = MQTTString_initializer;
  password.cstring = mqtt_pwd;

  MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
  data.clientID = clientId;
  data.username = userName;
  data.password = password;
  data.willFlag = 0;
  data.MQTTVersion = 4;
  data.keepAliveInterval = 60;
  data.cleansession = 1;

  printf("MQTT的Connect报文生成中...\n");
  rc = MQTTConnect(&client, &data);
  if (rc != 0) {
    printf("MQTT的Connect报文: %d\n", rc);
    NetworkDisconnect(&network);
    MQTTDisconnect(&client);
    osDelay(200);
    goto begin;
  }

  printf("MQTT的Subscribe报文生成中...\n");
  rc = MQTTSubscribe(&client, subcribe_topic, 0, mqtt_message_arrived);
  if (rc != 0) {
    printf("MQTT的Subscribe报文: %d\n", rc);
    osDelay(200);
    goto begin;
  }

  mqttConnectFlag = 1;
}

unsigned int mqtt_is_connected() { return mqttConnectFlag; }
//---------------云服务相关函数---------------//

//----------------互斥锁获取状态函数群----------------//
unsigned char Get_Alarm_Status(void)
{
  // 优先返回手动警报状态
  LOS_MuxPend(Manual_Alarm_Mux, LOS_WAIT_FOREVER);
  if (Manual_Alarm_Status > 0) {
    LOS_MuxPost(Manual_Alarm_Mux);
    return Manual_Alarm_Status;
  }
  LOS_MuxPost(Manual_Alarm_Mux);
  
  // 其次返回定时警报状态
  unsigned char temp;
  LOS_MuxPend(Alarm_StatusMux,LOS_WAIT_FOREVER);
  temp = Alarm_Status;
  LOS_MuxPost(Alarm_StatusMux);
  return temp;
}

unsigned char Get_Fan_Status(void)
{
  unsigned char temp;
  LOS_MuxPend(Fan_StatusMux,LOS_WAIT_FOREVER);
  temp = Fan_Status;
  LOS_MuxPost(Fan_StatusMux);
  return temp;
}

unsigned char Get_Light_Status(void)
{
  unsigned char temp;
  LOS_MuxPend(Light_StatusMux,LOS_WAIT_FOREVER);
  temp = Light_Status;
  LOS_MuxPost(Light_StatusMux);
  return temp;
}

unsigned char Get_Mode_Status(void)
{
  unsigned char temp;
  LOS_MuxPend(Mode_StatusMux,LOS_WAIT_FOREVER);
  temp = Mode_Status;
  LOS_MuxPost(Mode_StatusMux);
  return temp;
}

unsigned char Get_Lock_Status(void)
{
  unsigned char temp;
  LOS_MuxPend(Lock_StatusMux,LOS_WAIT_FOREVER);
  temp = Lock_Status;
  LOS_MuxPost(Lock_StatusMux);
  return temp;
}

unsigned int Get_Timed(void)
{
  unsigned int temp;
  LOS_MuxPend(Time_StatusMux,LOS_WAIT_FOREVER);
  temp = Timed;
  LOS_MuxPost(Time_StatusMux);
  return temp;
}
//----------------互斥锁获取状态函数群----------------//

// 红外传感器检测函数(模拟实现，需根据硬件调整)
// 返回1:手在药格内 0:手不在药格内
static uint8_t ir_sensor_detect(uint8_t location) {
    // 实际应用中需替换为真实硬件检测逻辑
    // 此处模拟：假设通过IO扩展芯片检测，location对应引脚
    uint8_t pin_data[2] = {0};
    pcf8575_get_inputs(&pin_data[0], &pin_data[1]);
    uint16_t pins = ((uint16_t)pin_data[1] << 8) | pin_data[0];
    // 假设6-11位对应1-6号药格的红外传感器(高电平表示有手)
    return (pins & (0x0001 << (location + 5))) ? 1 : 0;
}

// LCD显示任务
void LCD_Thread(void)
{
    e_iot_data LCD_Data;
    unsigned int bufferSize = sizeof(LCD_Data);
    unsigned int timed = 0;
    unsigned char location = 0;
    unsigned char hour = 0;
    unsigned char min = 0;
    unsigned char Flag = 0;
    
    // 上一次显示的值，用于避免重复刷新
    unsigned char last_Flag = 0;
    unsigned int last_Timed = 0;
    
    lcd_init();
    lcd_fill(0, 0, LCD_W, LCD_H, LCD_LIGHTBLUE);
    lcd_fill(0, 0, LCD_W, 26, LCD_LIGHTGREEN);

    lcd_show_chinese(76,1,"多功能智能药盒",LCD_BLACK,LCD_LIGHTGREEN,24,0);

    lcd_show_chinese(10,35,"温度",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(58,35,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_chinese(125,35,"℃",LCD_BLACK,LCD_LIGHTBLUE,24,0);

    lcd_show_chinese(205,35,"湿度",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(253,35,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(296,35,'%',LCD_BLACK,LCD_LIGHTBLUE,24,0);

    lcd_show_chinese(10,65,"系统时间",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(142,65,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(178,65,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);

    lcd_show_chinese(10,95,"定时",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(58,95,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_chinese(160,95,"取药位置",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(256,95,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    
    lcd_show_chinese(10,125,"锁状态",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(82,125,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_chinese(160,125,"警报状态",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(256,125,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    
    lcd_show_chinese(10,155,"灯光状态",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(106,155,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_chinese(160,155,"风扇状态",LCD_BLACK,LCD_LIGHTBLUE,24,0);
    lcd_show_char(256,155,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);

    lcd_show_chinese(304,2,"动",LCD_BLACK,LCD_LIGHTGREEN,12,0);
    
    while(1)
    {
        LOS_MuxPend(Flag_StatusMux,LOS_WAIT_FOREVER);
        Flag = Flag_Status;
        LOS_MuxPost(Flag_StatusMux);
        unsigned int ret = LOS_QueueReadCopy(LCD_QueueID,&LCD_Data,&bufferSize,LOS_WAIT_FOREVER);
        if(ret != LOS_OK) {
            printf("从消息队列读取数据失败！\n");
            LOS_Msleep(500);
            continue;
        }
        timed = LCD_Data.Timed;
        location = timed / 10000;
        hour = timed / 100 % 100;
        min = timed % 100;
        
        // 更新温度显示
        lcd_show_float_num1(72, 35, LCD_Data.temp, 3, LCD_BLACK, LCD_LIGHTBLUE, 24);
        
        // 更新湿度显示
        lcd_show_int_num(267, 35, LCD_Data.humi, 2, LCD_BLACK, LCD_LIGHTBLUE, 24);
        
        // 更新时间显示
        lcd_show_int_num(118, 65, LCD_Data.Time[0] / 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
        lcd_show_int_num(130, 65, LCD_Data.Time[0] % 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
        lcd_show_int_num(154, 65, LCD_Data.Time[1] / 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
        lcd_show_int_num(166, 65, LCD_Data.Time[1] % 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
        lcd_show_int_num(190, 65, LCD_Data.Time[2] / 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
        lcd_show_int_num(202, 65, LCD_Data.Time[2] % 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
        
        // 只在定时状态改变时刷新定时显示区域
        if (Flag != last_Flag || timed != last_Timed) {
            // 清除定时和时间显示区域
            lcd_fill(70, 95, 160, 120, LCD_LIGHTBLUE);
            lcd_fill(268, 95, LCD_W, 120, LCD_LIGHTBLUE);
            
            
            
            last_Flag = Flag;
            last_Timed = timed;
        }

        if(Flag == 1)
            {
                lcd_show_int_num(70, 95, hour / 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
                lcd_show_int_num(82, 95, hour % 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
                lcd_show_char(94,95,':',LCD_BLACK,LCD_LIGHTBLUE,24,0);
                lcd_show_int_num(108, 95, min / 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
                lcd_show_int_num(120, 95, min % 10, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
                
                lcd_show_int_num(268, 95, location, 1, LCD_BLACK, LCD_LIGHTBLUE, 24);
                lcd_show_chinese(280, 95,"号",LCD_BLACK,LCD_LIGHTBLUE,24,0);
            }
            else
            {
                lcd_show_chinese(70,95,"暂无",LCD_BLACK,LCD_LIGHTBLUE,24,0);
                lcd_show_chinese(268,95,"暂无",LCD_BLACK,LCD_LIGHTBLUE,24,0);
            }
        
        // 更新锁状态显示
        if(LCD_Data.Lock == 1)
        {
          lcd_show_chinese(94,125,"开",LCD_LIGHTGREEN2,LCD_LIGHTBLUE,24,0);
        }
        else
        {
          lcd_show_chinese(94,125,"关",LCD_RED,LCD_LIGHTBLUE,24,0);
        }
        
        // 显示报警状态文本
        if(LCD_Data.Alarm > 0)
        {
          lcd_show_chinese(268,125,"开",LCD_LIGHTGREEN2,LCD_LIGHTBLUE,24,0);
        }
        else
        {
          lcd_show_chinese(268,125,"关",LCD_RED,LCD_LIGHTBLUE,24,0);
        }
        
        // 更新灯光状态显示
        if(LCD_Data.Light == 1)
        {
          lcd_show_chinese(118,155,"开",LCD_LIGHTGREEN2,LCD_LIGHTBLUE,24,0);
        }
        else
        {
          lcd_show_chinese(118,155,"关",LCD_RED,LCD_LIGHTBLUE,24,0);
        }
        
        // 更新风扇状态显示
        if(LCD_Data.Fan == 1)
        {
          lcd_show_chinese(268,155,"开",LCD_LIGHTGREEN2,LCD_LIGHTBLUE,24,0);
        }
        else
        {
          lcd_show_chinese(268,155,"关",LCD_RED,LCD_LIGHTBLUE,24,0);
        }

        if(LCD_Data.Mode == 1)
        {
          lcd_show_chinese(292,2,"自",LCD_BLACK,LCD_LIGHTGREEN,12,0);
        }
        else
        {
          lcd_show_chinese(292,2,"手",LCD_BLACK,LCD_LIGHTGREEN,12,0);
        }
        
        LOS_Msleep(100);
    }
}

// 多功能药盒主线程
void Medicine_Box_Thread(void *arg)
{
    e_iot_data iot_data;
    unsigned int bufferSize = sizeof(iot_data);
    unsigned int Count = 0;
    unsigned char Count_Flag = 0;
    while(1)
    {
        unsigned int ret = LOS_QueueReadCopy(Sensor_QueueID,&iot_data,&bufferSize,LOS_WAIT_FOREVER);
        if(ret != LOS_OK) {
            printf("从消息队列读取数据失败！\n");
            LOS_Msleep(500);
            continue;
        }
        if(mqtt_is_connected())
        {
            send_msg_to_mqtt(&iot_data);
        }
        if(iot_data.Mode == 1)
        {
          if(iot_data.temp > 35 || iot_data.humi > 60)
          {
            LOS_MuxPend(Fan_StatusMux,LOS_WAIT_FOREVER);
            Fan_Status = 1;
            LOS_MuxPost(Fan_StatusMux);
          }
          else
          {
            LOS_MuxPend(Fan_StatusMux,LOS_WAIT_FOREVER);
            Fan_Status = 0;
            LOS_MuxPost(Fan_StatusMux);
          }
          if(iot_data.Time[1] == 0 && iot_data.Time[2] == 0)
          {
            LOS_MuxPend(Light_StatusMux,LOS_WAIT_FOREVER);
            Light_Status = 1;
            LOS_MuxPost(Light_StatusMux);
            Count_Flag = 1;
          }
        }
        else
        {
          Count_Flag = 0;
          Count = 0;
        }
        if(Count_Flag == 1)
        {
          Count++;
          if(Count == 600)
          {
            Count = 0;
            Count_Flag = 0;
            LOS_MuxPend(Light_StatusMux,LOS_WAIT_FOREVER);
            Light_Status = 0;
            LOS_MuxPost(Light_StatusMux);
          }
        }
        LOS_Msleep(500);
    }
}

// 获取传感器数据线程
void Sensor_ReadData_Thread(void)
{
    e_iot_data Sensor_Data;
    double SHT30_Data[2] = {0}; // 温湿度临时数据
    uint8_t Pin_Data[2] = {0}; // PCF8575扩展IO输入状态
    unsigned char time_buf[8] = {20,25,7,9,8,59,0,3};// 设置初始时间
    int32_t Weight = 0; // 当前重量
    uint32_t Weight_Maopi = 0; // 皮重量
    int32_t Weight_old = 0; // 定时触发时的基准重量

    unsigned char Alarm_temp = 0; // 警报临时状态
    unsigned char Fan_temp = 0; // 风扇临时状态
    unsigned char Light_temp = 0; // 紫光灯临时状态
    unsigned char Mode_temp = 0; // 模式临时状态
    unsigned char Lock_temp = 0; // 锁状态

    unsigned char Timed_Flag = 0; // 定时到标志位
    unsigned char Timed_Triggered = 0; // 定时已触发标志
    unsigned char Location = 0; // 药格位置
    unsigned char Hour = 0; // 定时时间-时
    unsigned char Minutes = 0; // 定时时间-分
    
    unsigned int Timed_temp = 0; // 定时时间临时数据
    unsigned int Sensor_Count = 0; // 定时读取数据计数器
    unsigned int ret = LOS_OK;
    
    // 初始化外设
    i2c_dev_init();
    DS1302_Init();
    HX711_Init();
    DS1302_SetTime(time_buf);
    
    // 皮重校准
    Weight_Maopi = HX711_Read();
    LOS_Msleep(1000);
    Weight_Maopi = HX711_Read();
    
    while(1)
    {
        Sensor_Count++;
        
        // 每100个循环（约1秒）读取一次时间和其他状态
        if(Sensor_Count % 100 == 0)
        {
            DS1302_GetTime(time_buf);
            Sensor_Count = 0;

            LOS_MuxPend(Timed_StatusMux,LOS_WAIT_FOREVER);
            Timed_Triggered = Timed_flag;
            LOS_MuxPost(Timed_StatusMux);
            
            // 获取当前状态
            Alarm_temp = Get_Alarm_Status();
            Fan_temp = Get_Fan_Status();
            Light_temp = Get_Light_Status();
            Mode_temp = Get_Mode_Status();
            Lock_temp = Get_Lock_Status();
            Timed_temp = Get_Timed();
            
            // 解析定时信息
            Location = Timed_temp / 10000; // 解析服药位置
            Hour = Timed_temp / 100 % 100; // 解析定时时间-时
            Minutes = Timed_temp % 100;    // 解析定时时间-分
            
            // 检查是否到达定时时间
            if(Location > 0 && Location <= 6) // 确保位置有效
            {
                // 精确匹配分钟触发（避免重复触发）
                if(time_buf[4] == Hour && time_buf[5] >= Minutes)
                {
                  Timed_Flag = 1;
                  LOS_MuxPend(Alarm_StatusMux,LOS_WAIT_FOREVER);
                  Alarm_Status = 2;
                  LOS_MuxPost(Alarm_StatusMux);
                }
            }
            
            // 检查定时是否超时（超过10分钟自动清除）
            if (Timed_Flag) {
                if (time_buf[4] > Hour || 
                    (time_buf[4] == Hour && time_buf[5] > Minutes + 10)) {
                    Timed_Flag = 0;
                    Timed_Triggered = 0;
                    Alarm_Status = 0;
                    
                    LOS_MuxPend(Time_StatusMux, LOS_WAIT_FOREVER);
                    Timed = 0;
                    LOS_MuxPost(Time_StatusMux);
                    
                    LOS_MuxPend(Flag_StatusMux, LOS_WAIT_FOREVER);
                    Flag_Status = 0;
                    LOS_MuxPost(Flag_StatusMux);
                    
                    printf("定时已超时，自动清除\n");
                }
            }
            
            // 更新传感器数据
            Sensor_Data.temp = SHT30_Data[0];
            Sensor_Data.humi = SHT30_Data[1];
            Sensor_Data.Time[0] = time_buf[4]; // 时
            Sensor_Data.Time[1] = time_buf[5]; // 分
            Sensor_Data.Time[2] = time_buf[6]; // 秒
            Sensor_Data.Alarm = Alarm_temp;
            Sensor_Data.Fan = Fan_temp;
            Sensor_Data.Light = Light_temp;
            Sensor_Data.Lock = Lock_temp;
            Sensor_Data.Mode = Mode_temp;
            Sensor_Data.Timed = Timed_temp;
            
            // 发送数据到消息队列
            ret = LOS_QueueWriteCopy(Sensor_QueueID, &Sensor_Data, sizeof(Sensor_Data), LOS_NO_WAIT);
            if(ret != LOS_OK) {
                printf("传感器数据写入失败！\n");
            }
            
            ret = LOS_QueueWriteCopy(LCD_QueueID, &Sensor_Data, sizeof(Sensor_Data), LOS_NO_WAIT);
            if(ret != LOS_OK) {
                printf("LCD显示数据写入失败！\n");
            }
            Weight_old = Weight;
            Weight = Get_Weight(Weight_Maopi);
            printf("重量: %d g\n", Weight);
        }
        
        // 每50个循环（约0.5秒）读取一次温湿度
        if(Sensor_Count % 50 == 0)
        {
            sht30_read_data(&SHT30_Data[0], &SHT30_Data[1]);
        }
        
        // 每10个循环（约0.1秒）更新重量值
        if(Sensor_Count % 10 == 0 && Timed_Flag)
        {
            pcf8575_get_inputs(&Pin_Data[0], &Pin_Data[1]);
            uint16_t Pin = ((uint16_t)Pin_Data[1] << 8) | Pin_Data[0];
            uint8_t openedBox = 0;

            for(uint8_t i = 0; i < 6; i++)
            {
                if(!(Pin & (0x0001 << i)))
                {
                    openedBox = i + 1;
                    if(openedBox == Location && Timed_Triggered == 1)
                    {
                      LOS_MuxPend(Flag_StatusMux,LOS_WAIT_FOREVER);
                      Flag_Status = 0;
                      LOS_MuxPost(Flag_StatusMux);
                      Timed_Flag = 0;
                      LOS_MuxPend(Timed_StatusMux,LOS_WAIT_FOREVER);
                      Timed_flag = 0;
                      Timed_Triggered = 0;
                      LOS_MuxPost(Timed_StatusMux);
                      LOS_MuxPend(Time_StatusMux,LOS_WAIT_FOREVER);
                      Timed = 0;
                      LOS_MuxPost(Time_StatusMux);
                      LOS_MuxPend(Alarm_StatusMux,LOS_WAIT_FOREVER);
                      Alarm_Status = 0;
                      LOS_MuxPost(Alarm_StatusMux);
                    }
                    else
                    {
                      LOS_MuxPend(Alarm_StatusMux,LOS_WAIT_FOREVER);
                      Alarm_Status = 1;
                      LOS_MuxPost(Alarm_StatusMux);
                    }
                    printf("%d号药盒被打开\n", openedBox);
                    break;
                }
                else
                {
                  LOS_MuxPend(Alarm_StatusMux,LOS_WAIT_FOREVER);
                  Alarm_Status = 2;
                  LOS_MuxPost(Alarm_StatusMux);
                }
            }
        }
        if(Timed_Flag != 1)
        {
          LOS_MuxPend(Alarm_StatusMux,LOS_WAIT_FOREVER);
          Alarm_Status = 0;
          LOS_MuxPost(Alarm_StatusMux);
        }
        
        LOS_Msleep(10); // 10ms延时
    }
}

// WIFI检测断开重连线程
void WIFI_Thread(void)
{
    uint8_t mac_address[12] = {0x00, 0xdc, 0xb6, 0x90, 0x01, 0x00};

    char ssid[32]=WIFI_SSID;
    char password[32]=WIFI_PASSWORD;
    char mac_addr[32]={0};

    FlashDeinit();
    FlashInit();

    VendorSet(VENDOR_ID_WIFI_MODE, "STA", 3);
    VendorSet(VENDOR_ID_MAC, mac_address, 6);
    VendorSet(VENDOR_ID_WIFI_ROUTE_SSID, ssid, sizeof(ssid));
    VendorSet(VENDOR_ID_WIFI_ROUTE_PASSWD, password,sizeof(password));

    reconnect:
    SetWifiModeOff();
    int ret = SetWifiModeOn();
    if(ret != 0){
        printf("wifi连接失败，请检查wifi配置和AP！\n");
        return;
    }
    mqtt_init();
    while (1) {
        if (!wait_message()) {
        goto reconnect;
        }
        LOS_Msleep(100);
    }
}


void Buzz_Thread(void)
{
  unsigned int ret;
  unsigned int AlarmStatus = 0;
  unsigned char BEEP_Flag = 0;
  // 蜂鸣器根据不同报警状态调整频率
  ret = IoTPwmInit(BEEP_PWM);
  if(ret != LOS_OK)
  {
     printf("蜂鸣器初始化失败！\n");
  }
  while(1)
  {
    AlarmStatus = Get_Alarm_Status();
    BEEP_Flag = !BEEP_Flag;
    if(AlarmStatus == 1)
    {
      IoTPwmStart(BEEP_PWM,90,1000); // 快速鸣叫(手不在)
    }
    else if(AlarmStatus == 2)
    {
      if(BEEP_Flag == 1)
      {
        IoTPwmStart(BEEP_PWM,90,2000); // 慢速鸣叫(定时到/手拿开)
      }
      else
      {
        IoTPwmStop(BEEP_PWM); // 停止鸣叫
      }
    }
    else
    {
      IoTPwmStop(BEEP_PWM); // 停止鸣叫
    }
    LOS_Msleep(100);
  }
}

void Relay_Thread(void)
{
  unsigned char FanStatus = 0;
  unsigned char LightStatus = 0;
  
  IoTGpioInit(Fan_Pin);
  IoTGpioInit(Light_Pin);
  IoTGpioSetDir(Fan_Pin,IOT_GPIO_DIR_OUT);
  IoTGpioSetDir(Light_Pin,IOT_GPIO_DIR_OUT);
  IoTGpioSetOutputVal(Fan_Pin,0);
  IoTGpioSetOutputVal(Light_Pin,0);
  
  while(1)
  {
    FanStatus = Get_Fan_Status();
    LightStatus = Get_Light_Status();
    
    IoTGpioSetOutputVal(Fan_Pin,FanStatus);
    IoTGpioSetOutputVal(Light_Pin,LightStatus);
    
    LOS_Msleep(500);
  }
}

void Lock_Thread(void)
{
  unsigned int ret;
  unsigned char LockStatus = 0;
  
  ret = IoTPwmInit(SG90_PWM);
  if(ret != LOS_OK)
  {
    printf("舵机初始化失败");
  }
  while(1)
  {
    LockStatus = Get_Lock_Status();
    if(LockStatus == 1)
    {
      IoTPwmStart(SG90_PWM,8,50);
    }
    else
    {
      IoTPwmStart(SG90_PWM,3,50);
    }
    LOS_Msleep(500);
  }
}


void Task_List(void)
{
    unsigned int thread_id;
    TSK_INIT_PARAM_S task = {0};
    unsigned int ret = LOS_OK;
    
    if (LOS_MuxCreate(&Alarm_StatusMux) != LOS_OK)
    {
        printf("创建警报状态互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Fan_StatusMux) != LOS_OK)
    {
        printf("创建风扇状态互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Light_StatusMux) != LOS_OK)
    {
        printf("创建紫光灯状态互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Time_StatusMux) != LOS_OK)
    {
        printf("创建定时时间互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Mode_StatusMux) != LOS_OK)
    {
        printf("创建模式状态互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Lock_StatusMux) != LOS_OK)
    {
        printf("创建锁状态互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Flag_StatusMux) != LOS_OK)
    {
        printf("创建标志状态互斥锁失败！\n");
        return;
    }

    if (LOS_MuxCreate(&Buzz_FlagMux) != LOS_OK)
    {
        printf("创建标志状态互斥锁失败！\n");
        return;
    } 

    if (LOS_MuxCreate(&Timed_StatusMux) != LOS_OK)
    {
        printf("创建定时标志位状态互斥锁失败！\n");
        return;
    } 
    
    if (LOS_MuxCreate(&Manual_Alarm_Mux) != LOS_OK) {
        printf("创建手动警报互斥锁失败！\n");
        return;
    }

    ret = LOS_QueueCreate("Sensor_Data",Sensor_DataLength,&Sensor_QueueID,0,Sensor_MsgSize);
    if(ret != LOS_OK)
    {
        printf("传感器消息队列创建失败！\n");
        return;
    }

    ret = LOS_QueueCreate("LCD_Data",Sensor_DataLength,&LCD_QueueID,0,Sensor_MsgSize);
    if(ret != LOS_OK)
    {
        printf("LCD显示数据消息队列创建失败！\n");
        return;
    }

    task.pfnTaskEntry = LCD_Thread;
    task.uwStackSize = 4096;
    task.pcName = "LCD";
    task.usTaskPrio = 26;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
        printf("LCD显示任务创建失败！\n");
    }

    task.pfnTaskEntry = (TSK_ENTRY_FUNC)Medicine_Box_Thread;
    task.uwStackSize = 2048;
    task.pcName = "MedicineBox";
    task.usTaskPrio = 25;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
        printf("多功能药盒主线程创建失败！\n");
    }

    task.pfnTaskEntry = Sensor_ReadData_Thread;
    task.uwStackSize = 4096;
    task.pcName = "SensorReadData";
    task.usTaskPrio = 24;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
        printf("传感器任务创建失败！\n");
    }

    task.pfnTaskEntry = WIFI_Thread;
    task.uwStackSize = 20480;
    task.pcName = "WIFI";
    task.usTaskPrio = 21;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
        printf("WIFI检测断开重连任务创建失败！\n");
    }

    task.pfnTaskEntry = Buzz_Thread;
    task.uwStackSize = 2048;
    task.pcName = "Buzz";
    task.usTaskPrio = 19;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
       printf("蜂鸣器任务创建失败！\n");
    }

    task.pfnTaskEntry = Relay_Thread;
    task.uwStackSize = 2048;
    task.pcName = "Relay";
    task.usTaskPrio = 19;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
       printf("继电器任务创建失败！\n");
    }

    task.pfnTaskEntry = Lock_Thread;
    task.uwStackSize = 2048;
    task.pcName = "Lock";
    task.usTaskPrio = 20;
    if(LOS_TaskCreate(&thread_id, &task) != LOS_OK) {
       printf("控制锁任务创建失败！\n");
    }

}

APP_FEATURE_INIT(Task_List);