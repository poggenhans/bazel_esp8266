"""BUILD file for external library arduino esp8266"""

load("@bazel_esp8266//bazel/external:arduino_esp8266/defs.bzl", "ARDUINO_EXTENSION_LIBS")
load("@bazel_esp8266//platform:boards.bzl", "BOARDS")
load("@bazel_esp8266//platform:platform.bzl", "NONO_SDK")

filegroup(
    name = "bootloader",
    srcs = ["bootloaders/eboot/eboot.elf"],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "sizes",
    srcs = ["tools/sizes.py"],
    visibility = ["//visibility:public"],
)

py_library(
    name = "esptool_lib",
    srcs = ["tools/esptool/esptool.py"],
    imports = ["tools/esptool"],
    deps = ["@pyserial"],
)

py_binary(
    name = "esptool",
    srcs = ["tools/esptool/esptool.py"],
    visibility = ["//visibility:public"],
    deps = ["esptool_lib"],
)

py_binary(
    name = "upload",
    srcs = ["tools/upload.py"],
    visibility = ["//visibility:public"],
    deps = ["esptool_lib"],
)

py_binary(
    name = "elf2bin",
    srcs = ["tools/elf2bin.py"],
    data = [
        "@xtensa_lx106_elf_linux64//:compiler_pieces",
    ],
    visibility = ["//visibility:public"],
)

genrule(
    name = "cp_flash_linkscript_h",
    srcs = select(
        {
            "@bazel_esp8266//platform/board:{board}_board".format(board = board): ["tools/sdk/ld/{flash_ld}".format(flash_ld = board_cfg["flash_ld"])]
            for board, board_cfg in BOARDS.items()
        },
    ),
    outs = ["local.eagle.flash.ld.h"],
    cmd = "cp $< $@",
)

genrule(
    name = "gen_flash_linkscript",
    srcs = ["local.eagle.flash.ld.h"],
    outs = ["ld/local.eagle.flash.ld"],
    cmd = select(
        {
            "@bazel_esp8266//platform/board:{board}_board".format(board = board): "$(location @xtensa_lx106_elf_linux64//:bin/xtensa-lx106-elf-gcc) -CC -E -P {} $< -o $@".format(" ".join(board_cfg["mmu_flags"] + board_cfg["vtable_flags"]))
            for board, board_cfg in BOARDS.items()
        },
    ),
    tools = ["@xtensa_lx106_elf_linux64//:bin/xtensa-lx106-elf-gcc"],
    visibility = ["//visibility:public"],
)

genrule(
    name = "gen_eagle_linkscript_unpatched",
    srcs = glob(["tools/sdk/ld/*.h"]),
    outs = ["local.eagle.app.v6.common.ld.unpatched"],
    cmd = select(
        {
            "@bazel_esp8266//platform/board:{board}_board".format(board = board): "$(location @xtensa_lx106_elf_linux64//:bin/xtensa-lx106-elf-gcc) -CC -E -P {} $(location tools/sdk/ld/eagle.app.v6.common.ld.h) -o $@".format(" ".join(board_cfg["mmu_flags"] + board_cfg["vtable_flags"]))
            for board, board_cfg in BOARDS.items()
        },
    ),
    tools = ["@xtensa_lx106_elf_linux64//:bin/xtensa-lx106-elf-gcc"],
    visibility = ["//visibility:public"],
)

# The linker script provided with the sdk assumes o files are created by appending ".o" but bazel instead replaces the extension.
# Hence things like "*.cpp.o" won't match. So we replace this by assuming all libs build by us are prefixed "arduino_"
LIB_COMMAND = "    *libarduino_*.a:(EXCLUDE_FILE (umm_malloc.o cont.o) .literal* EXCLUDE_FILE (umm_malloc.o cont.o) .text*)"

# The binaries for the "cc_binary" target will be object files, so we search for them like this (note the position of the ":")
# see also https://sourceware.org/binutils/docs/ld/Input-Section-Basics.html
MAIN_COMMAND = "    :*.o(.literal* .text*)"

# greater spiffs hack: -e 's/len = 0x8000/len = 0x80000/g'

genrule(
    name = "gen_eagle_linkscript",
    srcs = ["local.eagle.app.v6.common.ld.unpatched"],
    outs = ["ld/local.eagle.app.v6.common.ld"],
    cmd = "sed -e '/.cpp.o/c\\{}'  $< > $@".format("\\n".join([
        LIB_COMMAND,
        MAIN_COMMAND,
    ])),
)

genrule(
    name = "cp_eagle.rom.addr.v6.ld",
    srcs = ["tools/sdk/ld/eagle.rom.addr.v6.ld"],
    outs = ["ld/eagle.rom.addr.v6.ld"],
    cmd = "cp $< $@",
)

ARDUINO_SDK_PATH = "tools/sdk"

ARDUINO_SDK_LIB_PATH = ARDUINO_SDK_PATH + "/lib"

NONO_ARDUINO_SDK_LIB_PATH = ARDUINO_SDK_LIB_PATH + "/" + NONO_SDK

LIB_DEPS = {
    "libpp": ["liblwip2-536-feat"],
    "liblwip2-536-feat": ["arduino_time"],
}

SDK_LIBS = [
    "libhal",
    "libbearssl",
    "libstdc++",
]

SDK_LIBS_WITH_LWIP2 = SDK_LIBS + ["liblwip2-536-feat"]

[
    cc_import(
        name = lib,
        static_library = ARDUINO_SDK_LIB_PATH + "/" + lib + ".a",
        deps = LIB_DEPS.get(lib),
    )
    for lib in SDK_LIBS_WITH_LWIP2
]

NONO_SDK_LIBS = [
    "libphy",
    "libpp",
    "libwpa",
    "libwpa2",
    "libwps",
    "libespnow",
    "libsmartconfig",
    "libairkiss",
]

[
    cc_import(
        name = lib,
        static_library = NONO_ARDUINO_SDK_LIB_PATH + "/" + lib + ".a",
        deps = LIB_DEPS.get(lib),
    )
    for lib in NONO_SDK_LIBS
]

cc_import(
    name = "libmain",
    static_library = NONO_ARDUINO_SDK_LIB_PATH + "/libmain.a",
    deps = ["arduino_core"],
)

cc_library(
    name = "sdk_libs",
    hdrs = glob(
        [
            ARDUINO_SDK_PATH + "/include/*.h",
            ARDUINO_SDK_PATH + "/include/bearssl/*.h",
        ],
        allow_empty = False,
    ),
    includes = [ARDUINO_SDK_PATH + "/include"],
    deps = SDK_LIBS,
)

cc_library(
    name = "variant_lib",
    hdrs = select({
        "@bazel_esp8266//platform/board:{board}_board".format(board = board): glob(["variants/{variant}/*.h".format(variant = board_cfg["variant"]), "variants/generic/*.h"])
        for board, board_cfg in BOARDS.items()
    }),
    includes = select({
        "@bazel_esp8266//platform/board:{board}_board".format(board = board): ["variants/{variant}".format(variant = board_cfg["variant"]), "variants/generic"]
        for board, board_cfg in BOARDS.items()
    }),
)

# time.cpp for some reason defines symbols needed by liblwip2*.a. Which we in turn need for the core lib.
# To break the cycle, we move time.cpp out of core and compile it independently.

cc_library(
    name = "arduino_time",
    srcs = glob([
        ARDUINO_SDK_PATH + "/lwip2/include/**/*.h",
        "bootloaders/**/*.h",
        "cores/esp8266/**/*.h",
    ]) + ["cores/esp8266/time.cpp"],
    includes = [
        "cores/esp8266",
        ARDUINO_SDK_PATH + "/lwip2/include",
    ],
    target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa"],
    deps = ["sdk_libs", "variant_lib"],
)

cc_library(
    name = "liblwip2",
    hdrs = glob([
        ARDUINO_SDK_PATH + "/lwip2/include/**/*.h",
    ]),
    includes = [ARDUINO_SDK_PATH + "/lwip2/include"],
    deps = ["arduino_time", "liblwip2-536-feat"],
)

cc_library(
    name = "netlibs",
    srcs = [
        NONO_ARDUINO_SDK_LIB_PATH + "/libwpa.a",
        NONO_ARDUINO_SDK_LIB_PATH + "/libnet80211.a",
        NONO_ARDUINO_SDK_LIB_PATH + "/libcrypto.a",
    ],
    linkopts = [
        # These libraries have circular dependencies in their symbols. The way to deal with
        # this in static archives is to use -Wl,start-group / -Wl,end-group around the archives.
        "-Wl,--start-group",
        "$(location {})".format(NONO_ARDUINO_SDK_LIB_PATH + "/libwpa.a"),
        "$(location {})".format(NONO_ARDUINO_SDK_LIB_PATH + "/libnet80211.a"),
        "$(location {})".format(NONO_ARDUINO_SDK_LIB_PATH + "/libcrypto.a"),
        "-Wl,--end-group",
    ],
    linkstatic = 1,
    target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa"],
    alwayslink = 1,
)

# for some reason some files in cores/esp8266 import .c files
cc_library(
    name = "core_internal_headers",
    hdrs = glob(["cores/esp8266/umm_malloc/*.c"]),
)

_MAIN_SRCS = [
    "cores/esp8266/core_esp8266_app_entry_noextra4k.cpp",
    "cores/esp8266/core_esp8266_main.cpp",
]

cc_library(
    name = "arduino_core",
    srcs = glob(
        [
            "cores/esp8266/**/*.cpp",
            "cores/esp8266/**/*.c",
            "cores/esp8266/**/*.S",
            "cores/esp8266/**/*.h",
            "bootloaders/**/*.h",
        ],
        exclude = ["cores/esp8266/time.cpp"] + _MAIN_SRCS,
    ),
    hdrs = glob([
        "cores/esp8266/*.h",
    ]),
    implementation_deps = [":core_internal_headers"],
    includes = [
        "cores/esp8266",
    ],
    target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa"],
    visibility = ["//visibility:public"],
    deps = SDK_LIBS + NONO_SDK_LIBS + [
        "arduino_time",
        "liblwip2",
        "netlibs",
        "variant_lib",
        "@xtensa_lx106_elf_linux64//:xtensa_cc_libs",
    ],
)

genrule(
    name = "gen_l",
    outs = ["l"],
    cmd = "touch $@",
)

cc_library(
    name = "arduino_core_main",
    srcs = _MAIN_SRCS,
    additional_linker_inputs = [
        "l",
        "ld/local.eagle.app.v6.common.ld",
        "ld/local.eagle.flash.ld",
        "ld/eagle.rom.addr.v6.ld",
    ],
    implementation_deps = ["sdk_libs"],
    # make sure linker scripts are found
    linkopts = [
        # How do we get the path to the "ld" directory containing the linkscripts used by local.eagle.flash.ld?
        # Since execpath only resolves files, not directories and ld doesn't understand "/..",
        # we create a file named "l", resolve the path to it and append the "d". Voilà.
        "-L$(execpath l)d",
        "-T$(execpath ld/local.eagle.flash.ld)",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "arduino_core",
        "libmain",
    ],
)

# Bundled libraries
cc_library(
    name = "littlefs_internal",
    hdrs = glob(["libraries/LittleFS/lib/**"]),
)

implementation_deps = {
    "LittleFS": ["littlefs_internal"],
}

[
    cc_library(
        name = "arduino_" + lib,
        srcs = glob([
            "libraries/" + lib + "/src/**",
            "libraries/" + lib + "/*.cpp",
        ]),
        hdrs = glob([
            "libraries/" + lib + "/src/**/*.h",
            "libraries/" + lib + "/lib/**/*.h",
            "libraries/" + lib + "/*.h",
        ]),
        implementation_deps = implementation_deps.get(lib),
        includes = [
            "libraries/" + lib + "/src/",
            "libraries/" + lib,
        ],
        target_compatible_with = ["@bazel_esp8266//platform/cpu:xtensa"],
        deps = [
            "@arduino_esp8266//:arduino_core",
        ],
    )
    for lib in ARDUINO_EXTENSION_LIBS
]

[
    alias(
        name = lib,
        actual = "arduino_" + lib,
        visibility = ["//visibility:public"],
    )
    for lib in ARDUINO_EXTENSION_LIBS
]
