`timescale 1ns / 1ps
//------------------------------------------------------------------------
// bitslip_detect.v
//
// This module takes in the deserialized frame clock from the ADC and 
// determines how many bitslips are needed to align the data with the
// internally generated encode clock. Check the LTC2264-12 / LTC2268-14
// datasheet and associated timing diagrams for more details.
// Bitslip operations are explained in Xilinx XAPP1208.
//
//------------------------------------------------------------------------
// Copyright (c) 2021 Opal Kelly Incorporated
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


module bitslip_detect(
    input wire          clk_div,
    input wire [7:0]    data_in,
    input wire          ena,
    input wire          reset,
    output reg [3:0]    bitslip_count
    );
    
reg [7:0] stage_one, stage_two;
    
always @ (posedge clk_div or posedge reset) begin
    if (reset) begin
        stage_one <= 8'd0;
        stage_two <= 8'd0;
        bitslip_count <= 4'd0;
    end
    else if (ena) begin
        stage_one <= data_in;
        stage_two <= stage_one;
    
        case (stage_two)
            8'b00001111: bitslip_count <= 4'd0;
            8'b00011110: bitslip_count <= 4'd1;
            8'b00111100: bitslip_count <= 4'd2; 
            8'b01111000: bitslip_count <= 4'd3;
            8'b11110000: bitslip_count <= 4'd4; 
            8'b11100001: bitslip_count <= 4'd5;
            8'b11000011: bitslip_count <= 4'd6;  
            8'b10000111: bitslip_count <= 4'd7; 
            default: bitslip_count <= 4'd15;
        endcase
    end
end
endmodule
