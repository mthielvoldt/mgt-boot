

set(VERSION_FILE "${PROJECT_SOURCE_DIR}/version.txt")

# Function to read the version
function(read_version OUT_VAR)
    file(READ "${VERSION_FILE}" VERSION_CONTENT)
    string(STRIP "${VERSION_CONTENT}" VERSION_CONTENT)
    set(${OUT_VAR} "${VERSION_CONTENT}" PARENT_SCOPE)
endfunction()

# Function to increment the version
function(increment_version)
    # Check if version file exists, if not, create it
    if(NOT EXISTS "${VERSION_FILE}")
        file(WRITE "${VERSION_FILE}" "0") # Initial version
    endif()
    read_version(APP_VERSION)
    math(EXPR APP_VERSION "${APP_VERSION} + 1")
    file(WRITE "${VERSION_FILE}" "${APP_VERSION}")
    message(STATUS "App version incremented to: ${APP_VERSION}")
endfunction()

# add_custom_target(app_version
#   SOURCES ${VERSION_FILE}
#   COMMAND 
#     python -m ${VERSION_FILE} 
# )


# Increment the version on every build
# increment_version()


# Define the version as a CMake variable
set(APP_VERSION "13")
