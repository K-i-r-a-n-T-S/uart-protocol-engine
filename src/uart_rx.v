`timescale 1ns / 1ps

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_line,    // Serial input from Tx
    input  wire       tick_16x,   // Enable pulse running at 16x baud rate
    output reg  [7:0] rx_data,    // The fully received byte
    output reg        rx_done     // High for 1 tick when byte is ready
);

    // FSM States
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] tick_count;         // Counts 0 to 15 for oversampling
    reg [2:0] bit_index;          // Counts 0 to 7 for data bits
    reg [7:0] shift_reg;          // Internal shift register

    // --------------------------------------------------------
    // BLOCK 1: State Memory (Sequential)
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // --------------------------------------------------------
    // BLOCK 2: Next State Logic (Combinational)
    // --------------------------------------------------------
    always @(*) begin
        next_state = current_state; 
        
        case (current_state)
            IDLE: begin
                if (rx_line == 1'b0) // Falling edge of Start Bit detected
                    next_state = START;
            end
            
            START: begin
                if (tick_16x && tick_count == 4'd7) begin
                    if (rx_line == 1'b0) // Still low? It's a valid start bit.
                        next_state = DATA;
                    else                 // Glitch! Go back to IDLE.
                        next_state = IDLE; 
                end
            end
            
            DATA: begin
                // Wait 15 ticks to hit the middle of the next data bit
                if (tick_16x && tick_count == 4'd15) begin
                    if (bit_index == 3'd7)
                        next_state = STOP;
                end
            end
            
            STOP: begin
                if (tick_16x && tick_count == 4'd15)
                    next_state = IDLE;
            end
        endcase
    end

    // --------------------------------------------------------
    // BLOCK 3: Datapath & Output Logic (Sequential)
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_count <= 4'd0;
            bit_index  <= 3'd0;
            shift_reg  <= 8'h00;
            rx_data    <= 8'h00;
            rx_done    <= 1'b0;
        end else begin
            rx_done <= 1'b0; // Default pulse to 0

            case (current_state)
                IDLE: begin
                    tick_count <= 4'd0;
                    bit_index  <= 3'd0;
                end

                START: begin
                    if (tick_16x) begin
                        if (tick_count == 4'd7) begin
                            tick_count <= 4'd0; // Reset counter for the first data bit
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                DATA: begin
                    if (tick_16x) begin
                        if (tick_count == 4'd15) begin
                            tick_count <= 4'd0;
                            // UART sends LSB first. Shift right and append at MSB.
                            shift_reg  <= {rx_line, shift_reg[7:1]};
                            bit_index  <= bit_index + 1'b1;
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (tick_16x) begin
                        if (tick_count == 4'd15) begin
                            rx_done <= 1'b1;        // Signal that data is valid
                            rx_data <= shift_reg;   // Push internal shift_reg to output
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule