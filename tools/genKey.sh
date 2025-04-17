#!/bin/bash
KEYGEN_TOOL=$1
KEY_TYPE_OPTION=$2
OUT_DIR=$3

# if private key is missing, generate. 
if [ ! -f "$OUT_DIR/key.der" ]; then
  echo "Gen $OUT_DIR/key.der" 
  $KEYGEN_TOOL $KEY_TYPE_OPTION --exportpubkey -g key.der -keystoreDir $OUT_DIR
elif [ -f "$OUT_DIR/key_pub.der" ]; then
  echo "key.der/key_pub.der exist.  Touching existing keys without changes."
  touch $OUT_DIR/key.der $OUT_DIR/key_pub.der
else
  echo "Error: key.der exists, but key_pub.der does not."
  exit 1
fi
