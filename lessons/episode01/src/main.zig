// zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
const std = @import("std");
// Define pointers to hardware registers of atmega328p.
// Data Direction register
const DDRB: *volatile u8 = @ptrFromInt(0x24);
// Output register for PORT B
const PORTB: *volatile u8 = @ptrFromInt(0x25);

export fn _start() noreturn {
    // Set pine 5 of Port B to output mode (arduino pin13)
    DDRB.* |= (1 << 5);

    while (true) {
        // Switch the state of the led
        PORTB.* ^= (1 << 5);

        // volatile counter
        var i: u32 = 0;
        const counter: *volatile u32 = &i;
        while (i < 200000) : (counter.* += 1) {
            asm volatile ("nop");
        }
    }
}
