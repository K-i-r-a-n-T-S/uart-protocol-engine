`timescale 1ns / 1ps

module baud_rate_gen #(
    parameter CLK_FREQ  = 100_000_000, // 100 MHz
    parameter BAUD_RATE = 115200       // 115.2 kbps
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,  // Only run the counter when Tx is active
    output reg  tick     // 1-clock-cycle pulse
);

    // Calculate maximum count value (e.g., 868 - 1 = 867)
    localparam MAX_COUNT = (CLK_FREQ / (BAUD_RATE * 16)) - 1;
    
    // 16-bit counter handles divisions up to 65,535 
    // (enough for a 100MHz clock down to 1525 baud)
    reg [15:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            tick    <= 1'b0;
        end else if (enable) begin
            if (counter == MAX_COUNT) begin
                counter <= 16'd0;
                tick    <= 1'b1;  // Generate the pulse
            end else begin
                counter <= counter + 16'd1;
                tick    <= 1'b0;
            end
        end else begin
            // Keep counter reset when not transmitting to ensure 
            // the first bit gets a full baud period
            counter <= 16'd0;
            tick    <= 1'b0;
        end
    end

endmodule