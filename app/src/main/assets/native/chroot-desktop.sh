#!/bin/bash
# Inside the chroot, as root. usage: chroot-desktop.sh <user> <mate|xfce|lxqt|lxde|kde|cinnamon|gnome>
# Installs the chosen desktop (idempotent) and the start-desktop launcher.
set -e
export DEBIAN_FRONTEND=noninteractive
U="$1"; DE="${2:-mate}"
apt-get update
apt-get -y install sudo locales ca-certificates dbus-x11 pulseaudio pulseaudio-utils pavucontrol \
  x11-xserver-utils xdg-utils fonts-noto fonts-noto-color-emoji adwaita-icon-theme gvfs xterm
if ! grep -qx "$DE" /etc/ld-desktops 2>/dev/null; then
  case "$DE" in
    mate)     apt-get -y install mate-desktop-environment mate-tweak mate-terminal ;;
    xfce)     apt-get -y install xfce4 xfce4-goodies xfce4-terminal thunar mousepad ;;
    lxqt)     apt-get -y install lxqt qterminal pcmanfm-qt ;;
    lxde)     apt-get -y install lxde ;;
    kde)      apt-get -y install kde-plasma-desktop konsole dolphin ;;
    cinnamon) apt-get -y install cinnamon-desktop-environment ;;
    gnome)    apt-get -y install gnome-session gnome-shell gnome-terminal nautilus gnome-control-center ;;
    *) echo "unknown desktop: $DE"; exit 1 ;;
  esac
  echo "$DE" >> /etc/ld-desktops
fi
echo "$DE" > /etc/ld-desktop
id "$U" >/dev/null 2>&1 && usermod -aG audio,video,render "$U" || true
cat > /usr/local/bin/ld-dbus-start <<'EOS'
#!/bin/bash
mkdir -p /run/dbus
[ -s /etc/machine-id ] || dbus-uuidgen --ensure=/etc/machine-id
rm -f /run/dbus/pid
pgrep -x dbus-daemon >/dev/null || dbus-daemon --system --fork
EOS
cat > /usr/local/bin/start-desktop <<'EOS'
#!/bin/bash
# usage: start-desktop [gpu] [zink]   - desktop comes from /etc/ld-desktop
export DISPLAY=:0 PULSE_SERVER=127.0.0.1 XDG_SESSION_TYPE=x11 GDK_BACKEND=x11 NO_AT_BRIDGE=1
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u); mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
DE=$(cat /etc/ld-desktop 2>/dev/null || echo mate)
export XDG_CURRENT_DESKTOP=$DE
[ -f /etc/profile.d/gpu.sh ] && . /etc/profile.d/gpu.sh
case "$DE" in
  mate) S=mate-session ;; xfce) S=startxfce4 ;; lxqt) S=startlxqt ;; lxde) S=startlxde ;;
  kde) S=startplasma-x11; export KWIN_COMPOSE=O2ES ;; cinnamon) S=cinnamon-session ;; gnome) S=gnome-session ;;
  *) S=xterm ;;
esac
(exec 3<>/dev/tcp/127.0.0.1/4713) 2>/dev/null || pulseaudio --start --exit-idle-time=-1 \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" 2>/dev/null
exec dbus-launch --exit-with-session $S
EOS
chmod +x /usr/local/bin/start-desktop /usr/local/bin/ld-dbus-start
echo "desktop ready: $DE"
