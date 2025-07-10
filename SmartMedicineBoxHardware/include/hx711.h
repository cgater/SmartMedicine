#ifndef _HX711_H_
#define _HX711_H_

#include "los_task.h"

void HX711_Init(void);
uint32_t HX711_Read(void);
int32_t Get_Weight(uint32_t Weight_Maopi);

#endif