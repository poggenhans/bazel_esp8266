load("@bazel_esp8266//platform:boards.bzl", "BOARDS")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("//bazel/external:arduino_esp8266/defs.bzl", "ARDUINO_BINS", "ARDUINO_LIBS")

# register platforms for all boards
[
    platform(
        name = "{board}_platform".format(board = board),
        constraint_values = [
            "//platform/cpu:xtensa",
            "//platform/board:nodemcuv2",
        ],
        visibility = ["//visibility:public"],
    )
    for board in BOARDS
]

# register aliases for all toolchains
[
    alias(
        name = "cc-xtensa-toolchain-{board}".format(board = board),
        actual = "@xtensa_lx106_elf_linux64//:cc-xtensa-toolchain-{board}".format(board = board),
        visibility = ["//visibility:public"],
    )
    for board in BOARDS
]

bool_flag(
    name = "nonstandard_flags",
    build_setting_default = True,
    visibility = ["//visibility:public"],
)

[
    alias(
        name = lib,
        actual = "@arduino_esp8266//:{lib}".format(lib = lib),
        visibility = ["//visibility:public"],
    )
    for lib in ARDUINO_LIBS
]

[
    alias(
        name = bin,
        actual = "@arduino_esp8266//:{bin}".format(bin = bin),
        visibility = ["//visibility:public"],
    )
    for bin in ARDUINO_BINS
]

alias(
    name = "mklittlefs",
    actual = "@mklittlefs//:mklittlefs_bin",
    visibility = ["//visibility:public"],
)

alias(
    name = "xtensa_compiler_bins",
    actual = "@xtensa_lx106_elf_linux64//:compiler_components",
    visibility = ["//visibility:public"],
)

alias(
    name = "xtensa_readelf",
    actual = "@xtensa_lx106_elf_linux64//:readelf",
    visibility = ["//visibility:public"],
)

buildifier(
    name = "buildifier.check",
    exclude_patterns = ["./.git/*"],
    lint_mode = "warn",
    mode = "check",
)

buildifier(
    name = "buildifier",
    exclude_patterns = ["./.git/*"],
    lint_mode = "fix",
    mode = "fix",
)
