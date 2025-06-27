# AES RTL Implementation
A complete SystemVerilog implementation of the Advanced Encryption Standard (AES) (128 for now) algorithm for FPGA and ASIC development.

## Overview
This project provides a fully functional, synthesizable AES-128 encryption/decryption written in SystemVerilog. The implementation follows the [FIPS-197 standard](https://csrc.nist.gov/files/pubs/fips/197/final/docs/fips-197.pdf).

## Quick Start

### Prerequisites

- **ModelSim/QuestaSim**
- **Python 3.7+**
- **PyCryptodome**
```
pip install pycryptodome
```
### Running Tests

#### Generate Test Vectors
```
python generate_vectors.py
```
#### Run Test Suite

```
chmod +x run_tests.sh
./run_tests.sh
```

#### Run Individual Tests

##### Sbox Test
```
rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes_sbox; run -all; quit"
```
##### MixColumns test
```
rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes_mixw; run -all; quit"
```

##### Key scheduling test
```
rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes_key_scheduling; run -all; quit"
```

##### Full AES test
```
rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes; run -all; quit"
```
## Architecture Details

### State Machine
The core uses a 4-bit finite state machine with the following states:

| State | Value | Description |
|-------|-------|-------------|
| IDLE | 4'h0 | Waiting for input data |
| Round 1-9 | 4'h1-4'h9 | Middle rounds (full transformations) |
| FINAL | 4'hA | Final round (no MixColumns) |
| DONE | 4'hB | Output result |

### Data Flow

1. Initial Round: AddRoundKey only
2. Rounds 1-9: SubBytes → ShiftRows → MixColumns → AddRoundKey
3. Final Round: SubBytes → ShiftRows → AddRoundKey
4. Output: Result available with valid signal

## Resources
NIST Test Vectors
AES Animation
Galois Field Arithmetic
Daemen & Rijmen (2002): "The Design of Rijndael: AES - The Advanced Encryption Standard"
[Boyar & Peralta (2009): "A new combinational logic minimization technique with applications to cryptology"](https://eprint.iacr.org/2011/332.pdf)

⚠️ Disclaimer: This implementation is for educational and research purposes. Production cryptographic systems require additional security analysis and validation.