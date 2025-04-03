cmake_minimum_required(VERSION 3.22.1)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/config/toolchain-xmc.cmake)

project(mgt_boot_example LANGUAGES C ASM)

include(config/mcuDetails.cmake)
include(config/cryptOptions.cmake)
include(simpleVersion.cmake)
include(genLinker.cmake)

add_subdirectory(flashLib)

# build app
set(APP_SRCS src/app.c)

add_executable(app_root.elf ${APP_SRCS})
target_link_options(app_root.elf PRIVATE "-T${ROOT_PARTITION_LINKER_FILE}")

add_executable(app_offset.elf ${APP_SRCS})
target_link_options(app_offset.elf PRIVATE "-T${APP_PARTITION_LINKER_FILE}")

add_subdirectory(.. mgt-boot)