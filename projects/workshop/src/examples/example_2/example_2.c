#include "common_data.h"
#include "adxl355.h"
#include "no_os_delay.h"
#include "no_os_print_log.h"

/***************************************************************************//**
 * @brief Temperature reading example main execution.
 *
 * @return ret - Result of the example execution. If working correctly, will
 *               execute continuously the while(1) loop and will not return.
*******************************************************************************/
int example_main()
{
	struct adxl355_dev *adxl355_desc;
	struct no_os_uart_desc *uart_desc;
	struct adxl355_frac_repr temp;
	int ret;

	ret = no_os_uart_init(&uart_desc, &adxl355_uart_ip);
	if (ret)
		goto error;

	no_os_uart_stdio(uart_desc);

	ret = adxl355_init(&adxl355_desc, adxl355_ip);
	if (ret)
		goto error;

	ret = adxl355_soft_reset(adxl355_desc);
	if (ret)
		goto remove_adxl355;

	ret = adxl355_set_odr_lpf(adxl355_desc, ADXL355_ODR_3_906HZ);
	if (ret)
		goto remove_adxl355;

	ret = adxl355_set_op_mode(adxl355_desc, ADXL355_MEAS_TEMP_ON_DRDY_OFF);
	if (ret)
		goto remove_adxl355;

	while (1) {
		ret = adxl355_get_temp(adxl355_desc, &temp);
		if (ret)
			goto remove_adxl355;

		pr_info("Current temperature is %d.%09u millidegrees Celsius\r\n",
			(int)temp.integer, (unsigned int)abs(temp.fractional));

		no_os_mdelay(1000);
	}

	return 0;

remove_adxl355:
	adxl355_remove(adxl355_desc);
error:
	pr_info("Error!\r\n");
	return ret;
}
