#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

usage() {
    local prog="`basename $1`"
    echo "Usage: $prog [-c] [-d] [-k] [-m] [-a] [-i path] [-h] [-v]"
    echo "       $prog -h for help."
    exit 1
}

showhelp() {
    echo "Usage: `basename $1`: [-c] [-d] [-k] [-m] [-a] [-i path] [-h] [-v]" 
    echo "  -c          build .config"
    echo "  -d          build dtbs"
    echo "  -k          build kernel"
    echo "  -m          build modules"
    echo "  -a          build all needed files, default operation"
    echo "  -i  <path>  install kernel, dtbs and modules to given path"
    echo "  -h          show this help"
    echo "  -v          turn on verbose"
    exit 1
}

build_config() {
    echo "build .config..."
    if [ ! -e .config ]; then
        make itop4412_defconfig
        if [ ! $? -eq 0 ]; then
            echo 'failed to build config'
            exit 1
        fi
    fi
}

build_kernel() {
    build_config
    echo "build kernel..."
    make uImage LOADADDR=0x40007000 -j$(nproc)
    if [ ! $? -eq 0 ]; then
        echo 'failed to build kernel'
        exit 1
    fi
}

build_dtbs() {
    echo "building dtbs..."
    make dtbs
    if [ ! $? -eq 0 ]; then
        echo 'failed to build dtbs'
        exit 1
    fi
}

build_modules() {
    echo "building modules..."
    make modules -j$(nproc)
    if [ ! $? -eq 0 ]; then
        echo 'failed to build kernel'
        exit 1
    fi
}

build_all() {
    echo "building all needed files..."
    build_kernel
    build_dtbs
    build_modules
}

do_install() {
    echo "install to $1 ..."

    INSTALL_DIR=$1
    KERNEL=arch/arm/boot/uImage
    DTB=arch/arm/boot/dts/exynos4412-itop-elite.dtb

    if [ ! -e $INSTALL_DIR ]; then
        mkdir $INSTALL_DIR
    fi

    if [ -e $KERNEL ]; then
        rm -rf $INSTALL_DIR/uImage
        cp $KERNEL $INSTALL_DIR
    fi

    if [ -e $DTB ]; then
        rm -rf $INSTALL_DIR/exynos4412-itop-elite.dtb
        cp $DTB $INSTALL_DIR
    fi

    rm -rf $INSTALL_DIR/lib
    make modules_install INSTALL_MOD_PATH=$INSTALL_DIR
}

if [ $# -gt 0 ] ; then

    while getopts "acdkmi:vh" opt
    do
        case $opt in
            a) build_all ;;
            c) build_config ;;
            d) build_dtbs ;;
            k) build_kernel ;;
            m) build_modules ;;
            i)
                do_install $OPTARG
                ;;
            v) set -x ;;
            h) showhelp $0 ;;
            ?) usage $0 ;;
        esac
    done
else
    usage $0
fi
