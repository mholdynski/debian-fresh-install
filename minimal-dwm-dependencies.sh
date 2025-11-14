#!/bin/bash

sudo apt update
sudo apt install -y git
sudo apt install -y xserver-xorg-core xserver-xorg-video-amdgpu xinit xinput x11-xserver-utils
sudo apt install -y build-essential
sudo apt install -y libx11-dev libxinerama-dev libxft-dev
sudo apt install -y libxrandr-dev libimlib2-dev
sudo apt install -y brightnessctl
curl -fsS https://dl.brave.com/install.sh | sh

cd ~ 
mkdir -p github
cd github

git clone https://git.suckless.org/dwm
git clone https://git.suckless.org/st
git clone https://git.suckless.org/dmenu

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
cd ~/.local/share/fonts
unzip JetBrainsMono.zip
rm JetBrainsMono.zip
fc-cache -fv 
