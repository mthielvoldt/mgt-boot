cmake_minimum_required(VERSION 3.22.1)

# set(CMAKE_TOOLCHAIN_FILE "toolchain-xmc.cmake")

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

set(ARCH ARM)
set(VTOR 1)
set(SPMATH 1)
set(WOLFBOOT_TARGET xmc4700 CACHE INTERNAL "Target platform")
set(KEYTOOLS_DIR ${PROJECT_BINARY_DIR}/../keytools)

# Note: WolfBoot modifies CMAKE_C_COMPILER etc, in a file called 
# toolchain_arm-none-eabi.cmake  but this isn't the same as specifying a
# toolchain file for the whole project. 
add_subdirectory(deps/wolfBoot/lib) # provides library target: wolfcrypt
add_library(libwolfboot
  deps/wolfBoot/src/libwolfboot.c
)

# removed defs:  WOLFBOOT_FLAGS_INVERT=1; WOLFBOOT_VERSION=1; TARGET_${WOLFBOOT_TARGET}
target_compile_definitions(libwolfboot PUBLIC
  __WOLFBOOT;
  ARCH_${ARCH};
  ARCH_FLASH_OFFSET=${ARCH_FLASH_OFFSET};
  IMAGE_HEADER_SIZE=${IMAGE_HEADER_SIZE};
  WOLFBOOT_SIGN_${SIGN};
  WOLFBOOT_HASH_${HASH};
)
target_include_directories(libwolfboot PRIVATE
  deps/wolfBoot
  deps/wolfBoot/include
)
target_link_libraries(libwolfboot wolfcrypt)




set(KEYTOOLS_DIR ${PROJECT_BINARY_DIR}/../build-keytools)
set(SIGN_TOOL ${KEYTOOLS_DIR}/sign)
set(KEYGEN_TOOL ${KEYTOOLS_DIR}/keygen)
set(KEYSTORE ${KEYTOOLS_DIR}/keystore.c)
set(PRIVATE_KEY ${KEYTOOLS_DIR}/private_key.der)
include(keytoolSources.cmake)

# Signing tool always required
add_custom_command(
  OUTPUT ${SIGN_TOOL}
  COMMAND gcc -o ${SIGN_TOOL} tools/keytools/sign.c ${KEYTOOL_SOURCES}
          ${KEYTOOL_FLAGS}
  WORKING_DIRECTORY ${WOLFBOOT_ROOT}
  COMMENT "Building signing tool")

add_custom_command(
  OUTPUT ${KEYGEN_TOOL}
  COMMAND gcc -o ${KEYGEN_TOOL} tools/keytools/keygen.c ${KEYTOOL_SOURCES}
          ${KEYTOOL_FLAGS}
  WORKING_DIRECTORY ${WOLFBOOT_ROOT}
  COMMENT "Building keygen tool")

add_custom_command(
  OUTPUT ${KEYSTORE} ${PRIVATE_KEY}
  COMMAND ${KEYGEN_TOOL} ${KEYTOOL_OPTIONS} -g ${PRIVATE_KEY}
          -keystoreDir ${KEYTOOLS_DIR}
  WORKING_DIRECTORY ${WOLFBOOT_ROOT}
  COMMENT "Generating keystore.c and private key for signing")




add_custom_target(signed_app ALL DEPENDS app.bin keystore)
# Sign the binary.
add_custom_command(TARGET signed_app
  COMMAND IMAGE_HEADER_SIZE=${IMAGE_HEADER_SIZE} ${SIGN_TOOL} --ed25519 --sha256 
    ${PROJECT_BINARY_DIR}/app.bin 
    ${PRIVATE_KEY}
    ${APP_VERSION}
  COMMENT "Signing app.bin, creating app_v<x>_signed.bin"  
)

add_executable(bootloader.elf
  src/bl_main.c
  deps/wolfBoot/src/boot_arm.c
  deps/wolfBoot/src/image.c
  ${KEYSTORE}
)
# TODO: Move this into my replacement for target.h
target_compile_definitions(bootloader.elf PRIVATE
  APP_CODE_ADDRESS_CACHED=${APP_CODE_ADDRESS_CACHED}
)
target_link_libraries(bootloader.elf flash_lib)
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