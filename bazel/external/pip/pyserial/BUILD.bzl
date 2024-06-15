"""Build file for external package pyserial"""

py_library(
    name = "pyserial",
    srcs = glob(["serial/**/*.py"]),
    visibility = ["//visibility:public"],
)
