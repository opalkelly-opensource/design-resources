//------------------------------------------------------------------------
// image_if.v
//
// We utilize the MIPI CSI-2 Receiver Subsystem IP core in a multi-subsystem design as 
// described in PG232. The objective is to reuse the limited PLLs of an IO bank, there is
// 1 MMCM + 2 PLLs per bank on Artix UltraScale+. The master configures the MIPI ip with "shared
// logic in core" and supplys clkoutphy_out and pll_lock_out to the slave cores. The slave cores
// configure the MIPI IP with "shared logic in example design" and take clkoutphy_in and pll_lock_in
// as inputs from the master.
//
// The image sensor interface (image_if.v) implements the write path. It 
// contains the PHY that communicates to the image sensor. It has a state 
// machine that observes the incoming image stream and places that data in 
// a PIX_CLK<-->MEM_CLK CDC FIFO. It will receive a start address from the 
// Image Buffer Coordinator (imgbuf_coordinator.v) and request to write a 
// full frame from the memory arbiter (mem_arbiter.v) starting at that address. 
// When the request is acknowledged the data from the FIFO is written to DDR memory. 
//
// trigger       - This is a trigger input initiates a capture.
// start_addr    - The start (byte) address for storing the next frame.
// frame_done    - Asserted at completion of a stored frame.
// frame_written - Asserted after a frame has been written to memory
//
// Copyright (c) 2004-2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns / 1ps
module image_if(
    // Image sensor interface
    input  wire          clk, 
    input  wire          reset,
    input  wire          reset_mipi,
    input  wire          ctrl_core_en,
    input  wire          dphy_clk_200M,

    // Camera MIPI interface
    input wire  [0:0]    mipi_phy_if_clk_p,
    input wire  [0:0]    mipi_phy_if_clk_n,
    input wire  [1:0]    mipi_phy_if_data_p,
    input wire  [1:0]    mipi_phy_if_data_n,
    
    input  wire          trigger,
    output reg           frame_done,
    output wire          line_valid,
    output reg           skipped,
    
    output reg  [7:0]    sync_error_count,
    
    //MIG Write Interface
    input  wire          mem_clk,
    input  wire          mem_reset,
    
    input  wire [29:0]   start_addr,
    output reg  [29:0]   saved_addr,
    output reg           frame_written,

    output reg           mem_wr_req,
    output reg  [28:0]   mem_wr_addr,
    input  wire          mem_wr_ack,
    
    output wire [8:0]    fifo_rd_data_count,
    input  wire          mem_wdata_rd_en,
    output wire [127:0]  mem_wdf_data,
    output wire          fifo_full,
    output wire          fifo_empty,
    
    // For MASTER MODE
    output wire          pll_lock_out,
    output wire          clkoutphy_out,
    // For SLAVE MODE
    input wire           clkoutphy_in,
    input wire           pll_lock_in
    );

parameter  CAMERA_INTERFACE  = 0;

localparam MASTER_CAMERA_1_INTERFACE = 0,
           SLAVE_CAMERA_2_INTERFACE  = 1,
           SLAVE_CAMERA_3_INTERFACE  = 2;
           
localparam BURST_LEN           = 6'd1;  // (WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_UI_WORD_COUNT : 16*8/128 = 1
localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 32


wire         fifo_wren;
reg          fifo_reset;
wire [31:0]  fifo_din;

reg  [19:0]  xfer_cnt_pixclk;
reg  [19:0]  xfer_cnt_memclk;

wire [39:0]  pix_data;
wire [ 9:0]  sync_word;
wire         sync_sof;
wire         sync_sol;
wire         sync_eol;
wire         sync_eof;
wire         sync_error;

reg          enable_pix;
reg          ready_mig;
reg          ready_mig_reg;
reg          ready_mig_reg1;

reg          frame_valid;
reg          regm_fv;
reg          regm_fv1;

reg  [28:0]  cmd_start_address;
wire         wr_rst_busy;
wire         rd_rst_busy;
reg  [3:0]   resetCount; 

integer      state;
localparam   s_idle             = 0,
             s_framewait        = 1,
             s_framestore       = 2;

assign fifo_din  = {pix_data[9:2], pix_data[19:12], pix_data[29:22], pix_data[39:32]};
assign fifo_wren = line_valid & ((state == s_framestore) || (((state == s_framewait) && (sync_sof == 1'b1))));

always @(posedge clk) begin
    if (reset) begin
        frame_done        <= 1'b0;
        enable_pix        <= 1'b0;
        skipped           <= 1'b0;
        state             <= s_idle;
        ready_mig_reg     <= 1'b0;
        ready_mig_reg1    <= 1'b0;
        sync_error_count  <= 32'h0;
        frame_valid       <= 1'b0;
    end else begin
        skipped           <= 1'b0;
        frame_done        <= 1'b0;
        ready_mig_reg     <= ready_mig;
        ready_mig_reg1    <= ready_mig_reg;
        
        if (sync_error == 1'b1) begin
            sync_error_count <= sync_error_count + 1'b1;
        end
        
        // Handshake with MIG Write Process
        
        case (state)
            s_idle: begin
                // Catch the trigger if it occurs and the MIG side of things
                // is not yet ready, we'll stay in idle to catch any skipped
                // frames as they come by. This is mostly precautionary.
                if (trigger) begin
                    enable_pix          = 1'b1;
                end

                xfer_cnt_pixclk        <= 17'h00;

                if (enable_pix && ready_mig_reg1) begin
                    enable_pix         <= 1'b0;
                    state              <= s_framewait;
                end
                
                // Signal a skipped frame if we see a frame valid come by
                // in the idle state.
                if (sync_sof == 1'b1) begin
                    skipped            <= 1'b1;
                end
            end
            
            // Once triggered, we wait here for the start of a frame.
            s_framewait: begin
                if (sync_sof == 1'b1) begin
                    state              <= s_framestore;
                    frame_valid        <= 1'b1;
                end
            end
            
            // Track frames captured
            s_framestore: begin
                if (fifo_wren == 1'b1) begin
                    xfer_cnt_pixclk    <= xfer_cnt_pixclk + 1'b1;
                end
                
                if (sync_eof == 1'b1) begin
                    frame_done         <= 1'b1;
                    frame_valid        <= 1'b0;
                    state              <= s_idle;
                end
            end
        endcase
    end
end

////////////////////////////////
// Pixel Buffer -> DDR
/////////////////////////////////
integer pixbuf_state;
localparam ps_idle   = 0,
           WaitReset = 1,
           ps_write1 = 10,
           ps_write2 = 11,
           ps_flush1 = 31,
           ps_flush2 = 32;

always @(posedge mem_clk or posedge mem_reset) begin
    if (mem_reset) begin
        pixbuf_state      <= WaitReset;
        mem_wr_req        <= 1'b0;
        mem_wr_addr       <= 29'h0;
        fifo_reset        <= 1'b1;
        cmd_start_address <= 29'h0;
        frame_written     <= 1'b0;
        ready_mig         <= 1'b0;

        regm_fv1          <= 1'b0;
        regm_fv           <= 1'b0;
        resetCount        <= 4'h0;
    end else begin
        mem_wr_req        <= 1'b0;
        cmd_start_address <= start_addr[28:0];
        fifo_reset        <= 1'b0;
        frame_written     <= 1'b0;
        ready_mig         <= 1'b0;
        regm_fv1          <= regm_fv;
        regm_fv           <= frame_valid;

        case (pixbuf_state)
            // To reset the independent clock fifo we must asset reset for
            // a recommended 3 clock cycles of the slowest clock.
            // rd_clk = mem_clk = 333MHz
            // wr_clk = clk = clk_pix = 100 MHz
            // At least 10 mem_clk cycles are required.
            // See PG057 for more information.
            WaitReset: begin
                if (resetCount < 4'd15) begin
                    fifo_reset         <= 1'b1;
                    resetCount         <= resetCount + 1'b1;
                end else begin
                    if(!wr_rst_busy && !rd_rst_busy) begin
                        pixbuf_state   <= ps_idle;
                    end
                end
            end
            ps_idle: begin
                ready_mig              <= 1'b1;
                xfer_cnt_memclk        <= 17'h00;
                if (regm_fv1 == 1'b1) begin
                    mem_wr_addr        <= cmd_start_address;
                    pixbuf_state       <= ps_write1;
                end
            end
            
            // Signal the memory controller to write bursts of image data to the memory
            // when enough data is built up in the FIFO.
            ps_write1: begin
                if (regm_fv1 == 1'b0 && fifo_empty) begin
                    pixbuf_state       <= ps_flush1;
                end
                
                if ((fifo_rd_data_count >= BURST_LEN) && (mem_wr_ack == 1'b0) ) begin
                    // DDR write request
                    pixbuf_state       <= ps_write2;
                    mem_wr_req         <= 1'b1;
                end
            end
            
            ps_write2: begin 
                if (mem_wr_ack == 1'b1) begin
                    mem_wr_addr        <= mem_wr_addr + ADDRESS_INCREMENT;
                    pixbuf_state       <= ps_write1;
                    xfer_cnt_memclk    <= xfer_cnt_memclk + 1'b1;
                end else begin
                    mem_wr_req         <= 1'b1;
                end
            end

            // At the end of a frame, force a burst write to memory to clear
            // out the MIG write FIFO. Note that this may corrupt some FIFOs
            // if they do not have protections enabled.
            ps_flush1: begin //31
                if (mem_wr_ack == 1'b0) begin
                    // DDR write request
                    pixbuf_state       <= ps_flush2;
                    mem_wr_req         <= 1'b1;
                end
            end
            
            ps_flush2: begin //32
                if (mem_wr_ack == 1'b1) begin
                    mem_wr_addr        <= mem_wr_addr + ADDRESS_INCREMENT;
                    pixbuf_state       <= WaitReset;
                    resetCount         <= 4'h0;
                    frame_written      <= 1'b1;
                    saved_addr         <= mem_wr_addr;
                end else begin
                    mem_wr_req         <= 1'b1;
                end
            end
        endcase
        
    end
end

// Pixel CLock to MIG Clock CDC
fifo_w32_2048_r128_512 pix_clk_to_mem_clk_fifo (
  .rst                  (fifo_reset),           // input wire rst
  .wr_clk               (clk),                  // input wire wr_clk
  .rd_clk               (mem_clk),              // input wire rd_clk
  .din                  (fifo_din),             // input wire [31 : 0] din
  .wr_en                (fifo_wren),            // input wire wr_en
  .rd_en                (mem_wdata_rd_en),      // input wire rd_en
  .dout                 (mem_wdf_data),         // output wire [127 : 0] dout
  .full                 (fifo_full),            // output wire full
  .empty                (fifo_empty),           // output wire empty
  .valid                (),                     // output wire valid
  .wr_data_count        (),                     // output wire [10 : 0] wr_data_count
  .rd_data_count        (fifo_rd_data_count),   // output wire [8 : 0] rd_data_count
  .wr_rst_busy          (wr_rst_busy),          // output wire wr_rst_busy
  .rd_rst_busy          (rd_rst_busy)           // output wire rd_rst_busy
);

generate 
    if (CAMERA_INTERFACE == MASTER_CAMERA_1_INTERFACE) begin
        mipi_phy #(
            .CAMERA_INTERFACE(CAMERA_INTERFACE)
        ) mipi_phy_master_i (
            .video_aclk         (clk),                  // input
            .reset              (reset_mipi),           // input
            .ctrl_core_en       (ctrl_core_en),         // input
            .dphy_clk_200M      (dphy_clk_200M),        // input

            .mipi_phy_if_clk_p  (mipi_phy_if_clk_p),    // input
            .mipi_phy_if_clk_n  (mipi_phy_if_clk_n),    // input
            .mipi_phy_if_data_p (mipi_phy_if_data_p),   // input  [1:0]
            .mipi_phy_if_data_n (mipi_phy_if_data_n),   // input  [1:0]

            .pix_data           (pix_data),             // output [39:0]
            .line_valid         (line_valid),           // output
            .sync_word          (sync_word),            // output [9:0]
            .sync_sof           (sync_sof),             // output
            .sync_sol           (sync_sol),             // output
            .sync_eol           (sync_eol),             // output
            .sync_eof           (sync_eof),             // output
            .sync_error         (sync_error),           // output
            // MASTER MODE
            .pll_lock_out       (pll_lock_out),         // output
            .clkoutphy_out      (clkoutphy_out),        // output
            .clkoutphy_in       (),                     // input wire clkoutphy_in
            .pll_lock_in        ()                      // input wire pll_lock_in
        );
    end else begin
        mipi_phy #(
            .CAMERA_INTERFACE(CAMERA_INTERFACE)
        ) mipi_phy_slave_i (
            .video_aclk         (clk),                  // input
            .reset              (reset_mipi),           // input
            .ctrl_core_en       (ctrl_core_en),         // input
            .dphy_clk_200M      (dphy_clk_200M),        // input

            .mipi_phy_if_clk_p  (mipi_phy_if_clk_p),    // input
            .mipi_phy_if_clk_n  (mipi_phy_if_clk_n),    // input
            .mipi_phy_if_data_p (mipi_phy_if_data_p),   // input  [1:0]
            .mipi_phy_if_data_n (mipi_phy_if_data_n),   // input  [1:0]

            .pix_data           (pix_data),             // output [39:0]
            .line_valid         (line_valid),           // output
            .sync_word          (sync_word),            // output [9:0]
            .sync_sof           (sync_sof),             // output
            .sync_sol           (sync_sol),             // output
            .sync_eol           (sync_eol),             // output
            .sync_eof           (sync_eof),             // output
            .sync_error         (sync_error),           // output
            // SLAVE MODE
            .pll_lock_out       (),                     // output
            .clkoutphy_out      (),                     // output
            .clkoutphy_in       (clkoutphy_in),         // input wire clkoutphy_in
            .pll_lock_in        (pll_lock_in)           // input wire pll_lock_in
        );
    end
endgenerate

endmodule
