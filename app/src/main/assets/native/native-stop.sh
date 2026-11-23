#!/system/bin/sh
# Stop button (root). usage: native-stop.sh <ROOT>
ROOT="$1"
TP=/data/data/com.termux/files
TU=$(stat -c %u /data/data/com.termux 2>/dev/null)
TENV="env HOME=$TP/home PREFIX=$TP/usr PATH=$TP/usr/bin LD_LIBRARY_PATH=$TP/usr/lib TMPDIR=$TP/usr/tmp"
am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1
for sig in TERM KILL; do
  for p in /proc/[0-9]*; do [ "$(readlink "$p/root" 2>/dev/null)" = "$ROOT" ] && kill -$sig "${p#/proc/}" 2>/dev/null; done
  sleep 1
done
if [ -n "$TU" ]; then
  su "$TU" -c "$TENV pkill -f 'termux-x11 :0'" 2>/dev/null
  su "$TU" -c "$TENV pulseaudio --kill" 2>/dev/null
fi
exit 0
