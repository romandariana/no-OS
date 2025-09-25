# Embedded Software Workshop - Hands-On Guide

**Prerequisites:** Complete setup in `~/workshop_baremetal/README.md` before starting.

## Setup

In every new terminal session, export these variables:

```bash
export MAXIM_LIBRARIES=$HOME/workshop_baremetal/MAX78000SDK/Libraries
export PLATFORM=maxim
export TARGET=max78000
```

**Workshop location:**

```bash
cd ~/workshop_baremetal/no-OS/projects/workshop
```

---

## Example 1: Hello World

**Objective:** Print "Hello World" via UART every second.

**Hardware:** MAX78000FTHR board only.

### Build and Flash

```bash
make reset
make EXAMPLE=example_1 run
```

### Connect Serial Console

```bash
picocom -b 57600 /dev/ttyACM0
# Exit: Ctrl+A, Ctrl+X
```

**See project README for alternative serial tools and troubleshooting.**

### Expected Output

```text
Hello World
Hello World
Hello World
...
```

### What's Happening

**Source:** `src/examples/example_1/example_1.c`

The example demonstrates the no-OS framework pattern:

```c
int example_main()
{
    // Initialize UART for console output
    ret = no_os_uart_init(&uart_desc, &adxl355_uart_ip);

    // Redirect printf to UART
    ret = no_os_uart_stdio(uart_desc);

    // Print messages in a loop
    while (1) {
        pr_info("Hello World\r\n");
        no_os_mdelay(1000);
    }
}
```

**Key points:**

- `example_main()` is your entry point (called by platform `main()`)
- `adxl355_uart_ip` comes from `common_data.c` - shared configuration
- Hardware pins defined in `parameters.h`

---

## Example 2: Temperature Reading

**Objective:** Read temperature from ADXL355 sensor via SPI.

**Hardware:** MAX78000FTHR + ADXL355 (requires wiring).

### Hardware Setup

**⚠️ Disconnect USB before wiring. Reconnect after.**

Wire MAX78000FTHR to ADXL355 - see wiring table in project README.

### Build and Flash

```bash
make reset
make EXAMPLE=example_2 run
```

**Ensure serial console is open (57600 baud).**

### Expected Output

```text
Current temperature is 27545.032056750 millidegrees Celsius
Current temperature is 27337.001666950 millidegrees Celsius
Current temperature is 24447.051390750 millidegrees Celsius
...
```

### What's Happening

**Source:** `src/examples/example_2/example_2.c`

The example shows:

1. **Sensor initialization:**

   ```c
   adxl355_soft_reset()         // Clear registers
   adxl355_set_odr_lpf()        // Set data rate: 3.906 Hz
   adxl355_set_op_mode()        // Enable measurement + temperature
   ```

2. **Reading loop:**

   ```c
   while (1) {
       adxl355_get_temp(&temp);
       pr_info("Current temperature is %f millidegrees Celsius\n", temp);
       no_os_mdelay(1000);
   }
   ```

**Note:** We're using an accelerometer but reading only temperature. Acceleration comes in Example 3!

### Challenge: Convert to Degrees

**Task:** Display `27.54 degrees` instead of `27545.032056750 millidegrees`.

**Hint:** Divide by 1000.0 and use `%.2f` format.

**File to modify:** `src/examples/example_2/example_2.c` (line with `pr_info`)

```bash
make reset
make EXAMPLE=example_2 run
```

---

## Example 3: Acceleration and Temperature Conversion

**Objective:** Convert raw sensor values using fixed-point arithmetic.

**Hardware:** Same as Example 2.

### Build and Flash

```bash
make reset
make EXAMPLE=example_3 run
```

### Initial Output (Before Implementation)

```text
*** NEW READING ***
Reading temperature...
Temperature calculated value = 0.000000000 millidegrees Celsius
Temperature correct value = 24558.001114550 millidegrees Celsius
Wrong

Reading acceleration values...
Acceleration calculated values: x=0.000000000 y=0.000000000 z=0.000000000
Acceleration correct values: x=0.413390205 y=2.547690675 z=9.620185545
Wrong
```

### Why Fixed-Point?

Embedded systems often avoid floating-point for:

- **Speed** - Integer operations are faster (no FPU needed)
- **Size** - Smaller code (no floating-point library)
- **Precision** - Controlled decimal places

**Example:** To represent 0.00003824593:

- Numerator: 38245
- Denominator: 1000000000
- Calculation: `(raw × 38245) / 1000000000`

### Challenge: Implement Conversion Formulas

**File:** `src/examples/example_3/example_3.c`

Look for two `TODO` sections where you'll implement the conversions.

#### Temperature Formula

$$\text{TEMPERATURE} = \frac{(\text{RAW} \cdot \text{OFFSET\_DIV} + \text{OFFSET}) \cdot \text{SCALE\_FACTOR}}{\text{OFFSET\_DIV} \cdot \text{SCALE\_FACTOR\_DIV}}$$

**Available macros:**

| Macro | Value | Represents |
|-------|-------|------------|
| `ADXL355_TEMP_OFFSET` | -211125 | -2111.25 × 100 |
| `ADXL355_TEMP_OFFSET_DIV` | 100 | |
| `ADXL355_TEMP_SCALE_FACTOR` | -110497238 | -110.497238 × 10⁶ |
| `ADXL355_TEMP_SCALE_FACTOR_DIV` | 1000000 | |

**Implementation:**

```c
int64_t temp_dividend = ((int64_t)raw_temp * ADXL355_TEMP_OFFSET_DIV + ADXL355_TEMP_OFFSET) 
                        * ADXL355_TEMP_SCALE_FACTOR;
int64_t temp_divisor = ADXL355_TEMP_OFFSET_DIV * ADXL355_TEMP_SCALE_FACTOR_DIV;
```

**⚠️ CRITICAL - Prevent Overflow:**

```c
int64_t temp_dividend = ((int64_t)raw_temp * ADXL355_TEMP_OFFSET_DIV + ...
                        //  ↑ Must cast here!
```

When multiplying 32-bit integers, intermediate results exceed 32 bits. Casting to `int64_t` ensures 64-bit arithmetic throughout.

#### Acceleration Formula

$$\text{ACCELERATION} = \frac{\text{RAW} \cdot \text{SCALE\_FACTOR\_MUL}}{\text{SCALE\_FACTOR\_DIV}}$$

**Available macros:**

| Macro | Value |
|-------|-------|
| `ADXL355_ACC_SCALE_FACTOR_MUL` | 38245 |
| `ADXL355_ACC_SCALE_FACTOR_DIV` | 1000000000 |

**Implementation:**

```c
int64_t x_dividend = (int64_t)raw_x * ADXL355_ACC_SCALE_FACTOR_MUL;
int64_t y_dividend = (int64_t)raw_y * ADXL355_ACC_SCALE_FACTOR_MUL;
int64_t z_dividend = (int64_t)raw_z * ADXL355_ACC_SCALE_FACTOR_MUL;
int64_t accel_divisor = ADXL355_ACC_SCALE_FACTOR_DIV;
```

### Build and Test

```bash
make reset
make EXAMPLE=example_3 run
```

### Expected Output (After Implementation)

```text
*** NEW READING ***
Reading temperature...
Temperature calculated value = 24558.001114550 millidegrees Celsius
Temperature correct value = 24558.001114550 millidegrees Celsius
Correct

Reading acceleration values...
Acceleration calculated values: x=0.413390205 y=2.547690675 z=9.620185545
Acceleration correct values: x=0.413390205 y=2.547690675 z=9.620185545
Correct
```

### Understanding the Results

**Acceleration values represent:**

- **X-axis ≈ 0.41 m/s²** - Slight tilt left/right
- **Y-axis ≈ 2.55 m/s²** - Moderate tilt forward/backward  
- **Z-axis ≈ 9.62 m/s²** - Vertical component of Earth's gravity (9.81 m/s²)

**Try this:** Lay the board perfectly flat. Z should read ~9.81 m/s², X and Y near zero.

---

## Example 4: Interactive Game

**Objective:** Control a game by tilting the accelerometer board.

**Hardware:** Same as Examples 2-3.

### Overview

This example demonstrates real-time sensor streaming using the IIO (Industrial I/O) framework. The firmware streams acceleration data via UART, and a Python game reads these values to control gameplay.

### Build IIO Firmware

**Close picocom first** (Python needs the serial port).

```bash
cd ~/workshop_baremetal/no-OS/projects/workshop
make reset
make EXAMPLE=iio_example run
```

### Run the Game

```bash
cd ~/workshop_baremetal/play
python3 play.py
```

### Gameplay

- **Goal:** Place circuit components on the PCB
- **Controls:** Tilt the accelerometer board to move components
- **Placement:** Align with silkscreen outlines
- **Challenge:** Don't disconnect wires!

### How It Works

**Communication chain:**

```text
Python ↔ UART ↔ MAX78000 ↔ SPI ↔ ADXL355
 (IIO)   57600              1MHz
```

**IIO Framework** provides a standard interface:

- Linux-compatible sensor protocol
- Attributes for data access  
- Enables user-space applications

**Firmware loop:**

1. Read X/Y/Z acceleration from ADXL355
2. Convert raw values to m/s²
3. Transmit via UART using IIO protocol
4. Python reads and updates game graphics in real-time

---

## Troubleshooting

### Build Issues

```bash
# Verify environment
echo $MAXIM_LIBRARIES
echo $PLATFORM
echo $TARGET

# Clean rebuild
make reset
make EXAMPLE=example_1
```

**For detailed troubleshooting, see the project README.**

### Wrong Sensor Values

- Verify all 6 wires connected correctly
- Check wiring table in project README
- Ensure 3V3 and GND connected first
- Test with multimeter if available

### Game Not Responding

- Ensure picocom/screen is closed (releases serial port)
- Verify `iio_example` firmware flashed (not example_1/2/3)
- Check Python has serial port access
- Try: `sudo chmod 666 /dev/ttyACM0`

**For USB/serial troubleshooting, see root README troubleshooting section.**

---

## Next Steps

1. **Modify Example 2:** Display temperature in Fahrenheit
2. **Enhance Example 3:** Calculate acceleration magnitude: $\sqrt{x^2 + y^2 + z^2}$
3. **Game Features:** Add scoring, timer, or difficulty levels
4. **Experiment:** Try different SPI speeds in `parameters.h`, observe behavior
5. **Deep Dive:** Read ADXL355 datasheet, explore register configuration

---

## Resources

- **no-OS Documentation:** <https://analogdevicesinc.github.io/no-OS/>
- **ADXL355 Datasheet:** <https://www.analog.com/adxl355>
- **MAX78000 User Guide:** <https://www.analog.com/max78000>
- **Project README:** Hardware details, pin configuration, creating new examples
