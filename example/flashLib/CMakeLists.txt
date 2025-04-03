cmake_minimum_required(VERSION 3.22.1)

add_library(flash_lib
  flash.c
)

target_include_directories(flash_lib INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})