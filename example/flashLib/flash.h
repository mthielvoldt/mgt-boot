#ifndef FLASH_H
#define FLASH_H

#include <stdint.h>

/** flash_program
 * @param address Either an offset from the program memory base address, or an
 * absolute address.  Un-aligned addresses are permitted.
 * @param data the payload to be stored in the flash.
 * @param len the size of the payload. Valid range: [1, WOLFBOOT_SECTOR_SIZE]
 * @returns 0 on success, a negative value on failure.
 * Some flash memory models only support writing page-aligned addresses.  
 * Regardless, implementations must support un-aligned start and end addresses.
 */
int flash_program(uint32_t address, const uint8_t *data, int len);

/** flash_erase
 * Erase all the sectors within the specified range, accounting for flash sector
 * geometries.
 * @param start_address marks the start of the area to erase. start_address is
 * guaranteed to be aligned to WOLFBOOT_SECTOR_SIZE.
 * @param len specifies the size of the area to be erased. Len is guaranteed to 
 * be a multiple of WOLFBOOT_SECTOR_SIZE. 
 */
int flash_erase(uint32_t start_address, int len);

#endif // FLASH_H