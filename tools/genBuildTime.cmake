# Generate the "app version" which is really just the time of build.
set(BUILD_TIME_C ${PROJECT_BINARY_DIR}/build_time.c)
set(BUILD_TIME_TXT ${PROJECT_BINARY_DIR}/build_time.txt)

add_custom_command(OUTPUT ${BUILD_TIME_C} ${BUILD_TIME_TXT}
  DEPENDS ${APP_DEPENDS} ${MGTBOOT_DIR}/tools/genBuildTime.sh
  COMMAND ${MGTBOOT_DIR}/tools/genBuildTime.sh ${PROJECT_BINARY_DIR}
)