#!/bin/bash
OUT_DIR="$1"
BUILD_TIME=$(date +%s)
echo "generating build_time.(c/txt) in $OUT_DIR"

cat > $OUT_DIR/build_time.c<< EOF
#include <build_time.h>

uint32_t getBuildTime(void)
{
  return ${BUILD_TIME}U;
}
EOF

echo $BUILD_TIME > $OUT_DIR/build_time.txt