#!/usr/bin/env bash

#
#  Build Script for RenderZenith!
#

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Source from build config
if [ $# -ne 0 ]; then
    if [ ! -f $1 ]; then
        echo "$1 not found in current directory!"
        exit 1
    else
	source $1
    fi
elif [ -f build.config.default ]; then
    source build.config.default
else
    echo "build.config.default not found in current directory!"
    exit 1
fi

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"

# Create output directory
mkdir -p $KBUILD_OUTPUT

# Functions
function clean_all {
    rm -rf $AK2_DIR/$MODULES_DIR/*
    rm -f $AK2_DIR/$KERNEL
    rm -f $AK2_DIR/zImage
    echo
    make O=$KBUILD_OUTPUT clean && make O=$KBUILD_OUTPUT mrproper
}

function make_kernel {
    echo
    make $DEFCONFIG O=$KBUILD_OUTPUT $EXTRA_CONFIGS
    
    if [[ $CC = *clang* ]]; then
    # Clang
    echo
    echo "Building with Clang..."
    echo
    make $THREAD \
         ARCH=$ARCH \
	 CC="$CC" \
	 CLANG_TRIPLE=$CLANG_TRIPLE \
         CROSS_COMPILE="$CROSS_COMPILE" \
         KBUILD_BUILD_USER=$KBUILD_BUILD_USER \
         KBUILD_BUILD_HOST=$KBUILD_BUILD_HOST \
         LOCALVERSION=$LOCALVERSION \
         O=$KBUILD_OUTPUT \
         $EXTRA_CONFIGS
    else
    # GCC
    echo
    echo "Building with GCC..."
    echo
    make $THREAD \
         ARCH=$ARCH \
         CROSS_COMPILE="$CROSS_COMPILE" \
         KBUILD_BUILD_USER=$KBUILD_BUILD_USER \
         KBUILD_BUILD_HOST=$KBUILD_BUILD_HOST \
         LOCALVERSION=$LOCALVERSION \
         O=$KBUILD_OUTPUT \
         $EXTRA_CONFIGS
    fi
}

function make_modules {
    # Remove and re-create modules directory
    rm -rf $MODULES_DIR
    mkdir -p $MODULES_DIR

    # Copy modules over
    echo
    find $KBUILD_OUTPUT -name '*.ko' -exec cp -v {} $MODULES_DIR \;

    # Strip modules
    ${CROSS_COMPILE}strip --strip-unneeded $MODULES_DIR/*.ko

    # Sign modules
    if grep -Fxq "CONFIG_MODULE_SIG=y" $KBUILD_OUTPUT/.config
    then
        find $MODULES_DIR -name '*.ko' -exec $KBUILD_OUTPUT/scripts/sign-file sha512 $KBUILD_OUTPUT/certs/signing_key.pem $KBUILD_OUTPUT/certs/signing_key.x509 {} \;
    fi
}

function make_zip {
    cp -vr $ZIMAGE_DIR/$KERNEL $AK2_DIR/zImage
    pushd $AK2_DIR
    zip -r9 $KERNEL_ZIP.zip *

    if [ ! -d "$ZIP_MOVE" ]
    then
        sudo mkdir -p $ZIP_MOVE
	sudo chown -R $(whoami) $ZIP_MOVE
    fi

    mv $KERNEL_ZIP.zip $ZIP_MOVE
    popd
}

make_kernel

