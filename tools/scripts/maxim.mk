VSCODE_SUPPORT = yes

ifndef MAXIM_LIBRARIES
$(error MAXIM_LIBRARIES not defined.$(ENDL))
endif

export INCLUDE_OTHER_PATTERN	= $(PROJECT_BUILD)/root/MaximSDK/Libraries
export INCLUDE_OTHER_CORRECTED	= $(MAXIM_LIBRARIES)
CC=arm-none-eabi-gcc
AR=arm-none-eabi-ar
AS=arm-none-eabi-gcc
GDB=arm-none-eabi-gdb
GDB_PORT = 50000
OC=arm-none-eabi-objcopy
SIZE=arm-none-eabi-size

PYTHON = python
ARM_COMPILER_PATH = $(realpath $(dir $(shell find $(MAXIM_LIBRARIES)/../Tools/GNUTools -wholename "*bin/$(CC)" -o -name "$(CC).exe")))

# Use the user provided compiler if the SDK doesn't contain it.
ifeq ($(ARM_COMPILER_PATH),)
ARM_COMPILER_PATH = $(realpath $(dir $(shell which $(CC))))
endif
export COMPILER_INTELLISENSE_PATH = $(ARM_COMPILER_PATH)/$(CC)
export PATH := $(PATH):$(ARM_COMPILER_PATH)

CREATED_DIRECTORIES += Maxim
PROJECT_BUILD = $(BUILD_DIR)/app
COMPILER = gcc

ifneq "$(HEAP_SIZE)" ""
CFLAGS+=-D__HEAP_SIZE=$(HEAP_SIZE)
endif
ifneq "$(STACK_SIZE)" ""
CFLAGS+=-D_STACK_SIZE=$(STACK_SIZE)
endif

TARGET?=max32660
TARGET_NUMBER:=$(word 2,$(subst x, ,$(subst X, ,$(TARGET))))
TARGET_UCASE=$(addprefix MAX,$(TARGET_NUMBER))
TARGET_LCASE=$(addprefix max,$(TARGET_NUMBER))
TARGET_HARDWARE=TARGET=$(TARGET)

PLATFORM_DRIVERS := $(NO-OS)/drivers/platform/maxim/$(TARGET_LCASE)

# Choose between the v1 and v2 version of the SPI driver for MAX32690 and MAX78002
MXC_SPI_VERSION ?= v1

ifeq ($(TARGET_LCASE), $(filter $(TARGET_LCASE),max32655 max32690))
include $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Source/GCC/$(TARGET_LCASE)_memory.mk
endif
include $(MAXIM_LIBRARIES)/PeriphDrivers/$(TARGET_LCASE)_files.mk

HEX=$(basename $(BINARY)).hex
TARGET_REV=0x4131

TARGETCFG=$(TARGET_LCASE).cfg

# =============================================================================
# OpenOCD Configuration with ARM64 Support
# =============================================================================

# Detect host architecture
HOST_ARCH := $(shell uname -m)

ifeq ($(HOST_ARCH),aarch64)
    # ARM64 host detected
    
    # Priority 1: User-specified path (highest priority)
    ifdef OPENOCD_PATH
        OPENOCD_BIN := $(OPENOCD_PATH)
        ifdef OPENOCD_SCRIPTS_PATH
            OPENOCD_SCRIPTS := $(OPENOCD_SCRIPTS_PATH)
        else
            # Derive scripts path from binary path
            OPENOCD_SCRIPTS := $(dir $(OPENOCD_PATH))../
        endif
        $(info [ARM64] Using custom OpenOCD: $(OPENOCD_BIN))
    else
        # Priority 2: Workshop standard location (auto-detect)
        AI8X_OPENOCD := $(wildcard $(HOME)/workshop_baremetal/ai8x-synthesis/openocd/bin/Linux_aarch64/openocd)
        
        ifneq ($(AI8X_OPENOCD),)
            OPENOCD_BIN := $(dir $(AI8X_OPENOCD))
            OPENOCD_SCRIPTS := $(HOME)/workshop_baremetal/ai8x-synthesis/openocd
            $(info [ARM64] Using Workshop OpenOCD: $(OPENOCD_BIN))
        else
            # Priority 3: Error with helpful message
            $(error $(ENDL)\
╔════════════════════════════════════════════════════════════╗$(ENDL)\
║ ARM64 OpenOCD Not Found                                    ║$(ENDL)\
╚════════════════════════════════════════════════════════════╝$(ENDL)\
$(ENDL)\
OpenOCD not found in: ~/workshop_baremetal/ai8x-synthesis$(ENDL)\
$(ENDL)\
Option 1 - Install to workshop folder (recommended):$(ENDL)\
  cd ~/workshop_baremetal$(ENDL)\
  git clone https://github.com/analogdevicesinc/ai8x-synthesis.git$(ENDL)\
$(ENDL)\
Option 2 - Use custom location:$(ENDL)\
  export OPENOCD_PATH=/path/to/openocd/bin/Linux_aarch64$(ENDL)\
  export OPENOCD_SCRIPTS_PATH=/path/to/openocd$(ENDL)\
$(ENDL)\
Then run 'make run' again.$(ENDL))
        endif
    endif
    
    # Detect OpenOCD directory layout (ai8x-synthesis vs standard)
    OPENOCD_TARGET_AT_ROOT := $(wildcard $(OPENOCD_SCRIPTS)/$(TARGET_LCASE).cfg)
    ifneq ($(OPENOCD_TARGET_AT_ROOT),)
        # ai8x-synthesis style: target configs at root level
        OPENOCD_TARGET_CFG := $(TARGET_LCASE).cfg
        $(info [ARM64] Detected ai8x-synthesis OpenOCD layout)
    else
        # Standard OpenOCD: target configs in target/ subdirectory
        OPENOCD_TARGET_CFG := target/$(TARGET_LCASE).cfg
        $(info [ARM64] Detected standard OpenOCD layout)
    endif
    
else
    # x86_64 host: Use MaximSDK OpenOCD (standard layout)
    OPENOCD_BIN := $(MAXIM_LIBRARIES)/../Tools/OpenOCD
    OPENOCD_SCRIPTS := $(MAXIM_LIBRARIES)/../Tools/OpenOCD/scripts
    OPENOCD_TARGET_CFG := target/$(TARGET_LCASE).cfg
endif

# Default values if not set (should not happen, but safety net)
OPENOCD_BIN ?= $(MAXIM_LIBRARIES)/../Tools/OpenOCD
OPENOCD_SCRIPTS ?= $(MAXIM_LIBRARIES)/../Tools/OpenOCD/scripts
OPENOCD_TARGET_CFG ?= target/$(TARGET_LCASE).cfg

# =============================================================================
# End OpenOCD Configuration
# =============================================================================

GDB_PATH=$(ARM_COMPILER_PATH)
OPENOCD_SVD=$(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Include
TARGETSVD=$(TARGET)
VSCODE_CMSISCFG_FILE="interface/cmsis-dap.cfg","target/$(TARGET).cfg"

LDFLAGS += -mcpu=cortex-m4 	\
	-Wl,--gc-sections 	\
	--specs=nosys.specs	\
	-mfloat-abi=$(CFLAGS_MFLOAT_TYPE) 	\
	-mfpu=fpv4-sp-d16 	\
	--entry=Reset_Handler		
	
CFLAGS += -mthumb                                                                 \
        -mcpu=cortex-m4                                                         \
        -mfloat-abi=$(CFLAGS_MFLOAT_TYPE)                                       \
        -mfpu=fpv4-sp-d16                                                       \
        -Wa,-mimplicit-it=thumb                                                 \
        -fsingle-precision-constant                                             \
        -ffunction-sections                                                     \
        -fdata-sections                                                         \
        -MD                                                                     \
        -Wall                                                                   \
        -Wdouble-promotion                                                      \
        -Wno-format                                                      \
	-g3									\
	-c	

ASFLAGS += -x assembler-with-cpp

ASFLAGS += $(PROJ_AFLAGS)
CFLAGS += -DTARGET_REV=$(TARGET_REV) \
	-DTARGET=$(TARGET_LCASE)		\
	-DMAXIM_PLATFORM		\
	-DTARGET_NUM=$(TARGET_NUMBER)

SRC_TMP = $(foreach src,$(PERIPH_DRIVER_C_FILES),$(word 2,$(subst PeriphDrivers, ,$(src))))
DRIVER_C_FILES = $(foreach src,$(SRC_TMP),$(addprefix $(MAXIM_LIBRARIES)/PeriphDrivers,$(src)))

SRCS += $(DRIVER_C_FILES)
INCLUDE_DIR_TMP = $(foreach src,$(PERIPH_DRIVER_INCLUDE_DIR),$(word 2,$(subst PeriphDrivers, ,$(src))))
DRIVER_INCLUDE_DIR = $(foreach src,$(INCLUDE_DIR_TMP),$(addprefix $(MAXIM_LIBRARIES)/PeriphDrivers,$(src)))

ifeq ($(OS),Windows_NT)
INCLUDE_DIR_TMP += /Include/$(TARGET_UCASE)
endif

INCS += $(foreach dir,$(DRIVER_INCLUDE_DIR), $(wildcard $(dir)/*.h))

LSCRIPT += $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Source/GCC/$(TARGET_LCASE).ld
ASM_SRCS += $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Source/GCC/startup_$(TARGET_LCASE).S
SRCS += $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Source/heap.c
SRCS += $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Source/system_$(TARGET_LCASE).c
INCS += $(wildcard $(MAXIM_LIBRARIES)/CMSIS/Include/*.h)
INCS += $(wildcard $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Include/*.h)

ifeq ($(TARGET_LCASE), max32650)
INCS := $(filter-out $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Include/mxc_device.h, $(INCS))
endif

ifeq ($(NO_OS_USB_UART),y)
SRCS +=	$(MAXIM_LIBRARIES)/MAXUSB/src/core/usb_event.c
INCS += $(MAXIM_LIBRARIES)/MAXUSB/include/core/usb.h \
	$(MAXIM_LIBRARIES)/MAXUSB/include/core/usb_protocol.h \
	$(MAXIM_LIBRARIES)/MAXUSB/include/core/usb_event.h \
	$(PLATFORM_DRIVERS)/maxim_usb_uart_descriptors.h
SRC_DIRS += $(MAXIM_LIBRARIES)/MAXUSB/src/core/musbhsfc \
	$(MAXIM_LIBRARIES)/MAXUSB/src/enumerate \
	$(MAXIM_LIBRARIES)/MAXUSB/src/devclass \
	$(MAXIM_LIBRARIES)/MAXUSB/include/core/musbhsfc \
	$(MAXIM_LIBRARIES)/MAXUSB/include/enumerate \
	$(MAXIM_LIBRARIES)/MAXUSB/include/devclass
endif

$(PLATFORM)_project:
	$(call print,Building for target $(TARGET_LCASE))
	$(call print,Creating IDE project)
	$(call mk_dir,$(BUILD_DIR))
	$(call mk_dir,$(VSCODE_CFG_DIR))
	$(call set_one_time_rule,$@)
	$(MAKE) --no-print-directory $(PROJECT_TARGET)_configure

$(PROJECT_TARGET)_configure:
	$(file > $(CPP_PROP_JSON).default,$(CPP_FINAL_CONTENT))
	$(file > $(SETTINGSJSON).default,$(VSC_SET_CONTENT))
	$(file > $(LAUNCHJSON).default,$(VSC_LAUNCH_CONTENT))
	$(file > $(TASKSJSON).default,$(VSC_TASKS_CONTENT))

	[ -s $(CPP_PROP_JSON) ]	&& echo '.vscode/c_cpp_properties.json already exists, not overwriting'	|| cp $(CPP_PROP_JSON).default $(CPP_PROP_JSON)
	[ -s $(SETTINGSJSON) ] 	&& echo '.vscode/settings.json already exists, not overwriting'			|| cp $(SETTINGSJSON).default $(SETTINGSJSON)
	[ -s $(LAUNCHJSON) ] 	&& echo '.vscode/launch.json already exists, not overwriting'			|| cp $(LAUNCHJSON).default $(LAUNCHJSON)
	[ -s $(TASKSJSON) ] 	&& echo '.vscode/tasks.json already exists, not overwriting'			|| cp $(TASKSJSON).default $(TASKSJSON)

	rm $(CPP_PROP_JSON).default $(SETTINGSJSON).default $(LAUNCHJSON).default $(TASKSJSON).default

$(PLATFORM)_sdkopen:
	code $(PROJECT)

$(PLATFORM)_sdkclean: clean

$(PLATFORM)_reset:
	$(call remove_dir,$(VSCODE_CFG_DIR))

$(PLATFORM)_sdkbuild: build

.PHONY: $(BINARY).gdb
$(BINARY).gdb:
	@echo target remote localhost:$(GDB_PORT) > $(BINARY).gdb	
	@echo load $(BINARY) >> $(BINARY).gdb	
	@echo file $(BINARY) >> $(BINARY).gdb
	@echo b main >> $(BINARY).gdb	
	@echo monitor reset halt >> $(BINARY).gdb	
ifneq ($(OS),Windows_NT)
	@echo tui enable >> $(BINARY).gdb
endif	
	@echo c >> $(BINARY).gdb	

$(HEX): $(BINARY)
	$(call print,[HEX] $(notdir $@))
	$(OC) -O ihex $(BINARY) $(HEX)
	$(call print,$(notdir $@) is ready)

.NOTINTERMEDIATE: $(MAXIM_LIBRARIES)/CMSIS/Device/Maxim/$(TARGET_UCASE)/Source/GCC/startup_$(TARGET_LCASE).s

$(PLATFORM)_post_build: $(HEX)

clean_hex:
	@$(call print,[Delete] $(HEX))
	-$(call remove_file,$(HEX))

clean: clean_hex

.PHONY: $(PLATFORM)_run
$(PLATFORM)_run: all $(BINARY).id
	$(OPENOCD_BIN)/openocd -s "$(OPENOCD_SCRIPTS)" \
		-f $(BINARY).id \
		-f $(OPENOCD_TARGET_CFG) \
		-c "program $(BINARY) verify reset exit"

.PHONY: debug
debug: all $(BINARY).gdb start_openocd
	$(GDB) --command=$(BINARY).gdb

.PHONY: start_openocd
start_openocd:
	$(OPENOCD_BIN)/openocd -s "$(OPENOCD_SCRIPTS)" 	\
		-f interface/cmsis-dap.cfg -f $(OPENOCD_TARGET_CFG) -c "init" &
