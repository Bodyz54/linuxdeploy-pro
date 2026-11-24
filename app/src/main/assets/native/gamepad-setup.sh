#!/bin/bash
# Inside the chroot, as root. usage: gamepad-setup.sh <user>
# Gamepad as mouse/keyboard (padmouse) + fullscreen gamepad launcher. Works with any desktop.
set -e
export DEBIAN_FRONTEND=noninteractive
U="$1"
apt-get update
apt-get -y install python3-evdev python3-xlib python3-gi gir1.2-gtk-3.0 onboard libnotify-bin \
  jstest-gtk evtest x11-xserver-utils pavucontrol
usermod -aG input "$U" 2>/dev/null || true
install -m 755 /root/padmouse /usr/local/bin/padmouse
install -m 755 /root/gamelauncher /usr/local/bin/gamelauncher
cat > /usr/local/bin/ld-logout <<'EOS'
#!/bin/bash
for c in "xfce4-session-logout --logout --fast" "mate-session-save --logout-dialog" "cinnamon-session-quit --logout --no-prompt" \
         "gnome-session-quit --logout --no-prompt" "qdbus org.kde.ksmserver /KSMServer logout 0 0 0" "lxsession-logout"; do
  command -v ${c%% *} >/dev/null && { $c; exit; }
done
pkill -TERM -u "$(id -u)" dbus-launch
EOS
chmod 755 /usr/local/bin/ld-logout
cat > /usr/local/bin/gaming-tweaks <<'EOS'
#!/bin/bash
sleep 6
xset s off; xset -dpms; xset s noblank
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null
exit 0
EOS
chmod 755 /usr/local/bin/gaming-tweaks
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/padmouse.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=padmouse (gamepad as mouse)
Exec=/usr/local/bin/padmouse
X-GNOME-Autostart-enabled=true
EOS
cat > /etc/xdg/autostart/gaming-tweaks.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=Gaming tweaks
Exec=/usr/local/bin/gaming-tweaks
EOS
cat > /etc/xdg/autostart/gamelauncher-session.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=Game launcher (when game mode is on)
Exec=sh -c 'sleep 4; [ -f /tmp/tx11-game ] && exec /usr/local/bin/gamelauncher'
EOS
cat > /usr/share/applications/gamelauncher.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=Game Launcher
Exec=/usr/local/bin/gamelauncher
Icon=applications-games
Categories=Utility;
EOS
install -d -o "$U" -g "$U" "/home/$U/WinGames" 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
echo 1 > /etc/ld-gamepad
echo "gamepad support installed"
