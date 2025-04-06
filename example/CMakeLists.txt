cmake_minimum_required(VERSION 3.22.1)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/config/toolchain-xmc.cmake)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

project(mgt_boot_example LANGUAGES C ASM)

include(config/mcuDetails.cmake)
include(config/partitions.cmake)
include(genLinker.cmake)

include(config/cryptOptions.cmake)
include(simpleVersion.cmake)

add_subdirectory(flashLib)

# build app
set(APP_SRCS src/app.c)

add_library(mcu_startup
  src/system_XMC4700.c
  src/startup_XMC4700.S
)
target_include_directories(mcu_startup PRIVATE src/CMSIS-6.1.0/Core/Include)
target_compile_options(mcu_startup PRIVATE ${ASSEMBLER_FLAGS})

add_executable(app_root.elf ${APP_SRCS})
target_link_libraries(app_root.elf mcu_startup)
target_link_options(app_root.elf PRIVATE "-T${ROOT_PARTITION_LINKER_FILE}")


add_executable(app_offset.elf ${APP_SRCS})
target_link_libraries(app_offset.elf mcu_startup)
target_link_options(app_offset.elf PRIVATE "-T${APP_PARTITION_LINKER_FILE}")

add_subdirectory(.. mgt-boot)