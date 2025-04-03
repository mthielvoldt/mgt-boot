set(PARTITION_SIZE              0x40000) # 512kB
set(SECTOR_SIZE                 0x40000) # 256kB (5.5s erases)
set(ARCH_FLASH_OFFSET_DIRECT       0x0C000000) # non-cached access
set(ARCH_FLASH_OFFSET_CACHED       0x08000000)
set(PARTITION_BOOT_ADDRESS_DIRECT  0x0C040000) # sector 9
set(PARTITION_BOOT_ADDRESS_CACHED  0x08040000) # for linker
set(PARTITION_UPDATE_ADDRESS       0x0C080000) # sector 10
set(PARTITION_SWAP_ADDRESS         0x0C0C0000) # sector 11

# Arm MCUs often have alignment requirements for the vector table.
# Refer to for Vector Table Offset Register (VTOR) section in MCU reference.
# IMAGE_HEADER_SIZE must be a multiple of the VT alignment requirement.  
set(IMAGE_HEADER_SIZE 1024)

set(CMAKE_C_FLAGS "-Wa,-mcpu=cortex-m4 -mfloat-abi=hard -mcpu=cortex-m4 -mthumb -fdata-sections -ffunction-sections -ffreestanding")

# "-Wa," must preceed each option passed to the assembler.
set(ASSEMBLER_FLAGS "-Wa,-mcpu=cortex-m4")

set(FMT_PORT "XMC4")
set(MCU_VARIANT "XMC4700")
set(MCU_SPEED_VARIANT "F144")
set(MCU_MEM_VARIANT "2048")

# add_compile_definitions(XMC4400_F100x512)
add_compile_definitions(${MCU_VARIANT}_${MCU_SPEED_VARIANT}x${MCU_MEM_VARIANT})