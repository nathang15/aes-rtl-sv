`timescale 1ns/1ps

module aes_enc_tb;
    logic clk = 0;
    logic resetn;
    logic data_valid_in;
    logic [127:0] data_in;
    logic [127:0] key_in;
    logic [127:0] res_enc_out;
    logic res_valid_out;
    
    // Clock generation
    always #5 clk = ~clk;  // 100 MHz
    
    // DUT instantiation
    aes_enc_top dut (
        .clk(clk),
        .resetn(resetn),
        .data_valid_in(data_valid_in),
        .data_in(data_in),
        .key_in(key_in),
        .res_enc_out(res_enc_out),
        .res_valid_out(res_valid_out)
    );
    
    // Test variables
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // NIST test vectors (known good)
    logic [127:0] test_data[3] = '{
        128'h3243f6a8885a308d313198a2e0370734,
        128'h00000000000000000000000000000000,
        128'hffffffffffffffffffffffffffffffff
    };
    
    logic [127:0] test_keys[3] = '{
        128'h2b7e151628aed2a6abf7158809cf4f3c,
        128'h00000000000000000000000000000000,
        128'hffffffffffffffffffffffffffffffff
    };
    
    logic [127:0] expected_results[3] = '{
        128'h3925841d02dc09fbdc118597196a0b32,
        128'h66e94bd4ef8a2c3b884cfa59ca342b2e,
        128'ha1f6258c877d5fcd8969c964c583d057
    };
    
    // Test execution
    initial begin
        $display("=== AES Encryption Testbench (Windows) ===");
        $display("Time: %0t", $time);
        
        // Initialize
        resetn = 0;
        data_valid_in = 0;
        data_in = 0;
        key_in = 0;
        
        // Reset sequence
        repeat(10) @(posedge clk);
        resetn = 1;
        repeat(5) @(posedge clk);
        
        // Run NIST test vectors
        for (int i = 0; i < 3; i++) begin
            run_test_vector(i, test_data[i], test_keys[i], expected_results[i]);
        end
        
        // Final results
        $display("\n=== Test Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("✓ ALL TESTS PASSED!");
        end else begin
            $display("✗ SOME TESTS FAILED!");
        end
        
        $finish;
    end
    
    // Task to run individual test - FIXED for Questa compatibility
    task automatic run_test_vector(
        input int vector_num,
        input logic [127:0] data,
        input logic [127:0] key,
        input logic [127:0] expected
    );
        automatic logic [127:0] result;        // FIXED: Made explicit automatic
        automatic int timeout_count;           // FIXED: Made explicit automatic
        
        timeout_count = 0;  // Initialize here instead of in declaration
        
        $display("\n--- Test Vector %0d ---", vector_num);
        $display("Input:    0x%032h", data);
        $display("Key:      0x%032h", key);
        $display("Expected: 0x%032h", expected);
        
        // Apply inputs
        @(posedge clk);
        data_in = data;
        key_in = key;
        data_valid_in = 1;
        
        @(posedge clk);
        data_valid_in = 0;
        
        // Wait for result
        while (!res_valid_out && timeout_count < 1000) begin
            @(posedge clk);
            timeout_count++;
        end
        
        if (timeout_count >= 1000) begin
            $display("✗ TIMEOUT: No valid output received");
            fail_count++;
        end else begin
            result = res_enc_out;
            $display("Got:      0x%032h", result);
            $display("Cycles:   %0d", timeout_count + 1);
            
            if (result == expected) begin
                $display("✓ PASS");
                pass_count++;
            end else begin
                $display("✗ FAIL");
                fail_count++;
            end
        end
        
        test_count++;
        repeat(10) @(posedge clk);
    endtask
    
endmodule