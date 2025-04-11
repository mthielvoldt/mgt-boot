#!/bin/bash
signTool="$2"
KEY_FILE="$3"
VERSION=$(cat $4)
echo "Calling signing tool: $signTool"
echo "App Version: $VERSION"

IMAGE_HEADER_SIZE=$1 $signTool --ed25519 --sha256 app_offset.bin $KEY_FILE $VERSION
cp app_offset_v"$VERSION"_signed.bin app_offset_signed.bin
