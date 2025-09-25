#include "common_data.h"
#include "no_os_delay.h"
#include "no_os_print_log.h"

/***************************************************************************//**
 * @brief Hello World example main execution.
 *
 * @return ret - Result of the example execution. If working correctly, will
 *               execute continuously the while(1) loop and will not return.
*******************************************************************************/
int example_main()
{
	struct no_os_uart_desc *uart_desc;
	int ret;

	ret = no_os_uart_init(&uart_desc, &adxl355_uart_ip);
	if (ret)
		goto error;

	no_os_uart_stdio(uart_desc);

	while (1) {
		pr_info("Hello World\r\n");
		no_os_mdelay(1000);
	}

	return 0;

error:
	pr_info("Error initializing UART!\r\n");
	return ret;
}
