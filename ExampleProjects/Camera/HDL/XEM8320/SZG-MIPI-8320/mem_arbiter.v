//------------------------------------------------------------------------
// mem_arbiter.v
//
// Memory arbiter for the XEM8320. Handles coordination of reads and writes to 
// the MIG user interface.
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.

// Copyright (c) 2004-2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns/1ps

module mem_arbiter (
    // Clocks
    input  wire                                clk,
    input  wire                                reset,
    input  wire                                calib_done,
    
    // MIG Command Interface
    input  wire                                app_rdy,
    output reg                                 app_en,
    output reg  [2:0]                          app_cmd,
    output reg  [28:0]                         app_addr,
    
    // MIG Write Interface
    input wire                                 app_wdf_rdy,
    output reg                                 app_wdf_wren,
    output reg                                 app_wdf_end,
    output wire [15:0]                         app_wdf_mask,
    
    output reg                                 wdata_rd_en,
    
    input wire  [8:0]                          wr_fifo_count,
    input wire  [8:0]                          rd_fifo_count,
    
    // Arbiter requests and acknowledgements
    input  wire                                wr_req,
    output reg                                 wr_ack,
    input  wire [28:0]                         wr_addr,
    input  wire                                rd_req,
    output reg                                 rd_ack,
    input  wire [28:0]                         rd_addr
    );

    assign app_wdf_mask = 16'h0000;
    
    (* KEEP = "TRUE" *)integer state;
    localparam s_idle          = 0,
               s_calib_wait    = 1,
               s_write_0       = 10,
               s_write_1       = 11,
               s_read_0        = 20;

    always @(posedge clk) begin
        if (reset) begin
            state             <= s_idle;
            app_en            <= 1'b0;
            app_cmd           <= 3'b0;
            app_addr          <= 29'b0;
            wr_ack            <= 1'b0;
            rd_ack            <= 1'b0;
            wdata_rd_en       <= 1'b0;
            app_wdf_wren      <= 1'b0;
            app_wdf_end       <= 1'b0;
        end else begin
            app_en            <= 1'b0;
            wr_ack            <= 1'b0;
            rd_ack            <= 1'b0;
            wdata_rd_en       <= 1'b0;
            app_wdf_wren      <= 1'b0;
            app_wdf_end       <= 1'b0;
    
            case (state)
            
                s_calib_wait: begin
                    if (calib_done == 1'b1) begin
                        state           <= s_idle;
                    end
                end
                
                s_idle: begin
                    
                    if ((wr_req == 1'b1) && (rd_req == 1'b0)) begin
                        app_addr        <= wr_addr;
                        wdata_rd_en     <= 1'b1;
                        state           <= s_write_0;
                    end
                    
                    if ((wr_req == 1'b0) && (rd_req == 1'b1)) begin
                        app_addr        <= rd_addr;
                        state           <= s_read_0;
                        app_en          <= 1'b1;
                        app_cmd         <= 3'b001;
                        rd_ack          <= 1'b1;
                    end
                    
                    // Collision.  Give the request to the direction with the least FIFO space
                    if ((wr_req == 1'b1) && (rd_req == 1'b1)) begin
                        if (rd_fifo_count < (9'd255 - wr_fifo_count)) begin
                            app_addr    <= rd_addr;
                            state       <= s_read_0;
                            app_en      <= 1'b1;
                            app_cmd     <= 3'b001;
                            rd_ack      <= 1'b1;
                        end else begin
                            app_addr    <= wr_addr;
                            wdata_rd_en <= 1'b1;
                            state       <= s_write_0;
                        end
                    end
                end
                
                // Write to the memory controller write buffer and then signal a write command
                // to the controller
                s_write_0: begin
                    if (app_wdf_rdy == 1'b1 && app_wdf_wren == 1'b1) begin
                        app_en          <= 1'b1;
                        app_cmd         <= 3'b000;
                        state           <= s_write_1;
                    end else begin
                        app_wdf_wren    <= 1'b1;
                        app_wdf_end     <= 1'b1;
                    end
                end
                
                // Hold the write request until the controller confirms receipt with app_rdy
                s_write_1: begin
                    if (app_rdy == 1'b1) begin
                        wr_ack          <= 1'b1;
                        state           <= s_calib_wait;
                    end else begin
                        app_en          <= 1'b1;
                        app_cmd         <= 3'b000;
                    end
                end
                
                // Hold the read request until the controller confirms receipt with app_rdy
                s_read_0: begin
                    if (app_rdy == 1'b1) begin
                        state           <= s_idle;
                    end else begin
                        app_en          <= 1'b1;
                        app_cmd         <= 3'b001;
                    end
                end

            endcase
        end
    end

endmodule
