#include "common_data.h"
#include "adxl355.h"
#include "no_os_delay.h"
#include "no_os_print_log.h"

#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"

/***************************************************************************//**
 * @brief Data conversion workshop example main execution.
 *
 * This example demonstrates fixed-point arithmetic for converting raw sensor
 * values to physical units. Students must implement the conversion formulas.
 *
 * @return ret - Result of the example execution. If working correctly, will
 *               execute continuously the while(1) loop and will not return.
*******************************************************************************/
int example_main()
{
	struct adxl355_dev *adxl355_desc;
	struct no_os_uart_desc *uart_desc;
	struct adxl355_frac_repr correct_x = {0}, calc_x = {0};
	struct adxl355_frac_repr correct_y = {0}, calc_y = {0};
	struct adxl355_frac_repr correct_z = {0}, calc_z = {0};
	struct adxl355_frac_repr correct_temp = {0}, calc_temp = {0};
	uint16_t raw_temp = 0;
	int32_t raw_x = 0, raw_y = 0, raw_z = 0;
	int64_t temp_dividend = 0, x_dividend = 0, y_dividend = 0, z_dividend = 0;
	int64_t temp_divisor = 0, accel_divisor = 0;
	int ret;

	ret = no_os_uart_init(&uart_desc, &adxl355_uart_ip);
	if (ret)
		goto error;

	no_os_uart_stdio(uart_desc);

	ret = adxl355_init(&adxl355_desc, adxl355_ip);
	if (ret)
		goto error;

	ret = adxl355_set_op_mode(adxl355_desc, ADXL355_MEAS_TEMP_ON_DRDY_OFF);
	if (ret)
		goto remove_adxl355;

	while (1) {
		pr_info("\n*** NEW READING ***\r\n");
		pr_info("Reading temperature...\r\n");

		ret = adxl355_get_raw_temp(adxl355_desc, &raw_temp);
		if (ret)
			goto remove_adxl355;

		ret = adxl355_get_temp(adxl355_desc, &correct_temp);
		if (ret)
			goto remove_adxl355;

		/**************************************************************************/
		/************************** WRITE YOUR CODE HERE **************************/
		/**************************************************************************/

		temp_dividend = 0;  // TODO
		temp_divisor = 1;   // TODO

		/**************************************************************************/

		calc_temp.integer = no_os_div_s64_rem(temp_dividend, temp_divisor,
						      &(calc_temp.fractional));

		pr_info("Temperature calculated value = %d.%09u millidegrees Celsius\r\n",
			(int)calc_temp.integer, (unsigned int)abs(calc_temp.fractional));

		pr_info("Temperature correct value = %d.%09u millidegrees Celsius\r\n",
			(int)correct_temp.integer, (unsigned int)abs(correct_temp.fractional));

		if ((calc_temp.integer == correct_temp.integer) &&
		    (abs(calc_temp.fractional - correct_temp.fractional) < 100))
			pr_info(GREEN "Correct\r\n\n" RESET);
		else
			pr_info(RED "Wrong\r\n\n" RESET);

		pr_info("Reading acceleration values...\r\n");

		ret = adxl355_get_raw_xyz(adxl355_desc, &raw_x, &raw_y, &raw_z);
		if (ret)
			goto remove_adxl355;

		ret = adxl355_get_xyz(adxl355_desc, &correct_x, &correct_y, &correct_z);
		if (ret)
			goto remove_adxl355;

		if ((raw_x & NO_OS_BIT(19)) == NO_OS_BIT(19))
			raw_x = raw_x | ADXL355_NEG_ACC_MSK;
		if ((raw_y & NO_OS_BIT(19)) == NO_OS_BIT(19))
			raw_y = raw_y | ADXL355_NEG_ACC_MSK;
		if ((raw_z & NO_OS_BIT(19)) == NO_OS_BIT(19))
			raw_z = raw_z | ADXL355_NEG_ACC_MSK;

		/**************************************************************************/
		/************************** WRITE YOUR CODE HERE **************************/
		/**************************************************************************/

		x_dividend = 0;      // TODO
		y_dividend = 0;      // TODO
		z_dividend = 0;      // TODO
		accel_divisor = 1;   // TODO

		/**************************************************************************/

		calc_x.integer = no_os_div_s64_rem(x_dividend, accel_divisor,
						   &(calc_x.fractional));
		calc_y.integer = no_os_div_s64_rem(y_dividend, accel_divisor,
						   &(calc_y.fractional));
		calc_z.integer = no_os_div_s64_rem(z_dividend, accel_divisor,
						   &(calc_z.fractional));

		pr_info("Acceleration calculated values:");
		pr_info(" x=%d.%09u", (int)calc_x.integer, (unsigned int)abs(calc_x.fractional));
		pr_info(" y=%d.%09u", (int)calc_y.integer, (unsigned int)abs(calc_y.fractional));
		pr_info(" z=%d.%09u\r\n", (int)calc_z.integer, (unsigned int)abs(calc_z.fractional));

		pr_info("Acceleration correct values:");
		pr_info(" x=%d.%09u", (int)correct_x.integer,
			(unsigned int)abs(correct_x.fractional));
		pr_info(" y=%d.%09u", (int)correct_y.integer,
			(unsigned int)abs(correct_y.fractional));
		pr_info(" z=%d.%09u\r\n", (int)correct_z.integer,
			(unsigned int)abs(correct_z.fractional));

		if ((abs(calc_x.integer - correct_x.integer) <= 1) &&
		    (abs(calc_y.integer - correct_y.integer) <= 1) &&
		    (abs(calc_z.integer - correct_z.integer) <= 1))
			pr_info(GREEN "Correct\r\n\n" RESET);
		else
			pr_info(RED "Wrong\r\n\n" RESET);

		no_os_mdelay(5000);
	}

	return 0;

remove_adxl355:
	adxl355_remove(adxl355_desc);
error:
	pr_info("Error!\r\n");
	return ret;
}
