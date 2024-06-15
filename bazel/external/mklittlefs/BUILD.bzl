"""BUILD file for external library mklittlefs"""

sh_binary(
    name = "mklittlefs_bin",
    srcs = ["mklittlefs"],
    visibility = ["//visibility:public"],
)
