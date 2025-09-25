#include "parameters.h"

struct max_uart_init_param adxl355_uart_extra_ip = {
	.flow = MAX_UART_FLOW_DIS
};

struct max_spi_init_param adxl355_spi_extra_ip  = {
	.num_slaves = 1,
	.polarity = SPI_SS_POL_LOW,
	.vssel = MXC_GPIO_VSSEL_VDDIOH,
};
