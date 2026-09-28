Use the zig compiler to build the object file `main.o`.
```bash
zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
```

Use the avr linker to build the elf (Executable Linkable Format) file.
```bash
avr-ld.exe -o firmware.elf .\main.o --verbose
```

Convert the elf file to intel hex format, ready to be flashed into the board.
```bash
avr-objcopy -j .text -j .data -O ihex firmware.elf firmware.hex --verbose
```

Flash into the arduino board.
```bash
avrdude "-C:/../Arduino15\packages\arduino\tools\avrdude\8.0.0-arduino1/etc/avrdude.conf" -p atmega328p -c arduino -P COM4 -b 115200 -U flash:w:firmware.hex:i
```
