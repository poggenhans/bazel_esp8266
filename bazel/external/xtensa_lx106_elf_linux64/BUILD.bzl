"""BUILD file for xtensa gcc compiler variant"""

load("@bazel_esp8266//bazel/external:xtensa_lx106_elf_linux64/cc_toolchain_config.bzl", "cc_toolchain_config")
load("@bazel_esp8266//platform:boards.bzl", "BOARDS")

package(default_visibility = ["//visibility:public"])

filegroup(name = "empty")

filegroup(
    name = "all_files",
    srcs = ["compiler_pieces", "compiler_components"] + ["@bazel_tools//tools/bash/runfiles"],
)

filegroup(
    name = "compiler_pieces",
    srcs = glob([
        "xtensa-lx106-elf/**",
        "libexec/**",
        "lib/gcc/xtensa-lx106-elf/**",
        "include/**",
    ]),
)

filegroup(
    name = "compiler_components",
    srcs = glob(["bin/*"]),
)

filegroup(
    name = "readelf",
    srcs = glob(["bin/*-readelf"], allow_empty = False),
)

[
    cc_toolchain(
        name = "xtensa_toolchain_{board}".format(board = board),
        all_files = "all_files",
        ar_files = "all_files",
        compiler_files = "all_files",
        dwp_files = ":empty",
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        linker_files = "all_files",
        objcopy_files = "all_files",
        strip_files = "all_files",
        supports_param_files = 0,
        target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa", "@bazel_esp8266//platform/board:{board}".format(board = board)],
        toolchain_config = ":xtensa_toolchain_config_{board}".format(board = board),
        toolchain_identifier = "xtensa-toolchain-{board}".format(board = board),
    )
    for board in BOARDS
]
[
    cc_toolchain_config(
        name = "xtensa_toolchain_config_{board}".format(board = board),
        add_nonstandard_flags = select(
            {
                ":nonstandard_flags_true": True,
                "//conditions:default": False,
            },
        ),
        board = board,
    )
    for board in BOARDS
]
[
    toolchain(
        name = "cc-xtensa-toolchain-{board}".format(board = board),
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa"],
        toolchain = ":xtensa_toolchain_{board}".format(board = board),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
    for board in BOARDS
]

cc_library(
    name = "xtensa_cc_libs",
    hdrs = glob(["include/xtensa/*.h"]),
    target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa"],
    includes = ["include"],
)

config_setting(
    name = "nonstandard_flags_true",
    flag_values = {
        "@bazel_esp8266//:nonstandard_flags": "True",
    },
)
