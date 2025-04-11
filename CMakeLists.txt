cmake_minimum_required(VERSION 3.22.1)

## This file should be referenced as so:
# add_subdirectory(this/files/directory mgt-boot)
#
## it requires the following to be provided by the project's CMakeLists.txt: 
# Cmake variables to be set:
# - CMAKE_BUILD_TYPE: ["Debug" | "Release"]
# - ROOT_PARTITION_LINKER_FILE: path to MCU-appropriate .ld file.
# - MGTBOOT_DIR: absolute path to the mgt-boot dir.
# Targets:
# - MCUPort library.
# - flash_lib library that implements flash.h interface.
# - app_offset.elf executable


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
target_include_directories(target INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/stubs)
add_library(user_settings INTERFACE)
target_compile_definitions(user_settings INTERFACE ${USER_SETTINGS} ${SIGN_OPTIONS})

# provides library target: wolfcrypt
add_subdirectory(deps/wolfBoot/lib)

add_library(wolfboot
  deps/wolfBoot/src/libwolfboot.c
  deps/wolfBoot/src/boot_arm.c
  deps/wolfBoot/src/image.c
)
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
set(TOOLS_DIR ${PROJECT_BINARY_DIR}/../build-tools)
file(MAKE_DIRECTORY ${TOOLS_DIR})
set(SIGN_TOOL ${TOOLS_DIR}/sign)
set(KEYGEN_TOOL ${TOOLS_DIR}/keygen)
set(BIN_ASSEMBLE_TOOL ${TOOLS_DIR}/bin-assemble)

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
set(PUBLIC_KEY ${KEYS_DIR}/key_pub.der)
set(PRIVATE_KEY ${KEYS_DIR}/key.der)

# If either public or private key is missing, this custom command runs in place
# of the next custom command to generate keys, *and* keystore.c
add_custom_command(
  OUTPUT ${PUBLIC_KEY} ${PRIVATE_KEY}
  DEPENDS ${KEYGEN_TOOL}
  COMMAND ${KEYGEN_TOOL} ${KEYTOOL_OPTIONS} --exportpubkey -g key.der
    -keystoreDir ${KEYS_DIR}
  WORKING_DIRECTORY ${KEYS_DIR}
  COMMENT "Generating new key pair in ${KEYS_DIR}.")

add_custom_command(
  OUTPUT ${KEYSTORE}
  DEPENDS ${KEYGEN_TOOL} ${PUBLIC_KEY}
  COMMAND ${KEYGEN_TOOL} ${KEYTOOL_OPTIONS} -i ${PUBLIC_KEY}
    -keystoreDir ${KEYS_DIR}
  WORKING_DIRECTORY ${KEYS_DIR}
  COMMENT "Generating keystore.c in ${KEYS_DIR}.")

# Signed App Binary
add_custom_command(DEPENDS app_offset.elf
  OUTPUT app_offset.bin
  COMMAND ${CMAKE_C_OBJCOPY} ARGS -O binary ${PROJECT_BINARY_DIR}/app_offset.elf
    app_offset.bin
)
add_custom_target(signed_app ALL 
  DEPENDS app_offset.bin ${SIGN_TOOL} ${PRIVATE_KEY}
)
add_custom_command(TARGET signed_app POST_BUILD
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/tools/runSignTool.sh
    ${IMAGE_HEADER_SIZE} 
    ${SIGN_TOOL} 
    ${PRIVATE_KEY} 
    ${PROJECT_BINARY_DIR}/build_time.txt
  COMMENT "Signing app.bin, creating app_v<x>_signed.bin"  
)

# Bootloader build
configure_file(src/partitions.h.in partitions.h)
add_executable(bootloader.elf
  src/bl_main.c
  ${KEYSTORE}
)
target_include_directories(bootloader.elf PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(bootloader.elf flash_lib wolfboot MCUPort)
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
    app_offset_signed.bin
  COMMENT "Assembling factory image from bootloader and signed app"
)
