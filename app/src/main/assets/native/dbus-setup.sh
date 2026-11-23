#!/bin/bash
# Inside the chroot: system + session D-Bus support.
set -e
apt-get -y install dbus dbus-x11 dbus-user-session
mkdir -p /run/dbus /var/lib/dbus
[ -s /etc/machine-id ] || dbus-uuidgen --ensure=/etc/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id
pgrep -x dbus-daemon >/dev/null || dbus-daemon --system --fork
