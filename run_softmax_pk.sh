#!/bin/bash

# Exit on error
set -e

# Path to RISC-V Linux toolchain
export PATH=$PATH:/home/adiagrawal/riscv-linux-install/bin
# Path to Spike
export PATH=$PATH:/home/adiagrawal/riscv-install/bin
# Path to Proxy Kernel
export PATH=$PATH:/home/adiagrawal/riscv-pk-install/bin

echo "=== Compiling softmax.c for RISC-V ==="
cd /home/adiagrawal/riscv-hackathon
riscv64-unknown-linux-gnu-gcc -march=rv64gc -mabi=lp64d -O2 -o softmax.elf softmax.c -lm

echo "=== Running on Spike RISC-V simulator with Proxy Kernel ==="
spike --isa=rv64gc $(which pk) softmax.elf

echo "=== Execution completed ==="
