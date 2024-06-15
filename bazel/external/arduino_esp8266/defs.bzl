"""Defines targets exported by arduino_esp8266"""

ARDUINO_EXTENSION_LIBS = [
    "ESP8266WiFi",
    "SoftwareSerial",
    "SPI",
    "LittleFS",
    "ESP8266WebServer",
    "WiFiUdp",
]

ARDUINO_CORE_LIBS = [
    "arduino_core_main",
    "arduino_core",
]

ARDUINO_LIBS = ARDUINO_EXTENSION_LIBS + ARDUINO_CORE_LIBS

ARDUINO_BINS = [
    "bootloader",
    "elf2bin",
    "upload",
    "sizes",
    "esptool",
]
