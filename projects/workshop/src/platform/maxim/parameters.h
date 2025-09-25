#ifndef __PARAMETERS_H__
#define __PARAMETERS_H__

#include "maxim_irq.h"
#include "maxim_spi.h"
#include "maxim_gpio.h"
#include "maxim_uart.h"
#include "maxim_uart_stdio.h"

#ifdef IIO_SUPPORT
#define INTC_DEVICE_ID  0
#endif

#define UART_IRQ_ID     UART0_IRQn
#define UART_DEVICE_ID  0
#define UART_BAUDRATE   57600
#define UART_EXTRA      &adxl355_uart_extra_ip
#define UART_OPS        &max_uart_ops

#define SPI_DEVICE_ID   1
#define SPI_CS          1
#define SPI_BAUDRATE    1000000
#define SPI_OPS         &max_spi_ops
#define SPI_EXTRA       &adxl355_spi_extra_ip

extern struct max_uart_init_param adxl355_uart_extra_ip;
extern struct max_spi_init_param adxl355_spi_extra_ip;

#endif /* __PARAMETERS_H__ */
