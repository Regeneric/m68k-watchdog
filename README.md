### Hardware
If you're using `usbasp` programmer, make sure that you've made right connections to `MISO`, `MOSI`, `SCK` and `RESET` pins.  

Also you HAVE TO use pairs of capcitors (*100 nF + 2-40 uF*) for the filtering of the power supply output.  
Don't forget to use pull-up resistor for `PB5` aka `RESET` pin.  

Default pins on **ATTiny 13A** for Motorola 68000 control:  
 - Motorola 68000 RESET pin is connected to `PB0`
 - Motorola 68000 HALT  pin is connected to `PB2`
 - WTD signal from CPU (whatever it is) is connected to `PB1`  
 - `PB4` act as external reset source i.e. push button  

This watchdog controller is designed to work with **9.6 MHz internal oscillator _divided by /8_** of **ATTiny 13A** aka `1.2 MHz`.  

### Debian
```bash
sudo apt update
sudo apt install avr-gcc avr-libc make

git clone git@github.com:Regeneric/m68k-watchdog.git
cd m68k-watchdog/

make release    # without debug symbols
make debug      # with debug symbols for GDB

# To flash uC
make flash

# To run avr-sim
make sim
```

### Arch
```bash
sudo pacman -Syu
sudo pacman -S avr-gcc avr-libc make

git clone git@github.com:Regeneric/m68k-watchdog.git
cd m68k-watchdog/

make release    # without debug symbols
make debug      # with debug symbols for GDB

# To flash uC
make flash

# To run avr-sim
make sim
```
