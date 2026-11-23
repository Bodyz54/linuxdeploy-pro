#!/system/bin/sh
# usage: mount-extras.sh <ROOT>   (root, Android sh). Idempotent; undone by normal umount.
ROOT="$1"; [ -d "$ROOT" ] || exit 1
is_m() { grep -q " $1 " /proc/mounts; }
# battery / power: read-only view of Android's power_supply class
if [ -d /sys/class/power_supply ] && ! is_m "$ROOT/sys/class/power_supply"; then
  mkdir -p "$ROOT/sys/class/power_supply"
  mount --bind /sys/class/power_supply "$ROOT/sys/class/power_supply" 2>/dev/null &&
    mount -o remount,ro,bind "$ROOT/sys/class/power_supply" 2>/dev/null
fi
[ -d /dev/bus/usb ] && chmod -R a+rw /dev/bus/usb 2>/dev/null
chmod a+rw /dev/dri/* /dev/mali* /dev/kgsl-3d0 2>/dev/null
# share Termux tmp so the X11 socket (/tmp/.X11-unix/X0) is visible inside the chroot
TMPX=/data/data/com.termux/files/usr/tmp
if [ -d "$TMPX" ] && ! is_m "$ROOT/tmp"; then
  mkdir -p "$ROOT/tmp"; mount --bind "$TMPX" "$ROOT/tmp"
fi
exit 0
