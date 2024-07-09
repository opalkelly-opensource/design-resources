`timescale 1ns / 1ps
//------------------------------------------------------------------------
// syzygy-dac-phy.v
//
// Sends the IFFT output data repeatedly from a BRAM module. 
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

module syzygy_dac_data_reg(
    input wire clk,
    input wire locked,
    input wire reset,
    input wire wr_en,
    input wire [9:0] wr_addr,
    input wire data_en,
    input wire [11:0] data_i,
    
    output wire [11:0] data_o
    );
wire rsta_busy, rstb_busy;
wire [11:0] data_convert;
reg [9:0] bram_addr = 10'd0;
wire [9:0] addr;

assign addr = wr_en ? wr_addr : bram_addr;

// convert two's complement to unsigned, as the DAC expects unsigned data
assign data_o = data_convert[11] ?  {1'b0, data_convert[10:0]} : {1'b1, data_convert[10:0]};

always @(posedge clk) begin
    if (reset) begin
        bram_addr <= 10'd0;
    end else if (!rsta_busy) begin
        if (bram_addr != 10'd1023) begin
            bram_addr <= bram_addr + 1'b1; 
        end else begin
            bram_addr <= 10'd0;
        end
    end
end
    
blk_mem_gen_1 dac_bram (
  .clka(clk),            // input wire clka
  .ena({(wr_en | data_en) & !rsta_busy & locked}),              // input wire ena
  .wea(wr_en),              // input wire [0 : 0] wea
  .addra(addr),          // input wire [9 : 0] addra
  .dina(data_i),            // input wire [11 : 0] dina
  .douta(data_convert),       // output wire [11 : 0] doutb
  .rsta(reset),
  .rsta_busy(rsta_busy)
); 
    
endmodule

`default_nettype wire
