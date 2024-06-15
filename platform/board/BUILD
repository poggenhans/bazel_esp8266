load("//platform:boards.bzl", "BOARDS")

package(default_visibility = ["//visibility:public"])

constraint_setting(
    name = "board",
    default_constraint_value = "nodemcuv2",
)

[
    constraint_value(
        name = board,
        constraint_setting = "board",
    )
    for board in BOARDS
]

[
    config_setting(
        name = "{board}_board".format(board = board),
        constraint_values = [board],
    )
    for board in BOARDS
]
