#include "iot_i2c.h"
#include "stdint.h"
#include "iot_errno.h"
#include "string.h"  // 添加string.h头文件用于memset

#define I2C_HANDLE EI2C0_M2
#define SHT30_I2C_ADDRESS 0x44
#define PCF8575_I2C_ADDRESS 0x20  // 假设A0=A1=A2=0

/***************************************************************
 * 函数名称: sht30_init
 * 说    明: sht30初始化
 * 参    数: 无
 * 返 回 值: uint32_t IOT_SUCCESS表示成功 IOT_FAILURE表示失败
 ***************************************************************/
static uint32_t sht30_init(void)
{
    uint32_t ret = 0;
    uint8_t send_data[2] = {0x22, 0x36};
    uint32_t send_len = 2;

    ret = IoTI2cWrite(I2C_HANDLE, SHT30_I2C_ADDRESS, send_data, send_len); 
    if (ret != IOT_SUCCESS)
    {
        printf("I2c write failure.\r\n");
        return IOT_FAILURE;
    }

    return IOT_SUCCESS;
}

/***************************************************************
 * 函数名称: pcf8575_init
 * 说    明: PCF8575初始化
 * 参    数: 无
 * 返 回 值: uint32_t IOT_SUCCESS表示成功 IOT_FAILURE表示失败
 ***************************************************************/
static uint32_t pcf8575_init(void)
{
    // 初始化所有IO为高电平（输入模式）
    uint8_t init_data[2] = {0xFF, 0xFF};
    uint32_t ret = IoTI2cWrite(I2C_HANDLE, PCF8575_I2C_ADDRESS, init_data, sizeof(init_data)); 
    
    if (ret != IOT_SUCCESS)
    {
        printf("PCF8575 init failed!\r\n");
        return IOT_FAILURE;
    }
    
    return IOT_SUCCESS;
}

/***************************************************************
* 函数名称: sht30_calc_RH
* 说    明: 湿度计算
* 参    数: u16sRH：读取到的湿度原始数据
* 返 回 值: 计算后的湿度数据
***************************************************************/
static float sht30_calc_RH(uint16_t u16sRH)
{
    float humidityRH = 0;

    /*clear bits [1..0] (status bits)*/
    u16sRH &= ~0x0003;
    /*calculate relative humidity [%RH]*/
    /*RH = rawValue / (2^16-1) * 10*/
    humidityRH = (100 * (float)u16sRH / 65535);

    return humidityRH;
}

/***************************************************************
* 函数名称: sht30_calc_temperature
* 说    明: 温度计算
* 参    数: u16sT：读取到的温度原始数据
* 返 回 值: 计算后的温度数据
***************************************************************/
static float sht30_calc_temperature(uint16_t u16sT)
{
    float temperature = 0;

    /*clear bits [1..0] (status bits)*/
    u16sT &= ~0x0003;
    /*calculate temperature [℃]*/
    /*T = -45 + 175 * rawValue / (2^16-1)*/
    temperature = (175 * (float)u16sT / 65535 - 45);

    return temperature;
}

/***************************************************************
* 函数名称: sht30_check_crc
* 说    明: 检查数据正确性
* 参    数: data：读取到的数据
            nbrOfBytes：需要校验的数量
            checksum：读取到的校对比验值
* 返 回 值: 校验结果，0-成功 1-失败
***************************************************************/
static uint8_t sht30_check_crc(uint8_t *data, uint8_t nbrOfBytes, uint8_t checksum)
{
    uint8_t crc = 0xFF;
    uint8_t bit = 0;
    uint8_t byteCtr ;
    const int16_t POLYNOMIAL = 0x131;

    /*calculates 8-Bit checksum with given polynomial*/
    for(byteCtr = 0; byteCtr < nbrOfBytes; ++byteCtr)
    {
        crc ^= (data[byteCtr]);
        for ( bit = 8; bit > 0; --bit)
        {
            if (crc & 0x80) crc = (crc << 1) ^ POLYNOMIAL;
            else crc = (crc << 1);
        }
    }

    if(crc != checksum)
        return 1;
    else
        return 0;
}

/***************************************************************
* 函数名称: sht30_read_data
* 说    明: 读取温度、湿度
* 参    数: temp,humi：读取到的数据,通过指针返回 
* 返 回 值: 无
***************************************************************/
void sht30_read_data(double *temp, double *humi)
{
    /*checksum verification*/
    uint8_t data[3];
    uint16_t tmp;
    uint8_t rc;
    /*byte 0,1 is temperature byte 4,5 is humidity*/
    uint8_t SHT30_Data_Buffer[6];
    memset(SHT30_Data_Buffer, 0, 6);
    uint8_t send_data[2] = {0xE0, 0x00};

    uint32_t send_len = 2;
    IoTI2cWrite(I2C_HANDLE, SHT30_I2C_ADDRESS, send_data, send_len);

    uint32_t receive_len = 6;
    IoTI2cRead(I2C_HANDLE, SHT30_I2C_ADDRESS, SHT30_Data_Buffer, receive_len);

    /*check temperature*/
    data[0] = SHT30_Data_Buffer[0];
    data[1] = SHT30_Data_Buffer[1];
    data[2] = SHT30_Data_Buffer[2];
    rc = sht30_check_crc(data, 2, data[2]);
    if(!rc)
    {
        tmp = ((uint16_t)data[0] << 8) | data[1];
        *temp = sht30_calc_temperature(tmp);
    }
    
    /*check humidity*/
    data[0] = SHT30_Data_Buffer[3];
    data[1] = SHT30_Data_Buffer[4];
    data[2] = SHT30_Data_Buffer[5];
    rc = sht30_check_crc(data, 2, data[2]);
    if(!rc)
    {
        tmp = ((uint16_t)data[0] << 8) | data[1];
        *humi = sht30_calc_RH(tmp);
    }
}

/***************************************************************
* 函数名称: pcf8575_set_outputs
* 说    明: 设置PCF8575输出状态
* 参    数: port0 - P0端口输出值 (P07-P00)
*          port1 - P1端口输出值 (P17-P10)
* 返 回 值: uint32_t IOT_SUCCESS表示成功 IOT_FAILURE表示失败
***************************************************************/
uint32_t pcf8575_set_outputs(uint8_t port0, uint8_t port1)
{
    uint8_t output_data[2] = {port0, port1};
    uint32_t ret = IoTI2cWrite(I2C_HANDLE, PCF8575_I2C_ADDRESS, output_data, sizeof(output_data));
    
    if (ret != IOT_SUCCESS)
    {
        printf("PCF8575 write failed!\r\n");
        return IOT_FAILURE;
    }
    
    return IOT_SUCCESS;
}

/***************************************************************
* 函数名称: pcf8575_get_inputs
* 说    明: 读取PCF8575输入状态
* 参    数: port0 - 存储P0端口输入值的指针
*          port1 - 存储P1端口输入值的指针
* 返 回 值: uint32_t IOT_SUCCESS表示成功 IOT_FAILURE表示失败
***************************************************************/
uint32_t pcf8575_get_inputs(uint8_t *port0, uint8_t *port1)
{
    uint8_t input_data[2];
    uint32_t ret = IoTI2cRead(I2C_HANDLE, PCF8575_I2C_ADDRESS, input_data, sizeof(input_data));
    
    if (ret != IOT_SUCCESS)
    {
        printf("PCF8575 read failed!\r\n");
        return IOT_FAILURE;
    }
    
    *port0 = input_data[0];
    *port1 = input_data[1];
    
    return IOT_SUCCESS;
}

/***************************************************************
* 函数名称: pcf8575_set_pin
* 说    明: 设置单个引脚状态
* 参    数: pin - 引脚编号 (0-15: 0-7=P0, 8-15=P1)
*          state - 状态 (0=低电平, 1=高电平)
* 返 回 值: uint32_t IOT_SUCCESS表示成功 IOT_FAILURE表示失败
***************************************************************/
uint32_t pcf8575_set_pin(uint8_t pin, uint8_t state)
{
    static uint8_t current_port0 = 0xFF;  // 默认高电平
    static uint8_t current_port1 = 0xFF;
    
    // 根据引脚编号确定操作哪个端口
    if (pin < 8) {
        // P0端口
        if (state) {
            current_port0 |= (1 << pin);
        } else {
            current_port0 &= ~(1 << pin);
        }
    } else {
        // P1端口
        uint8_t pin_num = pin - 8;
        if (state) {
            current_port1 |= (1 << pin_num);
        } else {
            current_port1 &= ~(1 << pin_num);
        }
    }
    
    // 更新PCF8575状态
    return pcf8575_set_outputs(current_port0, current_port1);
}

/***************************************************************
* 函数名称: pcf8575_get_pin
* 说    明: 读取单个引脚状态
* 参    数: pin - 引脚编号 (0-15: 0-7=P0, 8-15=P1)
*          state - 存储引脚状态的指针
* 返 回 值: uint32_t IOT_SUCCESS表示成功 IOT_FAILURE表示失败
***************************************************************/
uint32_t pcf8575_get_pin(uint8_t pin, uint8_t *state)
{
    uint8_t port0, port1;
    uint32_t ret = pcf8575_get_inputs(&port0, &port1);
    if (ret != IOT_SUCCESS) {
        return ret;
    }
    
    if (pin < 8) {
        *state = (port0 >> pin) & 0x01;
    } else {
        uint8_t pin_num = pin - 8;
        *state = (port1 >> pin_num) & 0x01;
    }
    
    return IOT_SUCCESS;
}

/***************************************************************
* 函数名称: i2c_dev_init
* 说    明: i2c设备初始化
* 参    数: 无
* 返 回 值: 无
***************************************************************/
void i2c_dev_init(void)
{
    // 初始化I2C总线
    IoTI2cInit(I2C_HANDLE, EI2C_FRE_400K);
    
    // 初始化传感器
    sht30_init();
    pcf8575_init();
}