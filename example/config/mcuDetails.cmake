# This file sets variables that are determined by the selection of MCU.

set(CMAKE_C_FLAGS "-Wa,-mcpu=cortex-m4 -mfloat-abi=hard -mcpu=cortex-m4 -mthumb -fdata-sections -ffunction-sections -ffreestanding")

# "-Wa," must preceed each option passed to the assembler.
set(ASSEMBLER_FLAGS "-Wa,-mcpu=cortex-m4")

set(FMT_PORT "XMC4")
set(MCU_VARIANT "XMC4700")
set(MCU_SPEED_VARIANT "F144")
set(MCU_MEM_VARIANT "2048")

# add_compile_definitions(XMC4400_F100x512)
add_compile_definitions(${MCU_VARIANT}_${MCU_SPEED_VARIANT}x${MCU_MEM_VARIANT})

set(STARTUP_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/startup_XMC4700.S)
set(LINKER_SCRIPT_TEMPLATE ${CMAKE_CURRENT_SOURCE_DIR}/src/XMC4700x2048.ld)