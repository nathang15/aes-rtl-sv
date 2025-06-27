module tb_aes_key_scheduling;
    // Inputs
    logic [127:0] key_i = 128'h0;
    logic [7:0] key_rcon_i = 8'h0;
    
    // Outputs
    logic [127:0] key_next_o;
    logic [7:0] key_rcon_o = 8'h0;
    
    logic clk;
    parameter time CLK_PERIOD = 10ns;
    
    logic [7:0] key_rcon_next;
    logic [127:0] key_next;

    logic [7:0] tb_rcon [0:9] = '{
        8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 
        8'h20, 8'h40, 8'h80, 8'h1B, 8'h36
    };

    aes_key_scheduling uut (
        .key_in(key_i),
        .key_rcon_in(key_rcon_i),
        .key_next_out(key_next_o),
        .key_rcon_out(key_rcon_o)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 1'b0;
        #(CLK_PERIOD/2);
        
        key_rcon_i = 8'b00000001;
        key_i = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        
        $display("Starting AES Key Scheduling Test");
        $display("Initial Key: %032h", key_i);
        $display("Initial RCON: %02h", key_rcon_i);
        
        #(CLK_PERIOD);
        
        for (int i = 0; i < 16; i++) begin
            key_rcon_next = key_rcon_o;
            key_next = key_next_o;
            
            $display("Round %2d: Key = %032h, RCON = %02h", i+1, key_next, key_rcon_next);
            
            #(CLK_PERIOD);
            
            key_rcon_i = key_rcon_next;
            key_i = key_next;
        end
        
        $display("AES Key Scheduling test completed");
        $finish;
    end

endmodule