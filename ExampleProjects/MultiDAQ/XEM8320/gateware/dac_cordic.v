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

module cordic(
    input  wire        clk,
    input  wire        reset,

    input  wire        output_en,

    input  wire [31:0] freq,

    output reg  [15:0] data = 16'd0
);

// CORDIC
reg  [69:0]    delta = 70'd0;
reg  [31:0]    counter = 32'd0;
reg  [31:0]    freq_r = 32'd0;
reg  [31:0]    phase_r = 32'd0;
reg  [15:0]    cordic_out_shifted_up = 16'd0;

wire [15:0]    cordic_out;

// Max value for CORDIC input, 1 (3 FPN)
localparam     max_val          = 32'h40000000;
// Value to subtract counter by before passing into CORDIC
localparam     sub_val          = 32'hE0000000;
// Left bitshift quantity.
localparam     shift_factor     = 6'd37;

// CORDIC Module
cordic_0 cordic_0_inst(
    .aclk                (clk),
    .s_axis_phase_tdata  (counter + phase_r + sub_val), // Input stream, 32-bit width
    .s_axis_phase_tvalid (1'b1),                        // Input validity (always valid)
    .m_axis_dout_tdata   (cordic_out),                  // Output stream, 32-bits, 16-bit width
    .m_axis_dout_tvalid  ()                   // Output validity
);

always @(posedge clk) begin
    if (reset) begin
        delta                 <= 70'd0;

        counter               <= 32'd0;

        freq_r                <= 32'd0;

        cordic_out_shifted_up <= 16'd0;
    end else if (!output_en)
        data                  <= 16'd0;
    else begin

        data                  <= cordic_out_shifted_up;
        
        if (counter >= max_val - delta[65:34]) begin
            counter <= counter - max_val + delta[65:34];
        end else begin
            counter               <= counter + delta[65:34];
        end

        // Shift output up by 1 (2 FPN) from CORDIC to DAC
        cordic_out_shifted_up <= cordic_out + 16'h4000;
		
        // Update buffers
        freq_r                <= freq;
        delta                 <= freq_r << shift_factor;
    end
end

endmodule

`default_nettype wire