`timescale 1ns / 1ps

module aes(
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
logic finished_v; // high when encryption is done
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

// FSM Control Logic
assign fsm_en = (|fsm_q) | data_valid_in;
assign finished_v = fsm_q[3] & fsm_q[1] & fsm_q[0];
assign {unused_fsm_sum_msb, fsm_next} = finished_v ? 5'b00000 : fsm_q + 4'b0001;
assign last_iter_v = fsm_q[3] & fsm_q[1];

// FSM State Register
always_ff @(posedge clk) begin : fsm_dff
    if (!resetn) 
        fsm_q <= 4'b0000;
    else if (fsm_en) 
        fsm_q <= fsm_next;
end 

// Data Register
always_ff @(posedge clk) begin : data_dff
    data_q <= data_next;
end 

// S-box Substitution (SubBytes)
generate 
    for (i = 0; i < 16; i++) begin : loop_gen_sb_i				
        aes_sbox sbox(
            .data_in(data_q[(i*8)+7:(i*8)]),
            .data_out(sub_bytes[(i*8)+7:(i*8)])
        );
    end
endgenerate

// ShiftRows
generate 
    for (r = 0; r < 4; r++) begin : loop_gen_sr_r
        assign sub_bytes_row[r] = {sub_bytes[3*32+8*r+7:3*32+8*r],
                                   sub_bytes[2*32+8*r+7:2*32+8*r],
                                   sub_bytes[32+8*r+7:32+8*r],
                                   sub_bytes[8*r+7:8*r]};
        assign {shift_row[3*32+8*r+7:3*32+8*r],
                shift_row[2*32+8*r+7:2*32+8*r],
                shift_row[1*32+8*r+7:1*32+8*r],
                shift_row[0*32+8*r+7:0*32+8*r]} = shift_row_row[r];
    end
endgenerate

// ShiftRows transformation
assign shift_row_row[0] = sub_bytes_row[0]; // no shift on row 0
assign shift_row_row[3] = {sub_bytes_row[3][23:16], sub_bytes_row[3][15:8], sub_bytes_row[3][7:0], sub_bytes_row[3][31:24]}; // row1 0,1,2,3 -> 1,2,3,0
assign shift_row_row[2] = {sub_bytes_row[2][15:8], sub_bytes_row[2][7:0], sub_bytes_row[2][31:24], sub_bytes_row[2][23:16]}; // row2 0,1,2,3 -> 2,3,0,1
assign shift_row_row[1] = {sub_bytes_row[1][7:0], sub_bytes_row[1][31:24], sub_bytes_row[1][23:16], sub_bytes_row[1][15:8]}; // row3 0,1,2,3 -> 3,0,1,2

// MixColumns
generate 
    for (c = 0; c < 4; c++) begin : loop_gen_mc_c
        aes_mixw mixw ( 
            .w_i(shift_row[c*32+31:c*32]), 
            .mixw_o(mix_columns[c*32+31:c*32])
        );
    end
endgenerate

// AddRoundKey: bitwise XOR
assign round_key_result = data_valid_in ? data_in : (last_iter_v ? shift_row : mix_columns);
assign data_next = round_key_result ^ key_current;

// Key expansion logic
assign key_current = data_valid_in ? key_in : key_q;
assign key_rcon_current = data_valid_in ? 8'b0000_0001 : key_rcon_q;

// Key scheduler instance
aes_key_scheduling ks(
    .key_in(key_current),
    .key_rcon_in(key_rcon_current),
    .key_next_out(key_next),
    .key_rcon_out(key_rcon_next)
);

// Key registers
always_ff @(posedge clk) begin : key_dff
    if (fsm_en) begin
        key_q <= key_next;
        key_rcon_q <= key_rcon_next;
    end
end

// Output
assign res_valid_out = finished_v;
assign res_enc_out = data_q;

endmodule