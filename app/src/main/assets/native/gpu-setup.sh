#!/bin/bash
# Inside the chroot, as root. usage: gpu-setup.sh <mali|adreno|powervr|software> [panvk-tar.gz-url]
# Full GPU stack: Mesa + Vulkan loader + ICD manifest + env + self-test. Never touches the kernel.
set -e
export DEBIAN_FRONTEND=noninteractive
V="${1:-software}"; URL="$2"
apt-get update
apt-get -y install libvulkan1 vulkan-tools mesa-utils mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
  libegl-mesa0 libgbm1 libdrm2 libdrm-amdgpu1 xz-utils curl ca-certificates
mkdir -p /usr/share/vulkan/icd.d /etc/vulkan/icd.d
rm -f /usr/share/vulkan/icd.d/panfrost_icd*.json /usr/share/vulkan/icd.d/freedreno_icd*.json 2>/dev/null || true
ENVF=/etc/profile.d/gpu.sh
case "$V" in
  mali)
    D=/opt/panvk; mkdir -p "$D"
    if [ ! -f "$D/libvulkan_panfrost.so" ] && [ -n "$URL" ]; then
      T=$(mktemp -d); curl -fL --retry 3 "$URL" -o "$T/p.tgz"; tar -xzf "$T/p.tgz" -C "$T"
      for f in $(find "$T" -name 'libvulkan_panfrost.so*' -o -name 'libvulkan_panvk.so*'); do cp -a "$f" "$D/"; done
      L=$(find "$T" -name '*.so*' ! -name 'libvulkan_*' | head -50); [ -n "$L" ] && cp -a $L "$D/" 2>/dev/null || true
      rm -rf "$T"
    fi
    LIB="$D/libvulkan_panfrost.so"; [ -f "$LIB" ] || LIB=$(ls $D/libvulkan_pan*.so 2>/dev/null | head -1)
    [ -f "$LIB" ] || LIB=/usr/lib/aarch64-linux-gnu/libvulkan_panfrost.so
    ICD=/usr/share/vulkan/icd.d/panfrost_icd.aarch64.json
    printf '{ "file_format_version": "1.0.0", "ICD": { "library_path": "%s", "api_version": "1.3.0" } }\n' "$LIB" > "$ICD"
    cat > "$ENVF" <<E
export VK_ICD_FILENAMES=$ICD
export LD_LIBRARY_PATH=$D:\$LD_LIBRARY_PATH
export PANVK_NO_AFBC=1
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
export ZINK_DESCRIPTORS=lazy
E
    ;;
  adreno)
    ICD=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
    printf '{ "file_format_version": "1.0.0", "ICD": { "library_path": "libvulkan_freedreno.so", "api_version": "1.3.0" } }\n' > "$ICD"
    printf 'export VK_ICD_FILENAMES=%s\nexport MESA_LOADER_DRIVER_OVERRIDE=zink\nexport GALLIUM_DRIVER=zink\nexport TU_DEBUG=noconform\n' "$ICD" > "$ENVF" ;;
  *)
    printf 'export LIBGL_ALWAYS_SOFTWARE=1\nexport GALLIUM_DRIVER=llvmpipe\n' > "$ENVF" ;;
esac
echo "GPU_VENDOR=$V" > /etc/gpu-vendor
echo "--- self-test (failure here is reported, not fatal) ---"
( . "$ENVF"; vulkaninfo --summary 2>&1 | grep -E "deviceName|driverName|apiVersion" | head -5 ) || true
echo "GPU setup done: $V"
