#!/bin/bash

# Exit on error
set -e

echo "=== Installing dependencies ==="
sudo apt-get update
sudo apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build pkg-config libglib2.0-dev device-tree-compiler

# Create a directory for the RISC-V tools
mkdir -p ~/riscv
cd ~/riscv

echo "=== Cloning Spike repository ==="
if [ ! -d riscv-isa-sim ]; then
    git clone https://github.com/riscv-software-src/riscv-isa-sim.git
else
    echo "Spike repository already exists, updating..."
    cd riscv-isa-sim
    git pull
    cd ..
fi

echo "=== Building Spike ==="
cd riscv-isa-sim
mkdir -p build
cd build
../configure --prefix=/home/adiagrawal/riscv-install
make -j$(nproc)
make install

echo "=== Building RISC-V Tests ==="
cd ~/riscv
if [ ! -d riscv-tests ]; then
    git clone https://github.com/riscv-software-src/riscv-tests.git
else
    echo "RISC-V tests repository already exists, updating..."
    cd riscv-tests
    git pull
    cd ..
fi

cd riscv-tests
git submodule update --init --recursive
autoconf
./configure --prefix=/home/adiagrawal/riscv-install
make
make install

echo "=== Spike build completed ==="
echo "Add the following to your ~/.bashrc file:"
echo 'export PATH=$PATH:$HOME/riscv-install/bin'
echo "Then run 'source ~/.bashrc' or start a new terminal"
echo "You can now run spike with: spike [options] [binary]" 