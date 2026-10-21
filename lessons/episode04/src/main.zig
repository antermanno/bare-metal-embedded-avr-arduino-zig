// zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
const std = @import("std");
const reg = @import("atmega328p.zig").reg;
const gpio = @import("gpio.zig");
const uart = @import("uart.zig");
// Define pointers to hardware registers of atmega328p.

//
const data_n = 2;
const shift_n = 3;
const latch_n = 4;

const PORTB = reg.PORTB.PORTB;
const DDRB = reg.PORTB.DDRB;

fn serialOut(value: bool) void {
    if (value) {
        PORTB.* |= (1 << data_n);
    } else {
        PORTB.* &= ~@as(u8, 1 << data_n);
    }
}

fn shiftOut(value: bool) void {
    if (value) {
        PORTB.* |= (1 << shift_n);
    } else {
        PORTB.* &= ~@as(u8, 1 << shift_n);
    }
}

fn latchOut(value: bool) void {
    if (value) {
        PORTB.* |= (1 << latch_n);
    } else {
        PORTB.* &= ~@as(u8, 1 << latch_n);
    }
}

fn write_ch(char: u8) callconv(.avr_builtin) void {
    // uart.write_ch('0');
    // uart.write_ch('b');
    inline for (0..8) |i| {
        const shifted = char >> i;
        if (shifted & 1 != 0) {
            serialOut(true);
            // uart.write_ch('1');
        } else {
            serialOut(false);
            // uart.write_ch('0');
        }

        delay(1);
        shiftOut(false);
        delay(1);
        shiftOut(true);
        delay(1);
    }

    //latch flash
    latchOut(false);
    delay(1);
    latchOut(true);
    delay(1);
    // uart.write_ch('\r');
    // uart.write_ch('\n');
}

export fn _start() noreturn {
    // Set pin 5 of Port B to output mode (arduino pin13)
    // uart.init(9600);
    // Set all pins to output
    DDRB.* |= (1 << latch_n) | (1 << data_n) | (1 << shift_n);

    // set the led to zero
    delay(10);
    write_ch(0);
    delay(100);

    var count: u8 = 0;
    // use the count overflow to reset
    while (true) : (count += 1) {
        delay(5);
        write_ch(@intCast(count));
    }
    asm volatile ("sleep");
    while (true) {}
}

fn delay(comptime amount: u32) void {
    var i: u32 = 0;
    const counter: *volatile u32 = &i;
    while (i < 1000 * amount) : (counter.* += 1) {
        asm volatile ("nop");
    }
}
