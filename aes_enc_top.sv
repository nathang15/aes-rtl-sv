`timescale 1ns/1ps

module aes_enc_top(
    input logic clk, // clock signal
    input logic resetn, // active-low reset
    
    input logic data_valid_in, // input data valid signal
    input logic [127:0] data_in, // 128-bit input plaintext
    input logic [127:0] key_in, // 128-bit encryption key

    output logic [127:0] res_enc_out, // 128-bit encrypted output
    output logic res_valid_out // output valid signal
);

// Type definitions
typedef logic [127:0] aes_block_t; // 128-bit AES data block
typedef logic [31:0] aes_word_t; // 32-bit AES word
typedef logic [7:0] byte_t; // byte type
typedef logic [3:0] round_t; // round counter

// State machine params
localparam round_t IDLE = 4'h0; // waiting for new data input
localparam round_t FINAL = 4'hA; // round 10 - last transformation round
localparam round_t DONE = 4'hB; // round 11 - output result and reset

genvar i,r,c;

// INTERNAL REGISTERS
aes_block_t data_q; // current data being processed
aes_block_t data_next; // next data value to go in data_q

round_t fsm_q; // 4-bit current FSM state register (0-11)
round_t fsm_next; // next FSM state

aes_block_t key_q; // stored round key from previous clock cycle
aes_block_t key_next; // next round key computed by scheduler

byte_t key_rcon_q; // round constant reg for key expansion
byte_t key_rcon_next; // next round constant reg for key expansion

// CONTROL SIGNALS for FSM and data flow
logic fsm_en; // allows state machine to advance
logic finished_v; // hihg when encryption is done
logic last_iter_v; // high during final round (skip MixColumns)
logic round_active; // high when FSM is not idle
logic unused_fsm_sum_msb; // Unused MSB from addition

// AES TRANSFORMATION WIRES
aes_block_t sub_bytes; // result after SubBytes (Sbox substiution)
aes_block_t shift_row; // Result after ShiftRows (row shifting)
aes_block_t mix_columns; // result after MixColumns (column mixing)
aes_block_t round_key_result; // final result after AddRoundKey (XOR with round key)
aes_block_t key_current; // ACTIVE round key being used in current cycle
byte_t key_rcon_current; // ACTIVE round constant being used in current cycle

// DATA REORGANIZTION ARRAYS for easier bit manipulation
aes_word_t sub_bytes_row[4]; // SubBytes result organized by rows [r3, r2, r1, r0]
aes_word_t shift_row_row[4]; // ShiftRows result organized by rows [r3, r2, r1, r0]

// CONTROL LOGIC

// Check if any round is currently active
assign round_active = |fsm_q;

// Enable FSM to advance when either processing rounds OR new data arrives
assign fsm_en = round_active || data_valid_in;

// Check if done all rounds
assign finished_v = (fsm_q == DONE);

// Check if on the last transformation round
assign last_iter_v = (fsm_q == FINAL);

// Determine FSM next state
always_comb begin
    if (finished_v) begin
        fsm_next = IDLE; // return to IDL after completion
    end else if (fsm_en) begin
        fsm_next = fsm_q + 1'b1; // go to next round
    end else begin
        fsm_next = fsm_q; // stay in current state
    end
end

// SEQUENTIAL LOGIC

// FSM state register
always_ff @(posedge clk) begin
    if (!resetn) begin
        fsm_q <= IDLE;
    end else begin
        fsm_q <= fsm_next;
    end
end

// Data register
always_ff @(posedge clk) begin
    data_q <= data_next; // update with result from current round
end

// Key registers
always_ff @(posedge clk) begin
    if (fsm_en) begin
        key_q <= key_next;
        key_rcon_q <= key_rcon_next;
    end
end

// AES TRANSFORMATION

// SubBytes: Substitutes each byte using AES S-box
generate
    for (i = 0; i < 16; i++) begin : gen_sbox
        aes_sbox u_sbox (
            .data_in(data_q[i*8 +: 8]), // Input is each byte of current data
            .data_out(sub_bytes[i*8 +: 8])
        );
    end
endgenerate
 
// ShiftRows: Cyclically shift rows left

// Step 1: Reorganize 128-bit block into 4 rows of 32
// AES state matrix layout: [col3 col2 col1 col0] for each row
generate
    for (r = 0; r < 4; r++) begin: gen_rows
        assign sub_bytes_row[r] = {
            sub_bytes[3*32 + r*8 +: 8],
            sub_bytes[2*32 + r*8 +: 8],
            sub_bytes[1*32 + r*8 +: 8],
            sub_bytes[0*32 + r*8 +: 8]
        };
    end
endgenerate

// Apply ShiftRows transformation:
// Row 0: no shift                    [a b c d] -> [a b c d]
// Row 1: left shift by 1 position    [a b c d] -> [b c d a] 
// Row 2: left shift by 2 positions   [a b c d] -> [c d a b]
// Row 3: left shift by 3 positions   [a b c d] -> [d a b c]
 // Row 0: no shift
assign shift_row_row[0] = sub_bytes_row[0];
// Row 1: left shift by 1
assign shift_row_row[1] = {sub_bytes_row[1][23:0], sub_bytes_row[1][31:24]};
// Row 2: left shift by 2 
assign shift_row_row[2] = {sub_bytes_row[2][15:0], sub_bytes_row[2][31:16]};
// Row 3: left shift by 3
assign shift_row_row[3] = {sub_bytes_row[3][7:0],  sub_bytes_row[3][31:8]};

// Reorganize shifted rows back into column format for next transformation
generate
    for (r = 0; r < 4; r++) begin : gen_shift_cols
        assign {
            shift_row[3*32 + r*8 +: 8],
            shift_row[2*32 + r*8 +: 8],
            shift_row[1*32 + r*8 +: 8],
            shift_row[0*32 + r*8 +: 8]
        } = shift_row_row[r];
    end
endgenerate

// MixColumns
generate
    for (c = 0; c < 4; c++) begin : gen_mixcol
        aes_mixw u_mixw (
            .w_i(shift_row[c*32 +: 32]),
            .mixw_o(mix_columns[c*32 +: 32])
        );
    end
endgenerate

// KEY SCHEDULE AND ROUND KEY ADDITION

// Key schedule inputs
assign key_current = data_valid_in ? key_in : key_q;
assign key_rcon_current = data_valid_in ? 8'h01 : key_rcon_q;

// Key scheduling module
aes_key_scheduling u_key_scheduling (
    .key_in(key_current),
    .key_rcon_in(key_rcon_current),
    .key_next_out(key_next),
    .key_rcon_out(key_rcon_next)
);

// AddRoundKey: XOR with round key
// Skip MixColumns in the last round
always_comb begin
    if (data_valid_in) begin
        // Round 0
        // XOR input data with original key since no transformation yet
        round_key_result = data_in ^ key_current;
    end else if (last_iter_v) begin
        // Last round (round 10)
        // Apply SubBytes + ShiftRows, then XOR with round key
        round_key_result = shift_row ^ key_current;
    end else begin
        // Apply SubBytes + ShiftRows + MixColumns + AddRoundKey
        round_key_result = mix_columns ^ key_current;
    end
end

// Store the result for next clock cycle
assign data_next = round_key_result;

// OUTPUT ASSIGNMENT
assign res_valid_out = finished_v;
assign res_enc_out = data_q;

endmodule