#!/usr/bin/env bash
# Recolor Catppuccin Mocha (GTK3/4 + Kvantum) into the chongqing palette and
# write a qt6ct palette for QtQuick apps (lsfg-vk-ui) that ignore Kvantum.
# Re-run after a catppuccin package update.
# ponytail: palette mapping is hand-picked, not parsed from chongqing.conf; edit MAP if the palette changes.
set -euo pipefail

GTK_SRC=/usr/share/themes/catppuccin-mocha-blue-standard+default
KV_SRC=$HOME/.config/Kvantum/catppuccin-mocha-blue
GTK_DST=$HOME/.themes/chongqing
KV_DST=$HOME/.config/Kvantum/chongqing

# catppuccin -> chongqing (hex, then the rgba() forms the GTK css uses)
MAP=(
  1e1e2e:0a0f1f 181825:070b17 11111b:050812 393947:1a2338
  313244:141c2f 45475a:1f2a42 585b70:2b3854
  89b4fa:4fa3ff 7ea5e6:3d8fe6 97bbf9:6fb4ff
  74c7ec:22d3ee 89dceb:22d3ee cba6f7:7c3aed f38ba8:ff2e88
  a6adc8:94a3b8 9399b2:8391a7 6c7086:64748b
)
RGBA=( "17, 17, 27:5, 8, 18" "137, 180, 250:79, 163, 255" "11, 11, 18:3, 5, 12" )

sedargs=()
for p in "${MAP[@]}"; do sedargs+=(-e "s/#${p%%:*}/#${p##*:}/gI"); done
for p in "${RGBA[@]}"; do sedargs+=(-e "s/rgba(${p%%:*},/rgba(${p##*:},/g"); done

rm -rf "$GTK_DST" "$KV_DST"
mkdir -p "$GTK_DST" "$KV_DST"
cp -r "$GTK_SRC"/{gtk-3.0,gtk-4.0,index.theme} "$GTK_DST"/
find "$GTK_DST" -name '*.css' -exec sed -i "${sedargs[@]}" {} +
sed -i 's/^Name=.*/Name=chongqing/' "$GTK_DST/index.theme"

sed "${sedargs[@]}" "$KV_SRC/catppuccin-mocha-blue.kvconfig" > "$KV_DST/chongqing.kvconfig"
sed "${sedargs[@]}" "$KV_SRC/catppuccin-mocha-blue.svg"      > "$KV_DST/chongqing.svg"

# QPalette role order: WindowText Button Light Midlight Dark Mid Text BrightText
# ButtonText Base Window Shadow Highlight HighlightedText Link LinkVisited
# AlternateBase NoRole ToolTipBase ToolTipText PlaceholderText Accent
act='#ffcdd6f4, #ff141c2f, #ff2b3854, #ff1f2a42, #ff050812, #ff10162a, #ffcdd6f4, #ffffffff, #ffcdd6f4, #ff10162a, #ff0a0f1f, #ff000000, #ff4fa3ff, #ff0a0f1f, #ff22d3ee, #ff7c3aed, #ff141c2f, #ff000000, #ff10162a, #ffcdd6f4, #ff64748b, #ff4fa3ff'
dis=$(sed -e 's/#ffcdd6f4/#ff64748b/g' -e 's/#ff4fa3ff/#ff2b3854/g' <<<"$act")
mkdir -p "$HOME/.config/qt6ct/colors"
printf '[ColorScheme]\nactive_colors=%s\ndisabled_colors=%s\ninactive_colors=%s\n' "$act" "$dis" "$act" \
  > "$HOME/.config/qt6ct/colors/chongqing.conf"

# point everything at it
gsettings set org.gnome.desktop.interface gtk-theme chongqing
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
for v in 3.0 4.0; do
  f=$HOME/.config/gtk-$v/settings.ini
  grep -q '^gtk-theme-name' "$f" && sed -i 's/^gtk-theme-name=.*/gtk-theme-name=chongqing/' "$f" \
    || sed -i '/^\[Settings\]/a gtk-theme-name=chongqing\ngtk-application-prefer-dark-theme=1' "$f"
done
# libadwaita (GTK4) only reads ~/.config/gtk-4.0, not the theme name
for f in gtk.css gtk-dark.css assets; do ln -sfn "$GTK_DST/gtk-4.0/$f" "$HOME/.config/gtk-4.0/$f"; done

sed -i 's/^theme=.*/theme=chongqing/' "$HOME/.config/Kvantum/kvantum.kvconfig"
for c in qt5ct qt6ct; do
  f=$HOME/.config/$c/$c.conf
  sed -i -e "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt6ct/colors/chongqing.conf|" \
         -e 's/^custom_palette=.*/custom_palette=true/' "$f"
  grep -q '^custom_palette' "$f" || sed -i '/^\[Appearance\]/a custom_palette=true' "$f"
done
echo "chongqing applied — restart open apps."
