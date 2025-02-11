#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.10.0"
OPENCV_VERSION="4.10.0"

ffbuild_enabled() {
    [[ $TARGET == linux* ]] && return 0
    return 1
}

ffbuild_dockerdl() {
	default_dl .
        echo "git submodule update --init --recursive --depth=1"
	if [ ! -d "opencv_contrib" ]; then
		echo "git clone --branch \${OPENCV_VERSION} https://github.com/opencv/opencv_contrib.git"
	fi
}

ffbuild_dockerbuild() {
    # Gerekli bağımlılıkları yükle
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential cmake pkg-config unzip yasm git \
        libjpeg-dev libpng-dev libtiff-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libx264-dev libopus-dev libv4l-dev \
        libmp3lame-dev libvorbis-dev \
        libva-dev libdc1394-dev libxine2-dev \
        libgtk-3-dev libtbb-dev libatlas-base-dev gfortran \
        libprotobuf-dev protobuf-compiler libhdf5-dev

    # Video device header fix
    ln -sf /usr/include/libv4l1-videodev.h /usr/include/linux/videodev.h

    mkdir build && cd build

    # CMake ayarları
    local CMAKE_OPTIONS=(
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_PERF_TESTS=OFF
        -DWITH_FFMPEG=ON
        -DWITH_V4L=ON
        -DWITH_GTK=ON
        -DWITH_OPENCL=OFF
        -DENABLE_CXX11=ON
        -DOPENCV_GENERATE_PKGCONFIG=ON
        -DOPENCV_ENABLE_NONFREE=ON
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_INSTALL_LIBDIR=lib
        -DCMAKE_INSTALL_PKGCONFIGDIR=lib/pkgconfig
    )

    if command -v nvidia-smi &>/dev/null; then
        CMAKE_OPTIONS+=(
            -DWITH_CUDA=ON
            -DWITH_CUDNN=ON
            -DOPENCV_DNN_CUDA=ON
            -DCUDA_ARCH_BIN=ALL
            -DENABLE_FAST_MATH=ON
            -DWITH_TBB=OFF
        )
    else
        CMAKE_OPTIONS+=(
            -DWITH_CUDA=OFF
            -DWITH_TBB=ON
        )
    fi

    cmake "${CMAKE_OPTIONS[@]}" ..
    
    make -j$(nproc)
    make install

    # .pc dosyalarını doğrulama
    echo "opencv.pc içeriği:"
    cat "$FFBUILD_PREFIX/lib/pkgconfig/opencv4.pc"
    
    # opencv4.pc -> opencv.pc sembolik linki
    ln -sfv opencv4.pc "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
}

ffbuild_configure() {
    #echo --enable-libopencv  --pkg-config-flags="--define-variable=prefix=$FFBUILD_PREFIX"
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}

ffbuild_cflags() {
    echo -I$FFBUILD_PREFIX/include/opencv4
}

ffbuild_ldflags() {
    echo -L$FFBUILD_PREFIX/lib
}
