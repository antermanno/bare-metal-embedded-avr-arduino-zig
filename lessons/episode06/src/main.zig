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

// LET'S BUILD A COOPERATIVE SCHEDULER
const Task = struct {
    run: *const fn () void,
    interval_ms: u32,
    last_ms: u32,
};

fn task_led_13() void {
    PORTB.* ^= (1 << 5); //Turn on / Turn off the LED
}

fn task_led_12() void {
    PORTB.* ^= (1 << 4); //Turn on / Turn off the LED
}

var tasks = [_]Task{
    .{ .run = &task_led_13, .interval_ms = 1000, .last_ms = 0 },
    .{ .run = &task_led_12, .interval_ms = 500, .last_ms = 0 },
    .{ .run = &task_led_12, .interval_ms = 200, .last_ms = 0 },
};
const DDRB = reg.PORTB.DDRB;
const PORTB = reg.PORTB.PORTB;

export fn _main() noreturn {
    // Set pine 5 of Port B to output mode (arduino pin13)
    DDRB.* |= (1 << 5) | (1 << 4);
    init_millis(CPU_FREQ);
    sei();

    var now: u32 = 0;
    while (true) {
        now = millis();
        inline for (&tasks) |*task| {
            if (now - task.last_ms >= task.interval_ms) {
                task.run();
                task.last_ms = now;
            }
        }
    }
}
