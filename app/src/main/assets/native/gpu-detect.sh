#!/system/bin/sh
# Runs as root on Android. Prints GPU_VENDOR=<mali|adreno|powervr|other> and GPU_NODES.
# Read-only: it never writes to the system, kernel or bootloader.
vendor=other
nodes=""
for n in /dev/dri/renderD* /dev/dri/card* /dev/mali* /dev/kgsl-3d0 /dev/pvr_sync; do
  [ -e "$n" ] && nodes="$nodes $n"
done
case "$nodes" in
  *mali*) vendor=mali ;;
  *kgsl*) vendor=adreno ;;
  *pvr*)  vendor=powervr ;;
esac
if [ "$vendor" = other ]; then
  g=$(getprop ro.hardware.egl 2>/dev/null)
  case "$g" in mali*) vendor=mali ;; adreno*) vendor=adreno ;; powervr*) vendor=powervr ;; esac
fi
echo "GPU_VENDOR=$vendor"
echo "GPU_NODES=\"${nodes# }\""
