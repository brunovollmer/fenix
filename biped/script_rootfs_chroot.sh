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
    # echo in stderr too for debug
    # echo "==BIPED-CHROOT==" $@ >&2
}

# create a function is_directory_exist to check if directory exist
is_directory_exist() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}

install_bluez() {
    # upgrade bluetooth
    PACKAGE="bluez-5.65"
    echob "Installing $PACKAGE"

    # check if not is_directory_exist
    if ! is_directory_exist "/tmp/biped/build_reqs/$PACKAGE/"; then
        cd /tmp/biped/reqs/$PACKAGE
        echob "$PACKAGE is not already built, building now"
        ./bootstrap
        ./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var
        make -j8
        mv /tmp/biped/reqs/$PACKAGE /tmp/biped/build_reqs/$PACKAGE
    else
        echob "$PACKAGE is already built, skipping build"
    fi

    cd /tmp/biped/build_reqs/$PACKAGE
    make install
    echob "Installing $PACKAGE done"

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
    PACKAGE="Python-3.8.15"
    echob "Installing $PACKAGE"

    # check if not is_directory_exist
    if ! is_directory_exist "/tmp/biped/build_reqs/$PACKAGE/"; then
        cd /tmp/biped/reqs/$PACKAGE
        echob "$PACKAGE is not already built, building now"
        ./configure --enable-optimizations
        make -j8
        mv /tmp/biped/reqs/$PACKAGE /tmp/biped/build_reqs/$PACKAGE
    else
        echob "$PACKAGE is already built, skipping build"
    fi

    cd /tmp/biped/build_reqs/$PACKAGE
    make altinstall
    echob "Installing $PACKAGE done"
}

install_cmake() {
    # install cmake3.18.4
    PACKAGE="cmake-3.18.4"
    echob "Installing $PACKAGE"

    # # check if not is_directory_exist
    # if ! is_directory_exist "/tmp/biped/build_reqs/$PACKAGE/"; then
    #     echob "$PACKAGE is not already built, building now"
    #     cd /tmp/biped/reqs/$PACKAGE
    #     rm /tmp/biped/reqs/cmake-3.18.4/CMakeCache.txt
    #     ./configure
    #     make -j8
    # else
    #     echob "$PACKAGE is already built, skipping build, just configuring"
    #     rm -rf /tmp/biped/reqs/$PACKAGE
    #     mv /tmp/biped/build_reqs/$PACKAGE /tmp/biped/reqs/
    #     cd /tmp/biped/reqs/$PACKAGE
    #     ./configure
    # fi

    # cd /tmp/biped/reqs/$PACKAGE
    # ./bootstrap
    # make -j8
    # make install
    # rm -rf /tmp/biped/build_reqs/$PACKAGE
    # cp /tmp/biped/reqs/$PACKAGE /tmp/biped/build_reqs/

    # build method is very very slow, so we just install from deb file
    cd /tmp/biped/reqs/cmake

    dpkg -i libjsoncpp24_1.9.4-4_arm64.deb
    dpkg -i librhash0_1.3.8-1_arm64.deb
    dpkg -i cmake-data_3.18.4-2+deb11u1_all.deb
    dpkg -i cmake_3.18.4-2+deb11u1_arm64.deb

    echob "Installing $PACKAGE done"
}

install_virtual_env() {
    echob "Installing virtualenv"
    python3.8 -m pip install --user virtualenv
    
    mkdir -p /opt/biped/venv/
    cd /opt/biped/venv
    python3.8 -m venv venv-copilot
    source venv-copilot/bin/activate

    # for logging, should show 3.8.15
    echob "Virtualenv python version: "
    python --version

    echob "Installing virtualenv done"

    # downgrade pip
    echob "Downgrading pip"
    pip install pip==22.3
    echob "Downgrading pip done"
}

install_librealsense() {
    # install librealsense2.53.1
    # installing in /home/khadas/ folder else it will not work
    # (deleting after)
    PACKAGE="librealsense-2.53.1"
    echob "Installing $PACKAGE"

    mkdir -p /home/khadas/$PACKAGE

    # check if not is_directory_exist
    if ! is_directory_exist "/tmp/biped/build_reqs/$PACKAGE/"; then
        mv /tmp/biped/reqs/$PACKAGE /home/khadas
        cd /home/khadas/$PACKAGE
        echob "$PACKAGE is not already built, building now"
        mkdir build && cd build
        /usr/bin/cmake ../ -DBUILD_PYTHON_BINDINGS:bool=true -DFORCE_RSUSB_BACKEND:bool=true -DBUILD_WITH_CUDA:bool=false -DBUILD_GRAPHICAL_EXAMPLES:bool=false -DCMAKE_BUILD_TYPE=release
        make -j8
    else
        echob "$PACKAGE is already built, skipping build"
        mv /tmp/biped/build_reqs/$PACKAGE /home/khadas
    fi

    # set udev rules before install
    cd /home/khadas/$PACKAGE
    yes | bash -e ./scripts/setup_udev_rules.sh
    cd ./build/
    make install
    cp -r /home/khadas/$PACKAGE /tmp/biped/build_reqs/
    cd /home
    rm -rf /home/khadas/$PACKAGE
    echob "Installing $PACKAGE done"
}

install_copilot() {
    echob "Installing copilot pip requirements"
    cd /opt/biped/copilot
    pip install -r requirements.txt
    echob "Installing copilot pip requirements done"
}

apt full-upgrade -y
sync

ln -s /tmp/biped/reqs /home/khadas/reqs
mkdir -p /tmp/biped/build_reqs/

install_bluez
install_python
install_cmake

install_virtual_env # nexts steps need to be in virtual env
install_librealsense
install_copilot

# Self-deleting
rm $0
