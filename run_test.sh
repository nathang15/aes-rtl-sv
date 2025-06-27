echo "======================================"
echo "    AES Test Suite Runner"
echo "======================================"
echo

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

run_test() {
    local test_name=$1
    local testbench=$2
    
    echo -e "${BLUE}Running $test_name...${NC}"
    echo "----------------------------------------"
    
    rm -rf work 2>/dev/null
    
    if vsim -c -do "vlib work; vlog -sv *.sv; vsim work.$testbench; run -all; quit" 2>&1; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        return 1
    fi

    echo
    return 0
}

total_tests=0
passed_tests=0

echo "Starting AES component tests..."
echo

# Test 1: AES S-box
total_tests=$((total_tests + 1))
if run_test "AES S-box Test" "tb_aes_sbox"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 2: AES MixColumns
total_tests=$((total_tests + 1))
if run_test "AES MixColumns Test" "tb_aes_mixw"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 3: AES Key Scheduling
total_tests=$((total_tests + 1))
if run_test "AES Key Scheduling Test" "tb_aes_key_scheduling"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 4: Full AES Encryption
total_tests=$((total_tests + 1))
if run_test "AES Full Encryption Test" "tb_aes"; then
    passed_tests=$((passed_tests + 1))
fi

rm -rf work 2>/dev/null

echo "======================================"
echo "           Test Summary"
echo "======================================"
echo "Total tests run: $total_tests"
echo -e "Tests passed:    ${GREEN}$passed_tests${NC}"
echo -e "Tests failed:    ${RED}$((total_tests - passed_tests))${NC}"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}🎉 All tests PASSED! 🎉${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests FAILED ❌${NC}"
    exit 1
fi