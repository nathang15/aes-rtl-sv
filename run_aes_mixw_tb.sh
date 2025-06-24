RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting AES MixColumns Test Automation${NC}"
echo "========================================"

if ! command -v vsim &> /dev/null; then
    echo -e "${RED}Error: Questa (vsim) not found in PATH${NC}"
    echo "Please ensure Questa is installed and added to PATH"
    exit 1
fi

mkdir -p transcripts
mkdir -p waveforms
mkdir -p config/aes_mixw

# Clean prev sim files
echo "Cleaning previous simulation files..."
rm -rf aes_mixw_work
rm -rf work
rm -f *.wlf
rm -f transcripts/aes_mixw_transcript
rm -f waveforms/aes_mixw.vcd
rm -f modelsim.ini

echo "Creating work library..."
vlib aes_mixw_work
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create work library${NC}"
    exit 1
fi

vmap work aes_mixw_work
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to map work library${NC}"
    exit 1
fi

echo "Compiling design files..."
vlog -work aes_mixw_work -sv aes_mixw.sv tb_aes_mixw.sv
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Compilation failed${NC}"
    exit 1
fi

# Run
echo "Running simulation..."
vsim -c -voptargs=+acc tb_aes_mixw -do "run -all; quit -f"

if [ -f "transcript" ]; then
    mv transcript transcripts/aes_mixw_transcript
fi

if [ -f "modelsim.ini" ]; then
    mv modelsim.ini config/aes_mixw/modelsim.ini
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Simulation completed successfully${NC}"
    
    if grep -q "Test completed" transcripts/aes_mixw_transcript; then
        echo -e "${GREEN}✓ All tests completed${NC}"
        
        PASS_COUNT=$(grep -c "PASS" transcripts/aes_mixw_transcript)
        FAIL_COUNT=$(grep -c "FAIL" transcripts/aes_mixw_transcript)
        
        echo "Test Results:"
        echo "  PASS: $PASS_COUNT"
        echo "  FAIL: $FAIL_COUNT"
        
        if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -eq 4 ]; then
            echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
            exit 0
        else
            echo -e "${RED}❌ SOME TESTS FAILED${NC}"
            echo "Check transcripts/aes_mixw_transcript file for details"
            exit 1
        fi
    else
        echo -e "${RED}Error: Tests did not complete properly${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: Simulation failed${NC}"
    exit 1
fi