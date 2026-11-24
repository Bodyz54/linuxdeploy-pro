#!/system/bin/sh
# sourced: resolves the container mount point from Linux Deploy's own config (not guessed)
EXTERNAL_STORAGE=${EXTERNAL_STORAGE:-/sdcard}
CONF=/data/data/ru.meefik.linuxdeploy/files/cli.conf
[ -r "$CONF" ] && . "$CONF" 2>/dev/null
R="${MNT_TARGET:-$TARGET_PATH}"
[ -n "$1" ] && [ -d "$1/etc" ] && R="$1"
[ -n "$R" ] || R=/data/local/mnt
