`timescale 1ns/1ps

module tb_aes_mixw;

    // Testbench signals
    logic clk;
    logic [31:0] data_i;
    logic [31:0] data_o;
    logic [31:0] diff;
    
    // Test vectors
    logic [31:0] test_input [4] = '{
        32'h1a96de77,
        32'he598271e, 
        32'h3b87db49,
        32'h305dbfd4
    };
    
    logic [31:0] test_output [4] = '{
        32'he5b06b1b,
        32'h4c260628,
        32'hf1ca4d58,
        32'he5816604
    };
    
    // Clock generation
    parameter CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // DUT instantiation
    aes_mixw dut (
        .w_i(data_i),
        .mixw_o(data_o)
    );
    
    initial begin
        clk = 0;
        data_i = 32'hxxxxxxxx;
        
        $display("Starting AES MixColumns Test");
        $display("Time\tInput\t\tExpected\tActual\t\tResult");
        $display("----\t-----\t\t--------\t------\t\t------");

        #10;
        
        // Test all input vectors
        for (int i = 0; i < 4; i++) begin
            data_i = test_input[i];

            #(CLK_PERIOD/10);

            diff = data_o ^ test_output[i];
            
            // Check result
            if (diff == 32'h00000000) begin
                $display("%0t\t0x%08h\t0x%08h\t0x%08h\tPASS", 
                        $time, test_input[i], test_output[i], data_o);
            end else begin
                $display("%0t\t0x%08h\t0x%08h\t0x%08h\tFAIL", 
                        $time, test_input[i], test_output[i], data_o);
                $error("Test %0d failed: Expected 0x%08h, got 0x%08h", 
                       i, test_output[i], data_o);
            end
            
            #(CLK_PERIOD/10);
            #CLK_PERIOD;
        end
        
        $display("\nTest completed");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("waveforms/aes_mixw.vcd");
        $dumpvars(0, tb_aes_mixw);
    end
    
endmodule