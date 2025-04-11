# Generate the "app version" which is really just the time of build.
set(BUILD_TIME_HEADER ${PROJECT_BINARY_DIR}/build_time.h)
set(BUILD_TIME_TXT ${PROJECT_BINARY_DIR}/build_time.txt)

add_custom_command(OUTPUT ${BUILD_TIME_HEADER} ${BUILD_TIME_TXT}
  DEPENDS ${APP_DEPENDS} ${MGTBOOT_DIR}/tools/genBuildTime.sh
  COMMAND ${MGTBOOT_DIR}/tools/genBuildTime.sh ${PROJECT_BINARY_DIR}
)