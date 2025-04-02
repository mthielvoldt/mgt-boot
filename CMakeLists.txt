cmake_minimum_required(VERSION 3.22.1)

# set(CMAKE_TOOLCHAIN_FILE "toolchain-xmc.cmake")
project(xmc_ota LANGUAGES C ASM)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

set(XMCLIB ${PROJECT_SOURCE_DIR}/deps/firment/firmware/port/XMC4/mtb-xmclib-cat3/XMCLib)

# Note: WolfBoot modifies CMAKE_C_COMPILER etc, in a file called 
# toolchain_arm-none-eabi.cmake  but this isn't the same as specifying a
# toolchain file for the whole project. 

include(wolfBootConfig.cmake)
include(firmentConfig.cmake) # include after wolfBootConfig.cmake
include(simpleVersion.cmake)

add_subdirectory(deps/wolfBoot)

message(STATUS "IMAGE_HEADER_SIZE: ${IMAGE_HEADER_SIZE}")
math(EXPR APP_CODE_ADDRESS_CACHED "${CACHED_PARTITION_BOOT_ADDRESS} + ${IMAGE_HEADER_SIZE}"
     OUTPUT_FORMAT HEXADECIMAL)
math(EXPR APP_CODE_ADDRESS_DIRECT "${WOLFBOOT_PARTITION_BOOT_ADDRESS} + ${IMAGE_HEADER_SIZE}"
     OUTPUT_FORMAT HEXADECIMAL)
math(EXPR APP_CODE_SIZE "${WOLFBOOT_PARTITION_SIZE} - ${IMAGE_HEADER_SIZE}"
     OUTPUT_FORMAT HEXADECIMAL)
     
set(APP_PARTITION_LINKER_FILE ${PROJECT_BINARY_DIR}/app.ld)
set(ROOT_PARTITION_LINKER_FILE 
  ${PROJECT_SOURCE_DIR}/deps/firment/firmware/port/XMC4/XMC4700x2048.ld
)
configure_file(firmware/XMC4700x2048.ld ${APP_PARTITION_LINKER_FILE})

set(FIRMENT_DIR deps/firment)

# TODO: this could move into fmt's CML.
add_subdirectory(${FIRMENT_DIR}/firmware/port/${FMT_PORT} ${FMT_PORT})
add_subdirectory(${FIRMENT_DIR} firment)

set(APP_SOURCES
  firmware/main.c
  firmware/project_comms.c
  firmware/spi_init.c
)
add_executable(app.elf ${APP_SOURCES})
target_include_directories(app.elf PRIVATE firmware)
target_link_options(app.elf PRIVATE "-T${APP_PARTITION_LINKER_FILE}")
target_link_libraries(app.elf FirmentFW MCUPort wolfboot)

### Standalone app for debug. # TODO: DRY this with an add_library() layer. 
add_executable(app_standalone.elf ${APP_SOURCES})
target_include_directories(app_standalone.elf PRIVATE firmware)
# This is where app_standalone differs from app.
target_link_options(app_standalone.elf PRIVATE 
  "-T${ROOT_PARTITION_LINKER_FILE}")
target_link_libraries(app_standalone.elf FirmentFW MCUPort wolfboot)


# Build firmware artifacts: signed app binary and combined [boot/app] binary.
add_custom_command(DEPENDS app.elf
  OUTPUT app.bin
  COMMAND ${CMAKE_C_OBJCOPY} ARGS -O binary app.elf app.bin
)

# TODO: Refactor below artifacts creation to use wolfboot.cmake function:
# gen_wolfboot_factory_image()

add_custom_target(signed_app ALL DEPENDS app.bin keystore)
# Sign the binary.
add_custom_command(TARGET signed_app
  COMMAND IMAGE_HEADER_SIZE=${IMAGE_HEADER_SIZE} ${SIGN_TOOL} --ed25519 --sha256 
    ${PROJECT_BINARY_DIR}/app.bin 
    ${WOLFBOOT_SIGNING_PRIVATE_KEY}
    ${APP_VERSION}
  COMMENT "Signing app.bin, creating app_v<x>_signed.bin"  
)

add_executable(bootloader.elf
  bl/bl_main.c
  deps/wolfBoot/src/boot_arm.c
  deps/wolfBoot/src/image.c
)
# TODO: Move this into my replacement for target.h
target_compile_definitions(bootloader.elf PRIVATE
  APP_CODE_ADDRESS_CACHED=${APP_CODE_ADDRESS_CACHED}
)
target_link_libraries(bootloader.elf wolfboot public_key FirmentFW)
target_link_options(bootloader.elf PRIVATE 
  "-T${ROOT_PARTITION_LINKER_FILE}")
add_custom_command(TARGET bootloader.elf POST_BUILD
  COMMAND ${CMAKE_C_OBJCOPY} ARGS -O binary bootloader.elf bootloader.bin
)

add_custom_target(factory_bin ALL DEPENDS 
  signed_app
  bootloader.elf
  binAssemble
)

add_custom_command(TARGET factory_bin
  COMMAND ${BINASSEMBLE} 
    factory.bin 
    ${ARCH_FLASH_OFFSET}
    ${PROJECT_BINARY_DIR}/bootloader.bin
    ${WOLFBOOT_PARTITION_BOOT_ADDRESS}
    ${PROJECT_BINARY_DIR}/app_v${APP_VERSION}_signed.bin
)

# Copy image files to folder outside binary dir so I can use clean-build to make
# different versions.  Note I only need this until I figure out 
# - how to bump versions with just the build step, or 
# - how to re-configure without deleting the whole build dir.
set(IMAGES_DIR ${PROJECT_BINARY_DIR}/../images)
add_custom_command(TARGET factory_bin
  COMMAND mkdir -p ${PROJECT_BINARY_DIR}/../images &&
    cp ${PROJECT_BINARY_DIR}/factory.bin ${IMAGES_DIR}/factory_v${APP_VERSION}.bin &&
    cp ${PROJECT_BINARY_DIR}/app_v${APP_VERSION}_signed.bin ${IMAGES_DIR}/ &&
    cp ${PROJECT_BINARY_DIR}/app.elf ${IMAGES_DIR}/app_v${APP_VERSION}.elf
)