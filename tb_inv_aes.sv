`timescale 1ns / 1ps

module tb_inv_aes;
    // Inputs
    logic data_valid_in = 1'b0;
    logic [127:0] data_in = 128'h0;
    logic [127:0] key_in = 128'h0;

    // Outputs
    logic res_valid_out;
    logic [127:0] res_dec_out;
    
    // Clock and reset
    logic clk = 1'b0;
    logic resetn = 1'b0;

    // Debug and testbench signals
    logic tb_res_dec_out_ored;
    logic tb_data_in_ored;
    logic tb_key_in_ored;
    
    // File handles for test vectors
    int tb_data_in_file;
    int tb_key_in_file;
    int tb_res_dec_out_file;

    parameter time CLK_PERIOD = 10ns;

    // Instantiate
    inv_aes uut (
        .clk(clk),
        .resetn(resetn),
        .data_valid_in(data_valid_in),
        .data_in(data_in),
        .key_in(key_in),
        .res_valid_out(res_valid_out),
        .res_dec_out(res_dec_out)
    );

    // Clock gen
    always #(CLK_PERIOD/2) clk = ~clk;

    assign tb_res_dec_out_ored = |res_dec_out;
    assign tb_data_in_ored = |data_in;
    assign tb_key_in_ored = |key_in;

    always @(posedge clk) begin
        #1;
        
        // Reset X check
        assert (resetn !== 1'bx) else begin
            $error("resetn is X");
            $finish;
        end
        
        // Input valid and data X check
        assert (!(data_valid_in === 1'bx && resetn === 1'b1)) else begin
            $error("input valid is X");
            $finish;
        end

        assert (!(data_valid_in === 1'b1 && tb_data_in_ored === 1'bx && 
                  tb_key_in_ored === 1'bx && resetn === 1'b1)) else begin
            $error("input data and key contain X on valid");
            $finish;
        end
    
        // Output valid signal should never be X, except during reset
        assert (!(res_valid_out === 1'bx && resetn === 1'b1)) else begin
            $error("output valid is X");
            $finish;
        end
        
        // Output data should never contain X's when output valid is 1, except during reset
        assert (!(res_valid_out === 1'b1 && tb_res_dec_out_ored === 1'bx && resetn === 1'b1)) else begin
            $error("output data contains X on valid");
            $finish;
        end
    end

    // Test vector check
    initial begin
        string tb_data_in_line;
        string tb_key_in_line;
        string tb_res_dec_out_line;
        logic [127:0] tb_data_in_line_vec;
        logic [127:0] tb_key_in_line_vec;
        logic [127:0] tb_res_dec_out_line_vec;

        tb_data_in_file = $fopen("test_vec/dec_in.txt", "r");
        tb_key_in_file = $fopen("test_vec/dec_key.txt", "r");
        tb_res_dec_out_file = $fopen("test_vec/dec_expected_out.txt", "r");
        
        if (tb_data_in_file == 0 || tb_key_in_file == 0 || tb_res_dec_out_file == 0) begin
            $error("Failed to open decryption test vector files");
            $finish;
        end
        
        // Reset sequence
        resetn = 1'b0;
        #16ns;
        resetn = 1'b1;
        
        // Process test vectors
        while (!$feof(tb_data_in_file) && !$feof(tb_key_in_file) && !$feof(tb_res_dec_out_file)) begin
            if ($fgets(tb_data_in_line, tb_data_in_file) == 0) break;
            if ($fgets(tb_key_in_line, tb_key_in_file) == 0) break;
            if ($fgets(tb_res_dec_out_line, tb_res_dec_out_file) == 0) break;

            tb_data_in_line_vec = tb_data_in_line.atohex();
            tb_key_in_line_vec = tb_key_in_line.atohex();
            tb_res_dec_out_line_vec = tb_res_dec_out_line.atohex();
            
            data_valid_in = 1'b1;
            data_in = tb_data_in_line_vec;
            key_in = tb_key_in_line_vec;
            
            @(posedge clk);
            
            data_valid_in = 1'b0;
            data_in = 128'hx;
            key_in = 128'hx;
            
            while (res_valid_out !== 1'b1) begin
                @(posedge clk);
            end
            
            assert (res_valid_out === 1'b1 && res_dec_out === tb_res_dec_out_line_vec) else begin
                $error("AES decrypted output does not match test vector");
                $error("Expected: %032h, Got: %032h", tb_res_dec_out_line_vec, res_dec_out);
                $finish;
            end
            
            $display("Decryption test vector passed: Input=%032h, Key=%032h, Output=%032h", 
                     tb_data_in_line_vec, tb_key_in_line_vec, res_dec_out);
            
            @(posedge clk);
        end
        
        $fclose(tb_data_in_file);
        $fclose(tb_key_in_file);
        $fclose(tb_res_dec_out_file);
        
        $display("All decryption test vectors passed successfully!");
        $finish;
    end

endmodule