#!/bin/bash
# Inside the chroot, as root. usage: gpu-setup.sh <mali|adreno|powervr|other> [panvk-tar.gz-url]
# Installs matching packages and creates the Vulkan ICD directory and manifest automatically.
set -e
export DEBIAN_FRONTEND=noninteractive
V="${1:-other}"
mkdir -p /usr/share/vulkan/icd.d /etc/vulkan/icd.d
apt-get -y install libvulkan1 vulkan-tools mesa-utils mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0
case "$V" in
  mali)
    D=/opt/panvk-g57
    if [ ! -f "$D/libvulkan_panfrost.so" ] && [ -n "$2" ]; then
      mkdir -p "$D" /tmp/pv; curl -fL "$2" -o /tmp/pv/a.tgz; tar -xzf /tmp/pv/a.tgz -C /tmp/pv
      cp "$(find /tmp/pv -name libvulkan_panfrost.so | head -1)" "$D/"; rm -rf /tmp/pv
    fi
    LIB="$D/libvulkan_panfrost.so"; [ -f "$LIB" ] || LIB=libvulkan_panfrost.so
    ICD=panfrost_icd.aarch64.json ;;
  adreno) LIB=libvulkan_freedreno.so; ICD=freedreno_icd.aarch64.json ;;
  *)      LIB=libvulkan_lvp.so;       ICD=lvp_icd.aarch64.json ;;
esac
cat > "/usr/share/vulkan/icd.d/$ICD" <<J
{ "file_format_version": "1.0.0", "ICD": { "library_path": "$LIB", "api_version": "1.3.0" } }
J
echo "export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/$ICD" > /etc/profile.d/vk-icd.sh
echo "GPU_VENDOR=$V" > /etc/gpu-vendor
echo "ICD ready: /usr/share/vulkan/icd.d/$ICD -> $LIB"
