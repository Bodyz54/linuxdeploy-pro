#!/system/bin/sh
# READ-ONLY kernel capability report. It does not flash, patch, or load anything,
# so it cannot damage the phone or cause a bootloop.
if [ ! -r /proc/config.gz ]; then echo "kernel config not exposed (/proc/config.gz missing); skipping option check"; exit 0; fi
for k in CONFIG_SYSVIPC CONFIG_POSIX_MQUEUE CONFIG_DEVTMPFS CONFIG_UNIX CONFIG_DRM CONFIG_USB_SUPPORT CONFIG_POWER_SUPPLY CONFIG_EXT4_FS; do
  if zcat /proc/config.gz 2>/dev/null | grep -q "^$k=[ym]"; then echo "ok       $k"
  else echo "missing  $k  (feature may be limited; nothing was changed)"; fi
done
