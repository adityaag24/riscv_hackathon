#!/bin/bash

# Exit on error
set -e

# Install dependencies
echo "=== Installing dependencies ==="
sudo apt-get update
sudo apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build pkg-config libglib2.0-dev device-tree-compiler

# Directory for installation
INSTALL_DIR=$HOME/riscv-linux-install
mkdir -p $INSTALL_DIR

# Clone and build RISC-V GNU Toolchain for Linux targets
echo "=== Cloning RISC-V GNU Toolchain ==="
cd $HOME
if [ ! -d riscv-gnu-toolchain ]; then
    git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
else
    echo "RISC-V GNU Toolchain already exists, updating..."
    cd riscv-gnu-toolchain
    git pull
    git submodule update --init --recursive
    cd ..
fi

echo "=== Building RISC-V GNU Toolchain for Linux ==="
cd riscv-gnu-toolchain
mkdir -p build
cd build

# Configure for Linux targets with vector extension support
../configure --prefix=$INSTALL_DIR --with-arch=rv64gcv --with-abi=lp64d --enable-multilib

# Build the Linux toolchain
echo "=== Building ELF toolchain (this will take some time) ==="
make -j$(nproc)

echo "=== RISC-V GNU Toolchain for Linux built successfully ==="
echo "Add the following to your ~/.bashrc file:"
echo "export PATH=\$PATH:$INSTALL_DIR/bin"
echo "Then run 'source ~/.bashrc' or start a new terminal"
echo ""
echo "You can now compile RISC-V ELF programs with:"
echo "riscv64-unknown-elf-gcc -march=rv64gcv -mabi=lp64d"