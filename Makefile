CC=avr-gcc
AR=avr-ar rcs

MCU=atmega32
F_CPU=16000000UL

CFLAGS=-mmcu=$(MCU) -Os -DF_CPU=$(F_CPU)
AFLAGS=-mmcu=$(MCU) -DF_CPU=$(F_CPU)

CSRC=fiber.c sleep.c
ASRC=switch.S
OBJ=$(CSRC:%.c=%.o) $(ASRC:%.S=%.o)
TARGET=ufiber.a

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o: %.S
	$(CC) -c $(AFLAGS) $< -o $@

%.a: $(OBJ)
	$(AR) $@ $(OBJ)

all: $(TARGET)

clean:
	rm -f $(TARGET) $(OBJ)

.PRECIOUS: %.o
.PHONY: all clean
