// zig build-obj -O ReleaseSmall -target avr-freestanding-none -mcpu atmega328p main.zig
const std = @import("std");
const reg = @import("atmega328p.zig").reg;
const generate_asm = @import("interrupt.zig").generate_vector_table_asm;

pub const CPU_FREQ = 16000000;
const cycles_per_us = CPU_FREQ / 1_000_000;

comptime {
    asm (generate_asm(.jmp));
}

inline fn cli() void {
    asm volatile ("cli");
}

inline fn sei() void {
    asm volatile ("sei");
}

inline fn reti() void {
    asm volatile ("reti");
}

inline fn enable_int0() void {
    // Disable global interrupt
    cli();

    // PD2 (Arduino D2 / INT0) as input.
    reg.PORTD.DDRD.* &= ~@as(u8, (1 << 2));

    // Enable pull-up on PD2.
    reg.PORTD.PORTD.* |= (1 << 2);

    // Configure INT0 for rising edge:
    // ISC01 = 1, ISC00 = 1
    reg.EXINT.EICRA.modify_one("ISC0", 0b10);
    // EICRA |= _BV(ISC01) | _BV(ISC00);

    // Enable INT0.
    reg.EXINT.EIMSK.modify_one("INT", 0b01);
    // EIMSK |= _BV(INT0);

    // Enable global interrupts.
    sei();
}

inline fn enable_timer_interrupt() void {
    cli();
    reg.TC1.TCCR1A.write_raw(0x00); // OC2A and OC2B disconnected; Wave Form Generator: Normal Mode
    // registers.TC1.TCCR1B = (1<<WGM12) | (1<<CS12) | (1<<CS10); // CTC-Mode 4, prescaler = 1024;
    reg.TC1.TCCR1B.modify(.{ .CS1 = 0b101, .WGM1 = 0b01 }); // CTC-Mode 4, prescaler = 1024;
    // registers.TC1.TIMSK1 = (1<<OCIE1A); // interrupt on OCR1A match
    reg.TC1.TIMSK1.modify(.{ .OCIE1A = 0b1 }); // interrupt on OCR1A match
    reg.TC1.OCR1A.* = 31249;
    // DDRD |= (1<<PD7);  // pinMode(7, OUTPUT);
    sei();
}

export fn _isr_int0() callconv(.avr_signal) void {
    reg.PORTB.PORTB.* ^= (1 << 4);
    // uart.write("Interrupt\n");
    delayMs(200);
}

export fn _unhandled_vector() callconv(.avr_signal) void {
    while (true) {}
}
export fn _isr_tcmp1() callconv(.avr_signal) void {
    reg.PORTB.PORTB.* ^= (1 << 5);
    // uart.write("Timer\n");
}

fn main() void {
    enable_int0();
    enable_timer_interrupt();
    // Set pin 12 and 13 as output
    reg.PORTB.DDRB.* |= (1 << 5) | (1 << 4);

    while (true) {
        // sleep, waiting for interrupts
        asm volatile ("sleep");
    }
}

fn delayUs(us: u16) void {
    var remaining = us;
    while (remaining > 0) : (remaining -= 1) {
        inline for (0..cycles_per_us) |_| {
            asm volatile ("nop");
        }
    }
}

fn delayMs(ms: u16) void {
    delayUs(1000 * ms);
}

export fn my_start() noreturn {
    // main();
    clear_bss();
    copy_data_to_ram();
    enable_int0();
    main();
    while (true) {}
}

fn copy_data_to_ram() void {
    asm volatile (
        \\  ; load Z register with the address of the data in flash
        \\  ldi r30, lo8(__data_load_start)
        \\  ldi r31, hi8(__data_load_start)
        \\  ; load X register with address of the data in ram
        \\  ldi r26, lo8(__data_start)
        \\  ldi r27, hi8(__data_start)
        \\  ; load address of end of the data in ram
        \\  ldi r24, lo8(__data_end)
        \\  ldi r25, hi8(__data_end)
        \\  rjmp .L2
        \\
        \\.L1:
        \\  lpm r18, Z+ ; copy from Z into r18 and increment Z
        \\  st X+, r18  ; store r18 at location X and increment X
        \\
        \\.L2:
        \\  cp r26, r24
        \\  cpc r27, r25 ; check and branch if we are at the end of data
        \\  brne .L1
    );
    // Probably a good idea to add clobbers here, but compiler doesn't seem to care
}

fn clear_bss() void {
    asm volatile (
        \\  ; load X register with the beginning of bss section
        \\  ldi r26, lo8(__bss_start)
        \\  ldi r27, hi8(__bss_start)
        \\  ; load end of the bss in registers
        \\  ldi r24, lo8(__bss_end)
        \\  ldi r25, hi8(__bss_end)
        \\  ldi r18, 0x00
        \\  rjmp .L4
        \\
        \\.L3:
        \\  st X+, r18
        \\
        \\.L4:
        \\  cp r26, r24
        \\  cpc r27, r25 ; check and branch if we are at the end of bss
        \\  brne .L3
    );
    // Probably a good idea to add clobbers here, but compiler doesn't seem to care
}
