const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .avr,
        .os_tag = .freestanding,
        .cpu_model = .{
            .explicit = &std.Target.avr.cpu.atmega328p,
        },
    });
    // const optimize = b.standardOptimizeOption(.{});

    // try to use zig single compilation unit
    const exe = b.addExecutable(.{
        .name = "blinky.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
        }),
    });
    exe.bundle_compiler_rt = false;
    exe.setLinkerScript(b.path("src/linker_simple.ld"));

    // Install in at bin/blinky.elf
    b.installArtifact(exe);

    const assembly = exe.getEmittedAsm();

    // Install Assembly
    const install_asm = b.addInstallFile(assembly, "firmware/blinky.S");
    b.getInstallStep().dependOn(&install_asm.step);

    // avr-objcopy -j .text -j .data -O ihex blinky.elf blinky.hex
    const strip_command = b.addSystemCommand(&.{
        "avr-objcopy",
        "-j",
        ".text",
        "-j",
        ".data",
        "-O",
        "ihex",
    });
    strip_command.addFileArg(exe.getEmittedBin());
    const binary = strip_command.addOutputFileArg("blinky.hex");

    const install_hex = b.addInstallFile(binary, "firmware/blinky.hex");
    b.getInstallStep().dependOn(&install_hex.step);

    // Custom upload command
    const upload_cmd = b.addSystemCommand(&.{
        "avrdude",
        "-C",
        "src/avrdude.conf",
        "-p",
        "atmega328p",
        "-c",
        "arduino",
        "-P",
        "COM4",
        "-b",
        "115200",
        "-U",
        "flash:w:zig-out/firmware/blinky.hex:i",
    });

    // Upload only after the hex has been installed
    upload_cmd.step.dependOn(&install_hex.step);

    // `zig build upload`
    const upload_step = b.step("upload", "Build and upload the firmware");
    upload_step.dependOn(&upload_cmd.step);
}
