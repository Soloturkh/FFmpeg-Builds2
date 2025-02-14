#!/bin/bash
set -euo pipefail

DEBIAN_FRONTEND=noninteractive sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
build-essential cmake git ninja-build pkg-config \
wget yasm nasm libtool autoconf automake

# OpenCV + contrib static build
FF_CONFIGURE+=" --enable-libopencv"
FF_CFLAGS+=" -I/opt/ffbuild/include/opencv4"
FF_LDFLAGS+=" -L/opt/ffbuild/lib -lopencv_world"

add_pkg_config() {
  echo "Generating opencv.pc"
  cat >/opt/ffbuild/lib/pkgconfig/opencv_world.pc <<EOF
prefix=/opt/ffbuild
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include/opencv4

Name: OpenCV
Description: OpenCV (Open Computer Vision Library)
Version: 4.8.1
Libs: -L\${libdir} -lopencv_world
Cflags: -I\${includedir}
EOF
}

build() {
  OPENCV_VERSION="4.8.1"
  
  # OpenCV core
  git clone https://github.com/opencv/opencv.git --branch $OPENCV_VERSION --depth 1
  mkdir -p opencv/build && cd opencv/build
  
  # OpenCV contrib
  git clone https://github.com/opencv/opencv_contrib.git --branch $OPENCV_VERSION --depth 1 ../contrib
  
  cmake -GNinja \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_opencv_world=ON \
    -DOPENCV_EXTRA_MODULES_PATH=../contrib/modules \
    -DCMAKE_INSTALL_PREFIX=/opt/ffbuild \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DOPENCV_GENERATE_PKGCONFIG=ON \
    ..
  
  ninja install
  add_pkg_config
  cd ../..
}

# Build komutunu çağır
build
