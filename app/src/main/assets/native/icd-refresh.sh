#!/bin/bash
# Inside the chroot, runs on EVERY Start. usage: icd-refresh.sh <mali|adreno|powervr|software>
# Creates the Vulkan ICD directory and manifest automatically and finds the driver library itself.
V="${1:-software}"
mkdir -p /usr/share/vulkan/icd.d /etc/vulkan/icd.d
find_lib() { for n in "$@"; do
  for d in /opt/panvk /opt/panvk-g57 /usr/lib/aarch64-linux-gnu /usr/lib/x86_64-linux-gnu /usr/lib /usr/local/lib; do
    [ -f "$d/$n" ] && { echo "$d/$n"; return; }
  done; done; }
case "$V" in
  mali)   LIB=$(find_lib libvulkan_panfrost.so libvulkan_panvk.so); NAME=panfrost ;;
  adreno) LIB=$(find_lib libvulkan_freedreno.so);                   NAME=freedreno ;;
  *)      LIB=$(find_lib libvulkan_lvp.so);                          NAME=lvp ;;
esac
rm -f /usr/share/vulkan/icd.d/panfrost_icd*.json /usr/share/vulkan/icd.d/freedreno_icd*.json
if [ -z "$LIB" ]; then
  echo "ICD: no $NAME driver library found, falling back to software (llvmpipe)"
  printf 'export LIBGL_ALWAYS_SOFTWARE=1\nexport GALLIUM_DRIVER=llvmpipe\n' > /etc/profile.d/gpu.sh
  exit 0
fi
ICD=/usr/share/vulkan/icd.d/${NAME}_icd.json
printf '{ "file_format_version": "1.0.0", "ICD": { "library_path": "%s", "api_version": "1.3.0" } }\n' "$LIB" > "$ICD"
cp "$ICD" /etc/vulkan/icd.d/
{
  echo "export VK_ICD_FILENAMES=$ICD"
  echo "export VK_DRIVER_FILES=$ICD"
  [ "$V" != software ] && { echo "export MESA_LOADER_DRIVER_OVERRIDE=zink"; echo "export GALLIUM_DRIVER=zink"; }
  [ "$V" = mali ] && { echo "export PANVK_NO_AFBC=1"; echo "export LD_LIBRARY_PATH=$(dirname "$LIB"):\$LD_LIBRARY_PATH"; }
} > /etc/profile.d/gpu.sh
echo "GPU_VENDOR=$V" > /etc/gpu-vendor
echo "ICD ready: $ICD -> $LIB"
