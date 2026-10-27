// zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
const std = @import("std");
pub const board = @import("atmega328p.zig");
const reg = board.reg;

const gpio = @import("gpio.zig");
const uart = @import("uart.zig");
const generate_vec_table = @import("interrupt.zig").generate_vector_table_empty;

pub const interrupts = struct {
    pub fn INT0() void {
        @call(.always_inline, delay, .{10});
    }
};
fn vector_table() linksection(".text") callconv(.naked) noreturn {
    asm volatile (generate_vec_table(.jmp));
}

pub fn export_startup_logic() void {
    _ = interrupts;
    @export(&vector_table, .{
        .name = "_start",
    });
}
comptime {
    export_startup_logic();
}

export fn _main() noreturn {
    while (true) {}
}

fn delay(comptime amount: u32) void {
    var i: u32 = 0;
    const counter: *volatile u32 = &i;
    while (i < 1000 * amount) : (counter.* += 1) {
        asm volatile ("nop");
    }
}
