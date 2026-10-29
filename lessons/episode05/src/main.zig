const std = @import("std");
pub const board = @import("atmega328p.zig");
const reg = board.reg;
pub const CPU_FREQ = 16000000;

const gpio = @import("gpio.zig");
const uart = @import("uart.zig");
const generate_vec_table = @import("interrupt.zig").generate_vector_table_empty;

const mill = @import("millis.zig");
const millis = mill.millis;
const init_millis = mill.init_millis;

const assembly = @import("assembly.zig");
const sei = assembly.sei;
const cli = assembly.cli;

// for the millis function to work
pub export var timer1_millis: u32 = undefined;

pub const interrupts = struct {
    // increase the gloabl millis variable
    pub fn TIMER1_COMPA() void {
        timer1_millis += 1;
    }
};

fn vector_table() linksection(".text") callconv(.naked) noreturn {
    asm volatile (generate_vec_table(.jmp));
}

pub fn export_startup_logic() void {
    @export(&vector_table, .{
        .name = "_start",
    });
}
comptime {
    export_startup_logic();
}

const DDRB: *volatile u8 = @ptrFromInt(0x24);
// Output register for PORT B
const PORTB: *volatile u8 = @ptrFromInt(0x25);

export fn _main() noreturn {
    // Set pine 5 of Port B to output mode (arduino pin13)
    DDRB.* |= (1 << 5) | (1 << 4);
    init_millis(CPU_FREQ);
    var prev_millis_p13: u32 = undefined; //the last time the led was toggled
    var prev_millis_p12: u32 = undefined; //the last time the led was toggled
    prev_millis_p12 = millis();
    prev_millis_p13 = millis();
    sei();

    while (true) {
        if (millis() - prev_millis_p13 > 1000) {
            PORTB.* ^= (1 << 5); //Turn on / Turn off the LED
            prev_millis_p13 = millis();
        }

        if (millis() - prev_millis_p12 > 400) {
            PORTB.* ^= (1 << 4); //Turn on / Turn off the LED
            prev_millis_p12 = millis();
        }
    }
}
