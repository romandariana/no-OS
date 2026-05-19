IIOD=y

CFLAGS += -DNO_OS_NETWORKING

SRC_DIRS += $(NO-OS)/iio/iio_app

INCS += $(DRIVERS)/imu/iio_adis_internals.h \
	$(DRIVERS)/imu/iio_adis1647x.h
SRCS += $(DRIVERS)/imu/iio_adis.c \
	$(DRIVERS)/imu/iio_adis1647x.c

INCS += $(NO-OS)/network/linux_socket/linux_socket.h \
	$(NO-OS)/network/tcp_socket.h \
	$(NO-OS)/network/network_interface.h
SRCS += $(NO-OS)/network/linux_socket/linux_socket.c \
	$(NO-OS)/network/tcp_socket.c
