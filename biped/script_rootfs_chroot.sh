#!/bin/bash
# script executing on chroot when the rootfs is mounted

case $(readlink /proc/self/cwd) in
    *fenix*)
    echo "[e] only for chroot usage">&2
    exit 1
    ;;
esac

echob () {
    echo "==BIPED-CHROOT==" $@
}

install_bluez() {
    # upgrade bluetooth
    cd /tmp/biped/reqs/bluez-5.65

    echob "Installing bluez"
    ./bootstrap
    ./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var
    make -j8
    make install
    echob "Installing bluez done"

    # link new bluetooth config
    echob "Linking new bluetooth config"
    rm /lib/bluetooth/bluetoothd
    ln -s /usr/libexec/bluetooth/bluetoothd /lib/bluetooth/bluetoothd
    rm /lib/systemd/system/bluetooth.service
    cp /tmp/biped/reqs/configs/bluetooth.service /lib/systemd/system/
    echob "Linking new bluetooth config done"
}

install_python() {
    # install python3.8.15
    cd /tmp/biped/reqs/Python-3.8.15

    echob "Installing python3.8.15"
    ./configure --enable-optimizations
    make -j8
    make altinstall
    echob "Installing python3.8.15 done"
}

install_cmake() {
    # install cmake3.18.4
    cd /tmp/biped/reqs/cmake-3.18.4/

    echob "Installing cmake3.18.4"
    rm /tmp/biped/reqs/cmake-3.18.4/CMakeCache.txt
    ./configure
    make -j6
    make install
    echob "Installing cmake3.18.4 done"
}

install_librealsense() {
    # install librealsense2.53.1
    cd /tmp/biped/reqs/librealsense-2.53.1

    echob "Installing librealsense2.53.1"
    mkdir build && cd build
    cmake ../ -DBUILD_PYTHON_BINDINGS:bool=true -DFORCE_RSUSB_BACKEND:bool=true -DBUILD_WITH_CUDA:bool=false -DBUILD_GRAPHICAL_EXAMPLES:bool=false -DCMAKE_BUILD_TYPE=release
    make -j8

    # set udev rules before install
    cd /tmp/biped/reqs/librealsense-2.53.1
    yes | bash -e ./scripts/setup_udev_rules.sh

    cd ./build/
    make install
    echob "Installing librealsense2.53.1 done"
}

apt full-upgrade -y
sync

ln -s /tmp/biped/reqs /home/khadas/reqs

install_bluez
install_python
install_cmake
install_librealsense

# delete temp folder for reduce final image size
rm -rf /tmp/biped
# Self-deleting
rm $0
