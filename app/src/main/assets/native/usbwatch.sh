#!/system/bin/sh
# Root side, runs while the container is started: lets the chroot read USB and gamepad nodes,
# including devices plugged in later. native-stop.sh kills it and restores /dev/input permissions.
while :; do
  chmod -R a+rw /dev/bus/usb 2>/dev/null
  chmod 666 /dev/input/event* /dev/input/js* 2>/dev/null
  chmod 666 /dev/uinput /dev/uhid 2>/dev/null
  sleep 3
done
