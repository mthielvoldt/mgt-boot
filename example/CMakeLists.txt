cmake_minimum_required(VERSION 3.22.1)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/config/toolchain-xmc.cmake)

project(mgt_boot_example LANGUAGES C ASM)

include(config/mcuDetails.cmake)
include(config/cryptOptions.cmake)
include(simpleVersion.cmake)
include(genLinker.cmake)

add_subdirectory(flashLib)

# build app
set(APP_SRCS
  src/app.c
  src/system_XMC4700.c
  src/startup_XMC4700.S
)

add_executable(app_root.elf ${APP_SRCS})
target_link_options(app_root.elf PRIVATE "-T${ROOT_PARTITION_LINKER_FILE}")
target_compile_options(app_root.elf PRIVATE ${ASSEMBLER_FLAGS})
target_include_directories(app_root.elf PRIVATE src/CMSIS-6.1.0/Core/Include)

add_executable(app_offset.elf ${APP_SRCS})
target_link_options(app_offset.elf PRIVATE "-T${APP_PARTITION_LINKER_FILE}")
target_compile_options(app_offset.elf PRIVATE ${ASSEMBLER_FLAGS})
target_include_directories(app_offset.elf PRIVATE src/CMSIS-6.1.0/Core/Include)

add_subdirectory(.. mgt-boot)