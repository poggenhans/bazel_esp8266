"""board-specific settings"""

BOARDS = {
    "nodemcuv2": {
        # board details
        "f_cpu": "80000000L",
        "runtime_ide_version": "108012",
        "board": "ESP8266_NODEMCU_ESP12E",
        "arch": "ESP8266",
        "variant": "nodemcu",
        "led_builtin": 2,

        # flash settings
        "flash_ld": "eagle.flash.4m2m.ld",
        "flashmode": "dio",
        "flash_freq": 40,
        "flash_size": "4M",
        "before_flash": "default_reset",
        "after_flash": "hard_reset",

        # spiffs
        "spiffs_pagesize": 256,
        "spiffs_start": 0x200000,
        "spiffs_end": 0x3FA000,
        "spiffs_blocksize": 8192,

        # compiler settings
        "mmu_flags": ["-DMMU_IRAM_SIZE=0x8000", "-DMMU_ICACHE_SIZE=0x8000"],
        "vtable_flags": ["-DVTABLES_IN_FLASH"],
    },
}
