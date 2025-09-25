# Workshop Project

Embedded software examples for MAX78000FTHR using the no-OS framework.

**Prerequisites:** Complete the setup in `~/workshop_baremetal/README.md` first.

## Quick Start

```bash
# Set environment
export MAXIM_LIBRARIES=$HOME/workshop_baremetal/MAX78000SDK/Libraries
export PLATFORM=maxim
export TARGET=max78000

# Build and flash
make reset
make EXAMPLE=example_1 run
```

**For detailed workshop instructions, see [HANDS_ON.md](HANDS_ON.md)**

## Project Structure

```text
.
├── HANDS_ON.md            # Workshop guide
├── Makefile               # Build system
├── README.md              # This file
├── src.mk                 # Source organization
└── src/
    ├── common/
    │   ├── common_data.c  # Shared initialization
    │   └── common_data.h  
    ├── examples/
    │   ├── example_1/     # UART Hello World
    │   ├── example_2/     # SPI sensor reading
    │   ├── example_3/     # Data conversion
    │   ├── dummy/         # Template for new examples
    │   └── iio_example/   # IIO framework demo
    └── platform/
        └── maxim/
            ├── main.c           # Entry point
            ├── parameters.c     # Platform config
            ├── parameters.h     # Pin definitions
            └── platform_src.mk  # Platform sources
```

## Build System

### Commands

```bash
make reset                    # Clean everything (do this first!)
make EXAMPLE=<name>          # Build
make EXAMPLE=<name> run      # Build and flash to board
make clean                    # Clean build artifacts only
```

### Available Examples

| Example | Description |
|---------|-------------|
| `example_1` | UART Hello World - verifies toolchain |
| `example_2` | SPI sensor communication |
| `example_3` | Fixed-point math and conversion |
| `dummy` | Template for creating new examples |
| `iio_example` | IIO framework demonstration |

**Note:** Example 4 (IIO streaming) is covered in HANDS_ON.md with additional setup steps.

### Build Tips

- **First build?** Use `make reset` first
- **Faster builds:** `make -j$(nproc) EXAMPLE=example_1`
- **After environment changes:** `make reset`

## Hardware Reference

### MAX78000FTHR Specs

- **MCU:** MAX78000 (ARM Cortex-M4 @ 100MHz)
- **Memory:** 512KB Flash, 128KB SRAM
- **Programming:** USB via CMSIS-DAP

### Pin Configuration

See `src/platform/maxim/parameters.h` for complete definitions:

```c
// UART (USB serial console)
#define UART_DEVICE_ID   0          // UART0
#define UART_BAUDRATE    57600

// SPI (sensor communication)
#define SPI_DEVICE_ID    1          // SPI1
#define SPI_CS           1          // P0_11
#define SPI_BAUDRATE     1000000    // 1 MHz
```

### ADXL355 Wiring

For Examples 2-4:

| MAX78000FTHR | Signal | ADXL355 Pin |
|--------------|--------|-------------|
| 3V3          | Power  | 6 or 12     |
| GND          | Ground | 5 or 11     |
| P0_11        | CS     | 1           |
| P0_5         | MOSI   | 2           |
| P0_6         | MISO   | 3           |
| P0_7         | SCK    | 4           |
| P0_19        | DRDY   | 10 (optional) |

**Wiring tips:**

- Connect power first, then signals
- Keep wires short
- Double-check before powering on

## Serial Console

### Connect to Board

Find your device:

```bash
ls /dev/ttyACM* /dev/ttyUSB*
```

Connect with picocom:

```bash
picocom -b 57600 /dev/ttyACM0
```

**Exit:** `Ctrl+A` then `Ctrl+X`

Or with screen:

```bash
screen /dev/ttyACM0 57600
```

**Exit:** `Ctrl+A` then `K` then `Y`

### Serial Settings

- Baud: 57600
- Data: 8N1 (8 bits, no parity, 1 stop bit)
- Flow control: None

## Creating New Examples

### Quick Template

1. **Create directory:**

   ```bash
   mkdir -p src/examples/my_example
   ```

2. **Copy template:**

   ```bash
   cp src/examples/dummy/dummy_example.c src/examples/my_example/my_example.c
   ```

3. **Key points:**
   - Keep `example_main()` as entry point (not `main()`)
   - Use `adxl355_uart_ip` for UART (from common_data.h)
   - Use `adxl355_spi_ip` and `adxl355_ip` for sensor
   - Follow error handling pattern with `goto error`

4. **Build:**

   ```bash
   make reset
   make EXAMPLE=my_example run
   ```

### Example Structure

Study `src/examples/dummy/dummy_example.c` for the pattern:

```c
int example_main()
{
    int ret;

    // Initialize UART for console
    ret = no_os_uart_init(&uart_desc, &adxl355_uart_ip);
    if (ret)
        goto error;

    // Your code here

error:
    // Cleanup
    no_os_uart_remove(uart_desc);
    return ret;
}
```

## Documentation

- **HANDS_ON.md** - Detailed workshop guide
- **no-OS API:** <https://analogdevicesinc.github.io/no-OS/>
- **MAX78000 User Guide:** <https://www.analog.com/max78000>
- **ADXL355 Datasheet:** <https://www.analog.com/adxl355>

---

**Ready to start?** Open [HANDS_ON.md](HANDS_ON.md) for the workshop guide!
