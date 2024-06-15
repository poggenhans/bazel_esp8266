"""Defines the cc compiler toolchain for xtensa platform"""

load("@bazel_esp8266//platform:boards.bzl", "BOARDS")
load("@bazel_esp8266//platform:platform.bzl", "NONO_SDK")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)

COMPILER_PATH = "xtensa-lx106-elf"

BUILTIN_INCLUDE_DIRS = [
    COMPILER_PATH + "/include",
    COMPILER_PATH + "/sys-include",
    COMPILER_PATH + "/lib/gcc/xtensa-lx106-elf/10.3.0/include",
    COMPILER_PATH + "/lib/gcc/xtensa-lx106-elf/10.3.0/include-fixed",
    COMPILER_PATH + "/include/c++/10.3.0",
]

COMPILER_CPREPROCESSOR_FLAGS = [
    "-D__ets__",
    "-DICACHE_FLASH",
    "-U__STRICT_ANSI__",
    "-D_GNU_SOURCE",
    "-DTCP_MSS=536",
    "-DLWIP_OPEN_SRC",
    "-DLWIP_FEATURES=1",
    "-DLWIP_IPV6=0",
    # time.h doesn't define these by default, so set them to something sane.
    # This is required for Abseil's time handling.
    "-D__TM_GMTOFF=__tm_gmtoff",
    "-D__TM_ZONE=__tm_zone",
]

COMPILER_WARNING_FLAGS = ["-Wall"]

COMPILER_S_FLAGS = [
    "-x",
    "assembler-with-cpp",
    "-Os",  # size matters on esp8266
    "-MMD",
]

COMPILER_S_FLAGS_NONSTANDARD = ["-mlongcalls"]

COMPILER_C_FLAGS = [
    "-std=gnu17",  # this is what the compiler is built for
    "-Os",  # size matters on esp8266
    "-Werror=return-type",
    "-Wpointer-arith",
    "-Wno-implicit-function-declaration",
    "-fno-inline-functions",
    "-fno-exceptions",
    "-nostdlib",
    "-falign-functions=4",
    "-MMD",
    "-ffunction-sections",
    "-fdata-sections",
] + COMPILER_WARNING_FLAGS

COMPILER_C_FLAGS_NONSTANDARD = [
    "-free",
    "-fipa-pta",
    "-mlongcalls",
    "-mtext-section-literals",
]

COMPILER_CPP_FLAGS = [
    "-std=gnu++17",
    "-Os",  # size matters on esp8266
    "-Werror=return-type",
    "-fno-rtti",
    "-falign-functions=4",
    "-MMD",
    "-ffunction-sections",
    "-fdata-sections",
    "-fno-exceptions",
] + COMPILER_WARNING_FLAGS

COMPILER_CPP_FLAGS_NONSTANDARD = COMPILER_C_FLAGS_NONSTANDARD

COMPILER_C_ELF_FLAGS = [
    "-fno-exceptions",
    "-Os",
    "-nostdlib",
    "-Wl,--no-check-sections",
    "-u",
    "app_entry",
    "-u",
    "_printf_float",
    "-u",
    "_scanf_float",
    "-Wl,-static",
    "-Wl,--gc-sections",
    "-Wl,-wrap,system_restart_local",
    "-Wl,-wrap,spi_flash_read",
]

COMPILER_C_ELF_LIBS = [
    "-lm",
    "-lc",
    "-lgcc",
]

def _impl(ctx):
    def path_to(tool):
        return "bin/xtensa-lx106-elf-{tool}".format(tool = tool)

    board = BOARDS[ctx.attr.board]

    board_flags = [
        "-D{nono_sdk}=1".format(nono_sdk = NONO_SDK),
        "-DF_CPU={f_cpu}".format(f_cpu = board["f_cpu"]),
        "-DARDUINO={ide_version}".format(ide_version = board["runtime_ide_version"]),
        "-DARDUINO_{board}".format(board = ctx.attr.board.upper()),
        "-DARDUINO_ARCH_{arch}".format(arch = board["arch"]),
        "-DARDUINO_BOARD=\"{board}\"".format(board = board["board"]),
        "-DARDUINO_BOARD_ID=\"{variant}\"".format(variant = board["variant"]),
        "-DFLASHMODE_{flashmode}".format(flashmode = board["flashmode"].upper()),
        "-D{arch}".format(arch = board["arch"]),
    ]

    # the led
    led_flags = ["-DLED_BUILTIN={led}".format(led = board["led_builtin"])]
    common_flags = board_flags + led_flags + board["mmu_flags"] + board["vtable_flags"] + COMPILER_CPREPROCESSOR_FLAGS

    tool_paths = [
        tool_path(
            name = "gcc",
            path = path_to("gcc"),
        ),
        tool_path(
            name = "ld",
            path = path_to("ld"),
        ),
        tool_path(
            name = "ar",
            path = path_to("ar"),
        ),
        tool_path(
            name = "as",
            path = path_to("as"),
        ),
        tool_path(
            name = "cpp",
            path = path_to("cpp"),
        ),
        tool_path(
            name = "gcov",
            path = path_to("gcov"),
        ),
        tool_path(
            name = "nm",
            path = path_to("nm"),
        ),
        tool_path(
            name = "objdump",
            path = path_to("objdump"),
        ),
        tool_path(
            name = "strip",
            path = path_to("strip"),
        ),
    ]

    nonstd_flags = ctx.attr.add_nonstandard_flags

    cpp_flags = common_flags + COMPILER_CPP_FLAGS + (COMPILER_CPP_FLAGS_NONSTANDARD if nonstd_flags else [])
    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = cpp_flags,
                    ),
                ],
            ),
        ],
    )

    s_flags = common_flags + COMPILER_S_FLAGS + (COMPILER_S_FLAGS_NONSTANDARD if nonstd_flags else [])
    default_s_compile_flags_feature = feature(
        name = "default_s_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.assemble,
                ],
                flag_groups = [
                    flag_group(
                        flags = s_flags,
                    ),
                ],
            ),
        ],
    )

    c_flags = common_flags + COMPILER_C_FLAGS + (COMPILER_C_FLAGS_NONSTANDARD if nonstd_flags else [])
    default_c_compile_flags_feature = feature(
        name = "default_c_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = c_flags,
                    ),
                ],
            ),
        ],
    )

    all_link_actions = [
        ACTION_NAMES.cpp_link_executable,
        ACTION_NAMES.cpp_link_dynamic_library,
        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    link_flags = COMPILER_C_ELF_FLAGS + COMPILER_C_ELF_LIBS
    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = link_flags,
                    ),
                ],
            ),
        ],
    )

    features = [
        default_s_compile_flags_feature,
        default_compile_flags_feature,
        default_c_compile_flags_feature,
        default_link_flags_feature,
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        cxx_builtin_include_directories = BUILTIN_INCLUDE_DIRS,
        features = features,
        toolchain_identifier = "xtensa-toolchain",
        host_system_name = "local",
        target_system_name = "local",
        target_cpu = "xtensa",
        target_libc = "unknown",
        compiler = "cpp",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        tool_paths = tool_paths,
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "add_nonstandard_flags": attr.bool(default = True, doc = "Add flags not supported by standard GCC"),
        "board": attr.string(values = BOARDS.keys(), mandatory = True, doc = "Board name, see boards.bzl"),
    },
    provides = [CcToolchainConfigInfo],
)
