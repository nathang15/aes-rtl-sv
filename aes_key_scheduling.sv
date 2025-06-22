`timescale 1ns / 1ps
module aes_key_scheduling(
    input  logic [127:0] key_in,        // 128-bit input key
    input  logic [7:0]   key_rcon_in,   // Round constant input
    output logic [127:0] key_next_out,  // 128-bit output key
    output logic [7:0]   key_rcon_out   // Round constant output
);

    genvar i, j;

    // Internal signals
    logic [31:0] key_words[4];      // Input key split into words
    logic [31:0] key_words_next[4]; // Output key words
    logic [31:0] w3_rotated;        // After rotation
    logic [31:0] w3_substituted;    // After S-box
    logic [31:0] w3_transformed;    // Final transformed word
    
    // Rcon calculation signals
    logic        rcon_overflow;
    logic [7:0]  rcon_next;
    logic [7:0]  rcon_final;

    // Extract words from input key (column-major order)
    generate
        for (i = 0; i < 4; i++) begin : gen_extract_words
            assign key_words[i] = key_in[i*32 +: 32];
        end
    endgenerate

    // Transform the LAST word (w3): RotWord -> SubWord -> XOR with Rcon
    
    // RotWord
    assign w3_rotated[31:24] = key_words[3][7:0];    // Move LSB to MSB
    assign w3_rotated[23:16] = key_words[3][31:24];  // Move MSB to second position
    assign w3_rotated[15:8]  = key_words[3][23:16];  // Move second to third
    assign w3_rotated[7:0]   = key_words[3][15:8];   // Move third to LSB

    // SubWord: apply S-box to each byte in parallel
    generate
        for (j = 0; j < 4; j++) begin : gen_sbox_transform
            aes_sbox u_sbox (
                .data_in(w3_rotated[j*8 +: 8]),
                .data_out(w3_substituted[j*8 +: 8])
            );
        end
    endgenerate
    
    // XOR with round constant on LSB (least significant byte)
    assign w3_transformed = {w3_substituted[31:8], w3_substituted[7:0] ^ key_rcon_in};
    
    // Key expansion
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

    // Round constant update
    assign rcon_overflow = key_rcon_in[7];
    assign rcon_next = {key_rcon_in[6:0], 1'b0};

    assign rcon_final = ({8{rcon_overflow}} & 8'h1b) | ({8{~rcon_overflow}} & rcon_next);
    assign key_rcon_out = rcon_final;

endmodule