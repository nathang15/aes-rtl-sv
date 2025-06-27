`timescale 1ns / 1ps

module inv_aes_key_scheduling(
    input logic [127:0] key_in,
    input logic [7:0] key_rcon_in,
    output logic [127:0] key_next_out,
    output logic [7:0] key_rcon_out
);

// Internal signals
logic [31:0] w0, w1, w2, w3;  // Current key words (round N)
logic [31:0] w_prev0, w_prev1, w_prev2, w_prev3;  // Previous key words (round N-1)
logic [31:0] temp;
logic [31:0] rcon_word;
logic [7:0] prev_rcon;

// Extract current key into words
assign w0 = key_in[127:96];  // Most significant word
assign w1 = key_in[95:64];
assign w2 = key_in[63:32]; 
assign w3 = key_in[31:0];    // Least significant word

// Get previous Rcon value
assign prev_rcon = rcon_prev(key_rcon_in);
assign rcon_word = {prev_rcon, 24'h000000};

// Inverse key expansion
// To go backwards: w_prev[i] = w[i] ^ w[i+1]
// But w0 needs special handling since it used SubWord+RotWord+Rcon

// Generate intermediate values for w_prev0 calculation
logic [31:0] temp_rotated;
logic [31:0] temp_subbed;

// For w_prev0, we need to undo: w0 = w_prev0 ^ (SubWord(RotWord(w_prev3)) ^ Rcon)
// So: w_prev0 = w0 ^ (SubWord(RotWord(w_prev3)) ^ Rcon)

// First, calculate w_prev1, w_prev2, w_prev3
assign w_prev3 = w2 ^ w3;
assign w_prev2 = w1 ^ w2;
assign w_prev1 = w0 ^ w1;

// Now calculate temp using w_prev3
// RotWord: {a,b,c,d} -> {b,c,d,a}
assign temp_rotated = {w_prev3[23:16], w_prev3[15:8], w_prev3[7:0], w_prev3[31:24]};

// SubWord using inverse S-box (or regular S-box if that's what was used in forward)
logic [7:0] sbox_out_0, sbox_out_1, sbox_out_2, sbox_out_3;

aes_sbox sbox_0 (.data_in(temp_rotated[31:24]), .data_out(sbox_out_0));
aes_sbox sbox_1 (.data_in(temp_rotated[23:16]), .data_out(sbox_out_1));
aes_sbox sbox_2 (.data_in(temp_rotated[15:8]),  .data_out(sbox_out_2));
aes_sbox sbox_3 (.data_in(temp_rotated[7:0]),   .data_out(sbox_out_3));

assign temp_subbed = {sbox_out_0, sbox_out_1, sbox_out_2, sbox_out_3};
assign temp = temp_subbed ^ rcon_word;

// Calculate w_prev0
assign w_prev0 = w0 ^ temp;

// Output previous key
assign key_next_out = {w_prev0, w_prev1, w_prev2, w_prev3};

// Generate previous Rcon value
assign key_rcon_out = prev_rcon;

// Rcon previous function (inverse of rcon progression)
function [7:0] rcon_prev;
    input [7:0] current_rcon;
    begin
        case (current_rcon)
            8'h02: rcon_prev = 8'h01;
            8'h04: rcon_prev = 8'h02;
            8'h08: rcon_prev = 8'h04;
            8'h10: rcon_prev = 8'h08;
            8'h20: rcon_prev = 8'h10;
            8'h40: rcon_prev = 8'h20;
            8'h80: rcon_prev = 8'h40;
            8'h1b: rcon_prev = 8'h80;
            8'h36: rcon_prev = 8'h1b;
            8'h00: rcon_prev = 8'h36;
            8'h01: rcon_prev = 8'h00;
            default: rcon_prev = 8'h00;
        endcase
    end
endfunction

endmodule