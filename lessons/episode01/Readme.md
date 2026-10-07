Use the zig compiler to build the object file `main.o`.

Fundamental step of building an executable:
* Compilation
The command `zig build-obj` compiles zig source code into an object file.
This involves two steps.
** Compilation  - the zig compiler compiles the code to assembly for the target
** assembly     - the assembler builds the generated assembly into an elf object file
```bash
zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
```

* Linking
Use the avr linker to build the elf (Executable Linkable Format) file.
The object file is like a puzzle. Each puzzle piece is machine code. The code also holds spaces with references to other pieces of code. The linker's job is to assemble this puzzle, connecting matching pieces and putting the code in the right place.
```bash
avr-ld.exe -o firmware.elf .\main.o 
```

* Intel Hex format
AVR microcontroller operate with the code in hex format. The elf file we just generated contains metadata that are unused by the MCU. For that reasone we use objcopy to strip the sections that we do not need and convert the code in the appropriate format.
```bash
avr-objcopy -j .text -j .data -O ihex firmware.elf firmware.hex 
```

Flash into the arduino board. To find what works for you, check what command does your arduino IDE uses by setting the verbose mode.
```bash
avrdude "-C:/../Arduino15\packages\arduino\tools\avrdude\8.0.0-arduino1/etc/avrdude.conf" -p atmega328p -c arduino -P COM4 -b 115200 -U flash:w:firmware.hex:i
```
