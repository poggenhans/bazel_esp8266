# bazel_esp8266

With the discontinuation of official support for the ESP8266, you might need something to be able reproducibly build your code for your ESP8266.

This repo provides this by offering a hermetic, standalone bazel-based build environment that builds on the existing arduino esp8266 libraries.

Features:

- **hermetic build toolchain**
- **standalone build**, no previous install required, except for [bazelisk](https://bazel.build/install/bazelisk)
- compatible with **any recent x86 linux system**
- **Very fast build**, thanks to the efficient bazel build system
- Building and flashing of binary code and data **in a single bazel run** command

Limitations:

- Currently, only `nodemcu` is supported as board, however more boards can be added easily by adjusting [boards.bzl](./platform/boards.bzl)
- Only a limited set of extra arduino libraries supported, see [here](./bazel/external/arduino_esp8266/defs.bzl). This can also easily be extended and more repositories integrated through the usual bazel facilities.

## Kudos

This repo is based on the similar [bazel_esp32](https://github.com/simonhorlick/bazel_esp32.git) repo, but has extensively refactored and modernized.

## Usage

### Module.bzl

In your `MODULE.bazel` declare the dependency:

```starlark
bazel_dep(name = "bazel_esp8266")

git_override(
    module_name = "bazel_esp8266",
    remote = "https://github.com/poggenhans/bazel_esp8266.git",
    commit = "main", # chose an appropriate commit here
)
```

### Bazelrc

Add the toolchain configuration to your `.bazelrc` in the root of your repository:

```text
build:esp8266 --extra_toolchains=@bazel_esp8266//:cc-xtensa-toolchain-nodemcuv2
build:esp8266 --platforms=@bazel_esp8266//:nodemcuv2_platform
```

### BUILD file

An

```starlark
load("@bazel_esp8266//bazel/build_rules:flash.bzl", "esp8266_binary")

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    visibility = ["//visibility:public"],
    deps = [
        "//:arduino_core_main",
    ],
)

filegroup(
    name = "flash_data",
    srcs = glob(["data/**]),
)

esp8266_binary(
    name = "flash_hello",
    board = "nodemcuv2",
    cc_binary = "hello",
    data = "flash_data",
    data_root = "data",
    visibility = ["//visibility:public"],
)
```

Then build your targets for esp8266 with `bazel build --config=esp8266 //flash_hello` or directly flash it to your board with e.g. `bazel run --config=esp8266 //flash_hello -- --port /dev/ttyUSB1`. The implementation ensures that flashing only takes place when targets have changed.

## Examples

Have a look at the example [here](./example/).
