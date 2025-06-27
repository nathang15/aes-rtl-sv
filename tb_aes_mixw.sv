module tb_aes_mixw;
    logic [31:0] data_i = 32'hxxxxxxxx;
    logic [31:0] data_o;
    
    logic clk = 1'b0;
    parameter time CLK_PERIOD = 10ns;
    
    logic [31:0] test_diff;
    logic [31:0] test_input [0:3] = '{
        32'h1a96de77,
        32'he598271e,
        32'h3b87db49,
        32'h305dbfd4
    };
    
    logic [31:0] test_output [0:3] = '{
        32'he5b06b1b,
        32'h4c260628,
        32'hf1ca4d58,
        32'he5816604
    };

    aes_mixw uut (
        .w_i(data_i),
        .mixw_o(data_o)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        #10ns;
        
        for (int i = 0; i < 4; i++) begin
            data_i = test_input[i];
            
            #(CLK_PERIOD/10);
            
            test_diff = data_o ^ test_output[i];
            
            #(CLK_PERIOD/10);
            
            if (data_o !== test_output[i]) begin
                $fatal(1, "Output doesn't match expected at test %0d: got %08h, expected %08h, diff %08h", 
                       i, data_o, test_output[i], test_diff);
            end else begin
                $display("Test %0d passed: input %08h -> output %08h", i, test_input[i], data_o);
            end
            
            #(CLK_PERIOD);
        end
        
        $display("AES MixColumns test completed successfully");
        $finish;
    end

endmodule