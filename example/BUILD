load("//bazel/build_rules:flash.bzl", "esp8266_binary")

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    visibility = ["//visibility:public"],
    deps = [
        "//:arduino_core_main",  # the final binary must depend on this libary, it provides the main function
    ],
)

esp8266_binary(
    name = "flash_hello",  # running this target will flash the code to the board
    board = "nodemcuv2",  # see platform/boards.bzl for valid values
    cc_binary = "hello",  # the binary target we declared above
    visibility = ["//visibility:public"],
)
