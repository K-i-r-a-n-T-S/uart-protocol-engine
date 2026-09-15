`timescale 1ns / 1ps
//`include "C:/Users/MANOJ TM/Desktop/work/uart-protocol-engine/src/uart_tx.v"
module tb_uart_tx;

    // 1. Declare Testbench Signals
    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    
    wire       tx_line;
    wire       tx_active;
    wire       tx_done;

    // 2. Instantiate the Design Under Test (DUT)
    uart_tx dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_line(tx_line),
        .tx_active(tx_active),
        .tx_done(tx_done)
    );

    // 3. Clock Generation (100MHz = 10ns period)
    always #5 clk = ~clk;

    // 4. Reusable Task for sending a byte
    // This abstracts the timing so your main test block is clean.
    task send_byte(input [7:0] data);
        begin
            @(posedge clk);
            tx_data  = data;
            tx_start = 1'b1;
            
            @(posedge clk);
            tx_start = 1'b0; // De-assert start after 1 clock
            
            // Wait dynamically until the DUT says it's done
            @(posedge tx_done);
            $display("[%0t] Successfully transmitted byte: 8'h%h", $time, data);
            
            // Wait a few clocks before the next operation
            repeat(5) @(posedge clk); 
        end
    endtask

    // 5. Main Test Sequence
    initial begin
        // Setup GTKWave dump
        $dumpfile("sim/tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        // Initialize inputs
        clk      = 0;
        rst_n    = 0;
        tx_start = 0;
        tx_data  = 8'h00;

        // Apply Reset
        $display("[%0t] Asserting Reset...", $time);
        #20 rst_n = 1;
        $display("[%0t] Reset De-asserted. Starting tests...", $time);
        #10;

        // Test 1: Send 8'hA5 (Binary: 10100101)
        // Great for waveforms because the bits alternate
        send_byte(8'hA5);

        // Test 2: Send 8'h3C (Binary: 00111100)
        send_byte(8'h3C);

        $display("[%0t] All tests completed.", $time);
        $finish;
    end

endmodule