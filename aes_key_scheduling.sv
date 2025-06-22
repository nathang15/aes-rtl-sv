`timescale 1ns / 1ps
module aes_key_scheduling(
    input  logic [127:0] key_in,        // 128-bit input key
    input  logic [7:0]   key_rcon_in,   // Round constant input
    output logic [127:0] key_next_out,  // 128-bit output key
    output logic [7:0]   key_rcon_out   // Round constant output
);

    genvar i, j;

    // Internal signals
    logic [31:0] key_words[4]; // Input key split into words
    logic [31:0] key_words_next[4]; // Output key words
    logic [31:0] w3_transformed; // Last word after transformation

    // Extract words from input key (column-major order)
    generate
        for (i = 0; i < 4; i++) begin : gen_extract_words
            assign key_words[i] = key_in[i*32 +: 32];
        end
    endgenerate

    // Transform the LAST word (w3): RotWord -> SubWord -> XOR with Rcon
    logic [31:0] w3_rotated;
    logic [31:0] w3_substituted;

    // RotWord: rotate left by 8 bits (one byte position)
    assign w3_rotated = {key_words[3][23:0], key_words[3][31:24]};

    // SubWord: apply S-box to each byte in parallel
    generate
        for (j = 0; j < 4; j++) begin : gen_sbox_transform
            aes_sbox u_sbox (
                .data_in(w3_rotated[j*8 +: 8]),
                .data_out(w3_substituted[j*8 +: 8])
            );
        end
    endgenerate
    
    // XOR with round constant on MSB (first byte in little-endian)
    assign w3_transformed = {w3_substituted[31:8], w3_substituted[7:0] ^ key_rcon_in};
    
    // Key expansion: w[i] = w[i-4] XOR f(w[i-1])
    assign key_words_next[0] = key_words[0] ^ w3_transformed;
    assign key_words_next[1] = key_words[1] ^ key_words_next[0];
    assign key_words_next[2] = key_words[2] ^ key_words_next[1];
    assign key_words_next[3] = key_words[3] ^ key_words_next[2];

    // Reconstruct output key
    generate
        for (i = 0; i < 4; i++) begin : gen_reconstruct_key
            assign key_next_out[i*32 +: 32] = key_words_next[i];
        end
    endgenerate

    // Round constant update using Galois field multiplication
    always_comb begin
        case (key_rcon_in)
            8'h01: key_rcon_out = 8'h02;
            8'h02: key_rcon_out = 8'h04;
            8'h04: key_rcon_out = 8'h08;
            8'h08: key_rcon_out = 8'h10;
            8'h10: key_rcon_out = 8'h20;
            8'h20: key_rcon_out = 8'h40;
            8'h40: key_rcon_out = 8'h80;
            8'h80: key_rcon_out = 8'h1b;
            8'h1b: key_rcon_out = 8'h36;
            8'h36: key_rcon_out = 8'h01;
            default: key_rcon_out = 8'h01;
        endcase
    end
endmodule
