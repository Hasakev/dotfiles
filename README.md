# dotfiles

**chongqing** — a Hyprland + Quickshell rice. Blue-black slate, three glass
islands, accent pulled from the wallpaper, media panel tinted by the album art.

| Package      | What                                                        |
|--------------|-------------------------------------------------------------|
| `quickshell` | The shell: bar, launcher, notifications, OSD, panels         |
| `hypr`       | Hyprland (Lua config), hyprlock, helper scripts              |
| `kitty`      | Terminal                                                    |
| `waypaper`   | Wallpaper picker (drives Wallpaper Engine via `hypr/scripts`) |
| `dbus`       | Stops dunst grabbing the notification name from Quickshell   |
| `theme`      | Palette + `sync.sh`: GTK, Kvantum, qt5ct/qt6ct in the same colours |

## Install

```sh
sudo pacman -S --needed stow quickshell cava hyprland hyprlock kitty jq imagemagick \
  kvantum qt5ct qt6ct
paru -S catppuccin-gtk-theme-mocha   # AUR; sync.sh recolours it
git clone git@github.com:Hasakev/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow quickshell hypr kitty waypaper dbus theme
~/.config/theme/sync.sh   # builds the chongqing GTK/Kvantum/Qt themes
```

`packages.txt` is the full explicit package list (`pacman -Qqe`); refresh it with
`pacman -Qqe > packages.txt`. Add a new app with
`mkdir -p app/.config && mv ~/.config/app app/.config/ && stow app`.

## Keys

| Bind             | Action                    |
|------------------|---------------------------|
| Super+D          | Launcher (`>` run, `;` clipboard, maths inline) |
| Super+V          | Clipboard                 |
| Super+A / +Shift | Media / mixer             |
| Super+W          | Network                   |
| Super+N          | Notifications             |
| Super+L          | Lock                      |
