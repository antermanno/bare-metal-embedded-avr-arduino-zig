const at328p = @import("atmega328p.zig");
const reg = at328p.reg;
const assembly = @import("assembly.zig");
const sei = assembly.sei;
const cli = assembly.cli;

extern var timer1_millis: u32;

pub fn TIMER1_COMPA() void {
    timer1_millis += 1;
}

const TCCR1B = reg.TC1.TCCR1B;
const OCR1A = reg.TC1.OCR1A;
const TIMSK1 = reg.TC1.TIMSK1;

const WGM12 = 3;
const CS11 = 1;
const OCIE1A = 1;

pub fn init_millis(f_cpu: u32) void {
    //when timer1 is this value, 1ms has passed
    const ctc_match_overflow: u32 = f_cpu / 8000;

    // (Set timer to clear when matching ctc_match_overflow) | (Set clock divisor to 8)
    TCCR1B.modify(.{ .WGM1 = 0b01, .CS1 = 0b010 });
    // set the overflow in the overflow-Compare-Register?
    OCR1A.* = @intCast(ctc_match_overflow); // explicit u32 → u16

    TIMSK1.modify(.{ .OCIE1A = 0b1 }); // interrupt on OCR1A match
}

// reg.TC1.TCCR1A.write_raw(0x00); // OC2A and OC2B disconnected; Wave Form Generator: Normal Mode
// // registers.TC1.TCCR1B = (1<<WGM12) | (1<<CS12) | (1<<CS10); // CTC-Mode 4, prescaler = 1024;
// reg.TC1.TCCR1B.modify(.{ .CS1 = 0b101, .WGM1 = 0b01 }); // CTC-Mode 4, prescaler = 1024;
// // registers.TC1.TIMSK1 = (1<<OCIE1A); // interrupt on OCR1A match
// reg.TC1.TIMSK1.modify(.{ .OCIE1A = 0b1 }); // interrupt on OCR1A match
// reg.TC1.OCR1A.* = 31249;

pub fn millis() u32 {
    cli();
    defer sei();
    return timer1_millis;
}
