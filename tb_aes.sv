`timescale 1ns / 1ps

module tb_aes();
    parameter CLK_PERIOD = 10;
    parameter TIMEOUT_CYCLES = 20;
    
    // DUT signals
    logic clk;
    logic resetn;
    logic data_valid_in;
    logic [127:0] data_in;
    logic [127:0] key_in;
    logic [127:0] res_enc_out;
    logic res_valid_out;
    
    // Test control signals
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    int cycle_count;
    
    // File handles
    integer fd_data_hex, fd_key_hex, fd_res_hex;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT instantiation
    aes dut (
        .clk(clk),
        .resetn(resetn),
        .data_valid_in(data_valid_in),
        .data_in(data_in),
        .key_in(key_in),
        .res_enc_out(res_enc_out),
        .res_valid_out(res_valid_out)
    );
    
    // Reset task
    task automatic reset_dut();
        @(posedge clk);
        resetn = 0;
        data_valid_in = 0;
        data_in = 128'h0;
        key_in = 128'h0;
        repeat(2) @(posedge clk);
        resetn = 1;
        @(posedge clk);
    endtask
    
    // Apply test and check result
    task automatic apply_and_check_test(
        input logic [127:0] plaintext,
        input logic [127:0] key,
        input logic [127:0] expected_ciphertext
    );
        
        cycle_count = 0;
        
        // Apply inputs
        @(posedge clk);
        data_valid_in = 1;
        data_in = plaintext;
        key_in = key;
        
        @(posedge clk);
        data_valid_in = 0;
        
        // Wait for result
        while (!res_valid_out && cycle_count < TIMEOUT_CYCLES) begin
            @(posedge clk);
            cycle_count++;
        end
        
        // Check result
        if (cycle_count >= TIMEOUT_CYCLES) begin
            $display("[FAIL] Test %0d: TIMEOUT after %0d cycles", test_count, TIMEOUT_CYCLES);
            fail_count++;
        end else if (res_enc_out === expected_ciphertext) begin
            $display("[PASS] Test %0d: Completed in %0d cycles", test_count, cycle_count + 2);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Output mismatch", test_count);
            $display("       Input:    %032h", plaintext);
            $display("       Key:      %032h", key);
            $display("       Expected: %032h", expected_ciphertext);
            $display("       Got:      %032h", res_enc_out);
            fail_count++;
        end
        
        @(posedge clk);
    endtask
    
    // Main test sequence
    initial begin
        logic [127:0] plaintext, key, expected_ciphertext;
        int scan_result;
        
        $display("\n=========================================");
        $display("AES-128 SystemVerilog Verification Test");
        $display("=========================================\n");
        
        // Open test vector files (hex format)
        fd_data_hex = $fopen("test_vec/aes_enc_data_i_hex.txt", "r");
        fd_key_hex = $fopen("test_vec/aes_enc_key_i_hex.txt", "r");
        fd_res_hex = $fopen("test_vec/aes_enc_res_o_hex.txt", "r");
        
        // Reset DUT
        reset_dut();
        $display("DUT reset complete\n");
        
        // Process all test vectors
        while (!$feof(fd_data_hex) && !$feof(fd_key_hex) && !$feof(fd_res_hex)) begin
            scan_result = $fscanf(fd_data_hex, "%h\n", plaintext);
            if (scan_result != 1) break;
            
            scan_result = $fscanf(fd_key_hex, "%h\n", key);
            if (scan_result != 1) break;
            
            scan_result = $fscanf(fd_res_hex, "%h\n", expected_ciphertext);
            if (scan_result != 1) break;
            
            test_count++;
            
            if (test_count <= 5) begin
                $display("Test %0d:", test_count);
                $display("  Plaintext: %032h", plaintext);
                $display("  Key:       %032h", key);
                $display("  Expected:  %032h", expected_ciphertext);
            end
            
            apply_and_check_test(plaintext, key, expected_ciphertext);
            
            // Progress indicator every 10 tests
            if (test_count % 10 == 0 && test_count > 5) begin
                $display("Progress: %0d tests completed...", test_count);
            end
        end
        
        $fclose(fd_data_hex);
        $fclose(fd_key_hex);
        $fclose(fd_res_hex);
        
        $display("\n=========================================");
        $display("Test Summary:");
        $display("  Total Tests: %0d", test_count);
        $display("  Passed:      %0d", pass_count);
        $display("  Failed:      %0d", fail_count);
        $display("  Success Rate: %.1f%%", 100.0 * pass_count / test_count);
        $display("=========================================");
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED! ***\n");
        end else begin
            $display("\n*** %0d TESTS FAILED! ***\n", fail_count);
        end
        
        $finish;
    end
    
    initial begin
        #(10ms);
        $display("\n[ERROR] Global timeout reached!");
        $finish;
    end
    
    initial begin
        if ($test$plusargs("WAVES")) begin
            $dumpfile("tb_aes.vcd");
            $dumpvars(0, tb_aes);
        end
    end

endmodule