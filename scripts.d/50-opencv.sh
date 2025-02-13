#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.8.1"
OPENCV_VERSION="4.8.1"

ffbuild_enabled() {
    [[ $TARGET == linux* ]] && return 0
    return 1
}

ffbuild_dockerbuild() {

	ENV DEBIAN_FRONTEND=noninteractive
	
	# Install build dependencies
	RUN apt-get update && \
	    apt-get install -y \
	        build-essential \
	        cmake \
	        git \
	        ninja-build \
	        pkg-config \
	        wget \
	        yasm \
	        nasm \
	        libtool \
	        autoconf \
	        automake \
	        && \
	    rm -rf /var/lib/apt/lists/*
	
	# Build OpenCV 4.x (static)
	ARG OPENCV_VERSION=4.8.1
	WORKDIR /src/opencv
	RUN git clone https://github.com/opencv/opencv.git . && \
	    git checkout $OPENCV_VERSION && \
	    mkdir build && \
	    cd build && \
	    cmake -GNinja \
	        -DBUILD_SHARED_LIBS=OFF \
	        -DBUILD_opencv_world=ON \
	        -DCMAKE_BUILD_TYPE=Release \
	        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
	        -DBUILD_TESTS=OFF \
	        -DBUILD_PERF_TESTS=OFF \
	        -DBUILD_EXAMPLES=OFF \
	        -DBUILD_DOCS=OFF \
	        -DWITH_JPEG=ON \
	        -DBUILD_JPEG=ON \
	        -DWITH_PNG=ON \
	        -DBUILD_PNG=ON \
	        -DWITH_TIFF=ON \
	        -DBUILD_TIFF=ON \
	        -DWITH_WEBP=ON \
	        -DBUILD_WEBP=ON \
	        -DWITH_OPENJPEG=ON \
	        -DBUILD_OPENJPEG=ON \
	        -DWITH_JASPER=OFF \
	        -DWITH_GTK=OFF \
	        -DWITH_FFMPEG=OFF \
	        .. && \
	    ninja && \
	    ninja install
}

ffbuild_configure() {
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}


ffbuild_cflags() {
    echo -I$FFBUILD_PREFIX/include
}

ffbuild_ldflags() {
    echo -L$FFBUILD_PREFIX/lib -lopencv_world
}
