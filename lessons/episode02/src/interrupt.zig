const std = @import("std");
pub const JumpInstruction = enum {
    jmp,
    rjmp,

    pub fn to_string(insn: JumpInstruction) []const u8 {
        return switch (insn) {
            .jmp => "jmp",
            .rjmp => "rjmp",
        };
    }
};

pub fn generate_vector_table_empty(comptime jump_insn: JumpInstruction) []const u8 {
    var asm_str: []const u8 = jump_insn.to_string() ++ " my_start\n"; // 0

    for (0..26) |_| {
        asm_str = asm_str ++ jump_insn.to_string() ++ " _unhandled_vector\n";
    }

    return asm_str;
}
pub fn generate_vector_table_asm(comptime jump_insn: JumpInstruction) []const u8 {
    var asm_str: []const u8 = jump_insn.to_string() ++ " my_start\n"; // 0
    asm_str = asm_str ++ jump_insn.to_string() ++ " _isr_int0\n"; //1

    for (2..28 - 2) |i| {
        if (i == 11) {
            asm_str = asm_str ++ jump_insn.to_string() ++ " _isr_tcmp1\n"; // add timer vector
            continue;
        }
        asm_str = asm_str ++ jump_insn.to_string() ++ " _unhandled_vector\n";
    }

    return asm_str;
}
