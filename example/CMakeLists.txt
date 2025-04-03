cmake_minimum_required(VERSION 3.22.1)
project(mgt_boot_example LANGUAGES C ASM)

include(config/mcuDetails.cmake)
include(config/cryptOptions.cmake)
include(simpleVersion.cmake)

include(genLinker.cmake)

add_subdirectory(flashLib)


add_subdirectory(.. mgt-boot)