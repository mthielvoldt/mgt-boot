cmake_minimum_required(VERSION 3.22.1)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/config/toolchain-xmc.cmake)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

project(mgt_boot_example LANGUAGES C ASM)

include(config/mcuDetails.cmake)
include(config/partitions.cmake)
include(config/cryptOptions.cmake)

set(MGTBOOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
include(${MGTBOOT_DIR}/tools/genLinker.cmake) # req: LINKER_SCRIPT_TEMPLATE

add_subdirectory(mcu_port)

# build app
add_library(app_lib
  src/app.c 
  ${STARTUP_FILE}
)
target_include_directories(app_lib INTERFACE ${MGTBOOT_DIR}/inc)
target_link_libraries(app_lib mcu_port_lib)
target_compile_options(app_lib PRIVATE ${ASSEMBLER_FLAGS})

set(APP_DEPENDS 
  $<TARGET_FILE:app_lib>
  $<TARGET_FILE:mcu_port_lib>
)
include(${MGTBOOT_DIR}/tools/genBuildTime.cmake)

add_executable(app_root.elf ${BUILD_TIME_C})
target_link_libraries(app_root.elf app_lib)
target_link_options(app_root.elf PRIVATE "-T${ROOT_PARTITION_LINKER_FILE}")

add_executable(app_offset.elf ${BUILD_TIME_C})
target_link_libraries(app_offset.elf app_lib)
target_link_options(app_offset.elf PRIVATE "-T${APP_PARTITION_LINKER_FILE}")

add_subdirectory(${MGTBOOT_DIR} mgt-boot)