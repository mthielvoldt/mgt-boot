cmake_minimum_required(VERSION 3.22.1)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

set(GENERATED_FILE_WARNING 
  "NOTICE: This file is generated.  Edits will be overwritten.")

set(ARCH ARM)
set(VTOR 1) # TODO: prune? 
set(SPMATH 1)
set(WOLFBOOT_TARGET xmc4700 CACHE INTERNAL "Target platform")
set(DSA ed25519)
list(APPEND KEYTOOL_OPTIONS --ed25519)
list(APPEND SIGN_OPTIONS WOLFBOOT_SIGN_ED25519)


# Wolfcrypt
set(WOLFBOOT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/deps/wolfBoot)
add_library(target INTERFACE)
add_library(user_settings INTERFACE)
target_compile_definitions(user_settings INTERFACE ${USER_SETTINGS} ${SIGN_OPTIONS})
target_include_directories(user_settings INTERFACE ${PROJECT_SOURCE_DIR}/src)

# provides library target: wolfcrypt
add_subdirectory(deps/wolfBoot/lib)

add_library(wolfboot
  deps/wolfBoot/src/libwolfboot.c
  deps/wolfBoot/src/boot_arm.c
  deps/wolfBoot/src/image.c
)
# removed defs:  WOLFBOOT_FLAGS_INVERT=1; WOLFBOOT_VERSION=1; TARGET_${WOLFBOOT_TARGET}
target_compile_definitions(wolfboot PUBLIC
  __WOLFBOOT;
  ARCH_${ARCH};
  ARCH_FLASH_OFFSET=${PMEM_ROOT_ADDRESS_DIRECT};
  IMAGE_HEADER_SIZE=${IMAGE_HEADER_SIZE};
  WOLFBOOT_SIGN_${SIGN};
  WOLFBOOT_HASH_${HASH};
)
target_include_directories(wolfboot PUBLIC
  deps/wolfBoot/include
)
target_link_libraries(wolfboot wolfcrypt)



# Signing, Key-generation, and Bin-assemble tools Build
set(KEYTOOLS_DIR ${PROJECT_BINARY_DIR}/../build-keytools)
file(MAKE_DIRECTORY ${KEYTOOLS_DIR})
set(SIGN_TOOL ${KEYTOOLS_DIR}/sign)
set(KEYGEN_TOOL ${KEYTOOLS_DIR}/keygen)
set(BIN_ASSEMBLE_TOOL ${KEYTOOLS_DIR}/bin-assemble)

include(keytoolSources.cmake)

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
    OUTPUT ${BIN_ASSEMBLE_TOOL}
    COMMAND gcc tools/bin-assemble/bin-assemble.c -o ${BIN_ASSEMBLE_TOOL}
    WORKING_DIRECTORY ${WOLFBOOT_ROOT}
    COMMENT "Building bin-assemble tool")


# Key Generation
set(KEYS_DIR ${PROJECT_BINARY_DIR}/../build-keys)
file(MAKE_DIRECTORY ${KEYS_DIR})
set(KEYSTORE ${KEYS_DIR}/keystore.c)
set(PRIVATE_KEY ${KEYS_DIR}/private_key.der)

add_custom_command(
  OUTPUT ${KEYSTORE} ${PRIVATE_KEY}
  DEPENDS ${KEYGEN_TOOL}
  COMMAND ${KEYGEN_TOOL} ${KEYTOOL_OPTIONS} -g ${PRIVATE_KEY}
          -keystoreDir ${KEYS_DIR}
  WORKING_DIRECTORY ${KEYTOOLS_DIR}
  COMMENT "Generating keystore and private key in ${KEYS_DIR}.")

# Signed App Binary
add_custom_command(DEPENDS app_offset.elf
  OUTPUT app_offset.bin
  COMMAND ${CMAKE_C_OBJCOPY} ARGS -O binary ${PROJECT_BINARY_DIR}/app_offset.elf
    app_offset.bin
)
add_custom_target(signed_app ALL 
  DEPENDS app_offset.bin ${SIGN_TOOL} ${PRIVATE_KEY}
)
add_custom_command(TARGET signed_app
  COMMAND IMAGE_HEADER_SIZE=${IMAGE_HEADER_SIZE} ${SIGN_TOOL} --ed25519 --sha256 
    app_offset.bin
    ${PRIVATE_KEY}
    ${APP_VERSION}
  COMMENT "Signing app.bin, creating app_v<x>_signed.bin"  
)

# Bootloader build
configure_file(src/partitions.h.in partitions.h)
add_executable(bootloader.elf
  src/bl_main.c
  ${KEYSTORE}
)
target_include_directories(bootloader.elf PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(bootloader.elf flash_lib wolfboot mcu_startup)
target_link_options(bootloader.elf PRIVATE 
  "-T${ROOT_PARTITION_LINKER_FILE}")

add_custom_command(TARGET bootloader.elf POST_BUILD
  COMMAND ${CMAKE_C_OBJCOPY} ARGS -O binary bootloader.elf bootloader.bin
)

# Assemble factory binary (bl+app combined)
add_custom_command(OUTPUT factory.bin
  DEPENDS signed_app bootloader.bin ${BIN_ASSEMBLE_TOOL}
  COMMAND ${BIN_ASSEMBLE_TOOL} 
    factory.bin 
    ${PMEM_ROOT_ADDRESS_DIRECT}
    bootloader.bin
    ${PARTITION_ACTIVE_ADDRESS_DIRECT}
    app_offset_v${APP_VERSION}_signed.bin
  COMMENT "Assembling factory image from bootloader and signed app"
)

# Copy image files to dedicated dir
set(IMAGES_DIR ${PROJECT_BINARY_DIR}/../build-images/v${APP_VERSION})
file(MAKE_DIRECTORY ${IMAGES_DIR})
add_custom_target(bundle_images ALL DEPENDS factory.bin)
add_custom_command(TARGET bundle_images
  COMMAND 
    cp ${PROJECT_BINARY_DIR}/app_offset.elf  ${IMAGES_DIR}/ &&
    cp ${PROJECT_BINARY_DIR}/app_root.elf    ${IMAGES_DIR}/ &&
    cp app_offset_v${APP_VERSION}_signed.bin ${IMAGES_DIR}/ &&
    cp app_offset_v${APP_VERSION}_signed.bin app_offset_latest_signed.bin &&
    cp bootloader.elf                        ${IMAGES_DIR}/ &&
    cp factory.bin                           ${IMAGES_DIR}/
)