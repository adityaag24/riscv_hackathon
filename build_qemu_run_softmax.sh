#!/bin/bash

# Exit on error
set -e

QEMU_VERSION="7.2.0"
QEMU_DIR="$HOME/qemu-riscv"
INSTALL_DIR="$HOME/qemu-install"

echo "=== Installing dependencies ==="
sudo apt-get update
sudo apt-get install -y build-essential ninja-build libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev \
    libnfs-dev libiscsi-dev git python3 python3-pip python3-venv pkg-config flex bison

echo "=== Creating installation directories ==="
mkdir -p $QEMU_DIR
mkdir -p $INSTALL_DIR

# Download and build QEMU
echo "=== Downloading QEMU $QEMU_VERSION ==="
cd $QEMU_DIR
if [ ! -d "qemu-$QEMU_VERSION" ]; then
    wget "https://download.qemu.org/qemu-$QEMU_VERSION.tar.xz"
    tar xf "qemu-$QEMU_VERSION.tar.xz"
else
    echo "QEMU source already exists, skipping download"
fi

echo "=== Building QEMU with RISC-V support ==="
cd "qemu-$QEMU_VERSION"
./configure --target-list=riscv64-linux-user,riscv64-softmmu --prefix=$INSTALL_DIR
make -j$(nproc)
make install

echo "=== QEMU for RISC-V built successfully ==="
echo "Adding QEMU to PATH for this session"
export PATH=$PATH:$INSTALL_DIR/bin

# Setup a lightweight RISC-V Linux environment for user-mode emulation
echo "=== Compiling softmax.c for RISC-V ==="
cd $HOME/riscv-hackathon
export PATH=$PATH:$HOME/riscv-linux-install/bin

# Check if softmax.c exists, otherwise create a simple version
if [ ! -f "softmax.c" ]; then
    echo "Creating a simple softmax.c example"
    cat > softmax.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>

// Scalar implementation of softmax
void softmax_scalar(float* input, float* output, size_t size) {
    // Find maximum value for numerical stability
    float max_val = -FLT_MAX;
    for (size_t i = 0; i < size; i++) {
        if (input[i] > max_val) {
            max_val = input[i];
        }
    }
    
    // Compute exp(input[i] - max) and sum
    float sum = 0.0f;
    for (size_t i = 0; i < size; i++) {
        output[i] = expf(input[i] - max_val);
        sum += output[i];
    }
    
    // Normalize
    for (size_t i = 0; i < size; i++) {
        output[i] /= sum;
    }
}

int main() {
    // Example vector size
    const size_t size = 10;
    
    // Allocate and initialize input vector
    float* input = (float*)malloc(size * sizeof(float));
    float* output = (float*)malloc(size * sizeof(float));
    
    if (!input || !output) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    
    // Initialize with some sample values
    printf("Input vector:\n");
    for (size_t i = 0; i < size; i++) {
        input[i] = (float)(i + 1); // Simple values 1 to 10
        printf("%.4f ", input[i]);
    }
    printf("\n\n");
    
    // Calculate softmax using scalar code
    softmax_scalar(input, output, size);
    
    // Print results
    printf("Softmax outputs:\n");
    for (size_t i = 0; i < size; i++) {
        printf("%.10f ", output[i]);
    }
    printf("\n\n");
    
    // Calculate and print sum to verify probabilities add up to 1
    float sum = 0.0f;
    for (size_t i = 0; i < size; i++) {
        sum += output[i];
    }
    
    printf("Sum of softmax outputs: %.10f\n", sum);
    
    // Free allocated memory
    free(input);
    free(output);
    
    return 0;
}
EOF
fi

# Compile for RISC-V (keep existing file)
riscv64-unknown-linux-gnu-gcc -march=rv64gc -mabi=lp64d -static -O2 -o softmax.elf softmax.c -lm

echo "=== Running on QEMU RISC-V emulator ==="
qemu-riscv64 softmax.elf

echo "=== For system emulation (if needed) ==="
echo "You can also run system emulation with:"
echo "qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 2G -nographic -kernel /path/to/kernel -append \"console=ttyS0\" -initrd /path/to/initrd"

echo "=== Script completed ===" 