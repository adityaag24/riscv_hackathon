#!/bin/bash

# Exit on error
set -e

# Path to RISC-V Linux toolchain
export PATH=$PATH:$HOME/riscv-linux-install/bin
# Path to Spike
export PATH=$PATH:$HOME/riscv-install/bin

echo "=== Compiling softmax.c for RISC-V ==="
riscv64-unknown-elf-gcc -march=rv64gcv_zicntr_zihpm -mabi=lp64d -static -O2 -o softmax.elf softmax.c -lm

echo "=== Running on Spike RISC-V simulator ==="
# Run with Spike simulator
spike --isa=rv64imafdv softmax.elf

echo "=== Execution completed ==="
