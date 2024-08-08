//------------------------------------------------------------------------
// host_if.v
//
// The host interface (host_if.v) implements the read path. Upon receiving 
// the start signal and read address pointer from the image buffer coordinator 
// (imgbuf_coordinator.v) the host interface will request to read a full frame 
// from the memory arbiter (mem_arbiter.v) starting at that address. When the 
// request is acknowledged the data read from DDR memory is placed in a 
// MEM_CLK <--> CLK_TI CDC FIFO.
//
// Copyright (c) 2004-2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns / 1ps
module host_if(
    input  wire          clk,
    input  wire          clk_ti,
    input  wire          reset_clk,
    
    input  wire          readout_start,
    input  wire          readout_done,
    input  wire [29:0]   readout_addr,
    input  wire [31:0]   readout_count, 
    
    // MIG Read Interface
    output reg           mem_rd_req,
    output reg  [28:0]   mem_rd_addr,
    input  wire          mem_rd_ack,
    
    input  wire [127:0]  mem_rd_data,
    input  wire          mem_rd_data_valid,
    input  wire          mem_rd_data_end,

    output wire [8:0]    ob_count,
    
    output reg  [9:0]    outstanding_write_count,
    
    // Host PipeOut FIFO Interface
    input  wire          ob_rd_en,
    output wire [10:0]   pofifo0_rd_count,  
    output wire [31:0]   pofifo0_dout,
    output wire          pofifo0_underflow,
    output wire          pofifo0_full,
    output wire          pofifo0_empty
);


localparam BURST_LEN         = 6'd1;  //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_LEN : 16*8/128 = 1
localparam BURST_LEN_BYTES   = 8'd16;     // Number of bytes per command
localparam ADDRESS_INCREMENT = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 32


reg            ob_wr_en;
reg  [255:0]   ob_din;

reg  [23:0]    rd_byte_cnt;
reg            fifo_reset;


always @(posedge clk) begin
    if (reset_clk) begin
        outstanding_write_count <= 10'h00;
    end else begin
        if (mem_rd_req == 1'b1 && mem_rd_ack == 1'b1) begin
            outstanding_write_count = outstanding_write_count + 1'b1;
        end
        
        if (mem_rd_data_valid == 1'b1) begin
            outstanding_write_count = outstanding_write_count - 1'b1;
        end
    end
end


/////////////////////////////////
// DDR -> PipeOut Buffer
/////////////////////////////////
reg [3:0] po_state;
localparam ps_idle  = 0,
           ps_read1 = 10,
           ps_read2 = 11;
           
always @(posedge clk or posedge reset_clk) begin
    if (reset_clk) begin
        po_state      <= ps_idle;
        mem_rd_req    <= 1'b0;
        rd_byte_cnt   <= 24'b0;
        ob_wr_en      <= 1'b0;
        ob_din        <= 128'h0;
        mem_rd_addr   <= 29'b0;
        fifo_reset    <= 1'b1;
    end else begin
        ob_wr_en      <= mem_rd_data_valid;
        ob_din        <= mem_rd_data;
        fifo_reset    <= 1'b0;
        mem_rd_req    <= 1'b0;

        case (po_state)
            ps_idle: begin
                fifo_reset              <= 1'b1;
                if (readout_start) begin
                    mem_rd_addr         <= readout_addr[28:0]; //changed this
                    rd_byte_cnt         <= readout_count;
                    po_state            <= ps_read1;
                end
            end

            ps_read1: begin
                // Only read from DDR when there is room in output buffer
                if ( ~wr_rst_busy ) begin
                    if ( ( (ob_count < 200 ) && (rd_byte_cnt>0)) && (mem_rd_ack == 1'b0) ) begin
                        po_state        <= ps_read2;
                        mem_rd_req      <= 1'b1;
                    end
                end
            end

            ps_read2: begin
                if (1'b1 == mem_rd_ack) begin
                    rd_byte_cnt         <= rd_byte_cnt - BURST_LEN_BYTES;
                    mem_rd_addr         <= mem_rd_addr + ADDRESS_INCREMENT;
                    po_state            <= ps_read1;
                    if( (ob_count < 200 ) && (rd_byte_cnt > 0)) begin
                        po_state        <= ps_read2;
                        mem_rd_req      <= 1'b1;
                    end
                end else begin
                    mem_rd_req          <= 1'b1;
                end
            end

        endcase
        
        if (readout_done) begin
            po_state                    <= ps_idle;
        end
    end
end

// Pipeout FIFO
fifo_w128_512_r32_2048 mem_clk_to_clk_ti_fifo (
    .rst            (fifo_reset),        // input
    .wr_clk         (clk),               // input
    .wr_en          (ob_wr_en),          // input
    .din            (ob_din),            // input  [127:0] 
    .wr_data_count  (ob_count),          // output [8:0] 

    .rd_clk         (clk_ti),            // input
    .rd_en          (ob_rd_en),          // input
    .dout           ({pofifo0_dout[7:0], pofifo0_dout[15:8], pofifo0_dout[23:16], pofifo0_dout[31:24]}), // output [31 : 0] 
    .rd_data_count  (pofifo0_rd_count),  // output [10:0] 

    .full           (pofifo0_full),      // output
    .empty          (pofifo0_empty),     // output
    .underflow      (pofifo0_underflow), // output
    .valid          (),                  // output
    .wr_rst_busy    (wr_rst_busy),       // output 
    .rd_rst_busy    (rd_rst_busy)        // output
    );
    
endmodule
