#!/bin/bash

# まずは全部のインストール済みパッケージをアップグレード
yes | sudo apt update
yes | sudo apt upgrade

# ビルドに必要なパッケージをセットアップ
mkdir git
cd git
yes | sudo apt install tclsh pkg-config cmake libssl-dev build-essential
#H.264 と H.265 のサポートに必要
yes | sudo apt install libx264-dev libx265-dev nasm
#drawtext フィルタを使うのに必要
yes | sudo apt install libfreetype6-dev
#ffplay をビルドするのに必要
yes | sudo apt install libsdl2-dev libva-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev

# SRT Tools のセットアップ
git clone https://github.com/Haivision/srt.git
cd srt
git checkout -b v1.4.4 v1.4.4
./configure
make
sudo make install
sudo ldconfig
cd ..

# ffmpeg のビルド
git clone https://git.ffmpeg.org/ffmpeg.git
cd ffmpeg
git checkout -b n5.0 n5.0
./configure --enable-libsrt --enable-libx264 --enable-libx265 --enable-libfreetype --enable-gpl
make
sudo make install
cd ..
cd ..

# UDP の受信バッファサイズを拡張
sudo sysctl -w net.core.rmem_max=26214400
