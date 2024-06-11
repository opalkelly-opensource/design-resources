//------------------------------------------------------------------------
// adc_controller.sv
//
// A simple state machine that reads from the ADC on the SZG-MULTIDAQ.
// It reads 'channel_enable_count' channels from the ADC in sequential
// order. It then sends an AUTO_RST command to reset back to channel 0
// when all of the channels have been read. Includes a feature that 
// sends a one cycle trigger of the channel number when the data is valid.
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
module adc_controller(
    input  wire rst, 
    input  wire auto_rst,
    input wire locked,
    output reg cs_n,
    input  wire sclk_i,
    output wire sclk,
    output reg sdo,
    input  wire sdi,
    output wire adc_rst,
    input  wire [3:0] channel_enable_count,
    output wire [15:0] ch1_data,
    output wire [15:0] ch2_data,
    output wire [15:0] ch3_data,
    output wire [15:0] ch4_data,
    output wire [15:0] ch5_data,
    output wire [15:0] ch6_data,
    output wire [15:0] ch7_data,
    output wire [15:0] ch8_data,
    output reg [7:0] data_valid

    );

assign adc_rst = 1'b0;
assign sclk = cs_n ? 1'b1 : sclk_i; // sclk is active when cs_n is 0

reg [15:0] ch_data [7:0] = '{default: 16'd0};
assign ch1_data = ch_data[0];
assign ch2_data = ch_data[1];
assign ch3_data = ch_data[2];
assign ch4_data = ch_data[3];
assign ch5_data = ch_data[4];
assign ch6_data = ch_data[5];
assign ch7_data = ch_data[6];
assign ch8_data = ch_data[7];
reg [7:0] send_counter = 8'd0;
reg [7:0] wait_counter = 8'd0;
reg [7:0] receive_counter = 8'd0;
reg [3:0] ch_number = 4'd0;
reg [15:0] cmd = 16'd0;

parameter   AUTO_RST_CMD = 16'hA000;

parameter   S_IDLE = 8'd0,
            S_WAIT_FRAME = 8'd1, // wait for a complete frame
            S_RX_CH_W = 8'd2, // wait
            S_RX_CH = 8'd3,   // read ch n
            S_AUTO_RST = 8'd4, // send auto reset command (sample ch 1-8)
            S_WAIT_FRAME_W = 8'd5;

reg [7:0] state = S_IDLE;

always @(posedge sclk_i) begin
    if (rst) begin
        state <= S_IDLE;
        ch_number <= 4'd1;
        cs_n <= 1'b1;
        sdo <= 1'b0;
        ch_data <= '{default: 16'd0};
    end else begin
        state <= state;
        sdo <= 1'b0;
        cs_n <= 1'b1;
        data_valid <= 8'd0;
        ch_number <= ch_number;
        case (state)
        S_IDLE: begin
            if (auto_rst && locked) begin
                state <= S_AUTO_RST;
                cmd <= AUTO_RST_CMD;
                ch_number <= 4'd1;
                cs_n <= 1'b0;
                sdo <= cmd[15];
                send_counter <= 8'd15;
                cmd <= {cmd[14:0], 1'b0}; // shift cmd out MSB first
            end
        end
        S_AUTO_RST: begin
            ch_data <= '{default: 16'd0};
            cs_n <= 1'b0;
            ch_number <= 4'd1;
            sdo <= cmd[15];
            cmd <= {cmd[14:0], 1'b0}; // shift cmd out MSB first
            if (channel_enable_count > 8'd0) begin // stay here if no channels are enabled
                if (send_counter == 8'd0) begin
                    state <= S_WAIT_FRAME;
                    cmd <= AUTO_RST_CMD;
                    wait_counter <= 8'd15;
                end else begin
                    send_counter <= send_counter - 1'd1;
                end
            end
        end
        S_WAIT_FRAME: begin
            cs_n <= 1'b0;
            if (wait_counter == 8'd0) begin
                state <= S_WAIT_FRAME_W;
                wait_counter <= 8'd1;
            end else begin
                wait_counter <= wait_counter - 1'd1;
            end
        end
        S_WAIT_FRAME_W: begin // wait state for auto_reset
            if (wait_counter == 8'd0) begin
                state <= S_RX_CH;
                receive_counter <= 8'd31;
                cs_n <= 1'b0;
            end else begin
                wait_counter <= wait_counter - 1'b1;
            end
        end
        S_RX_CH_W: begin // wait state
            if (wait_counter == 8'd0) begin
                cs_n <= 1'b0;
                if (ch_number < channel_enable_count) begin // if our channel number is under the requested number of enabled channels
                    state <= S_RX_CH;                       // move to the next one
                    receive_counter <= 8'd31;
                    ch_number <= ch_number + 1'd1;
                end else begin
                    state <= S_AUTO_RST; // reset to channel 0
                    send_counter <= 8'd15;
                    sdo <= cmd[15];
                    cmd <= {cmd[14:0], 1'b0}; // shift cmd out MSB first
                end 
            end else begin
                wait_counter <= wait_counter - 1'b1;
            end
        end
        S_RX_CH: begin
            wait_counter <= 8'd1;
            cs_n <= 1'b0;
            receive_counter <= receive_counter - 1'b1;
            if (receive_counter == 8'd0) begin
                state <= S_RX_CH_W; // go to next channel
                data_valid <= ch_number;
            end else if (receive_counter <= 8'd16) begin
                ch_data[ch_number-1][0] <= sdi;
                ch_data[ch_number-1][15:1] <= ch_data[ch_number-1][14:0];
            end
        end
        endcase
    end
end

endmodule
`default_nettype wire
