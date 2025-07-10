#ifndef _DS1302_H_
#define _DS1302_H_

void DS1302_Init(void);
void DS1302_SetTime(unsigned char *time_buf);
void DS1302_GetTime(unsigned char *time_buf);


#endif