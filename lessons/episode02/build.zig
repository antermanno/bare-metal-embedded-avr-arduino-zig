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

    const obj = b.addObject(.{
        .name = "blinky_timer.o",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
        }),
    });
    const build_obj = obj.getEmittedBin();
    const assembly = obj.getEmittedAsm();

    // Install Assembly
    const install_asm = b.addInstallFile(assembly, "firmware/blinky_timer.S");
    b.getInstallStep().dependOn(&install_asm.step);

    // avr-ld.exe -o blinky_timer.elf -T linker.ld .\main.o
    const link_command = b.addSystemCommand(&.{
        "avr-ld.exe",
        "--verbose",
        "-o",
    });
    // The returned path is tracked as a build output.
    const elf_file = link_command.addOutputFileArg("blinky_timer.elf");
    link_command.addFileArg(build_obj);

    const install_elf = b.addInstallFile(elf_file, "firmware/blinky_timer.elf");
    b.getInstallStep().dependOn(&install_elf.step);

    // avr-objcopy -j .text -j .data -O ihex blinky_timer.elf blinky.hex
    const strip_command = b.addSystemCommand(&.{
        "avr-objcopy",
        "-j",
        ".text",
        "-j",
        ".data",
        "-O",
        "ihex",
    });
    strip_command.addFileArg(elf_file);
    const binary = strip_command.addOutputFileArg("blinky_timer.hex");

    const install_hex = b.addInstallFile(binary, "firmware/blinky_timer.hex");
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
        "flash:w:zig-out/firmware/blinky_timer.hex:i",
    });

    // Upload only after the hex has been installed
    upload_cmd.step.dependOn(&install_hex.step);

    // `zig build upload`
    const upload_step = b.step("upload", "Build and upload the firmware");
    upload_step.dependOn(&upload_cmd.step);
}
