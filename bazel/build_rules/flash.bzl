"""Macros and rules for flashing cc_binaries to esp"""

load(
    "@bazel_esp8266//platform:boards.bzl",
    "BOARDS",
)

THIS_REPO = "@bazel_esp8266"
MKLITTLEFS = THIS_REPO + "//:mklittlefs"
BOOTLOADER = THIS_REPO + "//:bootloader"
ELF2BIN = THIS_REPO + "//:elf2bin"
UPLOAD = THIS_REPO + "//:upload"
GET_SIZES = THIS_REPO + "//:sizes"
BAUD = 115200

def esp8266_binary(name, cc_binary, board, visibility = None, data = None, data_root = None):
    """
    Declare a binary for esp8266.

    Executing this rule will flash the binary and optionally the data. If nothing changed, nothing will be flashed.
    Any argument to running the command (e.g. --port) will be passed to upload.py

    Args:
      name: Name of the rule to create
      board: Name of the board to use (one of boards.bzl)
      cc_binary: Compiled binary created by cc_binary with the appropriate toolchain
      visibility: Visibility of the rule
      data: Data files to be flashed (a filegroup)
      data_root: Root directory for the data (relative to repository root)
    """
    bin = "{name}.bin".format(name = name)
    board = BOARDS[board]
    native.genrule(
        name = "{bin}_gen".format(bin = bin),
        srcs = [cc_binary, BOOTLOADER, THIS_REPO + "//:xtensa_compiler_bins"],
        tools = [ELF2BIN, GET_SIZES, THIS_REPO + "//:xtensa_readelf"],
        outs = [bin],
        cmd = "$(location {elf2bin}) --eboot $(location {eboot}) --app $(location {app}) --flash_mode {flash_mode} --flash_freq {flash_freq} --flash_size {flash_size} --path $$(dirname $(location {readelf})) --out $@ && $(location {get_sizes}) --elf $(location {app}) --path $$(dirname $(location {readelf})) --mmu '{mmu_flags}'".format(
            elf2bin = ELF2BIN,
            eboot = BOOTLOADER,
            app = cc_binary,
            flash_mode = board["flashmode"],
            flash_freq = board["flash_freq"],
            flash_size = board["flash_size"],
            readelf = THIS_REPO + "//:xtensa_readelf",
            get_sizes = GET_SIZES,
            mmu_flags = " ".join(board["mmu_flags"]),
        ),
    )
    if data and not data_root or data_root and not data:
        fail("Either both or none of data and data root arguments must be specified!")
    data_bin = None
    if data:
        data_bin = "{name}.data.bin".format(name = name)
        native.genrule(
            name = "{data}_gen".format(data = data_bin),
            srcs = [data],
            tools = [MKLITTLEFS],
            outs = [data_bin],
            cmd = "$(location {mklittle}) -c {data_root} -p {little_page} -b {little_block} -s {little_size} $@".format(
                mklittle = MKLITTLEFS,
                data_root = data_root,
                little_page = board["spiffs_pagesize"],
                little_block = board["spiffs_blocksize"],
                little_size = board["spiffs_end"] - board["spiffs_start"],
            ),
            executable = False,
        )
    _flash(
        name = name,
        chip = board["arch"].lower(),
        baud = BAUD,
        code = bin,
        data = data_bin,
        start_data = board["spiffs_start"],
        before = board["before_flash"],
        after = board["after_flash"],
        visibility = visibility,
    )

def _flash_impl(ctx):
    template = ctx.file._template
    output = ctx.actions.declare_file(ctx.label.name + ".sh")

    ctx.actions.expand_template(
        template = template,
        output = output,
        substitutions = {
            "{{upload}}": ctx.executable._upload.short_path,
            "{{chip}}": ctx.attr.chip,
            "{{baud}}": str(ctx.attr.baud),
            "{{code}}": ctx.file.code.short_path,
            "{{before}}": ctx.attr.before,
            "{{after}}": ctx.attr.after,
            "{{start_data}}": str(ctx.attr.start_data or 0),
            "{{data}}": ctx.file.data.short_path if ctx.attr.data else "",
        },
        is_executable = True,
    )
    direct_runfiles = [ctx.file.code, ctx.executable._upload] + ([ctx.file.data] if ctx.attr.data else [])
    runfiles = ctx.runfiles(direct_runfiles).merge(ctx.attr._upload[DefaultInfo].default_runfiles)
    return [DefaultInfo(executable = output, runfiles = runfiles)]

_flash = rule(
    doc = "Generates a script for flashing (and runs it)",
    implementation = _flash_impl,
    attrs = {
        "_template": attr.label(allow_single_file = True, default = "@bazel_esp8266//bazel/build_rules:flash.sh"),
        "_upload": attr.label(executable = True, default = UPLOAD, cfg = "exec"),
        "chip": attr.string(mandatory = True, doc = "Chip to flash to"),
        "baud": attr.int(mandatory = True, doc = "Baud rate to flash with"),
        "code": attr.label(mandatory = True, doc = "Code to flash to the chip", allow_single_file = True),
        "data": attr.label(mandatory = False, doc = "Packed data files to be flashed to little", allow_single_file = True),
        "start_data": attr.int(mandatory = False, doc = "Start of the data section"),
        "before": attr.string(doc = "What to do before flashing"),
        "after": attr.string(doc = "What to do after flashing"),
    },
    executable = True,
)
