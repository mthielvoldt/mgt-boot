cmake_minimum_required(VERSION 3.22.1)

add_library(flash_lib
  flash.c
)

target_include_directories(flash_lib PUBLIC
  ${MGTBOOT_DIR}/inc  # flash.h
  ${PROJECT_BINARY_DIR}/mgt-boot  # partitions.h (configured)
)