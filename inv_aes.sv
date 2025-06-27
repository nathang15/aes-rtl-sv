`timescale 1ns / 1ps

module inv_aes(
    input logic clk, // clock signal
    input logic resetn, // active-low reset
    
    input logic data_valid_in, // input data valid signal
    input logic [127:0] data_in, // 128-bit input ciphertext
    input logic [127:0] key_in, // 128-bit decryption key (original key)

    output logic [127:0] res_dec_out, // 128-bit decrypted output
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

genvar i, c;

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
logic finished_v; // high when decryption is done
logic last_iter_v; // high during final round (skip InvMixColumns)
logic round_active; // high when FSM is not idle
logic unused_fsm_sum_msb; // Unused MSB from addition

// AES INVERSE TRANSFORMATION WIRES
aes_block_t inv_shift_row; // result after InvShiftRows (inverse row shifting)
aes_block_t inv_sub_bytes; // Result after InvSubBytes (inverse Sbox substitution)
aes_block_t inv_mix_columns; // result after InvMixColumns (inverse column mixing)
aes_block_t round_key_result; // final result after AddRoundKey (XOR with round key)
aes_block_t key_current; // ACTIVE round key being used in current cycle
byte_t key_rcon_current; // ACTIVE round constant being used in current cycle

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

// Inverse ShiftRows (right shifts instead of left shifts)
// First row (r = 0) is not shifted: bits [127:120], [95:88], [63:56], [31:24]
assign inv_shift_row[127:120] = data_q[127:120];  // byte 0
assign inv_shift_row[95:88]   = data_q[95:88];    // byte 4  
assign inv_shift_row[63:56]   = data_q[63:56];    // byte 8
assign inv_shift_row[31:24]   = data_q[31:24];    // byte 12

// Second row (r = 1) is cyclically right shifted by 1: bits [119:112], [87:80], [55:48], [23:16]
assign inv_shift_row[119:112] = data_q[23:16];    // byte 1 <- byte 13
assign inv_shift_row[87:80]   = data_q[119:112];  // byte 5 <- byte 1
assign inv_shift_row[55:48]   = data_q[87:80];    // byte 9 <- byte 5
assign inv_shift_row[23:16]   = data_q[55:48];    // byte 13 <- byte 9

// Third row (r = 2) is cyclically right shifted by 2: bits [111:104], [79:72], [47:40], [15:8]
assign inv_shift_row[111:104] = data_q[47:40];    // byte 2 <- byte 10
assign inv_shift_row[79:72]   = data_q[15:8];     // byte 6 <- byte 14
assign inv_shift_row[47:40]   = data_q[111:104];  // byte 10 <- byte 2
assign inv_shift_row[15:8]    = data_q[79:72];    // byte 14 <- byte 6

// Fourth row (r = 3) is cyclically right shifted by 3: bits [103:96], [71:64], [39:32], [7:0]
assign inv_shift_row[103:96]  = data_q[71:64];    // byte 3 <- byte 7
assign inv_shift_row[71:64]   = data_q[39:32];    // byte 7 <- byte 11
assign inv_shift_row[39:32]   = data_q[7:0];      // byte 11 <- byte 15
assign inv_shift_row[7:0]     = data_q[103:96];   // byte 15 <- byte 3

// Inverse S-box
generate 
    for (i = 0; i < 16; i++) begin : loop_gen_isb_i				
        inv_aes_sbox inv_sbox(
            .data_in(inv_shift_row[(i*8)+7:(i*8)]),
            .data_out(inv_sub_bytes[(i*8)+7:(i*8)])
        );
    end
endgenerate

// Inverse MixColumns
generate 
    for (c = 0; c < 4; c++) begin : loop_gen_imc_c
        inv_aes_mixw inv_mixw ( 
            .w_i(round_key_result[c*32+31:c*32]), 
            .mixw_o(inv_mix_columns[c*32+31:c*32])
        );
    end
endgenerate

// AddRoundKey: bitwise XOR (same operation for encryption and decryption)
assign round_key_result = inv_sub_bytes ^ key_current;

// Data flow control: exact match to your encryption structure
assign data_next = data_valid_in ? (data_in ^ key_current) : 
                   (last_iter_v ? round_key_result : inv_mix_columns);

// Key expansion logic using your aes_key_scheduling module
// Generate Round 10 key from original key
logic [127:0] round_10_key;
logic [127:0] temp_keys [0:10];
logic [7:0] temp_rcons [0:10];

// Generate all round keys from 0 to 10
assign temp_keys[0] = key_in;

// Explicit Rcon values to avoid generate loop issues
logic [7:0] rcon_values [0:9];
assign rcon_values[0] = 8'h01;  // Round 1
assign rcon_values[1] = 8'h02;  // Round 2
assign rcon_values[2] = 8'h04;  // Round 3
assign rcon_values[3] = 8'h08;  // Round 4
assign rcon_values[4] = 8'h10;  // Round 5
assign rcon_values[5] = 8'h20;  // Round 6
assign rcon_values[6] = 8'h40;  // Round 7
assign rcon_values[7] = 8'h80;  // Round 8
assign rcon_values[8] = 8'h1b;  // Round 9
assign rcon_values[9] = 8'h36;  // Round 10

genvar k;
generate
    for (k = 0; k < 10; k++) begin : key_gen_loop
        logic [7:0] unused_rcon_out;
        aes_key_scheduling forward_ks (
            .key_in(temp_keys[k]),
            .key_rcon_in(rcon_values[k]),
            .key_next_out(temp_keys[k+1]),
            .key_rcon_out(unused_rcon_out)
        );
    end
endgenerate

assign round_10_key = temp_keys[10];

// Key management
assign key_current = data_valid_in ? round_10_key : key_q;
assign key_rcon_current = data_valid_in ? 8'h36 : key_rcon_q;

// Inverse Key scheduler
inv_aes_key_scheduling iks(
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

// Decrypted final value
assign res_valid_out = finished_v;
assign res_dec_out = data_q;

function string format_hex_line(input [127:0] value);
    return $sformatf("%08h%08h%08h%08h", 
                     value[127:96], value[95:64], value[63:32], value[31:0]);
endfunction

always_ff @(posedge clk) begin : trace_block
    if (resetn && fsm_en) begin      
        if (fsm_q >= 4'h1 && fsm_q <= 4'hA) begin
            $display("* **Round %0d**", 11 - fsm_q);
            $display("* input to Round %0d", 11 - fsm_q);
            $display("* %s", format_hex_line(data_q));
            
            $display("* after permutation:");
            $display("* %s", format_hex_line(inv_shift_row));
            
            $display("* after S-Box:");
            $display("* %s", format_hex_line(inv_sub_bytes));
            
            $display("* used subkey:");
            $display("* %s", format_hex_line(key_current));
            
            $display("* after mix with key:");
            $display("* %s", format_hex_line(round_key_result));

            if (!last_iter_v) begin
                $display("* after mult:");
                $display("* %s", format_hex_line(inv_mix_columns));
            end
            $display("");
        end

        if (finished_v) begin
            $display("* **Decoded**");
            $display("* %s", format_hex_line(data_q));
            $display("* **AES INVERSE DECRYPTION COMPLETE**");
            $display("");
        end
    end
end

endmodule