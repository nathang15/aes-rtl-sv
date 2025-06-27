`timescale 1ns / 1ps

module aes_key_scheduling(
    input logic [127:0] key_in,
    input logic [7:0] key_rcon_in,
    output logic [127:0] key_next_out,
    output logic [7:0] key_rcon_out
);

// Internal signals
logic [31:0] w0, w1, w2, w3;  // Current key words
logic [31:0] w4, w5, w6, w7;  // Next key words
logic [31:0] temp;
logic [31:0] rcon_word;

// Extract current key into words
assign w0 = key_in[127:96];  // Most significant word
assign w1 = key_in[95:64];
assign w2 = key_in[63:32]; 
assign w3 = key_in[31:0];    // Least significant word

// Generate Rcon word from input byte
assign rcon_word = {key_rcon_in, 24'h000000};

// Key expansion
// Apply RotWord, SubWord, and XOR with Rcon
logic [31:0] temp_rotated;
logic [31:0] temp_subbed;

// RotWord: {a,b,c,d} -> {b,c,d,a}
assign temp_rotated = {w3[23:16], w3[15:8], w3[7:0], w3[31:24]};

// SubWord
logic [7:0] sbox_out_0, sbox_out_1, sbox_out_2, sbox_out_3;

aes_sbox sbox_0 (.data_in(temp_rotated[31:24]), .data_out(sbox_out_0));
aes_sbox sbox_1 (.data_in(temp_rotated[23:16]), .data_out(sbox_out_1));
aes_sbox sbox_2 (.data_in(temp_rotated[15:8]),  .data_out(sbox_out_2));
aes_sbox sbox_3 (.data_in(temp_rotated[7:0]),   .data_out(sbox_out_3));

assign temp_subbed = {sbox_out_0, sbox_out_1, sbox_out_2, sbox_out_3};

assign temp = temp_subbed ^ rcon_word;

// Generate new key words
assign w4 = w0 ^ temp;
assign w5 = w1 ^ w4;
assign w6 = w2 ^ w5;
assign w7 = w3 ^ w6;

// Output next key
assign key_next_out = {w4, w5, w6, w7};

// Generate next Rcon value
assign key_rcon_out = rcon_next(key_rcon_in);

// Rcon progression function
function [7:0] rcon_next;
    input [7:0] current_rcon;
    begin
        case (current_rcon)
            8'h01: rcon_next = 8'h02;
            8'h02: rcon_next = 8'h04;
            8'h04: rcon_next = 8'h08;
            8'h08: rcon_next = 8'h10;
            8'h10: rcon_next = 8'h20;
            8'h20: rcon_next = 8'h40;
            8'h40: rcon_next = 8'h80;
            8'h80: rcon_next = 8'h1b;
            8'h1b: rcon_next = 8'h36;
            8'h36: rcon_next = 8'h00;
            default: rcon_next = 8'h00;
        endcase
    end
endfunction

endmodule