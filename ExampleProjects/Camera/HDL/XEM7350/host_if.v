//------------------------------------------------------------------------
// host_if.v
//
// Interface for reading frames from DDR
//
// Copyright (c) 2011 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns / 1ps
module host_if(
	input  wire          clk,
	input  wire          clk_ti,
	input  wire          reset_clk,
	
	input  wire          readout_start,
	input  wire          readout_done,
	input  wire [29:0]   readout_addr,
	input  wire [23:0]   readout_count,
	
	// MIG Read Interface
	output reg           mem_rd_req,
	output reg   [28:0]  mem_rd_addr,
	input  wire          mem_rd_ack,
	
	input  wire [127:0]  mem_rd_data,
	input  wire          mem_rd_data_valid,
	input  wire          mem_rd_data_end,

	output wire  [8:0]   ob_count,
	
	// Host PipeOut FIFO Interface
	input  wire          ob_rd_en,
	output wire [10:0]   pofifo0_rd_count,  
	output wire [31:0]   pofifo0_dout,
	output wire          pofifo0_underflow,
	output wire          pofifo0_full,
	output wire          pofifo0_empty

	);


localparam BURST_LEN = 6'd1;  //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_LEN : 16*8/128 = 1
localparam BURST_LEN_BYTES = 8'd16;     // Number of bytes per command
localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 16


reg           ob_wr_en;
reg  [127:0]   ob_din;

reg  [23:0]   rd_byte_cnt;
reg           fifo_reset;



/////////////////////////////////
// DDR -> PipeOut Buffer
/////////////////////////////////
integer po_state;
localparam ps_idle  = 0,
           WaitReset = 1,
           ps_read1 = 10,
           ps_read2 = 11;
           
wire       wr_rst_busy;
wire       rd_rst_busy;
reg  [3:0] resetCount; 
always @(posedge clk or posedge reset_clk) begin
	if (reset_clk) begin
		po_state           <= WaitReset;
		mem_rd_req         <= 1'b0;
		rd_byte_cnt        <= 24'b0;
		ob_wr_en           <= 1'b0;
		ob_din             <= 128'h0;
		mem_rd_addr        <= 29'b0;
		fifo_reset         <= 1'b1;
		resetCount         <= 4'h0;
	end else begin
		ob_wr_en      <= mem_rd_data_valid;
		ob_din        <= mem_rd_data;
		fifo_reset    <= 1'b0;
		mem_rd_req    <= 1'b0;
		

		case (po_state)
            // To reset the independent clock fifo we must asset reset for
            // a recommended 3 clock cycles of the slowest clock.
            // rd_clk = clk_ti = 100.8 MHz
            // wr_clk = clk = memif_clk = 100 MHz
            // At least 4 clk_ti cycles are required.
            // See PG057 for more information.
            WaitReset: begin
                if (resetCount < 4'd4) begin
                    fifo_reset         <= 1'b1;
                    resetCount         <= resetCount + 1'b1;
                end else begin
                    if(!wr_rst_busy && !rd_rst_busy) begin
                        po_state       <= ps_idle;
                    end
                end
            end
			ps_idle: begin
				if (readout_start) begin
					mem_rd_addr        <= readout_addr[29:1];
					rd_byte_cnt        <= readout_count;
					po_state           <= ps_read1;
				end
			end

			ps_read1: begin
				// Only read from DDR when there is room in output buffer
				if ( ( (ob_count < 450 ) && (rd_byte_cnt>0)) && (mem_rd_ack == 1'b0) ) begin
					po_state          <= ps_read2;
					mem_rd_req        <= 1'b1;
				end
			end

			ps_read2: begin
				if (1'b1 == mem_rd_ack) begin
					rd_byte_cnt  <= rd_byte_cnt - BURST_LEN_BYTES;
					mem_rd_addr  <= mem_rd_addr + ADDRESS_INCREMENT;
					po_state     <= ps_read1;
					if( (ob_count < 450 ) && (rd_byte_cnt > 0)) begin
						po_state <= ps_read2;
						mem_rd_req <= 1'b1;
					end
				end else begin
					mem_rd_req        <= 1'b1;
				end
			end

		endcase
		
		if (readout_done) begin
			po_state    <= WaitReset;
            resetCount  <= 4'd0;
		end
	end
end

// Pipeout FIFO
fifo_w128_512_r32_2048 pofifo0 (
	.rst            (fifo_reset),
	.wr_clk         (clk),
	.wr_en          (ob_wr_en),
	.din            (ob_din),           // Bus [127 : 0] 
	.wr_data_count  (ob_count),         // Bus [8 : 0] 

	.rd_clk         (clk_ti),
	.rd_en          (ob_rd_en),
	.dout           ({pofifo0_dout[7:0], pofifo0_dout[15:8], pofifo0_dout[23:16], pofifo0_dout[31:24]}),     // Bus [31 : 0] 
	.rd_data_count  (pofifo0_rd_count), // Bus [10 : 0] 

	.full           (pofifo0_full),
	.empty          (pofifo0_empty),
	.underflow      (pofifo0_underflow),
	.valid          ()
	);
endmodule
