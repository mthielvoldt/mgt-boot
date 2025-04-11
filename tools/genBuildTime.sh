#!/bin/bash
OUT_DIR="$1"
BUILD_TIME=$(date +%s)
echo "generating build_time.(h/txt) in $OUT_DIR"

echo "#pragma once" > $OUT_DIR/build_time.h
echo "#define BUILD_TIME $BUILD_TIME" >> $OUT_DIR/build_time.h
echo $BUILD_TIME > $OUT_DIR/build_time.txt