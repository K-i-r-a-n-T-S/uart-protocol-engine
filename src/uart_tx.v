`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,    // Trigger to start sending
    input  wire [7:0] tx_data,     // 8-bit data to send
    output reg        tx_line,     // Serial output wire
    output reg        tx_active,   // High when transmitting
    output reg        tx_done      // High for 1 tick when finished
);

    // FSM States
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] current_state, next_state;
    reg [2:0] bit_index;           // Counts from 0 to 7
    reg [7:0] shift_reg;           // Holds data being shifted out

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
        next_state = current_state; // Default stay in current state
        case (current_state)
            IDLE:  if (tx_start)  next_state = START;
            START: next_state = DATA;
            DATA:  if (bit_index == 7) next_state = STOP;
            STOP:  next_state = IDLE;
        endcase
    end

    // --------------------------------------------------------
    // BLOCK 3: Datapath & Output Logic (Sequential)
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_line   <= 1'b1; // Idle state for UART is HIGH
            tx_active <= 1'b0;
            tx_done   <= 1'b0;
            bit_index <= 3'd0;
            shift_reg <= 8'h00;
        end else begin
            // Default pulse to 0
            tx_done <= 1'b0; 

            case (current_state)
                IDLE: begin
                    tx_line   <= 1'b1;
                    tx_active <= 1'b0;
                    bit_index <= 3'd0;
                    if (tx_start) begin
                        shift_reg <= tx_data; // Capture data to send
                    end
                end

                START: begin
                    tx_line   <= 1'b0; // Pull line low for Start bit
                    tx_active <= 1'b1;
                end

                DATA: begin
                    tx_line   <= shift_reg[bit_index]; // Send LSB first
                    bit_index <= bit_index + 1;
                end

                STOP: begin
                    tx_line   <= 1'b1; // Drive high for Stop bit
                    tx_done   <= 1'b1; // Pulse done flag
                    tx_active <= 1'b0;
                end
            endcase
        end
    end

endmodule