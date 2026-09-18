`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,    
    input  wire [7:0] tx_data,     
    output reg        tx_line,     
    output reg        tx_active,   
    output reg        tx_done,     
    input  wire       tick
);

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] current_state, next_state;
    reg [2:0] bit_index;           
    reg [7:0] shift_reg;           

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state; 
        
        case (current_state)
            IDLE:  if (tx_start) next_state = START;
            START: if (tick)     next_state = DATA;
            DATA:  if (tick && bit_index == 7) next_state = STOP;
            STOP:  if (tick)     next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_line   <= 1'b1; 
            tx_active <= 1'b0;
            tx_done   <= 1'b0;
            bit_index <= 3'd0;
            shift_reg <= 8'h00;
        end else begin
            tx_done <= 1'b0; 

            case (current_state)
                IDLE: begin
                    tx_line   <= 1'b1;
                    tx_active <= 1'b0;
                    bit_index <= 3'd0;
                    if (tx_start) begin
                        shift_reg <= tx_data; 
                    end
                end

                START: begin
                    tx_line   <= 1'b0; 
                    tx_active <= 1'b1;
                end

                DATA: begin
                    tx_line <= shift_reg[bit_index]; 
                    if (tick) begin 
                        bit_index <= bit_index + 1'b1; 
                    end
                end

                STOP: begin
                    tx_line   <= 1'b1; 
                    tx_active <= 1'b0;
                    if (tick) begin
                        tx_done <= 1'b1; // Pulse tx_done on baud completion
                    end
                end
            endcase
        end
    end

endmodule