#ifndef clock_port_H
#define clock_port_H

/** @file clock_port.h 
 * @brief Interface for initializing the system clock.
 * initClock() called by the bootloader before doing any other computations.  
 * This allows the clock to be set to a high speed to accelerate crypto checks. 
 * 
 * @note Any callers of these functions must adhere to the guarantees specified
 * in the notes below for each function. 
*/

/** initClock
 * @brief configures the system clock to a speed appropriate for computation-
 * heavy authenticity checks.
 * @return 0 for success, nonzero for an error.
 */
int initClock(void);

#endif