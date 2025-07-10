#ifndef _FIFO_H_
#define _FIFO_H_

#define FIFO_MAX_UNIT           1024

struct tagFifo
{
    int max;            // 缓冲区最大单元数目
    int read;           // 读操作的偏移位置
    int write;          // 写操作的偏移位置
    unsigned char buffer[FIFO_MAX_UNIT];
};

/***************************************************************
* 函数名称: fifo_init
* 说    明: 初始化Fifo
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 无
***************************************************************/
static void fifo_init(struct tagFifo *fifo);

/***************************************************************
* 函数名称: fifo_is_empty
* 说    明: 判断Fifo是否已空
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 返回1为已空，反之为未空
***************************************************************/
static int fifo_is_empty(struct tagFifo *fifo);

/***************************************************************
* 函数名称: fifo_is_full
* 说    明: 判断Fifo是否已满
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 返回1为已满，反之为未满
***************************************************************/
static int fifo_is_full(struct tagFifo *fifo);

/***************************************************************
* 函数名称: fifo_valid_data
* 说    明: 获取fifo的有效数据长度
* 参    数:
*       @fifo           fifo结构体变量
* 返 回 值: 返回fifo的有效数据长度
***************************************************************/
static int fifo_valid_data(struct tagFifo *fifo);

/***************************************************************
* 函数名称: fifo_write
* 说    明: 将字符串写入fifo中
* 参    数:
*       @fifo           fifo结构体变量
*       @buffer         存放数据的缓存区
*       @buffer_length  缓冲区数据长度
* 返 回 值: 返回将buffer的数据存放到fifo，0表示无法写入fifo
***************************************************************/
static int fifo_write(struct tagFifo *fifo, unsigned char *buffer, int buffer_length);

/***************************************************************
* 函数名称: fifo_read
* 说    明: 从fifo中读取字符串
* 参    数:
*       @fifo       fifo结构体变量
*       @buffer     将从fifo读取数据，存放到该缓冲区中
*       @buffer_len 保存fifo读取数据的长度
* 返 回 值: 返回从fifo读取数据的长度，0表示没有数据
***************************************************************/
static int fifo_read(struct tagFifo *fifo, unsigned char *buffer, int buffer_maxlen, int *buffer_len);

#endif