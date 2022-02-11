// I2CCONTROLLER
//
// This is a simple I2C Controller designed to work on a single master 
// multiple slave I2C bus and support slave clock stretching.  A command 
// sequence for the controller is written to a small 64-byte memory after
// which the START signal is asserted.  The controller performs the 
// command and asserts DONE for a single cycle upon completion.
//
// The command memory is setup as follows:
//   Address   Bits    Contents
//      0       3:0    Preamble length (1..7) = P
//              7      1=read from I2C.  0=write to I2C.
//      1       7:0    Preamble STARTs
//      2       7:0    Preamble STOPs.
//      3       7:0    Payload Length = N
//      4       7:0    Preamble contents [P]
//      4+P     7:0    Payload contents [N]
//
// When a read is performed, a second memory is filled with the contents
// read from the bus.
//
// The memory access ports write to the command memory and read from the
// result memory.  MEMSTART is used to reset a shared address pointer.
//
//    Example: Write to 16 bits Register 9 the value 644 (0x0284)
//       Command Memory - 0x02 0x00 0x00 0x02 0xB8 0x09 0x02 0x84
//
//    Example: Read 16 bits from Register 9 (result is 0x0282)
//       Command Memory - 0x82 0x02 0x00 0x02 0xB8 0x09
//        Result Memory - 0x02 0x82
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
module i2cController(
	input  wire       clk,
	input  wire       reset,
	input  wire       start,
	output reg        done,
	
	input  wire       memclk,
	input  wire       memstart,
	input  wire       memwrite,
	input  wire       memread,
	input  wire [7:0] memdin,
	output wire [7:0] memdout,
	
	inout  wire       i2c_sclk,
	inout  wire       i2c_sdat
	);
	
	
parameter  CLOCK_STRETCH_SUPPORT  = 1;
parameter  CLOCK_DIVIDER          = 16'd32;


reg  [5:0] cmem_addr;
wire [7:0] cmem_dout;
reg        rmem_write;
reg  [5:0] rmem_addr;
reg  [5:0] mem_addr;

reg        twrite;

reg        tok_start;
reg        tok_stop;
reg        tok_write;
reg        tok_read;
wire       tok_done;
reg        tok_rack;
reg  [7:0] tok_datain;
wire [7:0] tok_dataout;

reg  [2:0] preamble_length;
reg  [2:0] preamble_count;
reg  [7:0] preamble_starts;
wire       preamble_start;
reg  [7:0] preamble_stops;
wire       preamble_stop;
reg  [6:0] payload_length;
reg  [6:0] payload_count;


// 64x8 dual-port distributed RAM for commands.
okDRAM64X8D cmem (
		.wclk(memclk), .we(memwrite),
		.addrA(mem_addr), .din(memdin), .doutA(),
		.addrB(cmem_addr), .doutB(cmem_dout) );

// 64x8 dual-port distributed RAM for results.
okDRAM64X8D rmem (
		.wclk(clk), .we(rmem_write),
		.addrA(rmem_addr), .din(tok_dataout), .doutA(),
		.addrB(mem_addr), .doutB(memdout) );

// Address generation for the Pipe memory access.
always @(posedge memclk) begin
	if (memstart == 1'b1) begin
		mem_addr <= 6'b000000;
	end else begin
		if ((memwrite == 1'b1) || (memread == 1'b1)) begin
			mem_addr <= mem_addr + 1'b1;
		end
	end
end



// Two inferred 8:1 MUXes to indicate whether a start or stop
// bit should occur after the present preamble byte.
mux_8to1 mux_starts (
	.sel       (preamble_count),
	.datain    (preamble_starts),
	.dataout   (preamble_start));
mux_8to1 mux_stops (
	.sel       (preamble_count),
	.datain    (preamble_stops),
	.dataout   (preamble_stop));
	

i2cTokenizer # (
		.CLOCK_STRETCH_SUPPORT  (CLOCK_STRETCH_SUPPORT),
		.CLOCK_DIVIDER          (CLOCK_DIVIDER)
	) tok (
		.clk           (clk),
		.reset         (reset),
		.tok_start     (tok_start),	
		.tok_stop      (tok_stop),
		.tok_write     (tok_write),
		.tok_read      (tok_read),
		.tok_done      (tok_done),
		.tok_datain    (tok_datain),
		.tok_dataout   (tok_dataout),
		.tok_rack      (tok_rack),
		.tok_wack      (),
		.i2c_sclk      (i2c_sclk),
		.i2c_sdat      (i2c_sdat)
	);



// I2C controller state machine.
parameter	s_idle = 0,
				
          s_get_preamble_length = 10,
          s_get_preamble_starts = 11,
          s_get_preamble_stops = 12,
          s_get_payload_length = 13,
				
          s_preamble_start = 20,
          s_preamble_startwait = 21,
          s_preamble_tx = 22,
          s_preamble_txwait = 23,
          s_preamble_startstopwait = 24,
          s_preamble_next = 25,
				
          s_payload = 30,
          s_payload_wait = 31,
          s_payload_stop = 32,
          s_payload_stopwait = 33;

integer state;
always @(posedge clk) begin
	if (reset) begin
		state <= s_idle;
		done <= 1'b0;
		cmem_addr <= 6'h0;
		rmem_addr <= 6'h0;
		rmem_write <= 1'b0;
		tok_start <= 1'b0;
		tok_stop  <= 1'b0;
		tok_write <= 1'b0;
		tok_read  <= 1'b0;
		twrite <= 0;
		tok_rack <= 1'b0;
		tok_datain <= 8'b0;
		payload_length  <= 7'd0;
		payload_count   <= 7'd0;
		preamble_length <= 3'd0;
		preamble_count  <= 3'd0;
		preamble_starts <= 8'h00;
		preamble_stops  <= 8'h00;
	end else begin
		tok_start  <= 1'b0;
		tok_stop   <= 1'b0;
		tok_write  <= 1'b0;
		tok_read   <= 1'b0;
		tok_rack   <= 1'b0;
		done       <= 1'b0;
		rmem_write <= 1'b0;
		
		case (state)
			s_idle: begin
				cmem_addr <= 6'h00;
				rmem_addr <= 6'h3f;
				if (start) begin
					state <= s_get_preamble_length;
				end
			end
			
			s_get_preamble_length: begin
				preamble_length <= cmem_dout[2:0];
				twrite          <= ~cmem_dout[7];
				cmem_addr       <= cmem_addr + 1'b1;
				state           <= s_get_preamble_starts;
			end
			
			s_get_preamble_starts: begin
				preamble_starts <= cmem_dout[7:0];
				cmem_addr       <= cmem_addr + 1'b1;
				state           <= s_get_preamble_stops;
			end
			
			s_get_preamble_stops: begin
				preamble_stops <= cmem_dout[7:0];
				cmem_addr      <= cmem_addr + 1'b1;
				state          <= s_get_payload_length;
			end
			
			s_get_payload_length: begin
				payload_length <= cmem_dout[6:0];
				payload_count  <= 7'd0;
				cmem_addr      <= cmem_addr + 1'b1;
				state          <= s_preamble_start;
			end
			
			
			//===================
			// Preamble Sequence
			//===================

			// Preamble always starts with a START TOKEN.
			s_preamble_start: begin
				preamble_count <= 3'd0;
				tok_start      <= 1'b1;
				state          <= s_preamble_startwait;
			end
			
			s_preamble_startwait: begin
				if (tok_done == 1'b1) begin
					state <= s_preamble_tx;
				end
			end
				
			// Send each byte of the preamble.
			s_preamble_tx: begin
				tok_write      <= 1'b1;
				tok_datain     <= cmem_dout[7:0];
				cmem_addr      <= cmem_addr + 1'b1;
				state          <= s_preamble_txwait;
			end

			// If requested, follow up each byte with a START or STOP TOKEN.
			s_preamble_txwait: begin
				if (tok_done == 1'b1) begin
					preamble_count <= preamble_count + 1'b1;
					state <= s_preamble_next;
					if (preamble_start == 1'b1) begin
						tok_start <= 1'b1;
						state <= s_preamble_startstopwait;
					end else if (preamble_stop == 1'b1) begin
						tok_stop <= 1'b1;
						state <= s_preamble_startstopwait;
					end
				end
			end

			s_preamble_startstopwait: begin
				if (tok_done == 1'b1) begin
					state <= s_preamble_next;
				end
			end
			
			// Loop until the preamble is complete.
			s_preamble_next: begin
				if (preamble_count == preamble_length) begin
					state <= s_payload;
				end else begin
					state <= s_preamble_tx;
				end
			end

			
			//==================
			// Payload Sequence
			//==================

			s_payload: begin
				payload_count <= payload_count + 1'b1;
				state <= s_payload_wait;
				if (twrite == 1'b1) begin
					tok_write    <= 1'b1;
					tok_datain   <= cmem_dout[7:0];
					cmem_addr    <= cmem_addr + 1'b1;
				end else begin
					tok_read <= 1'b1;
					
					// Send NACK on the last byte
					if (payload_count == payload_length - 1'b1) begin
						tok_rack <= 1'b1;
					end else begin
						tok_rack <= 1'b0;
					end
				end
			end

			s_payload_wait: begin
				if (tok_done == 1'b1) begin
					if (twrite == 1'b0) begin
						rmem_write <= 1'b1;
						rmem_addr <= rmem_addr + 1'b1;
					end
					
					if (payload_count == payload_length) begin
						state <= s_payload_stop;
					end else begin
						state <= s_payload;
					end
				end
			end
			
			s_payload_stop: begin
				tok_stop <= 1'b1;
				state    <= s_payload_stopwait;
			end
			
			s_payload_stopwait: begin
				if (tok_done == 1'b1) begin
					done  <= 1'b1;
					state <= s_idle;
				end
			end
			

		endcase
	end
end


endmodule
