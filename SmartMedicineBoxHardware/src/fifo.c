/*
 * Copyright (c) 2024 iSoftStone Education Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "los_task.h"
#include "ohos_init.h"
#include "iot_uart.h"
#include "iot_errno.h"

// 字符串最大长度
#define STRING_MAXSIZE          128
// FiFo最大单位数量
#define FIFO_MAX_UNIT           1024
// FiFo结构体，用于存放串口接收
struct tagFifo
{
    int max;            // 缓冲区最大单元数目
    int read;           // 读操作的偏移位置
    int write;          // 写操作的偏移位置
    unsigned char buffer[FIFO_MAX_UNIT];
};
// 定义串口接收的Fifo缓冲区
static struct tagFifo m_uart_recv_fifo =
{
    .max = FIFO_MAX_UNIT,
    .read = 0,
    .write = 0,
};

/***************************************************************
* 函数名称: fifo_init
* 说    明: 初始化Fifo
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 无
***************************************************************/
static void fifo_init(struct tagFifo *fifo)
{
    fifo->max = FIFO_MAX_UNIT;
    fifo->read = fifo->write = 0;
}

/***************************************************************
* 函数名称: fifo_is_empty
* 说    明: 判断Fifo是否已空
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 返回1为已空，反之为未空
***************************************************************/
static int fifo_is_empty(struct tagFifo *fifo)
{
    if (fifo->write == fifo->read)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

/***************************************************************
* 函数名称: fifo_is_full
* 说    明: 判断Fifo是否已满
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 返回1为已满，反之为未满
***************************************************************/
static int fifo_is_full(struct tagFifo *fifo)
{
    int write_next = (fifo->write + 1) % (fifo->max);
    if (write_next == fifo->read)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

/***************************************************************
* 函数名称: fifo_valid_data
* 说    明: 获取fifo的有效数据长度
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 返回fifo的有效数据长度
***************************************************************/
static int fifo_valid_data(struct tagFifo *fifo)
{
    return ((fifo->max + fifo->write - fifo->read) % fifo->max);
}

/***************************************************************
* 函数名称: fifo_write
* 说    明: 将字符串写入fifo中
* 参    数:
*       @fifo           fifo结构体变量
*       @buffer         存放数据的缓存区
*       @buffer_length  缓冲区数据长度
* 返 回 值: 返回将buffer的数据存放到fifo，0表示无法写入fifo
***************************************************************/
static int fifo_write(struct tagFifo *fifo, unsigned char *buffer, int buffer_length)
{
    for (int i = 0; i < buffer_length; i++)
    {
        if (fifo_is_full(&fifo) != 0)
        {
            printf("%s, %d: fifo_write() fifo is full and loss data\n", __FILE__, __LINE__);
        }
        fifo->buffer[fifo->write] = buffer[i];
        fifo->write = (fifo->write + 1) % (fifo->max);
    }
}

/***************************************************************
* 函数名称: fifo_read
* 说    明: 从fifo中读取字符串
* 参    数:
*       @fifo       fifo结构体变量
*       @buffer     将从fifo读取数据，存放到该缓冲区中
*       @buffer_len 保存fifo读取数据的长度
* 返 回 值: 返回从fifo读取数据的长度，0表示没有数据
***************************************************************/
static int fifo_read(struct tagFifo *fifo, unsigned char *buffer, int buffer_maxlen, int *buffer_len)
{
    int valid_data_len = 0;
    
    for (int i = 0; i < buffer_maxlen; i++)
    {
        // 判断fifo不为空
        if (fifo_is_empty(fifo) == 0)
        {
            buffer[i] = fifo->buffer[fifo->read];
            fifo->read = (fifo->read + 1) % fifo->max;
            valid_data_len++;
            continue;
        }
        else
        {
            break;
        }
    }
    
    *buffer_len = valid_data_len;
    return valid_data_len;
}