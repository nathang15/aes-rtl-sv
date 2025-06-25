`timescale 1ns/1ps

module tb_aes_key_scheduling;
    // Inputs
    logic [127:0] key_in;
    logic [7:0] key_rcon_in;
    
    // Outputs
    logic [127:0] key_next_out;
    logic [7:0] key_rcon_out;
    
    // Clock signal
    logic clk;
    
    // Internal testbench signals
    logic [7:0] key_rcon_next;
    logic [127:0] key_next;
    
    // Clock period
    parameter time CLK_PERIOD = 10ns;
    
    // Round constants array for verification
    // i:    1    2    3    4    5    6    7    8    9    10
    // rcon: 01   02   04   08   10   20   40   80   1B   36
    logic [7:0] tb_rcon [0:10] = '{
        8'h01, 8'h02, 8'h04, 8'h08, 8'h10,
        8'h20, 8'h40, 8'h80, 8'h1B, 8'h36, 8'h6C
    };

    // Instantiate
    aes_key_scheduling dut (
        .key_in(key_in),
        .key_rcon_in(key_rcon_in),
        .key_next_out(key_next_out),
        .key_rcon_out(key_rcon_out)
    );
    
    // Clock gen
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test
    initial begin
        $display("Starting AES Key Scheduling Test");
        $display("==================================");
        
        key_rcon_in = 8'h01;  // Start with rcon = 0x01
        key_in = 128'h2b7e151628aed2a6abf7158809cf4f3c;  // AES test key
        
        $display("Initial Key: %h", key_in);
        $display("Initial Rcon: %h", key_rcon_in);
        $display("");
        
        #1ns;
        
        assert (key_rcon_in === tb_rcon[0]) 
            else begin
                $error("Initial Rcon mismatch. Expected: %h, Got: %h", tb_rcon[0], key_rcon_in);
                $fatal(1, "Initial setup failed");
            end

        
        // Run key expansion for 10 rounds (AES-128)
        for (int i = 0; i < 10; i++) begin
            $display("Round %2d:", i+1);
            $display("  Input Key:   %h", key_in);
            $display("  Input Rcon:  %h", key_rcon_in);

            #1ns;
            
            $display("  Output Key:  %h", key_next_out);
            $display("  Output Rcon: %h", key_rcon_out);
            
            // Verify round constant progression
            if (key_rcon_out !== tb_rcon[i+1]) begin
                $fatal(1, "Round %d: Rcon mismatch. Expected: %h, Got: %h", 
                       i+1, tb_rcon[i+1], key_rcon_out);
            end
            
            // Verify key changes
            if (key_next_out === key_in) begin
                $fatal(1, "Round %d: Output key same as input key", i+1);
            end
            
            // Verify rcon changes
            if (key_rcon_out === key_rcon_in) begin
                $fatal(1, "Round %d: Output rcon same as input rcon", i+1);
            end
            
            $display("  Round %d completed", i+1);
            $display("");
            
            // Update inputs for next iter
            key_rcon_in = key_rcon_out;
            key_in = key_next_out;
            
            #(CLK_PERIOD);
        end
        
        // Final results
        $display("All tests passed!");
        $finish;
    end
    
    // Timeout
    initial begin
        #1ms;
        $fatal(1, "Timeout - test did not complete");
    end
    
    // Monitor for unexpected X values
    always @* begin
        if ($isunknown(key_next_out)) begin
            $warning("Unknown values detected in key_next_out at time %t", $time);
        end
        if ($isunknown(key_rcon_out)) begin
            $warning("Unknown values detected in key_rcon_out at time %t", $time);
        end
    end

    // Waveform dump
    initial begin
        $dumpfile("waveforms/aes_key_scheduling.vcd");
        $dumpvars(0, tb_aes_key_scheduling);
    end

endmodule