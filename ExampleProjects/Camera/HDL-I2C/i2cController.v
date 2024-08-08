// I2CCONTROLLER
//
// This is a simple I2C Controller designed to work with the Micron
// MT9V403 CMOS image sensor's two-wire serial interface.  A command 
// sequence for the controller is written to a small 16-byte memory after
// which the START signal is asserted.  The controller performs the 
// command and asserts DONE for a single cycle upon completion.
//
// The command memory is setup as follows:
//   Address   Bits    Contents
//      0       7-4    Data transfer count (1 to 13).
//               0     1=read from I2C.  0=write to I2C.
//      1       7-1    Device address (B8 for the MT9V403).
//      2       7-0    Register address.
//      3       7-0    Data 0 (for writes)
//      4       7-0    Data 1
//     ...      ...    ...
//      F       7-0    Data 12
//
// When a read is performed, a second memory is filled with the contents
// read from the bus.
//
// The memory access ports write to the command memory and read from the
// result memory.  MEMSTART is used to reset a shared address pointer.
//
//    Example: Write to 16 bits Register 9 the value 644 (0x0284)
//       Command Memory - 0x30 0xB8 0x09 0x02 0x84
//
//    Example: Read 16 bits from Register 9 (result is 0x0282)
//       Command Memory - 0x31 0xB8 0x09
//        Result Memory - 0x02 0x82
//
// I2C rate = Clock Rate / 4 / (DIVCLK+1)
//------------------------------------------------------------------------
//    Slices: 113
// Slice FFs: 100
//    4-LUTs: 188
//     Speed: 142.005 MHz
//------------------------------------------------------------------------
// Copyright (c) 2005, Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none
module i2cController (
	input  wire       clk,
	input  wire       reset,
	input  wire       start,
	output reg        done,
	input  wire [7:0] divclk,
	
	input  wire       memclk,
	input  wire       memstart,
	input  wire       memwrite,
	input  wire       memread,
	input  wire [7:0] memdin,
	output wire [7:0] memdout,
	
	output reg        i2c_sclk,
	input  wire       i2c_sdat_in,
	output reg        i2c_sdat_out,
	output reg        i2c_drive
	);


reg  [7:0] divcount;
reg        divenable;
reg  [1:0] phase;


reg  [3:0] cmem_addr;
wire [7:0] cmem_dout;
reg        rmem_write;
reg  [3:0] rmem_addr;
wire [7:0] rmem_din;
reg  [3:0] mem_addr;

reg  [3:0] tcount;
reg        twrite;
reg  [6:0] dev_addr;
reg  [7:0] reg_addr;

reg  [1:0] tx_tok;
reg        tx_start;
reg        tx_done;
reg        tx_enable;
reg        tx_rack;
reg        tx_wack;
reg  [3:0] tx_count;
reg  [7:0] tx_word;
reg  [7:0] tx_shift;


// 16x8 dual-port distributed RAM for commands.  (8 slices)
okDRAM16X8D cmem (
		.wclk(memclk), .we(memwrite),
		.addrA(mem_addr), .din(memdin), .doutA(),
		.addrB(cmem_addr), .doutB(cmem_dout) );

// 16x8 dual-port distributed RAM for results.  (8 slices)
okDRAM16X8D rmem (
		.wclk(clk), .we(rmem_write),
		.addrA(rmem_addr), .din(rmem_din), .doutA(),
		.addrB(mem_addr), .doutB(memdout) );

// Address generation for the Pipe memory access.
always @(posedge memclk) begin
	if (memstart == 1'b1) begin
		mem_addr <= 4'b0000;
	end else begin
		if ((memwrite == 1'b1) || (memread == 1'b1)) begin
			mem_addr <= mem_addr + 1'b1;
		end
	end
end


assign rmem_din = tx_shift;


// I2C interface.
//
// This machine handles all communication with the I2C interface at an 
// atomic level consisting of tokens:
//    START
//    STOP
//    WRITE (8-bit write with ACK receive)
//    READ  (8-bit read with ACK transmit)
//
// The sensor's two-wire serial bus requires a certain minimum number
// of master clock cycles between transitions.  The divenable handles that.
//
// The serial interface requires data line transition while the clock line is
// asserted to indicate START or STOP bits.  We do this with PHASE signal 
// that toggles at four times the clock rate.  When PHASE=0, the clock line
// will not transition.  When PHASE=1, the clock line will transition.
parameter   tok_start = 2'b00,
            tok_stop = 2'b01,
            tok_write = 2'b10,
            tok_read = 2'b11;
always @(posedge clk) begin
	if (reset) begin
		divcount <= 8'd0;
		divenable <= 1'b0;
		phase <= 2'b00;
		i2c_sclk <= 1'b1;
		i2c_sdat_out <= 1'b1;
		i2c_drive <= 1'b1;
	end else begin
		divenable <= 1'b0;
		if (divcount == 8'd0) begin
			divcount <= divclk;
			divenable <= 1'b1;
		end else begin
			divcount <= divcount - 1'b1;
		end
	end
		
	if (tx_start) begin
		tx_enable <= 1'b1;
		tx_count <= 8;
		tx_shift <= tx_word;
	end

	tx_done <= 1'b0;
			
	// Word transfer happens outside the state machine to avoid having too
	// many states.
	if (divenable && tx_enable) begin
		phase <= phase + 1'b1;
		case (phase)
			2'b00: begin
				if (tx_tok == tok_start) begin
					i2c_sdat_out <= 1'b1;
					i2c_drive <= 1'b1;
				end else if (tx_tok == tok_stop) begin
					i2c_sdat_out <= 1'b0;
					i2c_drive <= 1'b1;
				end else	if (tx_tok == tok_write) begin
					i2c_sclk <= 1'b0;
					i2c_sdat_out <= tx_shift[7];
					i2c_drive <= 1'b1;
					tx_shift <= {tx_shift[6:0], 1'b0};
					if (tx_count == 0) begin
						i2c_drive <= 1'b0;
						i2c_sdat_out <= 1'b0;
					end
				end else if (tx_tok == tok_read) begin
					i2c_sclk <= 1'b0;
					i2c_drive <= 1'b0;
					if (tx_count == 0) begin
						i2c_drive <= 1'b1;
						i2c_sdat_out <= tx_rack;
					end
				end
			end
				
			2'b01: begin
				i2c_sclk <= 1'b1;
			end
				
			2'b10: begin
				i2c_sclk <= 1'b1;
				if (tx_tok == tok_start) begin
					i2c_sdat_out <= 1'b0;
				end else	if (tx_tok == tok_stop) begin
					i2c_sdat_out <= 1'b1;
				end else	if (tx_tok == tok_read) begin
					if (tx_count > 0) begin
						tx_shift <= {tx_shift[6:0], i2c_sdat_in};
					end
				end else if (tx_tok == tok_write) begin
					if (tx_count == 0) begin
						tx_wack <= i2c_sdat_in;
					end
				end
			end

			2'b11: begin
				if (tx_tok == tok_stop)
					i2c_sclk <= 1'b1;
				else
					i2c_sclk <= 1'b0;

				if ((tx_tok == tok_write) || (tx_tok == tok_read)) begin
					if (tx_count != 0) begin
						tx_count <= tx_count - 1'b1;
					end
				end
					
				if ((tx_tok == tok_start) ||
					 (tx_tok == tok_stop) ||
					 ((tx_tok == tok_write) && (tx_count == 0)) ||
					 ((tx_tok == tok_read) && (tx_count == 0)) ) begin
					tx_done <= 1'b1;
					tx_enable <= 1'b0;
				end
			end

		endcase
	end
end


// I2C controller state machine.
// 
parameter	s_idle = 0,
				s_start = 1,
				s_gettcount = 2,
				s_getdevaddr = 3,
				s_getregaddr = 4,
				sw_start = 100,
				sw_startwait = 101,
				sw_devaddr = 102,
				sw_devaddrwait = 103,
				sw_regaddr = 104,
				sw_regaddrwait = 105,
				sw_txdata = 106,
				sw_txdatawait = 107,
				sw_stop = 108,
				sw_stopwait = 109,
				sr_start1 = 200,
				sr_startwait1 = 201,
				sr_devaddr1 = 202,
				sr_devaddrwait1 = 203,
				sr_regaddr = 204,
				sr_regaddrwait = 205,
				sr_start2 = 206,
				sr_startwait2 = 207,
				sr_devaddr2 = 208,
				sr_devaddrwait2 = 209,
				sr_rxdata = 210,
				sr_rxdatawait = 211,
				sr_rxdatastore = 212,
				sr_stop = 213,
				sr_stopwait = 214;
integer state;
always @(posedge clk) begin
	if (reset) begin
		state <= s_idle;
		done <= 1'b0;
		cmem_addr <= 4'h0;
		rmem_addr <= 4'h0;
		rmem_write <= 1'b0;
		tx_start <= 1'b0;
		tx_tok <= tok_start;
		tcount <= 0;
		twrite <= 0;
	end else begin
		tx_start <= 1'b0;
		done <= 1'b0;
		rmem_write <= 1'b0;
		
		case (state)
			s_idle: begin
				cmem_addr <= 4'h0;
				rmem_addr <= 4'h0;
				state <= s_idle;
				if (start) begin
					state <= s_gettcount;
				end
			end
			
			s_gettcount: begin
				cmem_addr <= cmem_addr + 1'b1;
				tcount <= cmem_dout[7:4];
				twrite <= ~cmem_dout[0];
				state <= s_getdevaddr;
			end
			
			s_getdevaddr: begin
				cmem_addr <= cmem_addr + 1'b1;
				dev_addr <= cmem_dout[7:1];
				state <= s_getregaddr;
			end
			
			s_getregaddr: begin
				cmem_addr <= cmem_addr + 1'b1;
				reg_addr <= cmem_dout;
				if (twrite)
					state <= sw_start;
				else
					state <= sr_start1;
			end
			
			// WRITE sequence
			//
			// 1. START
			// 2. Device addr w/write bit. (ACK)
			// 3. Register #. (ACK)
			// 4. data transfer. (ACK)
			// 5. STOP
			sw_start: begin
				tx_tok <= tok_start;
				tx_start <= 1'b1;
				state <= sw_startwait;
			end
			
			sw_startwait: begin
				state <= sw_startwait;
				if (tx_done == 1'b1)
					state <= sw_devaddr;
			end

			sw_devaddr: begin
				tx_tok <= tok_write;
				tx_word <= {dev_addr, 1'b0};
				tx_start <= 1'b1;
				state <= sw_devaddrwait;
			end
			
			sw_devaddrwait: begin
				state <= sw_devaddrwait;
				if (tx_done == 1'b1)
					state <= sw_regaddr;
			end

			sw_regaddr: begin
				tx_tok <= tok_write;
				tx_word <= reg_addr;
				tx_start <= 1'b1;
				tcount <= tcount - 1'b1;
				state <= sw_regaddrwait;
			end
			
			sw_regaddrwait: begin
				state <= sw_regaddrwait;
				if (tx_done == 1'b1) begin
					state <= sw_txdata;
				end
			end
			
			sw_txdata: begin
				tx_tok <= tok_write;
				tx_word <= cmem_dout;
				tx_start <= 1'b1;
				cmem_addr <= cmem_addr + 1'b1;
				tcount <= tcount - 1'b1;
				state <= sw_txdatawait;
			end
			
			sw_txdatawait: begin
				state <= sw_txdatawait;
				if (tx_done == 1'b1) begin
					if (tcount == 0)
						state <= sw_stop;
					else
						state <= sw_txdata;
				end
			end

			sw_stop: begin
				state <= sw_stopwait;
				tx_tok <= tok_stop;
				tx_start <= 1'b1;
			end
			
			sw_stopwait: begin
				state <= sw_stopwait;
				if (tx_done == 1'b1) begin
					done <= 1'b1;
					state <= s_idle;
				end
			end
			
			// READ sequence
			//
			// Read sequence
			// 1. START
			// 2. Device addr w/write bit. (ACK)
			// 3. Register #. (ACK)
			// 4. START
			// 5. Device addr w/read bit. (ACK)
			// 7. Data READ. (ACK - NACK for last)
			// 8. STOP
			sr_start1: begin
				tx_tok <= tok_start;
				tx_start <= 1'b1;
				state <= sr_startwait1;
			end
			
			sr_startwait1: begin
				state <= sr_startwait1;
				if (tx_done == 1'b1)
					state <= sr_devaddr1;
			end

			sr_devaddr1: begin
				tx_tok <= tok_write;
				tx_word <= {dev_addr, 1'b0};
				tx_start <= 1'b1;
				state <= sr_devaddrwait1;
			end
			
			sr_devaddrwait1: begin
				state <= sr_devaddrwait1;
				if (tx_done == 1'b1)
					state <= sr_regaddr;
			end

			sr_regaddr: begin
				tx_tok <= tok_write;
				tx_word <= reg_addr;
				tx_start <= 1'b1;
				tcount <= tcount - 1'b1;
				state <= sr_regaddrwait;
			end
			
			sr_regaddrwait: begin
				state <= sr_regaddrwait;
				if (tx_done == 1'b1) begin
					state <= sr_start2;
				end
			end
			
			sr_start2: begin
				tx_tok <= tok_start;
				tx_start <= 1'b1;
				state <= sr_startwait2;
			end
			
			sr_startwait2: begin
				state <= sr_startwait2;
				if (tx_done == 1'b1)
					state <= sr_devaddr2;
			end

			sr_devaddr2: begin
				tx_tok <= tok_write;
				tx_word <= {dev_addr, 1'b1};
				tx_start <= 1'b1;
				state <= sr_devaddrwait2;
			end

			sr_devaddrwait2: begin
				state <= sr_devaddrwait2;
				if (tx_done == 1'b1)
					state <= sr_rxdata;
			end

			sr_rxdata: begin
				tx_tok <= tok_read;
				tx_start <= 1'b1;
				if (tcount == 1)
					tx_rack <= 1'b1;
				else
					tx_rack <= 1'b0;
				tcount <= tcount - 1'b1;
				state <= sr_rxdatawait;
			end

			sr_rxdatawait: begin
				state <= sr_rxdatawait;
				if (tx_done == 1'b1) begin
					rmem_write <= 1'b1;
					state <= sr_rxdatastore;
				end
			end
			
			sr_rxdatastore: begin
				rmem_addr <= rmem_addr + 1'b1;
				if (tcount == 0)
					state <= sr_stop;
				else
					state <= sr_rxdata;
			end

			sr_stop: begin
				state <= sr_stopwait;
				tx_tok <= tok_stop;
				tx_start <= 1'b1;
			end

			sr_stopwait: begin
				state <= sr_stopwait;
				if (tx_done == 1'b1) begin
					done <= 1'b1;
					state <= s_idle;
				end
			end

		endcase
	end
end


endmodule
