## dependecies

- ghostty
- nautilus/dolphin
- rofi
- hyprpaper
- hyprlock
- hypridle
- hyprpicker
- hyprshot
- hyprpanel
- pipewire
- wireplumber
- xdg-desktop-portal-hyprland
- xdg-desktop-portal-gtk
- hyprpolkitagent
- qt5-wayland
- qt6-wayland
- fcitx5
  - fcitx5-rime
- swww
- cliphist
  - wl-clipboard

## tips

- scale of xwayland applications
  - set `Xft.dpi` in `~/.Xresources` and `exec-once = xrdb -merge ~/.Xresources`, [the value of `Xft.dpi` should be scale integer multiples of 96.](https://wiki.archlinux.org/title/HiDPI#X_Resources)
  - or set env `GDK_SCALE = 2` and `QT_FONT_DPI = 192`
  - force applications use wayland

* set GTK theme

* waydroid
  - `sudo waydroid shell` and set `setprop persist.waydroid.multi_windows false`
