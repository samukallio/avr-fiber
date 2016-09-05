CC=avr-gcc
AR=avr-ar rcs

MCU=atmega32

CFLAGS=-mmcu=$(MCU)
CFLAGS+=-std=c99 -pedantic
CFLAGS+=-Werror -Wall -Wextra -Wshadow
CFLAGS+=-Os
AFLAGS=-mmcu=$(MCU)

CSRC=fiber.c sleep.c
ASRC=switch.S
OBJ=$(CSRC:%.c=%.o) $(ASRC:%.S=%.o)
TARGET=fiber.a

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
