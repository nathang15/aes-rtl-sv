`timescale 1ns / 1ps

module aes_mixw (
    input logic [31:0] w_i,
    output logic [31:0] mixw_o
);
    logic [7:0] b0, b1, b2, b3;
    assign b0 = w_i[7:0];     // LSB byte (i*32+:8)
    assign b1 = w_i[15:8];    // (i*32 + 8)+:8  
    assign b2 = w_i[23:16];   // (i*32 + 16)+:8
    assign b3 = w_i[31:24];   // MSB byte (i*32 + 24)+:8

    // Parallel GF multiplications
    logic [7:0] gm2_b0, gm2_b1, gm2_b2, gm2_b3;
    logic [7:0] gm3_b0, gm3_b1, gm3_b2, gm3_b3;
    
    // GF(2^8) multiplication by 2 (xtime)
    assign gm2_b0 = b0[7] ? ({b0[6:0], 1'b0} ^ 8'h1b) : {b0[6:0], 1'b0};
    assign gm2_b1 = b1[7] ? ({b1[6:0], 1'b0} ^ 8'h1b) : {b1[6:0], 1'b0};
    assign gm2_b2 = b2[7] ? ({b2[6:0], 1'b0} ^ 8'h1b) : {b2[6:0], 1'b0};
    assign gm2_b3 = b3[7] ? ({b3[6:0], 1'b0} ^ 8'h1b) : {b3[6:0], 1'b0};
    
    // GF(2^8) multiplication by 3
    assign gm3_b0 = gm2_b0 ^ b0;
    assign gm3_b1 = gm2_b1 ^ b1;
    assign gm3_b2 = gm2_b2 ^ b2;
    assign gm3_b3 = gm2_b3 ^ b3;
    
    logic [7:0] mb0, mb1, mb2, mb3;
    
    assign mb3 = gm2_b3 ^ gm3_b2 ^ b1 ^ b0;     // MSB output byte
    assign mb2 = b3 ^ gm2_b2 ^ gm3_b1 ^ b0;     // 
    assign mb1 = b3 ^ b2 ^ gm2_b1 ^ gm3_b0;     // 
    assign mb0 = gm3_b3 ^ b2 ^ b1 ^ gm2_b0;     // LSB output byte
    
    assign mixw_o = {mb3, mb2, mb1, mb0};
    
endmodule