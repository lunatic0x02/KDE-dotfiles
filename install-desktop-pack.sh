#!/bin/bash

set -e
$STARTING_DIR=$(pwd)

echo "# Installing Required Desktop Packages"
sudo dnf install -y git stow kvantum

echo "# Stowing Desktop Theme"
$THEME="milkyway"
stow -R "$THEME"

echo "# Set Kvantum Theme"
kvantummanager --set $(cat ~/.config/Kvantum/kvantum.kvconfig | grep theme | sed 's/theme=//')

echo "# Installing Plasmoids"
$PLASMOIDS_DIR="$STARTING_DIR/milkyway/.local/share/plasma/plasmoids/"
for widget in "$PLASMOIDS_DIR"/*; do
    [[ $(basename "$widget") != "org.kde.plasma.*" ]] || continue
    echo "Installing plasmoid: $(basename "$widget")"
    kpackagetool6 --install "$widget"
done

echo "# Building Better Blur"
cd ~
mkdir -p ~/builds
cd builds
if [ ! -d "kwin-effects-forceblur" ]; then
    git clone https://github.com/taj-ny/kwin-effects-forceblur
    cd kwin-effects-forceblur
    mkdir build
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr
    make -j$(nproc)
    sudo make install
fi

echo "# Restarting Plasma Shell"
kquitapp5 plasmashell || true
plasmashell --replace &

echo "# Installation Finished!"
echo "Check if desktop theme is properly configured."
echo "If theme is not applied regardless, try logging out and in, or reboot."
