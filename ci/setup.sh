#!/usr/bin/env bash

# Install necessary packages
sudo apt install -y build-essential git libssl-dev bc

# Clone toolchains
mkdir -p $HOME/kernel/toolchains
git clone https://github.com/EAS-Project/toolchains -b gcc-linaro-7.3.1 --single-branch $HOME/kernel/toolchains/gcc-linaro-7.3.1
