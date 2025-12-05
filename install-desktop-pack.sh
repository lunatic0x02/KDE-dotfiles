#!/bin/bash

set -e
STARTING_DIR="$(pwd)"

# Starting
# echo "# Before you start"
# echo "Please make sure you have upgraded your Fedora after fresh install, it may have missing features if ran without updating (The fresh install may have outdated KDE Plasma)."
# echo "Do you want to upgrade your system first and run [sudo dnf upgrade]? It would take several minutes."

# options=("y" "Y" "n" "N")
# PS3="[y/n]: "

# select choice in "${options[@]}"
# do
#     case $choice in
#         "y")
#             sudo dnf upgrade
#             echo "Finished updating. You may run this script again."
#             exit 0
#             ;;
#         "Y")
#             sudo dnf upgrade
#             echo "Finished updating. You may run this script again."
#             exit 0
#             ;;
#         "N")
#             echo " "
#             ;;
#         "n")
#             echo " "
#             ;;
#         *)
#             echo "Invalid option."
#             exit 0
#             ;;
#     esac
# done

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

sudo dnf -y install git cmake extra-cmake-modules gcc-g++ kf6-kwindowsystem-devel plasma-workspace-devel libplasma-devel qt6-qtbase-private-devel qt6-qtbase-devel cmake kwin-devel extra-cmake-modules kwin-devel kf6-knotifications-devel kf6-kio-devel kf6-kcrash-devel kf6-ki18n-devel kf6-kguiaddons-devel libepoxy-devel kf6-kglobalaccel-devel kf6-kcmutils-devel kf6-kconfigwidgets-devel kf6-kdeclarative-devel kdecoration-devel kf6-kglobalaccel kf6-kdeclarative libplasma kf6-kio qt6-qtbase kf6-kguiaddons kf6-ki18n wayland-devel libdrm-devel

if [ ! -d "kwin-effects-forceblur" ]; then
    git clone https://github.com/taj-ny/kwin-effects-forceblur
fi

cd kwin-effects-forceblur

mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j"$(nproc)"
sudo make install

# Building Shader Wallpaper
git clone https://github.com/y4my4my4m/kde-shader-wallpaper.git
rm -rf ~/.local/share/plasma/wallpapers/online.knowmad.shaderwallpaper/
kpackagetool6 -t Plasma/Wallpaper -i kde-shader-wallpaper/package

# Finishing
echo "# Restarting Plasma Shell (Plasma 6)"
kquitapp6 plasmashell || true
plasmashell --replace &>/dev/null &

echo "# Installation Finished!"
echo "If the theme is not applied, try logging out and back in or rebooting."
