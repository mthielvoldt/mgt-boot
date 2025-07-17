/** Stub implementation of a flash library - MCU agnostic.
 * 
 * This stub serves as a placeholder in the mgt-boot example, which does not
 * assume any specific MCU.
 * 
 * In an embedded project, a flash driver must be provided.  This would likely
 * be an adapter between a manufacturer-HAL and the interface specified in 
 * flash_hal.h
 */
#include <flash_port.h>

int flash_program(uint32_t address, const uint8_t *data, uint32_t len) {}

int flash_erase(uint32_t start_address, uint32_t len) {}

