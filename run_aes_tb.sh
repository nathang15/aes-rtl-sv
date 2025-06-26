#!/bin/bash
# AES-128 SystemVerilog Verification Script

echo "======================================"
echo "AES-128 SystemVerilog Verification"
echo "======================================"

echo -e "\nCompiling SystemVerilog files..."

if command -v vlog &> /dev/null; then
    echo "Using Questa/ModelSim"
    vlib work
    vlog -sv aes.sv aes_sbox.sv aes_mixw.sv aes_key_scheduling.sv tb_aes.sv
    if [ $? -ne 0 ]; then
        echo "Error: Compilation failed"
        exit 1
    fi
    
    echo -e "\nRunning simulation..."
    vsim -c -do "run -all; quit" work.tb_aes
    
else
    echo "Error: No supported SystemVerilog simulator found"
    echo "Please install Questa/ModelSim"
    exit 1
fi

echo -e "\n======================================"
echo "Test Results Summary:"
echo "======================================"
grep -E "Test Summary:|Total Tests:|Passed:|Failed:|Success Rate:|ALL TESTS" aes_test_results.log

if grep -q "ALL TESTS PASSED" aes_test_results.log; then
    echo -e "\nSUCCESS: All tests passed!"
    exit 0
else
    echo -e "\nFAILURE: Some tests failed."
    exit 1
fi