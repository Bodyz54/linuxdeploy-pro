#!/data/data/com.termux/files/usr/bin/bash
# Turn any proot-distro rootfs (Manjaro, Arch, Fedora, Alpine, openSUSE, Void, ...) into a tarball
# that Linux Deploy can install through  Properties > Distribution > rootfs.tar  (chroot mode).
# usage: bash proot-to-chroot.sh <proot-distro-alias>      e.g.  manjaro
#   the result is /sdcard/Download/<alias>-chroot-rootfs.tar.gz
set -e
D="${1:?usage: $0 <alias>   (see: proot-distro list)}"
pkg install -y proot-distro tar gzip >/dev/null
proot-distro list | grep -qi "$D" || { echo "unknown alias '$D' - run: proot-distro list"; exit 1; }
[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$D" ] || proot-distro install "$D"
R="$PREFIX/var/lib/proot-distro/installed-rootfs/$D"
# make it chroot-ready: DNS, Android network groups, no proot-only leftovers
printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > "$R/etc/resolv.conf"
for g in "aid_inet:3003" "aid_net_raw:3004" "aid_sdcard_rw:1015"; do
  n=${g%%:*}; i=${g##*:}; grep -q "^$n:" "$R/etc/group" 2>/dev/null || echo "$n:x:$i:" >> "$R/etc/group"
done
rm -rf "$R/tmp/"* 2>/dev/null || true
OUT="/sdcard/Download/$D-chroot-rootfs.tar.gz"
tar -C "$R" -czpf "$OUT" --numeric-owner .
echo "done: $OUT"
echo "In Linux Deploy: Properties > Distribution = rootfs.tar, Source path = $OUT, Install type = directory or image."
