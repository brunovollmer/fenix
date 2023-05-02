#!/bin/bash
# script executing on chroot when the rootfs is mounted

case $(readlink /proc/self/cwd) in
    *fenix*)
    echo "[e] only for chroot usage">&2
    exit 1
    ;;
esac

apt full-upgrade -y
sync

# upgrade bluetooth
cd /tmp/biped/reqs/bluez-5.65

./bootstrap
./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var
make -j8
make install

# link new bluetooth config
rm /lib/bluetooth/bluetoothd 
ln -s /usr/libexec/bluetooth/bluetoothd /lib/bluetooth/bluetoothd
rm /lib/systemd/system/bluetooth.service
cp /tmp/biped/reqs/configs/bluetooth.service /lib/systemd/system/

# Self-deleting
rm $0
