// ----------------------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
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
// ----------------------------------------------------------------------------------------

`default_nettype none

module btpipe2axi_video_stream(
    input wire          aclk,
    input wire          aresetn,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein10_transfers_in_line EP_DATAOUT" *)
    input  wire [31:0] wi10_ep_dataout_transfers_in_line,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein11_transfers_in_frame EP_DATAOUT" *)
    input  wire [31:0] wi11_ep_dataout_transfers_in_frame,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein12_frames_in_batch EP_DATAOUT" *)
    input  wire [31:0] wi12_ep_dataout_frames_in_batch,
    
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wireout:1.0 wireout30_frame_status EP_DATAIN" *)
    output wire [31:0] wo30_ep_datain_frame_status,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin40_video_control EP_TRIGGER" *)
    input  wire [31:0] ti40_ep_trigger_video_control,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin40_video_control EP_CLK" *)
    output wire        ti40_ep_clk_video_control,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin41_microblaze_domain EP_TRIGGER" *)
    input  wire [31:0] ti41_ep_trigger_microblaze_domain,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin41_microblaze_domain EP_CLK" *)
    output wire        ti41_ep_clk_microblaze_domain,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:btpipein:1.0 btpipein80_rgb_data EP_DATAOUT" *)
    input  wire [31:0] btpi80_ep_dataout_rgb_data,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:btpipein:1.0 btpipein80_rgb_data EP_WRITE" *)
    input  wire        btpi80_ep_write_rgb_data,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:btpipein:1.0 btpipein80_rgb_data EP_BLOCKSTROBE" *)
    input  wire        btpi80_ep_blockstrobe_rgb_data,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:btpipein:1.0 btpipein80_rgb_data EP_READY" *)
    output wire        btpi80_ep_ready_rgb_data,
    

    
    output wire [47:0] m_rgb_axis_tdata,
    output wire [5:0]  m_rgb_axis_tkeep,
    output wire        m_rgb_axis_tvalid,
    input  wire        m_rgb_axis_tready,
    output wire        m_rgb_axis_tuser,
    output wire        m_rgb_axis_tlast,
    
    // MicroBlaze interrupts
    input  wire                   microblaze_aclk,
    output wire                   fp2mb_int_change_batch_size,
    output wire [31:0]            fp2mb_batch_size
    );
    
    wire [14:0] data_count;
    wire fifo_generator_frontpanel_overflow;
    
    reg [31:0] count_transfers_in_line;
    reg [31:0] count_transfers_in_frame;
    reg [31:0] count_frames_in_batch;
    reg        frame_done;
    reg        frame_error;

    // State enumeration
    parameter IDLE = 2'b00;
    parameter FIRST_TRANSFER = 2'b01;
    parameter SECOND_TRANSFER = 2'b10;
    
    reg [31:0] buffer;
    
    reg [47:0] pixel_data_rgb;
    reg [0:0]  pixel_data_valid;
    reg [7:0] R1, R2, G1, G2, B1, B2;
    reg [47:0] pixel_data_gbr;

    reg [1:0] state = 0;
    reg [1:0] next_state = 0;

    wire fifo_generator_frontpanel_rd_en;
    wire fifo_generator_frontpanel_valid;
    wire [47:0] fifo_generator_frontpanel_dout;
    wire fifo_generator_frontpanel_empty;
    
    wire start_frame;
    
    assign btpi80_ep_ready_rgb_data = fifo_generator_frontpanel_empty;
    assign fifo_generator_frontpanel_rd_en = m_rgb_axis_tready;
    assign m_rgb_axis_tvalid = fifo_generator_frontpanel_valid;
    assign m_rgb_axis_tdata = fifo_generator_frontpanel_dout;
    
    assign ti40_ep_clk_video_control = aclk;
    assign start_frame = ti40_ep_trigger_video_control[0];
    
    assign ti41_ep_clk_microblaze_domain = microblaze_aclk;
    assign fp2mb_int_change_batch_size = ti41_ep_trigger_microblaze_domain[0];
    assign fp2mb_batch_size = wi12_ep_dataout_frames_in_batch;
    
    assign wo30_ep_datain_frame_status = {30'd0, frame_error, frame_done};
    
    assign m_rgb_axis_tkeep = 6'b111111;
    assign m_rgb_axis_tuser = (count_transfers_in_frame == 0) ? 1'b1 : 1'b0;
    assign m_rgb_axis_tlast = (count_transfers_in_line == wi10_ep_dataout_transfers_in_line - 1) ? 1'b1 : 1'b0;
    
    wire [7:0] btpi80_ep_dataout_rgb_data_green_0;
    wire [7:0] btpi80_ep_dataout_rgb_data_blue_0;
    wire [7:0] btpi80_ep_dataout_rgb_data_red_0;
    wire [7:0] btpi80_ep_dataout_rgb_data_green_1;
    
    
    // This logic pulls data from the BRAM and constructs an AMD AXI4-Stream Video. 
    // Refer to the Xilinx documentation: https://docs.xilinx.com/r/en-US/pg231-v-proc-ss/AXI4-Stream-Video
    // The logic inputs Start of frame on tuser and inputs End of Line on tlast.
    // Parameters that describe the stream, such as resolution and size, are brought in on WireIns.
    always @(posedge aclk) begin
        if (~aresetn) begin
            count_transfers_in_line <= 32'd0;
            count_transfers_in_frame <= 32'd0;
            count_frames_in_batch <= 32'd0;
            frame_done <= 32'd0;
            frame_error <= 32'd0;
        end else begin
            if (count_frames_in_batch == wi12_ep_dataout_frames_in_batch) begin
                frame_done <= 32'd1;
            end
            if (fifo_generator_frontpanel_overflow) begin
                frame_error <= 32'd1;
            end
            if (start_frame) begin
                count_transfers_in_line <= 32'd0;
                count_transfers_in_frame <= 32'd0;
                count_frames_in_batch <= 32'd0;
                frame_done <= 32'd0;
                frame_error <= 32'd0;
            end else if (m_rgb_axis_tvalid && m_rgb_axis_tready) begin
                count_transfers_in_line <= count_transfers_in_line + 32'd1;
                count_transfers_in_frame <= count_transfers_in_frame + 32'd1;
                if (count_transfers_in_line == wi10_ep_dataout_transfers_in_line - 1) begin
                    count_transfers_in_line <= 32'd0;
                end
                if (count_transfers_in_frame == wi11_ep_dataout_transfers_in_frame - 1) begin
                    count_transfers_in_frame <= 32'd0;
                    count_frames_in_batch <= count_frames_in_batch + 32'd1;
                end
            end
        end
    end
    
    
    // This logic implements a gearbox for handling data transformation:
    //  - Inputs: It accepts a 32-bit wide data stream every clock cycle.
    //  - Outputs: Produces a 48-bit wide data stream every 2/3 clock cycles.
    always @(posedge aclk) begin
        if (~aresetn) begin
            state <= IDLE;
            buffer <= 64'd0;
        end else begin
            pixel_data_valid <= 1'b0;
            if (btpi80_ep_write_rgb_data) begin
                case(state)
                    IDLE: begin
                        buffer[31:0]  <= btpi80_ep_dataout_rgb_data[31:0];
                        state <= FIRST_TRANSFER;
                    end
                    FIRST_TRANSFER: begin
                        pixel_data_rgb[47:0] <= {btpi80_ep_dataout_rgb_data[15:0], buffer[31:0]};
                        pixel_data_valid <= 1'b1;
                        buffer[31:0] <= {16'd0, btpi80_ep_dataout_rgb_data[31:16]};
                        state <= SECOND_TRANSFER;
                    end
                    SECOND_TRANSFER: begin
                        pixel_data_rgb[47:0] <= {btpi80_ep_dataout_rgb_data[31:0], buffer[15:0]};
                        pixel_data_valid <= 1'b1;
                        buffer[31:0] <= {16'd0, 16'd0};
                        state <= IDLE;
                    end
                endcase
            end
        end
    end
    

    // Software Application Buffer Byte Order:
    //  index 0 = Red,
    //  index 1 = Blue,
    //  index 2 = Green,
    //  ... repeated ...
    //
    // Byte Order with FrontPanel:
    //  - B2 (47:40), G2 (39:32), R2 (31:24), B1 (23:16), G1 (15:8), R1 (7:0).
    //   Reference: https://docs.opalkelly.com/fpsdk/frontpanel-api/ (See "Byte Order (USB 3.0)").
    //
    // AMD's RGB Order:
    //  R2 (47:40), B2 (39:32), G2 (31:24), R1 (23:16), B1 (15:8), G1 (7:0).
    //  Reference: https://docs.xilinx.com/r/en-US/pg231-v-proc-ss/AXI4-Stream-Video
    always @* begin
        B2 = pixel_data_rgb[47:40];
        G2 = pixel_data_rgb[39:32];
        R2 = pixel_data_rgb[31:24];
        B1 = pixel_data_rgb[23:16];
        G1 = pixel_data_rgb[15:8];
        R1 = pixel_data_rgb[7:0];
    
        pixel_data_gbr[47:40] = R2;
        pixel_data_gbr[39:32] = B2;
        pixel_data_gbr[31:24] = G2;
        pixel_data_gbr[23:16] = R1;
        pixel_data_gbr[15:8]  = B1;
        pixel_data_gbr[7:0]   = G1;
    end
    
    
    // FIFO Generator for AXI-Stream Backpressure Support:
    // This BRAM supports backpressure management using the BlockPipeIn endpoint type.
    // - Capacity: It has a 24KB capacity, the minimum step allowed by the FIFO Generator to cater to 
    //   all FrontPanel supported block sizes (max: 16KB).
    // - Data Flow: 
    //   1. BlockPipeIn sends data in entire block chunks, which can't be paused after the BlockPipeIn's blockstrobe
    //      signal acknowledges the ready signal.
    //   2. This BRAM has the capability to store an entire block.
    //   3. Once the AXI system consumes the block (i.e., the BRAM is empty), the empty flag signals
    //      BlockPipeIn's ready signal to send the next block.
    // - Backpressure Handling: The empty flag of the BRAM is directly connected to the BlockPipeIn's ready signal.
    //   This setup allows for some degree of backpressure management. However, the extent of backpressure
    //   handling is determined by the FrontPanel link's characteristics.
    // - For detailed characteristics and design considerations, refer to:
    //   "Flow Control and Protocol Design" and "Timeout" sections at:
    //   https://docs.opalkelly.com/fpsdk/system-design/
    fifo_generator_frontpanel fifo_generator_frontpanel_i (
      .clk(aclk),                                    // input wire clk
      .din(pixel_data_gbr),                          // input wire [47 : 0] din
      .wr_en(pixel_data_valid),                      // input wire wr_en
      
      .rd_en(fifo_generator_frontpanel_rd_en),       // input wire rd_en
      .valid(fifo_generator_frontpanel_valid),       // output wire valid
      .dout(fifo_generator_frontpanel_dout),         // output wire [47 : 0] dout
      
      .full(),                                       // output wire full
      .overflow(fifo_generator_frontpanel_overflow), // output wire overflow
      .empty(fifo_generator_frontpanel_empty),       // output wire empty
      .underflow()                                   // output wire underflow
    );
       
endmodule
`default_nettype wire
