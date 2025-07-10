#include "stdint.h"
#include "iot_gpio.h"
#include "iot_errno.h"
   
#define ds1302_sec_add         0x80        // 秒数据写地址
#define ds1302_min_add         0x82        // 分数据写地址
#define ds1302_hr_add          0x84        // 时数据写地址
#define ds1302_date_add        0x86        // 日数据写地址
#define ds1302_month_add       0x88        // 月数据写地址
#define ds1302_day_add         0x8a        // 星期数据写地址
#define ds1302_year_add        0x8c        // 年数据写地址
#define ds1302_control_add     0x8e        // 控制寄存器写地址
#define ds1302_charger_add     0x90        // 涓流充电寄存器写地址
#define ds1302_clkburst_add    0xbe        // 时钟多字节写地址

#define SCK GPIO0_PA2
#define IO GPIO0_PB0
#define RST GPIO0_PA3

// BCD码转十进制函数（根据手册：寄存器数据为BCD格式）
unsigned char BCD_to_DEC(unsigned char bcd_data)
{
    // 高4位为十位，低4位为个位（如BCD码0x59转换为59）
    return ( (bcd_data >> 4) * 10 ) + (bcd_data & 0x0F);
}

// 十进制转BCD码函数（设置时间时使用）
unsigned char DEC_to_BCD(unsigned char dec_data)
{
    // 十位存于高4位，个位存于低4位（如十进制59转换为0x59）
    return ( (dec_data / 10) << 4 ) + (dec_data % 10);
}

void DS1302_Init(void)
{
    IoTGpioInit(SCK);
    IoTGpioInit(RST);
    IoTGpioInit(IO);
    IoTGpioSetDir(SCK, IOT_GPIO_DIR_OUT);
    IoTGpioSetDir(RST, IOT_GPIO_DIR_OUT);
    IoTGpioSetDir(IO, IOT_GPIO_DIR_OUT);
    IoTGpioSetOutputVal(SCK, 0);
    IoTGpioSetOutputVal(RST, 0);
}

void DS1302_Write_Byte(unsigned char addr, unsigned char dat)
{
    unsigned char i;
    IoTGpioSetDir(IO, IOT_GPIO_DIR_OUT);
    IoTGpioSetOutputVal(RST, 1);
    addr &= 0XFE;
    for (i = 0; i < 8; i++) {
        IoTGpioSetOutputVal(IO, (addr & 0X01) ? 1 : 0);
        IoTGpioSetOutputVal(SCK, 1);
        IoTGpioSetOutputVal(SCK, 0);
        addr >>= 1;
    }
    for (i = 0; i < 8; i++) {
        IoTGpioSetOutputVal(IO, (dat & 0X01) ? 1 : 0);
        IoTGpioSetOutputVal(SCK, 1);
        IoTGpioSetOutputVal(SCK, 0);
        dat >>= 1;
    }
    IoTGpioSetOutputVal(RST, 0);
}

unsigned char DS1302_Read_Byte(unsigned char addr) 
{
    unsigned char i, temp = 0;
    IotGpioValue val;
    IoTGpioSetDir(IO, IOT_GPIO_DIR_OUT);
    IoTGpioSetOutputVal(RST, 1);
    addr |= 0X01;
    for (i = 0; i < 8; i++) {
        IoTGpioSetOutputVal(IO, (addr & 0X01) ? 1 : 0);
        IoTGpioSetOutputVal(SCK, 1);
        IoTGpioSetOutputVal(SCK, 0);
        addr >>= 1;
    }
    IoTGpioSetDir(IO, IOT_GPIO_DIR_IN);
    for (i = 0; i < 8; i++) {
        temp >>= 1;
        IoTGpioGetInputVal(IO, &val);
        if (val == IOT_GPIO_VALUE1) {
            temp |= 0X80;
        }
        IoTGpioSetOutputVal(SCK, 1);
        IoTGpioSetOutputVal(SCK, 0);
    }
    IoTGpioSetOutputVal(RST, 0);
    return temp;
}

void DS1302_SetTime(unsigned char *time_buf)
{
    // 输入的time_buf为十进制，需转换为BCD码写入寄存器
    DS1302_Write_Byte(ds1302_control_add, 0X00);
    DS1302_Write_Byte(ds1302_sec_add, 0X80);
    DS1302_Write_Byte(ds1302_year_add, DEC_to_BCD(time_buf[1]));  // 十进制转BCD
    DS1302_Write_Byte(ds1302_month_add, DEC_to_BCD(time_buf[2]));
    DS1302_Write_Byte(ds1302_date_add, DEC_to_BCD(time_buf[3]));
    DS1302_Write_Byte(ds1302_hr_add, DEC_to_BCD(time_buf[4]));
    DS1302_Write_Byte(ds1302_min_add, DEC_to_BCD(time_buf[5]));
    DS1302_Write_Byte(ds1302_sec_add, DEC_to_BCD(time_buf[6]) & 0X7F);  // 清除CH位
    DS1302_Write_Byte(ds1302_day_add, DEC_to_BCD(time_buf[7]));
    DS1302_Write_Byte(ds1302_control_add, 0X80);
}

void DS1302_GetTime(unsigned char *time_buf)
{
    // 从寄存器读取BCD码，转换为十进制存入time_buf
    time_buf[1] = BCD_to_DEC(DS1302_Read_Byte(ds1302_year_add));  // BCD转十进制
    time_buf[2] = BCD_to_DEC(DS1302_Read_Byte(ds1302_month_add));
    time_buf[3] = BCD_to_DEC(DS1302_Read_Byte(ds1302_date_add));
    time_buf[4] = BCD_to_DEC(DS1302_Read_Byte(ds1302_hr_add));
    time_buf[5] = BCD_to_DEC(DS1302_Read_Byte(ds1302_min_add));
    time_buf[6] = BCD_to_DEC(DS1302_Read_Byte(ds1302_sec_add) & 0X7F);  // 屏蔽CH位后转换
    time_buf[7] = BCD_to_DEC(DS1302_Read_Byte(ds1302_day_add));
}