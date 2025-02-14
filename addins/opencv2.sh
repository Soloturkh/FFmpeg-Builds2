#!/bin/bash
set -euo pipefail

DEBIAN_FRONTEND=noninteractive sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
build-essential cmake git ninja-build pkg-config \
wget yasm nasm libtool autoconf automake

# OpenCV + contrib static build
FF_CONFIGURE+=" --enable-libopencv"
PKG_CONFIG_LIBDIR+=":/usr/local/share/pkgconfig:/usr/local/bin/pkgconfig"
FF_CFLAGS+=" -I/usr/local/include/opencv4"
FF_LDFLAGS+=" -L/usr/local/lib"


build() {
  DEBIAN_FRONTEND=noninteractive apt install libopencv-dev
}

# Build komutunu çağır
build
