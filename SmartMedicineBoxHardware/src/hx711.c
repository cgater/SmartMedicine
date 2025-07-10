#include "iot_gpio.h"
#include "los_task.h"
#include "iot_adc.h"
#include "stdio.h"
#include "string.h"

#define HX711_SCK_Pin  GPIO0_PA5
#define HX711_DOUT_Pin GPIO0_PB1

#define GapValue 214.74

uint32_t HX711_Buffer; // 读取实际的重量
uint32_t Weight_Maopi; // 毛皮
int32_t Weight_Shiwu;  // 实物重量
uint8_t Flag_Error = 0;

void HX711_Init(void)
{
    IoTGpioInit(HX711_SCK_Pin);
    IoTGpioInit(HX711_DOUT_Pin);
    IoTGpioSetDir(HX711_SCK_Pin,IOT_GPIO_DIR_OUT);
    IoTGpioSetDir(HX711_DOUT_Pin,IOT_GPIO_DIR_IN);
}

uint32_t HX711_Read(void)
{
    uint32_t Count = 0;
    uint8_t i = 0;
    IotGpioValue Val;
    LOS_Msleep(10);
    IoTGpioSetOutputVal(HX711_SCK_Pin,0);
    
    while(Val == IOT_GPIO_VALUE1)
    {
        IoTGpioGetInputVal(HX711_DOUT_Pin,&Val);
    }
    for(i = 0; i < 24; i++)
    {
        IoTGpioSetOutputVal(HX711_SCK_Pin,1);
        Count = Count << 1;
        IoTGpioGetInputVal(HX711_DOUT_Pin,&Val);
        if(Val == IOT_GPIO_VALUE1)
        {
            Count ++;
        }
        IoTGpioSetOutputVal(HX711_SCK_Pin,0);
    }
    IoTGpioSetOutputVal(HX711_SCK_Pin,1);
    Count = Count ^ 0X800000;
    IoTGpioSetOutputVal(HX711_SCK_Pin,0);
    return Count;
}

int32_t Get_Weight(uint32_t Weight_Maopi)
{
	HX711_Buffer = HX711_Read();
	if(HX711_Buffer > Weight_Maopi)			
	{
		Weight_Shiwu = HX711_Buffer;
		Weight_Shiwu = Weight_Shiwu - Weight_Maopi;
		Weight_Shiwu = (int32_t)((float)Weight_Shiwu/GapValue);
	}
    return Weight_Shiwu;
}