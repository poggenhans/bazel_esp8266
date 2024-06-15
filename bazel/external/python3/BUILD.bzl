"""Build file for external python3 toolchain"""

load("@rules_python//python:defs.bzl", "py_runtime", "py_runtime_pair")

filegroup(
    name = "files",
    srcs = glob(
        ["lib/**"],
        exclude = ["**/* *"],
    ),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "interpreter",
    srcs = ["bin/python3"],
    visibility = ["//visibility:public"],
)

py_runtime(
    name = "py_runtime",
    files = [":files"],
    interpreter = ":interpreter",
    python_version = "PY3",
    # see https://github.com/bazelbuild/rules_python/issues/691
    stub_shebang = r"""#!/usr/bin/env -S /bin/bash -c 'if [[ $(pwd) =~ (.*\\.runfiles[/$]) ]]; then ${BASH_REMATCH[0]}/_main~_repo_rules~python3/bin/python3 $0 "$@"; else $0.runfiles/_main~_repo_rules~python3/bin/python3 $0 "$@"; fi'""",
    visibility = ["//visibility:public"],
)
py_runtime_pair(
    name = "py_runtime_pair",
    py2_runtime = None,
    py3_runtime = ":py_runtime",
)

toolchain(
    name = "toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":py_runtime_pair",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)
