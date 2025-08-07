# Generate Linker files for code running from: 
# - the root of Program mem (flash)
# - the app partition (offset by the header)

function(config_link_script 
  input_file 
  output_file 
  CODE_ADDRESS_CACHED 
  CODE_ADDRESS_DIRECT 
  CODE_SIZE)
    configure_file(${input_file} ${output_file} @ONLY)
endfunction()

set(ROOT_PARTITION_LINKER_FILE ${PROJECT_BINARY_DIR}/root_part_linker.ld)

config_link_script(
  ${LINKER_SCRIPT_TEMPLATE}
  ${ROOT_PARTITION_LINKER_FILE}
  ${PMEM_ROOT_ADDRESS_CACHED}
  ${PMEM_ROOT_ADDRESS_DIRECT}
  ${PARTITION_SIZE}
)

# This conditional is for projects that need to configure FW-update to be
# supported or unsupported (for example if only some MCUs have enough flash)
if(NOT DEFINED UPDATE_SUPPORTED OR UPDATE_SUPPORTED)

  set(APP_PARTITION_LINKER_FILE  ${PROJECT_BINARY_DIR}/app_part_linker.ld)

  math(EXPR ACTIVE_APP_ADDRESS_CACHED 
      "${PARTITION_ACTIVE_ADDRESS_CACHED} + ${IMAGE_HEADER_SIZE}" 
      OUTPUT_FORMAT HEXADECIMAL)
  math(EXPR APP_CODE_ADDRESS_DIRECT
      "${PARTITION_ACTIVE_ADDRESS_DIRECT} + ${IMAGE_HEADER_SIZE}"
      OUTPUT_FORMAT HEXADECIMAL)
  math(EXPR CODE_SIZE "${PARTITION_SIZE} - ${IMAGE_HEADER_SIZE}"
      OUTPUT_FORMAT HEXADECIMAL)

  config_link_script(
    ${LINKER_SCRIPT_TEMPLATE}
    ${APP_PARTITION_LINKER_FILE} 
    ${ACTIVE_APP_ADDRESS_CACHED}
    ${APP_CODE_ADDRESS_DIRECT}
    ${CODE_SIZE}
  )
endif()