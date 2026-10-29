pub inline fn sei() void {
    asm volatile ("sei");
}

pub inline fn cli() void {
    asm volatile ("cli");
}
