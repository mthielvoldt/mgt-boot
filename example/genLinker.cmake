# Generate Linker files for code running from: 
# - the root of Program mem (flash)
# - the app partition (offset by the header)

set(LINKER_SCRIPT_TEMPLATE src/XMC4700x2048.ld)

math(EXPR APP_CODE_ADDRESS_CACHED 
    "${PARTITION_BOOT_ADDRESS_CACHED} + ${IMAGE_HEADER_SIZE}" 
    OUTPUT_FORMAT HEXADECIMAL)
math(EXPR APP_CODE_ADDRESS_DIRECT
    "${PARTITION_BOOT_ADDRESS_DIRECT} + ${IMAGE_HEADER_SIZE}"
     OUTPUT_FORMAT HEXADECIMAL)
math(EXPR CODE_SIZE "${PARTITION_SIZE} - ${IMAGE_HEADER_SIZE}"
     OUTPUT_FORMAT HEXADECIMAL)

set(APP_PARTITION_LINKER_FILE  ${PROJECT_BINARY_DIR}/app_part_linker.ld)
set(ROOT_PARTITION_LINKER_FILE ${PROJECT_BINARY_DIR}/root_part_linker.ld)

function(config_link_script 
  input_file 
  output_file 
  CODE_ADDRESS_CACHED 
  CODE_ADDRESS_DIRECT 
  CODE_SIZE)
    configure_file(${input_file} ${output_file} @ONLY)
endfunction()

config_link_script(
  ${LINKER_SCRIPT_TEMPLATE}
  ${APP_PARTITION_LINKER_FILE} 
  ${APP_CODE_ADDRESS_CACHED}
  ${APP_CODE_ADDRESS_DIRECT}
  ${CODE_SIZE}
)
config_link_script(
  ${LINKER_SCRIPT_TEMPLATE}
  ${ROOT_PARTITION_LINKER_FILE}
  ${ARCH_FLASH_OFFSET_CACHED}
  ${ARCH_FLASH_OFFSET_DIRECT}
  ${PARTITION_SIZE}
)