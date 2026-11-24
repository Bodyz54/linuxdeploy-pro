#!/system/bin/sh
# Start button (root). usage: native-start.sh <ROOT> <USER> <GPU:auto|mali|adreno|powervr|software>
CUSER="$2"; GPU="${3:-auto}"; DE="${4:-mate}"
D="$(dirname "$0")"
. "$D/lib-root.sh" "$1"
ROOT="$R"
[ -d "$ROOT/etc" ] || { echo "container not installed at $ROOT - use menu > Install first"; exit 1; }
echo "container: $ROOT"
TP=/data/data/com.termux/files
TU=$(stat -c %u /data/data/com.termux 2>/dev/null)
[ -n "$TU" ] || { echo "Termux is not installed (needed for PulseAudio and termux-x11)"; exit 1; }
TENV="env HOME=$TP/home PREFIX=$TP/usr PATH=$TP/usr/bin LD_LIBRARY_PATH=$TP/usr/lib TMPDIR=$TP/usr/tmp"

sh "$D/mount-extras.sh" "$ROOT"
if [ "$GPU" = auto ]; then eval "$(sh "$D/gpu-detect.sh")"; GPU="$GPU_VENDOR"; fi
echo "GPU: $GPU"
sh "$D/kernel-check.sh" | grep -v '^ok' 

# Install the chosen desktop / GPU packages inside the chroot when missing
CH="chroot $ROOT /usr/bin/env -i HOME=/root TERM=xterm-256color LANG=C.UTF-8 TMPDIR=/tmp PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
cp "$D/chroot-desktop.sh" "$D/gpu-setup.sh" "$D/dbus-setup.sh" "$D/icd-refresh.sh" "$ROOT/root/" 2>/dev/null
if ! grep -qx "$DE" "$ROOT/etc/ld-desktops" 2>/dev/null || [ ! -x "$ROOT/usr/local/bin/start-desktop" ]; then
  echo "installing desktop '$DE' (needs internet, takes a while)"
  printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > "$ROOT/etc/resolv.conf"
  $CH /bin/bash /root/chroot-desktop.sh "$CUSER" "$DE" && $CH /bin/bash /root/dbus-setup.sh ||
    { echo "desktop install failed; see log above"; exit 1; }
fi
if [ ! -f "$ROOT/etc/gpu-vendor" ]; then
  $CH /bin/bash /root/gpu-setup.sh "$GPU" "https://github.com/apexspan-svg/mesa-panvk-mali-g57/releases/download/v1.0.0-async/panvk-mali-g57-v1.0.0-glibc-async.tar.gz" || echo "GPU setup incomplete; continuing"
fi
echo "$DE" > "$ROOT/etc/ld-desktop"
# ICD directory + manifest are regenerated automatically on every Start
$CH /bin/bash /root/icd-refresh.sh "$GPU"

# PulseAudio (runs as the Termux user, TCP on localhost)
su "$TU" -c "$TENV pulseaudio --kill" 2>/dev/null; sleep 1
su "$TU" -c "$TENV pulseaudio --start --exit-idle-time=-1 --load='module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1'"

# Termux:X11 server (sharedUid build) + its Android activity
su "$TU" -c "$TENV pkill -f 'termux-x11 :0'" 2>/dev/null
rm -f "$TP/usr/tmp/.X11-unix/X0" "$TP/usr/tmp/.X0-lock"
su "$TU" -c "$TENV termux-x11 :0 -ac >/dev/null 2>&1 &"
i=0; while [ $i -lt 30 ] && [ ! -S "$TP/usr/tmp/.X11-unix/X0" ]; do sleep 1; i=$((i+1)); done
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

# D-Bus + desktop inside the chroot
chroot "$ROOT" /usr/bin/env -i TERM=xterm-256color /bin/bash -c "/usr/local/bin/ld-dbus-start" 2>/dev/null
chroot "$ROOT" /usr/bin/env -i TERM=xterm-256color /bin/su -l "$CUSER" -c "/usr/local/bin/start-desktop $GPU 1" >/dev/null 2>&1 &
echo "desktop started"
