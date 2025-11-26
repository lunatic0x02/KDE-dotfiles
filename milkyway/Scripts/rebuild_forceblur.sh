#!/bin/bash
cd ~/Apps/kwin-effects-forceblur/
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
sudo make install
