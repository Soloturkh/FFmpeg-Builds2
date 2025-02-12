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

	apt update -y
	DEBIAN_FRONTEND=noninteractive apt upgrade -y
	
	#Generic tools
	DEBIAN_FRONTEND=noninteractive apt install -y build-essential cmake pkg-config unzip yasm git checkinstall curl software-properties-common
	#image i/o Libs
	DEBIAN_FRONTEND=noninteractive apt install -y libjpeg-dev libpng-dev libtiff-dev
	#Video/Audio Libs
	# Install basic codec libraries
	DEBIAN_FRONTEND=noninteractive apt install -y libavcodec-dev libavformat-dev libswscale-dev

	# Install GStreamer development libraries
	DEBIAN_FRONTEND=noninteractive apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

	# Install additional codec and format libraries
	DEBIAN_FRONTEND=noninteractive apt install -y libxvidcore-dev libx264-dev libopus-dev libv4l-dev

	# Install additional audio codec libraries
	DEBIAN_FRONTEND=noninteractive apt install -y libmp3lame-dev libvorbis-dev

	# Install FFmpeg (which includes libavresample functionality)
	DEBIAN_FRONTEND=noninteractive apt install -y ffmpeg

	# Optional: Install VA-API for hardware acceleration
	DEBIAN_FRONTEND=noninteractive apt install -y libva-dev
	
	# Install video capture libraries and utilities
	DEBIAN_FRONTEND=noninteractive apt install -y libdc1394-25 libdc1394-dev libxine2-dev libv4l-dev v4l-utils
	
	#Create a symbolic link for video device header
	ln -s /usr/include/libv4l1-videodev.h /usr/include/linux/videodev.h
	
	#GTK lib for the graphical user functionalites coming from OpenCV highghui module
	DEBIAN_FRONTEND=noninteractive apt install -y libgtk-3-dev
	#Parallelism library C++ for CPU
	DEBIAN_FRONTEND=noninteractive apt install -y libtbb-dev
	#Optimization libraries for OpenCV
	DEBIAN_FRONTEND=noninteractive apt install -y libatlas-base-dev gfortran
	#Optional libraries:
	DEBIAN_FRONTEND=noninteractive apt install -y libprotobuf-dev protobuf-compiler
	DEBIAN_FRONTEND=noninteractive apt install -y libgoogle-glog-dev libgflags-dev
	DEBIAN_FRONTEND=noninteractive apt install -y libgphoto2-dev libeigen3-dev libhdf5-dev doxygen
	DEBIAN_FRONTEND=noninteractive apt install -y libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev python3-numpy

	#python
 	# En son Python sürümünü almak için Deadsnakes PPA ekle
	# DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:deadsnakes/ppa
	# DEBIAN_FRONTEND=noninteractive apt update -y
 	# Python 3.20 ve gerekli kütüphaneleri yükle
   	# DEBIAN_FRONTEND=noninteractive apt install -y python3.20 python3.20-dev python3.20-venv python3.20-distutils
     	# Varsayılan python3 sürümünü Python 3.20 olarak ayarla
	# update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.20 1
	# update-alternatives --config python3
	# Pip'i güncelle
	# curl -sS https://bootstrap.pypa.io/get-pip.py | python3.20
    # OpenCV ve ek modülleri indir
    # git clone "$SCRIPT_REPO" opencv
    # cd opencv
    # git checkout "$SCRIPT_COMMIT"

    # OpenCV ek modülleri (opencv_contrib) indir
    # git clone https://github.com/opencv/opencv_contrib.git contrib
    # cd contrib
    # git checkout "$SCRIPT_COMMIT"
    # cd ..

    # Build dizini oluştur ve CMake ile yapılandır
    mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
    mkdir build && cd build

    if command -v nvidia-smi &> /dev/null; then
    		echo "NVIDIA GPU algılandı, CUDA desteği ve TBB devre dışı bırakılıyor..."
    		GPU_OPTIONS="-DWITH_CUDA=ON \
    					  -DWITH_CUDNN=ON \
    					  -DOPENCV_DNN_CUDA=ON \
    					  -DCUDA_ARCH_BIN=ALL \
    					  -DENABLE_FAST_MATH=ON \
    					  -DCUDA_FAST_MATH=ON \
    					  -DWITH_CUBLAS=ON \
    					  -DBUILD_opencv_cudacodec=ON"
    		TBB_OPTION="-DWITH_TBB=OFF"  # GPU mevcutsa TBB devre dışı
    else
    		echo "NVIDIA GPU algılanmadı, sadece CPU desteği etkinleştiriliyor..."
    		GPU_OPTIONS="-DWITH_CUDA=OFF \
    					  -DWITH_CUDNN=OFF \
    					  -DOPENCV_DNN_CUDA=OFF \
    					  -DWITH_CUBLAS=OFF \
    					  -DBUILD_opencv_cudacodec=OFF"
    		TBB_OPTION="-DWITH_TBB=ON"  # GPU yoksa TBB etkin
    fi

    cmake \
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
        -DENABLE_PRECOMPILED_HEADERS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
		$GPU_OPTIONS \
		$TBB_OPTION \
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
        -DCMAKE_INSTALL_PKGCONFIGDIR=lib/pkgconfig \
	-DOPENCV_PC_FILE_NAME=opencv4.pc \
	-DCMAKE_INSTALL_LIBDIR=lib \
        -DOPENCV_ENABLE_NONFREE=ON \
        -DBUILD_EXAMPLES=OFF \
		-DINSTALL_PYTHON_EXAMPLES=OFF \
		-DINSTALL_C_EXAMPLES=OFF \
		-DBUILD_ZLIB=ON \
		-DBUILD_SHARED_LIBS=OFF ..
   
    # Derleme ve kurulum
    make -j$(nproc)
    make install
    ldconfig

    # opencv.pc dosyasını tüm build dizininde ara ve kopyala
    #export PKG_CONFIG_PATH="$FFBUILD_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
    #mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
    found_pc_files=$(find . -name 'opencv.pc' -o -name 'opencv4.pc')
    
    if [[ -z "$found_pc_files" ]]; then
        echo "HATA: opencv.pc veya opencv4.pc dosyası bulunamadı!"
        exit 1
    fi

    while IFS= read -r pc_file; do
        echo "Bulundu: $pc_file -> $FFBUILD_PREFIX/lib/pkgconfig/"
	#cat "$pc_file"  # Dosya içeriğini ekrana yazdır
        cp -f "$pc_file" "$FFBUILD_PREFIX/lib/pkgconfig/"
    done <<< "$found_pc_files"
    echo "kopyası"
    cat "$FFBUILD_PREFIX/lib/pkgconfig/opencv4.pc"
    install -d -m 0755 $FFBUILD_PREFIX/lib/pkgconfig
    /usr/bin/install -c -m 644 opencv4.pc $FFBUILD_PREFIX/lib/pkgconfig
}

ffbuild_configure() {
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}

#ffbuild_cflags() {
#    echo -I$FFBUILD_PREFIX/include/opencv4
#}

#ffbuild_ldflags() {
#    echo -L$FFBUILD_PREFIX/lib
#}
