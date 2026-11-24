#!/system/bin/sh
# usage: shell-run.sh <USER> ; command text is read from <dir>/cmd.txt. Keeps cwd between commands.
D="$(dirname "$0")"; U="${1:-root}"
. "$D/lib-root.sh"
if [ ! -d "$R/etc" ]; then echo "container not found at '$R' - install it first (menu > Install)"; exit 1; fi
grep -q " $R/proc " /proc/mounts || { echo "container is not running - press Start first"; exit 1; }
cp "$D/cmd.txt" "$R/tmp/.ldcmd" 2>/dev/null; chmod 644 "$R/tmp/.ldcmd"
INNER='cd "$(cat /tmp/.ldcwd 2>/dev/null || echo ~)" 2>/dev/null; export TERM=xterm-256color DISPLAY=:0 PULSE_SERVER=127.0.0.1; . /tmp/.ldcmd; echo "$PWD" > /tmp/.ldcwd'
ENVI="/usr/bin/env -i HOME=/root LANG=C.UTF-8 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ "$U" = root ]; then
  exec chroot "$R" $ENVI /bin/bash -c "$INNER" 2>&1
else
  exec chroot "$R" $ENVI /bin/su -l "$U" -c "$INNER" 2>&1
fi
