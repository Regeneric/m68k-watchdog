MMCU = attiny13a
FCPU=1200000
CFLAGS = -nostdlib -Wl,-e,RESET
CFLAGS_DEBUG = -g3 -Wa,--gstabs
CFLAGS_RELEASE = -s
OBJ_FORMAT = ihex
SOURCE_FILE = main.s
ELF_FILE = main.elf
HEX_FILE = main.hex
PROGRAMMER = avrisp
PROGRAMMER_PORT = /dev/ttyUSB0
PROGRAMMER_BAUD = 19200
PROGRAMMER_MMCU = t13

.PHONY: debug release

debug: 
	avr-gcc -mmcu=$(MMCU) $(CFLAGS) $(CFLAGS_DEBUG) -o $(ELF_FILE) $(SOURCE_FILE)
	avr-objcopy -O $(OBJ_FORMAT) $(ELF_FILE) $(HEX_FILE)

release:
	avr-gcc -mmcu=$(MMCU) $(CFLAGS) $(CFLAGS_RELEASE) -o $(ELF_FILE) $(SOURCE_FILE)
	avr-objcopy -O $(OBJ_FORMAT) $(ELF_FILE) $(HEX_FILE)

flash:
	avrdude -p $(PROGRAMMER_MMCU) -c $(PROGRAMMER) -P $(PROGRAMMER_PORT) -b $(PROGRAMMER_BAUD) -U flash:w:$(HEX_FILE):i

sim: debug
	simavr -g --freq $(FCPU) --mcu $(MMCU) --ff $(HEX_FILE)