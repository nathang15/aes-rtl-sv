RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting AES Key Scheduling Test Automation${NC}"
echo "=============================================="

if ! command -v vsim &> /dev/null; then
    echo -e "${RED}Error: Questa (vsim) not found in PATH${NC}"
    echo "Please ensure Questa is installed and added to PATH"
    exit 1
fi

mkdir -p transcripts
mkdir -p waveforms
mkdir -p config/aes_key_scheduling

echo -e "${BLUE}Setting up simulation environment...${NC}"

echo "Cleaning previous simulation files..."
rm -rf aes_key_scheduling_work
rm -rf work
rm -f *.wlf
rm -f transcripts/aes_key_scheduling_transcript
rm -f waveforms/aes_key_scheduling.vcd
rm -f modelsim.ini

echo "Creating work library..."
vlib aes_key_scheduling_work
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create work library${NC}"
    exit 1
fi

vmap work aes_key_scheduling_work
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to map work library${NC}"
    exit 1
fi

echo "Checking for required files..."

REQUIRED_FILES=("aes_key_scheduling.sv" "tb_aes_key_scheduling.sv")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    else
        echo -e "${GREEN}  ✓ Found: $file${NC}"
    fi
done

if [ -f "aes_sbox.sv" ]; then
    echo -e "${GREEN}  ✓ Found: aes_sbox.sv${NC}"
    REQUIRED_FILES+=("aes_sbox.sv")
else
    echo -e "${RED}  ✗ Missing: aes_sbox.sv (required dependency)${NC}"
    MISSING_FILES+=("aes_sbox.sv")
fi

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    exit 1
fi

echo "Compiling SystemVerilog files..."

COMPILE_CMD="vlog -work aes_key_scheduling_work -sv"

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        COMPILE_CMD="$COMPILE_CMD $file"
    fi
done

echo "Compile command: $COMPILE_CMD"
eval $COMPILE_CMD

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Compilation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Compilation successful${NC}"

# Run
echo ""
echo -e "${PURPLE}Running AES Key Scheduling simulation...${NC}"
echo "This will test the key expansion algorithm for 10 rounds."

vsim -c -voptargs=+acc tb_aes_key_scheduling -do "
    # Add waves for debugging if needed
    # add wave -r /*
    
    run -all;
    
    if {[runStatus] == \"ready\"} {
        echo \"Simulation completed normally\";
    } else {
        echo \"Simulation ended with status: [runStatus]\";
    }
    quit -f
" 2>&1

if [ -f "transcript" ]; then
    mv transcript transcripts/aes_key_scheduling_transcript
fi

if [ -f "modelsim.ini" ]; then
    mv modelsim.ini config/aes_key_scheduling/modelsim.ini
fi

echo ""
echo "Analyzing simulation results..."

if [ -f "transcripts/aes_key_scheduling_transcript" ]; then
    if grep -q "All tests passed!" transcripts/aes_key_scheduling_transcript; then
        echo -e "${GREEN}✓ Key scheduling test completed successfully${NC}"
        
        ROUND_COUNT=$(grep -c "Round.*completed" transcripts/aes_key_scheduling_transcript)
        
        echo ""
        echo "Test Results Summary:"
        echo "Rounds completed: $ROUND_COUNT/10"
        
        if [ $ROUND_COUNT -eq 10 ]; then
            echo ""
            echo -e "${GREEN}🎉 ALL KEY SCHEDULING TESTS PASSED! 🎉${NC}"
            exit 0
        else
            echo -e "${YELLOW}Warning: Only $ROUND_COUNT rounds completed (expected 10)${NC}"
            exit 1
        fi
        
    elif grep -q "FATAL" transcripts/aes_key_scheduling_transcript || grep -q "ERROR" transcripts/aes_key_scheduling_transcript; then
        echo -e "${RED}❌ SIMULATION FAILED${NC}"
        echo ""
        echo "Error details:"
        grep -E "(FATAL|ERROR)" transcripts/aes_key_scheduling_transcript | head -10
        echo "Check transcripts/aes_key_scheduling_transcript for full details"
        exit 1
    else
        echo -e "${YELLOW}Warning: Simulation completed but status unclear${NC}"
        echo "Check transcripts/aes_key_scheduling_transcript for details"
        exit 1
    fi
else
    echo -e "${RED}Error: No transcript file found${NC}"
    echo "Simulation may not have run correctly"
    exit 1
fi