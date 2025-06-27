`timescale 1ns / 1ps

module tb_inv_aes_key_scheduling;

    // Signals
    logic [127:0] key_i;
    logic [7:0] key_rcon_i;
    logic [127:0] key_next_o;
    logic [7:0] key_rcon_o;
    
    logic clk = 1'b0;
    parameter time CLK_PERIOD = 10ns;
    
    logic [7:0] key_rcon_next;
    logic [127:0] key_next;
    
    // Test bench signals
    logic [127:0] tb_rnd_1 = 128'hb1d4d8e28a7db9da1d7bb3de4c664941;
    
    // Rcon array
    logic [7:0] tb_rcon [0:9] = '{
        8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 
        8'h20, 8'h40, 8'h80, 8'h1b, 8'h36
    };

    // Instantiate
    inv_aes_key_scheduling uut (
        .key_in(key_i),
        .key_rcon_in(key_rcon_i),
        .key_next_out(key_next_o),
        .key_rcon_out(key_rcon_o)
    );

    // Clock gen
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $display("Starting AES Inverse Key Scheduling testbench");
        
        #(CLK_PERIOD/2);
        
        key_rcon_i = 8'h36;
        key_i = 128'h8e188f6fcf51e92311e2923ecb5befb4;
        
        $display("Initial key: %032h, rcon: %02h", key_i, key_rcon_i);
        
        #(CLK_PERIOD);
        
        for (int i = 0; i < 50; i++) begin
            key_rcon_next = key_rcon_o;
            key_next = key_next_o;
            
            $display("Round %2d: key = %032h, rcon = %02h -> %02h", 
                     i, key_next, key_rcon_i, key_rcon_next);
            
            #(CLK_PERIOD);
            
            key_rcon_i = key_rcon_next;
            key_i = key_next;
            
            if (key_rcon_next == 8'h00) begin
                $display("Reached original key (round 0)");
                break;
            end
        end
        
        $display("AES Inverse Key Scheduling test completed");
        $finish;
    end

endmodule