`timescale 1ns / 1ps

module inv_aes_mixw (
    input logic [31:0] w_i,
    output logic [31:0] mixw_o
);
    logic [7:0] b0, b1, b2, b3;
    assign b0 = w_i[7:0];     // LSB byte
    assign b1 = w_i[15:8];    
    assign b2 = w_i[23:16];   
    assign b3 = w_i[31:24];   // MSB byte

    // Helper function for GF(2^8) multiplication by 2 (xtime)
    function automatic logic [7:0] multiply(input logic [7:0] x, input integer n);
        logic [7:0] result;
        integer i;
        begin
            result = x;
            for(i = 0; i < n; i = i + 1) begin
                if(result[7] == 1) 
                    result = ((result << 1) ^ 8'h1b);
                else 
                    result = result << 1; 
            end
            multiply = result;
        end
    endfunction
    
    // GF(2^8) multiplication
    function automatic logic [7:0] mb0e(input logic [7:0] x); // multiply by {0e}
        begin
            mb0e = multiply(x, 3) ^ multiply(x, 2) ^ multiply(x, 1);
        end
    endfunction
    
    function automatic logic [7:0] mb0d(input logic [7:0] x); // multiply by {0d}
        begin
            mb0d = multiply(x, 3) ^ multiply(x, 2) ^ x;
        end
    endfunction
    
    function automatic logic [7:0] mb0b(input logic [7:0] x); // multiply by {0b}
        begin
            mb0b = multiply(x, 3) ^ multiply(x, 1) ^ x;
        end
    endfunction
    
    function automatic logic [7:0] mb09(input logic [7:0] x); // multiply by {09}
        begin
            mb09 = multiply(x, 3) ^ x;
        end
    endfunction
    
    logic [7:0] mb0, mb1, mb2, mb3;
    
    assign mb3 = mb0e(b3) ^ mb0b(b2) ^ mb0d(b1) ^ mb09(b0);  // MSB output byte
    assign mb2 = mb09(b3) ^ mb0e(b2) ^ mb0b(b1) ^ mb0d(b0);  
    assign mb1 = mb0d(b3) ^ mb09(b2) ^ mb0e(b1) ^ mb0b(b0);  
    assign mb0 = mb0b(b3) ^ mb0d(b2) ^ mb09(b1) ^ mb0e(b0);  // LSB output byte
    
    assign mixw_o = {mb3, mb2, mb1, mb0};
    
endmodule