// I2CTOKENIZER
//
// This machine handles all communication with the I2C interface at an 
// atomic level consisting of tokens:
//    START
//    STOP
//    WRITE (8-bit write with ACK receive)
//    READ  (8-bit read with ACK transmit)
//
// 
//------------------------------------------------------------------------
// Copyright (c) 2005-2017 Opal Kelly Incorporated
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
module i2cTokenizer(
	input  wire       clk,
	input  wire       reset,
	input  wire       tok_start,
	input  wire       tok_stop,
	input  wire       tok_write,
	input  wire       tok_read,
	output reg        tok_done,
	
	input  wire [7:0] tok_datain,
	output wire [7:0] tok_dataout,
	input  wire       tok_rack,
	output reg        tok_wack,
	
	inout  wire       i2c_sclk,
	inout  wire       i2c_sdat
	);
	
parameter  CLOCK_STRETCH_SUPPORT  = 1;
parameter  CLOCK_DIVIDER          = 16'd32;

reg  [15:0] divcount;
reg         divenable;
reg         stretch_clk;

reg  [3:0]  i2c_shift_count;
reg  [7:0]  i2c_shift_reg;

reg         i2c_dout;
reg         i2c_sdat_oen;
reg         i2c_sclk_oen;
reg         i2c_sclk_oen_d;

reg         tok_start_go;
reg         tok_stop_go;
reg         tok_write_go;
reg         tok_read_go;

reg         tok_rack_r;

// I2C direction:
//   i2c_sdat_oen = 1 - READ mode (i2c_sdat is an input).
//   i2c_sdat_oen = 0 - WRITE mode (i2c_sdat is an output).
assign i2c_sdat = (i2c_sdat_oen) ? (1'bz) : (i2c_dout);
assign i2c_sclk = (i2c_sclk_oen) ? (1'bz) : (1'b0);


assign tok_dataout = i2c_shift_reg;


// The two-wire serial bus requires a certain minimum number
// of master clock cycles between transitions.  The divenable handles that.
//
            
integer state;
parameter s_idle   = 0,
          s_start0 = 10,
          s_start1 = 11,
          s_start2 = 12,
          s_start3 = 13,
          s_start4 = 14,
          s_write0 = 20,
          s_write1 = 21,
          s_write2 = 22,
          s_write3 = 23,
          s_read0  = 30,
          s_read1  = 31,
          s_read2  = 32,
          s_read3  = 33,
          s_stop0  = 40,
          s_stop1  = 41,
          s_stop2  = 42,
          s_stop3  = 43;
          
          
always @(posedge clk) begin
	if (reset) begin
		divcount         <= 16'h0000;
		divenable        <= 1'b0;
		state            <= s_idle;
		i2c_sclk_oen     <= 1'b1;
		i2c_dout         <= 1'b1;
		i2c_sdat_oen     <= 1'b1;
		i2c_shift_reg    <= 8'b0;
		i2c_shift_count  <= 4'b0;
		stretch_clk      <= 1'b0;
		tok_wack         <= 1'b0;
		tok_done         <= 1'b0;
		tok_start_go     <= 1'b0;
		tok_stop_go      <= 1'b0;
		tok_write_go     <= 1'b0;
		tok_read_go      <= 1'b0;
		tok_rack_r       <= 1'b0;
	end else begin
		
		// Support for slave clock stretching
		if (1 == CLOCK_STRETCH_SUPPORT) begin
			i2c_sclk_oen_d <= i2c_sclk_oen;
			stretch_clk <= (i2c_sclk_oen & ~i2c_sclk_oen_d & ~i2c_sclk) |
			               (stretch_clk & ~i2c_sclk);
		end
		
		// Clock divider
		divenable <= 1'b0;
		if (divcount == 16'h0000) begin
				divcount <= CLOCK_DIVIDER;
				divenable <= 1'b1;
		end else begin
			if(1'b0 == stretch_clk) begin
				divcount <= divcount - 1'b1;
			end else begin
				divcount <= CLOCK_DIVIDER;
			end
		end
		
	end


	// Reset our "go" signals when the machine completes.
	// Otherwise, capture the machine triggers so that we can initiate
	// the token on our divided clock.
	tok_done <= 1'b0;			
	if (tok_done == 1'b1) begin
		tok_start_go     <= 1'b0;
		tok_stop_go      <= 1'b0;
		tok_write_go     <= 1'b0;
		tok_read_go      <= 1'b0;
	end
	
	if (tok_start == 1'b1) begin
		tok_start_go <= 1'b1;
	end
	if (tok_stop == 1'b1) begin
		tok_stop_go <= 1'b1;
	end
	if (tok_write == 1'b1) begin
		tok_write_go <= 1'b1;
		i2c_shift_count <= 8;
		i2c_shift_reg <= tok_datain;
	end
	if (tok_read == 1'b1) begin
		tok_read_go <= 1'b1;
		i2c_shift_count <= 8;
		i2c_shift_reg <= 8'h00;
		tok_rack_r <= tok_rack;
	end

	// I2C bit control
	if (divenable) begin
		
		case (state)
			s_idle: begin
				if (tok_start_go == 1'b1) begin
					i2c_dout <= 1'b0;
					state <= s_start0;
				end else if (tok_stop_go == 1'b1) begin
					i2c_dout <= 1'b0;
					state <= s_stop0;
				end else if (tok_write_go == 1'b1) begin
					state <= s_write0;
				end else if (tok_read_go == 1'b1) begin
					state <= s_read0;
				end
			end
			
			//-------------
			// START TOKEN
			//-------------
			s_start0: begin
				i2c_sdat_oen <= 1'b1;
				state <= s_start1;
			end
			
			s_start1: begin
				i2c_sdat_oen <= 1'b1;
				i2c_sclk_oen <= 1'b1;
				state <= s_start2;
			end
			
			s_start2: begin
				i2c_sdat_oen <= 1'b0;
				i2c_sclk_oen <= 1'b1;
				state <= s_start3;
			end
			
			s_start3: begin
				state <= s_start4;
			end
			
			s_start4: begin
				i2c_sclk_oen <= 1'b0;
				tok_done <= 1'b1;
				state <= s_idle;
			end
			
			
			//-------------
			// WRITE TOKEN
			//-------------
			s_write0: begin
				i2c_sclk_oen <= 1'b0;
				i2c_dout <= i2c_shift_reg[7];
				i2c_shift_reg <= {i2c_shift_reg[6:0], 1'b0};
				if (0 == i2c_shift_count) begin
					//Release sdat to read ACK from slave device
					i2c_sdat_oen <= 1'b1;
				end else begin
					i2c_sdat_oen <= 1'b0;
				end
				state <= s_write1;
			end
			
			s_write1: begin
				i2c_sclk_oen <= 1'b1;
				if (0 == i2c_shift_count) begin
					tok_wack <= i2c_sdat;
				end
				state <= s_write2;
			end
			
			s_write2: begin
				state <= s_write3;
			end
			
			s_write3: begin
				i2c_sclk_oen <= 1'b0;
				i2c_sdat_oen <= 1'b0;
				if (i2c_shift_count > 0) begin
					i2c_shift_count <= i2c_shift_count - 1'b1;
					state <= s_write0;
				end else begin
					tok_done <= 1'b1;
					state <= s_idle;
				end
			end
			
			//------------
			// READ TOKEN
			//------------
			s_read0: begin
				i2c_sclk_oen <= 1'b0;
				if (0 == i2c_shift_count) begin
					//Drive sdat to send ACK to slave device
					i2c_sdat_oen <= 1'b0;
					i2c_dout <= tok_rack_r;
				end else begin
					i2c_sdat_oen <= 1'b1;
				end
				state <= s_read1;
			end
			
			s_read1: begin
				i2c_sclk_oen <= 1'b1;
				state <= s_read2;
			end
			
			s_read2: begin
				if (i2c_shift_count > 0) begin
					i2c_shift_reg <= {i2c_shift_reg[6:0], i2c_sdat};
				end
				state <= s_read3;
			end
			
			s_read3: begin
				i2c_sclk_oen <= 1'b0;
				if (i2c_shift_count > 0) begin
					i2c_shift_count <= i2c_shift_count - 1'b1;
					state <= s_read0;
				end else begin
					tok_done <= 1'b1;
					state <= s_idle;
				end
			end
			
			//------------
			// STOP TOKEN
			//------------
			s_stop0: begin
				i2c_sdat_oen <= 1'b0;
				i2c_sclk_oen <= 1'b0;
				state <= s_stop1;
			end
			
			s_stop1: begin
				i2c_sclk_oen <= 1'b1;
				state <= s_stop2;
			end
			
			s_stop2: begin
				state <= s_stop3;
			end
			
			s_stop3: begin
				i2c_sdat_oen <= 1'b1;
				tok_done <= 1'b1;
				state <= s_idle;
			end
			
		endcase
		
	end
end


endmodule
`default_nettype wire
