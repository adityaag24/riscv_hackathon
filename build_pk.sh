#!/bin/bash

# Exit on error
set -e

# Directory structure
RISCV_DIR="$HOME/riscv"
INSTALL_DIR="$HOME/riscv-pk-install"
mkdir -p $RISCV_DIR
mkdir -p $INSTALL_DIR

# Install dependencies
echo "=== Installing dependencies ==="
sudo apt-get update
sudo apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git cmake

# First check if RISC-V GNU toolchain is installed and in PATH
echo "=== Checking for RISC-V GNU Toolchain ==="
if ! command -v riscv64-unknown-linux-gnu-gcc &> /dev/null; then
    echo "RISC-V GNU Toolchain not found in PATH"
    
    # Check if it's installed in the expected location
    if [ -d "$HOME/riscv-linux-install/bin" ]; then
        echo "Found toolchain in $HOME/riscv-linux-install/bin, adding to PATH"
        export PATH="$PATH:$HOME/riscv-linux-install/bin"
    else
        echo "ERROR: RISC-V GNU Toolchain not found. Please install it first."
        echo "You can use the build_riscv_toolchain.sh script for this."
        exit 1
    fi
fi

# Get the RISC-V Proxy Kernel (pk) repository
echo "=== Cloning RISC-V Proxy Kernel (pk) repository ==="
cd $RISCV_DIR
if [ ! -d "riscv-pk" ]; then
    git clone https://github.com/riscv-software-src/riscv-pk.git
else
    echo "RISC-V PK repository already exists, updating..."
    cd riscv-pk
    git pull
    cd ..
fi

# Build the proxy kernel
echo "=== Building RISC-V Proxy Kernel (pk) ==="
cd riscv-pk
mkdir -p build
cd build

# Configure for RV64GC and build
../configure --prefix=$INSTALL_DIR --host=riscv64-unknown-linux-gnu --with-arch=rv64gc
make -j$(nproc)
make install

echo "=== RISC-V Proxy Kernel (pk) built successfully ==="
echo "The proxy kernel (pk) has been installed to: $INSTALL_DIR/bin"
echo "You can now use pk to run RISC-V ELF binaries:"
echo "spike --isa=rv64gc $INSTALL_DIR/bin/pk your_program.elf"

# Update softmax run script to use the proxy kernel
echo "=== Updating run_softmax.sh script ==="
cat > $HOME/riscv-hackathon/run_softmax_pk.sh << EOF
#!/bin/bash

# Exit on error
set -e

# Path to RISC-V Linux toolchain
export PATH=\$PATH:$HOME/riscv-linux-install/bin
# Path to Spike
export PATH=\$PATH:$HOME/riscv-install/bin
# Path to Proxy Kernel
export PATH=\$PATH:$INSTALL_DIR/bin

echo "=== Compiling softmax.c for RISC-V ==="
cd $HOME/riscv-hackathon
riscv64-unknown-linux-gnu-gcc -march=rv64gc -mabi=lp64d -O2 -o softmax.elf softmax.c -lm

echo "=== Running on Spike RISC-V simulator with Proxy Kernel ==="
spike --isa=rv64gc \$(which pk) softmax.elf

echo "=== Execution completed ==="
EOF

chmod +x $HOME/riscv-hackathon/run_softmax_pk.sh

echo "=== Created run_softmax_pk.sh script ==="
echo "You can now run your softmax program with the proxy kernel using:"
echo "./riscv-hackathon/run_softmax_pk.sh"
