#include <boot_app.h>
#include <stdint.h>
#include <partitions.h>

/** appAddress points to an address in program memory containing:
 * 4b: address of stack end
 * 4b: address of reset function
 * ... Rest of vector table ...
 */

#define VTOR (*(volatile uint32_t *)(0xE000ED08))


void bootApp(void)
{
  const uint32_t* appAddress = (uint32_t*)ACTIVE_APP_ADDRESS_CACHED;
  uint32_t stackStartAddress = *(appAddress + 0);
  uint32_t resetFnAddress = *(appAddress + 1);


  // disable interrupts
  asm volatile("cpsid i");

  VTOR = ((uint32_t)appAddress);


  /* Update stack pointer */
  asm volatile("msr msp, %0" ::"r"(stackStartAddress));

  // re-enable interrupts
  asm volatile("cpsie i");

  /* Unconditionally jump to resetFnAddress */
  asm volatile("mov pc, %0" ::"r"(resetFnAddress));
}