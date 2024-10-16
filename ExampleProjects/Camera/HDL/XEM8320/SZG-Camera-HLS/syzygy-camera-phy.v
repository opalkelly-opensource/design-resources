//------------------------------------------------------------------------
// syzygy-camera-phy.v
//
// Physical interface for HiSPi compatible cameras, including the AR0330
// sensor present on the SYZYGY Camera Pod. This module takes in the 
// serialized LVDS HiSPi interface signals from the camera and converts
// them to a parralel output with 10 bits per pixel. This module also
// performs the synchronization necessary to align the data and inform
// other modules of the start/end of lines/frames.
//
// To use this module, connect the cameras HiSPi interface to the slvs
// inputs and read the data out from this module. Pixel data is output on
// the pix_data wire as 4 10-bit pixels per clock cycle, synchronous to
// the 'clk' output signal. Pixel data is valid when the 'line_valid'
// signal is asserted. The sync_xxx signals can be used to align the data
// to lines and frames.
//
// The reset_sync output signal mirrors the reset_async input synchronized
// to the output clock signal.
//
// This module is only designed to work with sensors sending 10-bit data
// with a Packetized-SP HiSPi format.
//
// Due to the FPGA primitives used this module is only compatible with
// Xilinx 7-series devices.
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

`default_nettype none

module syzygy_camera_phy (
    output wire        clk, // derived from hispi clock
    input  wire        reset_async,
    output wire        reset_sync_out,

    // Camera HiSPi interface
    input  wire [3:0]  slvs_p,
    input  wire [3:0]  slvs_n,
    input  wire        slvsc_p,
    input  wire        slvsc_n,
    output wire        reset_b,

    // Deserialized outputs
    output wire [39:0] pix_data,   // 10 bits per pixel, 4 pixels at a time
    output wire        line_valid, // Pixel data is valid
    output reg  [9:0]  sync_word,  // useful for debug, view sync word 4
    output reg         sync_sof,
    output reg         sync_sol,
    output reg         sync_eol,
    output reg         sync_eof,
    output reg         sync_error, // Invalid sync word detected, error
    
    input  wire        idelay_rdy
);


wire        clk_out_int, clk_out_bufio, clk_out_div, clk_out_pix;

reg  [7:0]  reset_serdes_cnt;
reg         reset_sync;
// Internal camera data routing signals
wire [3:0]  slvs_p_buf, slvs_p_del;
wire [7:0]  camera_data[3:0]; // data from each lane
wire        iserdes_shift1[3:0];
wire        iserdes_shift2[3:0];

// Synchronization related signals
reg         sync_code_detect, sync_code_detect_reg;
reg  [3:0]  phase;
reg  [3:0]  phase_reg;
wire [39:0] camera_data_aligned [3:0]; // camera data after alignment
reg  [49:0] camera_data_reg_comb[3:0];
reg  [3:0]  pix_data_valid;

wire [7:0]  px_rd_curr [3:0];
wire [7:0]  px_rd_last [3:0];
reg  [9:0]  px_data    [3:0];

// Gearbox Reset, data, and control signals
reg  [3:0]  rx_reset_sync;
reg  [3:0]  px_reset_sync;
wire        rx_reset;
wire        px_reset;
reg  [4:0]  rx_wr_count;
reg  [4:0]  px_rd_count;
wire [4:0]  rx_wr_addr;
wire [4:0]  px_rd_addr1;
wire [4:0]  px_rd_addr2;
reg  [1:0]  px_rd_seq;
wire [7:0]  camera_data_reversed [3:0];

assign reset_sync_out = px_reset | reset_sync;
assign clk            = clk_out_pix;
assign reset_b        = ~reset_async;
assign line_valid     = (&pix_data_valid) & ~sync_code_detect_reg;

// Logic reset, must be held for at least two clock cycles to
// fully reset the ISERDES blocks
wire reset_sync_clk;
sync_reset sync_reset1 (.clk(clk), .async_reset(reset_async),    .sync_reset(reset_sync_clk));

always @(posedge clk) begin
    if (reset_sync_clk == 1'b1) begin
        reset_sync <= 1'b1;
        reset_serdes_cnt <= 8'h20;
    end else begin
        if (reset_serdes_cnt > 00) begin
            reset_serdes_cnt <= reset_serdes_cnt - 1'b1;
            reset_sync <= 1'b1;
        end else begin
            reset_sync <= 1'b0;
        end
    end
end

IBUFDS #(
    .IOSTANDARD ("LVDS"),
    .DIFF_TERM  ("TRUE")
) camera_dco (
    .I  (slvsc_p),
    .IB (slvsc_n),
    .O  (clk_out_int)
);

BUFIO camera_bufio (
    .I (clk_out_int),
    .O (clk_out_bufio)
);

BUFGCE_DIV #(
  .BUFGCE_DIVIDE(5),              // 1-8
  // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
  .IS_CE_INVERTED(1'b0),          // Optional inversion for CE
  .IS_CLR_INVERTED(1'b0),         // Optional inversion for CLR
  .IS_I_INVERTED(1'b0),           // Optional inversion for I
  .SIM_DEVICE("ULTRASCALE_PLUS")  // ULTRASCALE, ULTRASCALE_PLUS
)
BUFGCE_DIV_inst1 (
  .O(clk_out_pix),                // 1-bit output: Buffer
  .CE(1'b1),                      // 1-bit input: Buffer enable
  .CLR(reset_async),              // 1-bit input: Asynchronous clear
  .I(clk_out_int)                 // 1-bit input: Buffer
);

BUFGCE_DIV #(
  .BUFGCE_DIVIDE(4),              // 1-8
  // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
  .IS_CE_INVERTED(1'b0),          // Optional inversion for CE
  .IS_CLR_INVERTED(1'b0),         // Optional inversion for CLR
  .IS_I_INVERTED(1'b0),           // Optional inversion for I
  .SIM_DEVICE("ULTRASCALE_PLUS")  // ULTRASCALE, ULTRASCALE_PLUS
)
BUFGCE_DIV_inst2 (
  .O(clk_out_div),                // 1-bit output: Buffer
  .CE(1'b1),                      // 1-bit input: Buffer enable
  .CLR(reset_async),              // 1-bit input: Asynchronous clear
  .I(clk_out_int)                 // 1-bit input: Buffer
);

always @(*) begin: detect_sync_codes
    integer j;
    integer i;
    reg sync_code_found;

    sync_code_detect = 1'b0;
    phase = 5'h00;

    for (j=9; j >= 0; j=j-1) begin: find_phase
        sync_code_found = 1'b1;
        // check each phase j, if there are 20 zeros we've found the
        // sync word and correct phase
        for (i=0; i<20; i=i+1) begin: find_sync
            if (camera_data_reg_comb[0][j+i] == 1'b1) begin
                sync_code_found = 1'b0;
            end
        end
        
        if (sync_code_found == 1'b1) begin
            phase = j;
            sync_code_detect = 1'b1;
        end
    end
end

// Interpret sync codes
always @(posedge clk_out_pix) begin
    if (px_reset == 1'b1) begin
        sync_sof <= 1'b0;
        sync_sol <= 1'b0;
        sync_eof <= 1'b0;
        sync_eol <= 1'b0;
        sync_error <= 1'b0;
        phase_reg <= 5'h00;
        sync_code_detect_reg <= 1'b0;

        pix_data_valid <= 4'b000;
    end else begin
        sync_sof <= 1'b0;
        sync_sol <= 1'b0;
        sync_eof <= 1'b0;
        sync_eol <= 1'b0;
        sync_error <= 1'b0;

        pix_data_valid <= {pix_data_valid, pix_data_valid[0]};
        
        sync_code_detect_reg <= sync_code_detect;

        if (sync_code_detect == 1'b1) begin
            phase_reg <= phase;
        end
        
        if (sync_code_detect_reg == 1'b1) begin
            pix_data_valid[0] <= 1'b0;
            sync_word <= camera_data_aligned[0][9:0];
            case (camera_data_aligned[0][2:0])
                3'b011: begin
                    sync_sof <= 1'b1;
                    pix_data_valid[0] <= 1'b1;
                end
                3'b001: begin
                    sync_sol <= 1'b1;
                    pix_data_valid[0] <= 1'b1;
                end
                3'b111: begin
                    sync_eof <= 1'b1;
                    pix_data_valid[0] <= 1'b0;
                end
                3'b101: begin
                    sync_eol <= 1'b1;
                    pix_data_valid[0] <= 1'b0;
                end
                default: begin
                    sync_error <= 1'b1;
                    pix_data_valid[0] <= 1'b0;
                end
            endcase
        end
    end
end

// Gearbox synchronous reset logic to the corresponding clock domains: 
// We first reset the clk_out_div domain (and the write address counter) 
// first to allow the gearbox memory to queue enough memory to allow for 
// the px_rd_addr to increment by 2 without issue when the px_rd_seq is 3.

// Gearbox: Synchronize idelay_rdy to clk_out_div
always @ (posedge clk_out_div or negedge idelay_rdy)
begin
   if (!idelay_rdy)
       rx_reset_sync <= 4'b1111;
   else
       rx_reset_sync <= {1'b0,rx_reset_sync[3:1]};
end
assign rx_reset = rx_reset_sync[0];

// Gearbox: Synchronize rx_reset to px_clk
always @ (posedge clk_out_pix or posedge rx_reset)
begin
   if (rx_reset)
       px_reset_sync <= 4'b1111;
   else
       px_reset_sync <= {1'b0,px_reset_sync[3:1]};
end
assign px_reset = px_reset_sync[0];

// Gearbox: Write address counter
always @ (posedge clk_out_div)
begin
    if (rx_reset)
        rx_wr_count <= 5'h0;
    else
        rx_wr_count <= rx_wr_count + 1'b1;
end
assign rx_wr_addr   = rx_wr_count;

//  Gearbox: Read address counter
always @ (posedge clk_out_pix)
begin
    if (px_reset) begin
       px_rd_count <= 5'h0;
       end
    else if (px_rd_seq == 2'h3) begin
       // Increment counter by 2 when sequence is 3 because
       // all bits of px_rd_curr (px_rd_addr1) are read this 
       // clock cycle, so there are no bits of px_rd_curr that need 
       // to be captured in the next clock cycle's px_rd_last (px_rd_addr2). 
       px_rd_count <= px_rd_count + 2'h2;
    end else begin
       px_rd_count <= px_rd_count + 1'h1;
    end
end
assign px_rd_addr1 = px_rd_count;       
assign px_rd_addr2 = px_rd_count - 1'b1;
        
// Direct connections for each lane
generate
    genvar i;
    for (i=0; i<4; i=i+1) begin: camera_lane_deserial
        genvar j, k;
        for (j=0; j<4; j=j+1) begin
            for (k = 0; k < 10; k=k+1) begin
                assign camera_data_aligned[i][(10*j) + k] = camera_data_reg_comb[i][phase_reg + (10*j) + (9-k)];
            end
        end

        assign pix_data[(i*10)+9:i*10] = camera_data_aligned[i][39:30]; // pull pixel data from the end of the aligned data buffer

        always @(posedge clk_out_pix) begin
            if (px_reset == 1'b1) begin
                camera_data_reg_comb[i] <= 50'h3_ffff_ffff_ffff;
            end else begin
                camera_data_reg_comb[i] <= {camera_data_reg_comb[i], px_data[i]};
            end
        end


        IBUFDS #(
            .IOSTANDARD ("LVDS_25"),
            .DIFF_TERM  ("TRUE")
        ) camera_ibuf (
            .I  (slvs_p[i]),
            .IB (slvs_n[i]),
            .O  (slvs_p_buf[i])
        );
        
        IDELAYE3 #(
          .CASCADE("NONE"),               // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
          .DELAY_FORMAT("TIME"),          // Units of the DELAY_VALUE (COUNT, TIME)
          .DELAY_SRC("IDATAIN"),          // Delay input (DATAIN, IDATAIN)
          .DELAY_TYPE("FIXED"),           // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
          .DELAY_VALUE(525),              // Input delay value setting
          .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
          .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
          .REFCLK_FREQUENCY(300.0),       // IDELAYCTRL clock input frequency in MHz (200.0-800.0)
          .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
                                          // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
          .UPDATE_MODE("ASYNC")           // Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                          // SYNC)
        )
        camera_idelayp (
          .CASC_OUT(),                    // 1-bit output: Cascade delay output to ODELAY input cascade
          .CNTVALUEOUT(),                 // 9-bit output: Counter value output
          .DATAOUT(slvs_p_del[i]),        // 1-bit output: Delayed data output
          .CASC_IN(),                     // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
          .CASC_RETURN(),                 // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
          .CE(1'b0),                      // 1-bit input: Active-High enable increment/decrement input
          .CLK(1'b0),                     // 1-bit input: Clock input. Not necessary in FIXED mode.  
          .CNTVALUEIN(9'h00),             // 9-bit input: Counter value input
          .DATAIN(1'b0),                  // 1-bit input: Data input from the logic
          .EN_VTC(1'b1),                  // 1-bit input: Keep delay constant over VT
          .IDATAIN(slvs_p_buf[i]),        // 1-bit input: Data input from the IOBUF
          .INC(1'b0),                     // 1-bit input: Increment / Decrement tap delay input
          .LOAD(1'b0),                    // 1-bit input: Load DELAY_VALUE input
          .RST(reset_sync)                // 1-bit input: Asynchronous Reset to the DELAY_VALUE
        );
        
        ISERDESE3 #(
          .DATA_WIDTH(8),                 // Parallel data width (4,8)
          .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
          .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
          .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B. 1 = internal inversion
          .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
          .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
          .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
                                          // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
        )
        channel1_lane1_SERDES (
          .FIFO_EMPTY(),                  // 1-bit output: FIFO empty flag
          .INTERNAL_DIVCLK(),             // 1-bit output: Internally divided down clock used when FIFO is
                                          // disabled (do not connect)
          .Q(camera_data[i]),             // 8-bit registered output
          .CLK(clk_out_bufio),            // 1-bit input: High-speed clock
          .CLKDIV(clk_out_div),           // 1-bit input: Divided Clock
          .CLK_B(clk_out_bufio),          // 1-bit input: Inversion of High-speed clock CLK
          .D(slvs_p_del[i]),              // 1-bit input: Serial Data Input
          .FIFO_RD_CLK(),                 // 1-bit input: FIFO read clock
          .FIFO_RD_EN(),                  // 1-bit input: Enables reading the FIFO when asserted
          .RST(reset_sync)                // 1-bit input: Asynchronous Reset
        );
        
        assign camera_data_reversed[i] = {camera_data[i][0], camera_data[i][1],camera_data[i][2],camera_data[i][3],camera_data[i][4],camera_data[i][5],camera_data[i][6],camera_data[i][7]};
        
        // Gearbox 8:10 memory
        // We save two instances of the ISERDESE3 output because of the requirement to skip ahead 
        // the address pointer by 2 when the sequence is 3. This allows the  px_rd_curr and px_rd_last 
        // to be available on the same clock cycle. As a result of this requirement a simple 
        // "px_rd_last <= px_rd_curr" would not work here. 
        genvar m;
        genvar n;
        for (m = 0 ; m < 8 ; m = m+1) begin : bit1
          RAM32X1D fifo1 (
             .D     (camera_data_reversed[i][m]),
             .WCLK  (clk_out_div),
             .WE    (1'b1),
             .A4    (rx_wr_addr[4]),
             .A3    (rx_wr_addr[3]),
             .A2    (rx_wr_addr[2]),
             .A1    (rx_wr_addr[1]),
             .A0    (rx_wr_addr[0]),
             .SPO   (),
             .DPRA4 (px_rd_addr1[4]),
             .DPRA3 (px_rd_addr1[3]),
             .DPRA2 (px_rd_addr1[2]),
             .DPRA1 (px_rd_addr1[1]),
             .DPRA0 (px_rd_addr1[0]),
             .DPO   (px_rd_curr[i][m]));
        end
        
        for (n = 0 ; n < 8 ; n = n+1) begin : bit2
          RAM32X1D fifo2 (
             .D     (camera_data_reversed[i][n]),
             .WCLK  (clk_out_div),
             .WE    (1'b1),
             .A4    (rx_wr_addr[4]),
             .A3    (rx_wr_addr[3]),
             .A2    (rx_wr_addr[2]),
             .A1    (rx_wr_addr[1]),
             .A0    (rx_wr_addr[0]),
             .SPO   (),
             .DPRA4 (px_rd_addr2[4]),
             .DPRA3 (px_rd_addr2[3]),
             .DPRA2 (px_rd_addr2[2]),
             .DPRA1 (px_rd_addr2[1]),
             .DPRA0 (px_rd_addr2[0]),
             .DPO   (px_rd_last[i][n]));
        end     
        
        // Gearbox bit selection based on the sequence
        always @ (posedge clk_out_pix) begin
            if (px_reset) begin
               px_rd_seq <= 3'b0;
            end else  begin
               px_rd_seq <= px_rd_seq + 1'b1;
               case (px_rd_seq) 
                  3'h0 : begin 
                     px_data[i] <= {px_rd_last[i][7:0], px_rd_curr[i][7:6]};
                     end
                  3'h1 : begin 
                     px_data[i] <= {px_rd_last[i][5:0], px_rd_curr[i][7:4]};
                     end
                  3'h2 : begin 
                     px_data[i] <= {px_rd_last[i][3:0], px_rd_curr[i][7:2]};
                     end
                  3'h3 : begin 
                     px_data[i] <= {px_rd_last[i][1:0], px_rd_curr[i][7:0]};
                     end
                endcase
            end
        end
        
        
    end
endgenerate

endmodule
`default_nettype wire
