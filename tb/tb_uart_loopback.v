`timescale 1ns / 1ps

module tb_uart_loopback;

    // System Signals
    reg clk;
    reg rst_n;

    // Tick generators for simulation
    reg tick_tx;  // 1x Baud rate (for Tx)
    reg tick_rx;  // 16x Baud rate (for Rx)
    
    integer tx_counter;
    integer rx_counter;

    // Tx Inputs & Outputs
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_line;   // The physical "wire" connecting them
    wire       tx_done;

    // Rx Outputs
    wire [7:0] rx_data;
    wire       rx_done;

    // --------------------------------------------------------
    // Instantiate the Transmitter (Tx)
    // --------------------------------------------------------
    uart_tx my_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick_tx),     // 1x Baud tick
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_line(tx_line),  // Drives the wire
        .tx_active(),       // (Unconnected)
        .tx_done(tx_done)
    );

    // --------------------------------------------------------
    // Instantiate the Receiver (Rx)
    // --------------------------------------------------------
    uart_rx my_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_line(tx_line),  // Reads from the wire
        .tick_16x(tick_rx), // 16x Baud tick
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // --------------------------------------------------------
    // Clock & Tick Generation (100MHz System Clock)
    // --------------------------------------------------------
    always #5 clk = ~clk; // 10ns period = 100MHz

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_counter <= 0;
            rx_counter <= 0;
            tick_tx    <= 0;
            tick_rx    <= 0;
        end else begin
            // Generate Tx Tick (115200 baud -> every 868 clocks)
            if (tx_counter == 867) begin
                tx_counter <= 0;
                tick_tx    <= 1;
            end else begin
                tx_counter <= tx_counter + 1;
                tick_tx    <= 0;
            end

            // Generate Rx Tick (16x 115200 -> every 54 clocks)
            if (rx_counter == 53) begin
                rx_counter <= 0;
                tick_rx    <= 1;
            end else begin
                rx_counter <= rx_counter + 1;
                tick_rx    <= 0;
            end
        end
    end

    // --------------------------------------------------------
    // Main Test Sequence
    // --------------------------------------------------------
    initial begin
        $dumpfile("sim/tb_uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);

        // Initialize
        clk      = 0;
        rst_n    = 0;
        tx_start = 0;
        tx_data  = 8'h00;

        $display("\n===========================================");
        $display("   UART END-TO-END LOOPBACK SIMULATION");
        $display("===========================================\n");

        #100 rst_n = 1;
        #100;

        // --- TEST 1: Send 0x55 ---
        $display("[%0t] TX: Starting transmission of 8'h55", $time);
        
        @(posedge clk);
        tx_data  <= 8'h55;
        tx_start <= 1;
        
        @(posedge clk);
        tx_start <= 0; 

        // Wait for Rx to announce it received the data
        @(posedge rx_done);
        @(posedge clk); // Allow output assignment to settle
        
        if (rx_data == 8'h55)
            $display("[%0t] RX: SUCCESS! Received 8'h%h", $time, rx_data);
        else
            $display("[%0t] RX: ERROR! Expected 8'h55, Got 8'h%h", $time, rx_data);

        #5000; // Small delay between bytes

        // --- TEST 2: Send 0xC3 (11000011) ---
        $display("\n[%0t] TX: Starting transmission of 8'hC3", $time);
        
        @(posedge clk);
        tx_data  <= 8'hC3;
        tx_start <= 1;
        
        @(posedge clk);
        tx_start <= 0;

        @(posedge rx_done);
        @(posedge clk);
        
        if (rx_data == 8'hC3)
            $display("[%0t] RX: SUCCESS! Received 8'h%h", $time, rx_data);
        else
            $display("[%0t] RX: ERROR! Expected 8'hC3, Got 8'h%h", $time, rx_data);

        $display("\n===========================================");
        $display("               SIMULATION END");
        $display("===========================================\n");
        $finish;
    end

endmodule