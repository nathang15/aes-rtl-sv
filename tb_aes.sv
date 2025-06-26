`timescale 1ns / 1ps

module tb_aes();

    // Clock and reset
    logic clk;
    logic resetn;
    
    // DUT signals
    logic data_valid_in;
    logic [127:0] data_in;
    logic [127:0] key_in;
    logic [127:0] res_enc_out;
    logic res_valid_out;
    
    typedef struct {
        logic [127:0] plaintext;
        logic [127:0] key;
        logic [127:0] expected_ciphertext;
        string description;
    } test_vector_t;
    
    test_vector_t test_vectors[] = '{
        '{
            plaintext: 128'h54776f204f6e65204e696e652054776f,
            key:       128'h5468617473206d79204b756e67204675,
            expected_ciphertext: 128'h29c3505f571420f6402299b31a02d73a,
            description: "Test 1"
        }
    };
    
    // Instantiate DUT
    aes dut (
        .clk(clk),
        .resetn(resetn),
        .data_valid_in(data_valid_in),
        .data_in(data_in),
        .key_in(key_in),
        .res_enc_out(res_enc_out),
        .res_valid_out(res_valid_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        resetn = 0;
        data_valid_in = 0;
        data_in = 0;
        key_in = 0;
        
        repeat(3) @(posedge clk);
        resetn = 1;
        repeat(2) @(posedge clk);
        
        foreach(test_vectors[i]) begin
            run_test_vector(test_vectors[i], i);
        end
        
        $display("\n=== AES TEST SUMMARY ===");
        $display("All tests completed!");
        $finish;
    end
    
    task run_test_vector(test_vector_t tv, int test_num);
        $display("\n=== Running Test %0d: %s ===", test_num, tv.description);
        $display("Plaintext: %032h", tv.plaintext);
        $display("Key:       %032h", tv.key);
        $display("Expected:  %032h", tv.expected_ciphertext);
        
        @(posedge clk);
        data_in = tv.plaintext;
        key_in = tv.key;
        data_valid_in = 1;
        
        @(posedge clk);
        data_valid_in = 0;
        
        wait(res_valid_out);
        @(posedge clk);
        
        $display("Actual:    %032h", res_enc_out);
        
        if (res_enc_out === tv.expected_ciphertext) begin
            $display("✓ PASS: Test %0d passed!", test_num);
        end else begin
            $display("✗ FAIL: Test %0d failed!", test_num);
            $display("  Expected: %032h", tv.expected_ciphertext);
            $display("  Got:      %032h", res_enc_out);
        end
        
        repeat(5) @(posedge clk);
    endtask
    
    initial begin
        $monitor("Time=%0t | State=%0d | Valid_out=%b | Result=%032h", 
                 $time, dut.fsm_q, res_valid_out, res_enc_out);
    end

endmodule