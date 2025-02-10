#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.10.0"

ffbuild_enabled() {
    [[ $TARGET == linux* ]] && return 0
    return 1
}

ffbuild_dockerbuild() {
    # OpenCV ve ek modülleri indir
    git clone "$SCRIPT_REPO" opencv
    cd opencv
    git checkout "$SCRIPT_COMMIT"

    # OpenCV ek modülleri (opencv_contrib) indir
    git clone https://github.com/opencv/opencv_contrib.git contrib
    cd contrib
    git checkout "$SCRIPT_COMMIT"
    cd ..

    # Build dizini oluştur ve CMake ile yapılandır
    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DOPENCV_EXTRA_MODULES_PATH=../contrib/modules \
        -DENABLE_PRECOMPILED_HEADERS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DWITH_OPENCL=OFF \
        -DWITH_V4L=ON \
        -DWITH_FFMPEG=ON \
        -DWITH_GSTREAMER=OFF \
        -DWITH_MSMF=OFF \
        -DWITH_DSHOW=OFF \
        -DWITH_AVFOUNDATION=OFF \
        -DWITH_1394=OFF \
        -DWITH_IPP=OFF \
        -DWITH_PROTOBUF=OFF \
        -DENABLE_CXX11=ON \
        -DBUILD_PKG_CONFIG=ON \
        -DOPENCV_ENABLE_PKG_CONFIG=ON \
        -DOPENCV_GENERATE_PKGCONFIG=ON \
        -DOPENCV_PC_FILE_NAME=opencv.pc \
        -DOPENCV_ENABLE_NONFREE=ON \
        -DBUILD_EXAMPLES=OFF \
        -DINSTALL_PYTHON_EXAMPLES=OFF \
        -DINSTALL_C_EXAMPLES=OFF \
        -DBUILD_ZLIB=ON \
        -DBUILD_SHARED_LIBS=OFF ..

    # Derleme ve kurulum
    make -j$(nproc)
    make install

    # opencv.pc ve diğer pkgconfig dosyalarını $FFBUILD_PREFIX/lib/pkgconfig'e taşı
    mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
    cp -f "unix-install/opencv.pc" "$FFBUILD_PREFIX/lib/pkgconfig/"
    cp -f "unix-install/opencv4.pc" "$FFBUILD_PREFIX/lib/pkgconfig/"
}

ffbuild_configure() {
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
