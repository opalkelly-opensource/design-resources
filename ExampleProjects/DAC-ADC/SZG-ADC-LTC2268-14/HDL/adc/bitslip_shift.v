`timescale 1ns / 1ps
//------------------------------------------------------------------------
// bitslip_shift.v
//
// This module takes in a bitslip amount count, and bitslips the data by 
// that amount. This is necessary to align the DDR output from the adc.
// For more information about bitslip operations, read XAPP1208 for 
// more information.
//
//------------------------------------------------------------------------
// Copyright (c) 2022 Opal Kelly Incorporated
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

module bitslip_shift(
    input wire          clk_div,
    input wire [7:0]    data_in,
    input wire          ena,
    input wire          reset,
    input wire [3:0]    bitslip_count,
    output reg [7:0]    data_out
    );
    
reg [7:0] stage_one, stage_two;

always @(posedge clk_div or posedge reset) begin
    if (reset) begin
        stage_one <= 8'd0;
        stage_two <= 8'd0;
        data_out <= 8'd0;
    end        
    else if (ena) begin
        stage_one <= data_in;
        stage_two <= stage_one;
        case (bitslip_count)
            4'd0: data_out <= stage_two;
            4'd1: data_out <= {stage_one[0],   stage_two[7:1]};
            4'd2: data_out <= {stage_one[1:0], stage_two[7:2]};
            4'd3: data_out <= {stage_one[2:0], stage_two[7:3]};
            4'd4: data_out <= {stage_one[3:0], stage_two[7:4]};
            4'd5: data_out <= {stage_one[4:0], stage_two[7:5]};
            4'd6: data_out <= {stage_one[5:0], stage_two[7:6]};
            4'd7: data_out <= {stage_one[6:0], stage_two[7]};
            default: data_out <= 8'hFF;
         endcase
    end
   
end
endmodule
