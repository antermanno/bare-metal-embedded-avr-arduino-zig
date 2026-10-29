const std = @import("std");
const root = @import("root");
const board = root.board;

const VectorTable = board.VectorTable;
const HandlerFn = board.HandlerFn;
/// The different jump instructions allowed in the "vector table"
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
    const vector_table_info = @typeInfo(VectorTable);
    const int_names = vector_table_info.@"struct".field_names;

    if (@hasDecl(root, "interrupts")) {
        if (@hasDecl(root.interrupts, "RESET"))
            @compileError("Not allowed to overload the reset vector");
    } else {
        var asm_str: []const u8 = jump_insn.to_string() ++ " _main\n"; // 0
        for (0..26) |_| {
            asm_str = asm_str ++ jump_insn.to_string() ++ " _unhandled_vector\n";
        }
        return asm_str;
    }

    var asm_str: []const u8 = jump_insn.to_string() ++ " _main\n"; // 0
    for (int_names[1..]) |vec_name| {
        // find if vec name is in the root interrupt declaration
        if (@hasDecl(root.interrupts, vec_name)) {
            // add the vector_name to the vector jmp table
            asm_str = asm_str ++ jump_insn.to_string() ++ " " ++ vec_name ++ "\n";
            // Get the declared handler function body and calling convention
            const handler = @field(root.interrupts, vec_name);
            const calling_conv = switch (@typeInfo(@TypeOf(handler))) {
                .@"fn" => |info| info.attrs.@"callconv",
                else => {
                    @compileError("Declarations in interrupts must be functions " ++ vec_name ++ "is not a function!");
                },
            };
            // based on the calling convention,
            // wrap the function with avr interrupt function prelude and tail
            const exported_fn = switch (calling_conv) {
                // wrap the naked function with a avr signal calling convention
                .auto => struct {
                    fn wrapper() callconv(.avr_signal) void {
                        @call(.always_inline, handler, .{});
                    }
                }.wrapper,
                .avr_interrupt, .avr_signal => handler,
                else => @compileError("Just leave interrupt handlers with .auto calling convention"),
            };
            // export the symbol, so that it can be read by the program
            @export(&exported_fn, .{ .name = vec_name, .linkage = .strong });
        } else {
            asm_str = asm_str ++ jump_insn.to_string() ++ " _unhandled_vector\n";
        }
    }
    return asm_str;
}

export fn _unhandled_vector() callconv(.avr_signal) void {
    while (true) {}
}
