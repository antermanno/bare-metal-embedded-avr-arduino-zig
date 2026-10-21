// zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
const std = @import("std");
const regs = @import("atmega328p.zig").reg;
const gpio = @import("gpio.zig");

const PORTB = regs.PORTB.PORTB;

export fn _start() noreturn {
    // Set pine 5 of Port B to output mode (arduino pin13)
    regs.PORTB.DDRB.* |= (1 << 5);
    gpio.init(.D13, .out);

    while (true) {
        // Switch the state of the led
        gpio.toggle(.D13);

        // volatile counter
        var i: u32 = 0;
        const counter: *volatile u32 = &i;
        while (i < 200000) : (counter.* += 1) {
            asm volatile ("nop");
        }
    }
}
