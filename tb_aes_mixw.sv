`timescale 1ns / 1ps

module tb_aes_mixw;
    logic [31:0] data_i;
    logic [31:0] data_o;
    
    logic clk = 1'b0;
    parameter time CLK_PERIOD = 10ns;
    
    logic [31:0] test_diff;

    logic [31:0] test_input [0:3] = '{
        32'h6353e08c,
        32'h0960e104,
        32'hcd70b751,
        32'hbacad0e7
    };
    
    logic [31:0] test_output [0:3] = '{
        32'h5f726415,
        32'h57f5bc92,
        32'hf7be3b29,
        32'h1db9f91a
    };

    aes_mixw uut (
        .w_i(data_i),
        .mixw_o(data_o)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $display("Starting AES MixColumns testbench");
        #10ns;
        
        for (int i = 0; i < 4; i++) begin
            data_i = test_input[i];
            
            #1ns;
            
            test_diff = data_o ^ test_output[i];
            
            if (data_o !== test_output[i]) begin
                $display("FAIL: Test %0d failed", i);
                $display("  Input:    %08h", test_input[i]);
                $display("  Got:      %08h", data_o);
                $display("  Expected: %08h", test_output[i]);
                $display("  Diff:     %08h", test_diff);
                
                $display("  Byte analysis:");
                $display("    Input bytes:  %02h %02h %02h %02h", 
                         test_input[i][31:24], test_input[i][23:16], 
                         test_input[i][15:8], test_input[i][7:0]);
                $display("    Output bytes: %02h %02h %02h %02h", 
                         data_o[31:24], data_o[23:16], data_o[15:8], data_o[7:0]);
                $display("    Expected:     %02h %02h %02h %02h", 
                         test_output[i][31:24], test_output[i][23:16], 
                         test_output[i][15:8], test_output[i][7:0]);
                
                $fatal(1, "MixColumns test failed at vector %0d", i);
            end else begin
                $display("PASS: Test %0d - input %08h -> output %08h", i, test_input[i], data_o);
            end
            
            #(CLK_PERIOD);
        end
        
        $display("All AES MixColumns tests passed successfully!");
        $finish;
    end
endmodule