#include "common_data.h"
#include "adxl355.h"
#include "no_os_delay.h"
#include "no_os_print_log.h"

/***************************************************************************//**
 * @brief Dummy example main execution.
 *
 * @return ret - Result of the example execution. If working correctly, will
 *               execute continuously the while(1) loop and will not return.
*******************************************************************************/
int example_main()
{
	struct adxl355_dev *adxl355_desc;
	struct no_os_uart_desc *uart_desc;
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
		goto error;
	ret = adxl355_set_odr_lpf(adxl355_desc, ADXL355_ODR_3_906HZ);
	if (ret)
		goto error;
	ret = adxl355_set_op_mode(adxl355_desc, ADXL355_MEAS_TEMP_ON_DRDY_OFF);
	if (ret)
		goto error;

	struct adxl355_frac_repr x[32] = {0};
	struct adxl355_frac_repr y[32] = {0};
	struct adxl355_frac_repr z[32] = {0};
	struct adxl355_frac_repr temp;
	union adxl355_sts_reg_flags status_flags = {0};
	uint8_t fifo_entries = 0;

	while (1) {

		pr_info("Single read \n");
		ret = adxl355_get_xyz(adxl355_desc, &x[0], &y[0], &z[0]);
		if (ret)
			goto error;
		pr_info(" x=%d"".%09u", (int)x[0].integer, (abs)(x[0].fractional));
		pr_info(" y=%d"".%09u", (int)y[0].integer, (abs)(y[0].fractional));
		pr_info(" z=%d"".%09u \n", (int)z[0].integer, (abs)(z[0].fractional));

		ret = adxl355_get_fifo_data(adxl355_desc,
					    &fifo_entries,
					    &x[0],
					    &y[0],
					    &z[0]);
		if (ret)
			goto error;
		pr_info("Number of read entries from the FIFO %d \n", fifo_entries);
		pr_info("Number of read data sets from the FIFO %d \n", fifo_entries / 3);
		for (uint8_t idx = 0; idx < 32; idx ++) {
			if (idx < fifo_entries / 3) {
				pr_info(" x=%d"".%09u m/s^2", (int)x[idx].integer, (abs)(x[idx].fractional));
				pr_info(" y=%d"".%09u m/s^2", (int)y[idx].integer, (abs)(y[idx].fractional));
				pr_info(" z=%d"".%09u m/s^2", (int)z[idx].integer, (abs)(z[idx].fractional));
				pr_info("\n");
			}
		}

		pr_info("==========================================================\n");
		ret = adxl355_get_sts_reg(adxl355_desc, &status_flags);
		if (ret)
			goto error;
		pr_info("Activity flag = %d \n", (uint8_t)(status_flags.fields.Activity));
		pr_info("DATA_RDY flag = %d \n", (uint8_t)(status_flags.fields.DATA_RDY));
		pr_info("FIFO_FULL flag = %d \n", (uint8_t)(status_flags.fields.FIFO_FULL));
		pr_info("FIFO_OVR flag = %d \n", (uint8_t)(status_flags.fields.FIFO_OVR));
		pr_info("NVM_BUSY flag = %d \n", (uint8_t)(status_flags.fields.NVM_BUSY));
		pr_info("===========================================================\n");

		ret = adxl355_get_temp(adxl355_desc, &temp);
		if (ret)
			goto error;
		pr_info(" Temp =%d"".%09u millidegress Celsius \n", (int)temp.integer,
			(abs)(temp.fractional));

		no_os_mdelay(1000);
	}

error:
	pr_info("Error!\n");
	return 0;
}
