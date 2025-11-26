#!/bin/bash

set -e
STARTING_DIR="$(pwd)"

# Installing Required Desktop Packages
echo "# Installing Required Desktop Packages"
sudo dnf install -y git stow kvantum

echo "# Stowing Desktop Theme"
THEME="milkyway"
stow -R "$THEME"

# Setting Kvantum Theme
echo "# Setting Kvantum Theme"
kvantummanager --set "$(grep '^theme=' ~/.config/Kvantum/kvantum.kvconfig | sed 's/theme=//')"

# Installing Plasmoids
echo "# Installing Plasmoids"

PLASMOIDS_DIR="$STARTING_DIR/milkyway/.local/share/plasma/plasmoids"
if [ ! -d "$PLASMOIDS_DIR" ]; then
    echo "Plasmoids directory not found: $PLASMOIDS_DIR"
    exit 1
fi

for widget in "$PLASMOIDS_DIR"/*; do
    if [[ "$(basename "$widget")" == org.kde.plasma.* ]]; then
        continue
    fi

    echo "Installing plasmoid: $(basename "$widget")"
    kpackagetool6 --install "$widget" || true
done

# Building Better Blur
echo "# Building Better Blur"
mkdir -p ~/builds
cd ~/builds

if [ ! -d "kwin-effects-forceblur" ]; then
    git clone https://github.com/taj-ny/kwin-effects-forceblur
fi

cd kwin-effects-forceblur

mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j"$(nproc)"
sudo make install

# Finishing
echo "# Restarting Plasma Shell (Plasma 6)"
kquitapp6 plasmashell || true
plasmashell --replace &>/dev/null &

echo "# Installation Finished!"
echo "If the theme is not applied, try logging out and back in or rebooting."
