cmake_minimum_required(VERSION 3.22.1)

add_library(mcu_port_lib
  flash.c
  clock.c
  system_XMC4700.c
)

target_include_directories(mcu_port_lib 
PUBLIC
  ${MGTBOOT_DIR}/inc  # flash_port.h, clock_port.h
  ${PROJECT_BINARY_DIR}/mgt-boot  # partitions.h (configured)
PRIVATE
  CMSIS-6.1.0/Core/Include
)