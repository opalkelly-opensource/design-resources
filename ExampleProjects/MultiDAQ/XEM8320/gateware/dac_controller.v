//------------------------------------------------------------------------
// dac_controller.v
//
// A simple state machine that writes channel data to any channel that is
// active, when is encoded in the bits of data_rdy register. Active channels
// can be disjoint, unlike the ADC state machine.
//
//------------------------------------------------------------------------
// Copyright (c) 2024 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//------------------------------------------------------------------------
`default_nettype none
`timescale 1ns / 1ps
module dac_controller(
    input  wire rst,
    input wire locked,
    output reg cs_n = 1'b1,
    input  wire sclk_i,
    output wire sclk,
    output reg sdo = 1'b0,
    input  wire sdi,
    input wire [15:0] ch1_data,
    input wire [15:0] ch2_data,
    input wire [15:0] ch3_data,
    input wire [15:0] ch4_data,
    input wire [15:0] ch5_data,
    input wire [15:0] ch6_data,
    input wire [15:0] ch7_data,
    input wire [15:0] ch8_data,
    input wire [7:0] data_rdy

    );
    
assign sclk = sclk_i;

reg [7:0] send_counter = 8'd0;
reg [7:0] wait_counter = 8'd0;
reg [7:0] channel_queue = 8'd0;
reg [23:0] cmd = 24'd0;

reg done = 1'b0;

parameter   WR_CMD = 4'b0000,
            RD_CMD = 4'b0100;

parameter   CH1_ADDR = 4'd8,
            CH2_ADDR = 4'd9,
            CH3_ADDR = 4'd10,
            CH4_ADDR = 4'd11,
            CH5_ADDR = 4'd12,
            CH6_ADDR = 4'd13,
            CH7_ADDR = 4'd14,
            CH8_ADDR = 4'd15;

parameter   S_IDLE = 8'd0,
            S_TX_CMD = 8'd1,
            S_TX_W = 8'd2,
            S_TX = 8'd3;

reg [7:0] state = S_IDLE;

always @(posedge sclk_i) begin
    if (rst) begin
        state <= S_IDLE;
        cs_n <= 1'b1;
        sdo <= 1'b0;
        wait_counter <= 8'd1;
        cmd <= 24'd0;
    end else begin
        state <= state;
        cs_n <= 1'b1;
        sdo <= 1'b0;
        channel_queue <= channel_queue;
        send_counter <= send_counter;
        cmd <= cmd;
        case (state)
        S_IDLE: begin
            if (data_rdy && locked) begin
                state <= S_TX_CMD;
                channel_queue <= data_rdy; 
            end else begin
                state <= S_IDLE;
            end
        end
        S_TX_CMD: begin
            if (locked) begin
                state <= S_TX;
                send_counter <= 8'd24;
                casex (channel_queue)
                8'bxxxxxxx1: begin
                    cmd <= {WR_CMD, CH1_ADDR, ch1_data}; // prepare next channel data
                    channel_queue[0] <= 1'b0;
                end
                8'bxxxxxx10: begin
                    cmd <= {WR_CMD, CH2_ADDR, ch2_data};
                    channel_queue[1] <= 1'b0;
                end
                8'bxxxxx100: begin
                    cmd <= {WR_CMD, CH3_ADDR, ch3_data};
                    channel_queue[2] <= 1'b0;
                end
                8'bxxxx1000: begin
                    cmd <= {WR_CMD, CH4_ADDR, ch4_data};
                    channel_queue[3] <= 1'b0;
                end
                8'bxxx10000: begin
                    cmd <= {WR_CMD, CH5_ADDR, ch5_data};
                    channel_queue[4] <= 1'b0;
                end
                8'bxx100000: begin
                    cmd <= {WR_CMD, CH6_ADDR, ch6_data};
                    channel_queue[5] <= 1'b0;
                end
                8'bx1000000: begin
                    cmd <= {WR_CMD, CH7_ADDR, ch7_data};
                    channel_queue[6] <= 1'b0;
                end
                8'b10000000: begin
                    cmd <= {WR_CMD, CH8_ADDR, ch8_data};
                    channel_queue[7] <= 1'b0;
                end
                8'b00000000: begin
                    state <= S_TX_CMD;
                    channel_queue <= data_rdy; 
                end
                endcase
            end else begin
                state <= S_IDLE;
            end
        end
        S_TX_W: begin // wait state
            state <= S_TX_CMD;
        end
        S_TX: begin
            if (send_counter != 8'd0) begin
                cs_n <= 1'b0;
                sdo <= cmd[23];
                cmd <= {cmd[22:0], 1'b0}; // shift cmd out MSB first
                send_counter <= send_counter - 1'd1;
            end else begin
                state <= S_TX_W;
            end
        end
        endcase
    end
end
endmodule
`default_nettype wire
