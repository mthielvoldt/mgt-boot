#include <stdint.h>
#include <stdbool.h>
#include <flash.h>
#include <image.h>
#include <boot_app.h>
#include <wolfboot/wolfboot.h>
#include <wolfboot/version.h>
#include <partitions.h>

typedef struct
{
  uint8_t rightType;
  uint8_t uncorrputed;
  uint8_t authentic;
  uint8_t newest;
  uint8_t unconfirmed;
} partition_status_t;

#define ACTIVE_PARTITION   (uint8_t *)PARTITION_ACTIVE_ADDRESS_DIRECT
#define DOWNLOAD_PARTITION (uint8_t *)PARTITION_UPDATE_ADDRESS
#define BACKUP_PARTITION   (uint8_t *)PARTITION_BACKUP_ADDRESS
#define TEST_RESULT_FLASH_ADDRESS     0x0C01C000u // S7 (logical) last 16kB sector.

#define STATUS_TEST_PASS 0xFFFFFFFFu

// Zero signifies an invalid header.
uint32_t version(uint8_t *partition)
{
  return wolfBoot_get_blob_version(partition);
}
bool hasIntegrity(uint8_t *partition)
{
  struct wolfBoot_image wbImage = {0};
  wolfBoot_open_image_address(&wbImage, partition);
  // 0 = verified.  -1 = verification failed.
  int wbReturn = wolfBoot_verify_integrity(&wbImage);
  return (wbReturn == 0);
}
bool authentic(uint8_t *partition)
{
  struct wolfBoot_image wbImage = {0};
  wolfBoot_open_image_address(&wbImage, partition);

  // verify_integrity sets wbImage.sha_hash and .sha_ok on success;
  int wbIntegrity = wolfBoot_verify_integrity(&wbImage);

  // Skip the time-consuming authenticity check if already failed.
  if (wbIntegrity != 0)
    return false;

  int wbAuthenticity = wolfBoot_verify_authenticity(&wbImage);
  return (wbAuthenticity == 0);
}

bool validNoncePresent(void)
{
  // TODO: Implement nonce check.
  return true;
}
void copyImage(uint8_t * dest, uint8_t * src)
{
  // Note: flash_erase checks each sector is blank before erasing.
  flash_erase((int32_t)dest, PARTITION_SIZE);

  // TODO: Optim: only write the image size.
  flash_program((int32_t)dest, src, PARTITION_SIZE);
}
bool testPassSaved()
{
  return *(uint32_t *)TEST_RESULT_FLASH_ADDRESS == STATUS_TEST_PASS;
}
void clearTestResult(void)
{
  if (testPassSaved())
  {
    flash_erase(TEST_RESULT_FLASH_ADDRESS, sizeof(uint32_t));
  }
}
void saveTestPass(void)
{
  const uint32_t testPass = STATUS_TEST_PASS;
  if (!testPassSaved())
  {
    flash_program(
        TEST_RESULT_FLASH_ADDRESS,
        (uint8_t *)&testPass,
        sizeof(uint32_t));
  }
}

void installUpdate(void)
{
  if (hasIntegrity(ACTIVE_PARTITION))
  {
    copyImage(BACKUP_PARTITION, ACTIVE_PARTITION);
  }
  clearTestResult();
  copyImage(ACTIVE_PARTITION, DOWNLOAD_PARTITION);
}

void restoreBackup(void)
{
  copyImage(ACTIVE_PARTITION, BACKUP_PARTITION);
  saveTestPass();
}

bool downloadHasGoodUpdate(void)
{
  if (!version(DOWNLOAD_PARTITION))
  {
    return false;
  }
  if (version(DOWNLOAD_PARTITION) <= version(ACTIVE_PARTITION))
  {
    return false;
  }
  // authenticity implies integrity.
  if (!authentic(DOWNLOAD_PARTITION))
  {
    return false;
  }
  return true;
}

bool activeImageOk(bool justInstalled)
{
  if (!version(ACTIVE_PARTITION))
  {
    return false;
  }

  /* If we just finished an update, authenticity is already checked and this app
  hasn't had a chance to perform the functional test.  Just check integrity.*/
  if (justInstalled)
  {
    if (!hasIntegrity(ACTIVE_PARTITION))
    {
      return false;
    }
  }
  /* App has now had a chance to run.  It's accountable to the functional test
  and authenticity checks.*/
  else
  {
    if (!testPassSaved())
    {
      if (validNoncePresent())
      {
        saveTestPass();
      }
      else
      {
        return false;
      }
    }
    // authenticity implies integrity.
    if (!authentic(ACTIVE_PARTITION))
    {
      return false;
    }
  }
  return true;
}

bool backupImageOk(void)
{
  if (!version(BACKUP_PARTITION))
  {
    return false;
  }
  // Implies integrity.
  if (!authentic(BACKUP_PARTITION))
  {
    return false;
  }
  return true;
}

void main(void)
{
  bool justInstalled = false;

  if (downloadHasGoodUpdate())
  {
    installUpdate();
    justInstalled = true; // save time; already authenticated
  }

  if (activeImageOk(justInstalled))
  {
    bootApp();
  }
  else // Active image has a problem.
  {
    if (backupImageOk())
    {
      restoreBackup();
      bootApp();
    }
  }

  // No good images.  Panic.
  for (;;)
    ;
}