//------------------------------------------------------------------------
// ExtractMACAddress.v
// 
// This module utilizes our Opal Kelly I2C controller. First we stage the 
// data to be sent to the I2C controller. We then stimulate the controller 
// using a state machine that follows the instruction from the I2C Controller 
// documentation. The source code and documentation is located at:
// https://github.com/opalkelly-opensource/I2CController
//
// The module will output the "done" signal once the "MACAddr[47:0]" is valid. 
// "rst" restarts the retrieval process.
//
// Copyright (c) 2005-2021  Opal Kelly Incorporated
//------------------------------------------------------------------------
module ExtractMACAddress (
	input              okClk,
	input              rst,
	inout              sclk,
	inout              sdata,
	
	output reg [47:0]  MACAddr,
    output reg         done
);
// Register and wire definitions
reg  [7:0] byteArray [6:0];
reg        resetMemPointer;
reg        memWrite;
reg        memRead;
reg        memStart;
reg        shift;
wire       transactionDone;
wire [7:0] outData;
reg  [3:0] countBytesTransmitted;
reg  [1:0] state;
reg  [3:0] receiveCounter;
reg        incrementCount;
integer i;

// State parameters
localparam  RESET              = 0,
            TRANSMIT           = 1,
            WAIT_TO_FINISH     = 2,
            GET_RECEIEVED_DATA = 3;

always @(posedge okClk) begin
    if (rst) begin
        countBytesTransmitted <= 4'h0;
        //Configuration bytes (These are not transfered, they are used to configure the I2C controller)
        byteArray[0]          <= 8'h83; // Preamble Length ORed with 0x80 (0x80 indicates a read)
        // Starts. 4'b0001 transmits a start bit after first byte, 4'b0010 transmits a start bit after second byte,
        // 4'b0100 transmits a start bit after third byte, etc.
        byteArray[1]          <= 8'h02; // Starts
        byteArray[2]          <= 8'h00; // Stops
        byteArray[3]          <= 8'h06; // Recieve Length (Amount of bytes to receive.
        //Preamble (These bytes are transmitted onto the I2C line)
        byteArray[4]          <= 8'b10101110; // Dev Address (Write)
        byteArray[5]          <= 8'hFA;       // 24AA025E48 EEPROM MAC address register start location.
        byteArray[6]          <= 8'b10101111; // Dev Address (Read)
    end else if (shift) begin 
        countBytesTransmitted <= countBytesTransmitted + 4'h1;
        for (i = 0; i <= 5; i = i + 1) begin 
            byteArray[i]      <= byteArray[i + 1];
        end
        byteArray[6]          <= 8'h00;
    end

end

always @(posedge okClk) begin
    if (rst) begin
        receiveCounter        <= 4'h0;
    end else if (incrementCount) begin
        receiveCounter        <= receiveCounter + 4'h1;
    end
end


always @(posedge okClk) begin
    if (rst) begin
        state <=            RESET;
        resetMemPointer  <= 0;
        memWrite         <= 0;
        memRead          <= 0;
        memStart         <= 0;
        shift            <= 0;
        incrementCount   <= 0;
        done             <= 0;
        MACAddr          <= 48'd0;
    end else begin
        resetMemPointer  <= 0;
        memWrite         <= 0;
        memRead          <= 0;
        memStart         <= 0;
        shift            <= 0;
        incrementCount   <= 0;
        done             <= 0;
        // state will stay in same state if not set. It is not defaulted here. 
        
        case(state)
            RESET: begin
               state                  <= TRANSMIT;
               resetMemPointer        <= 1'b1;
            end
            
            TRANSMIT: begin
                if (countBytesTransmitted == 4'h6) begin
                    state             <= WAIT_TO_FINISH;
                    memStart          <= 1'b1;
                end else begin
                    shift             <= 1'b1;
                    memWrite          <= 1'b1;
                end
            end
            
            WAIT_TO_FINISH: begin
                if (transactionDone) begin
                    state             <= GET_RECEIEVED_DATA;
                    resetMemPointer   <= 1'b1;
                end
            end
            
            GET_RECEIEVED_DATA: begin
                if (receiveCounter < 6) begin
                    MACAddr           <= {MACAddr[39:0], outData};
                    incrementCount    <= 1'b1;
                    memRead           <= 1'b1;
                end else begin
                    done              <= 1'b1;
                end
            end
            
            
        endcase
    end
end 

i2cController # (
    .CLOCK_STRETCH_SUPPORT  (1),
    .CLOCK_DIVIDER          (480)
) i2c_ctrl0 (
    .clk                    (okClk),            // input
    .reset                  (rst),              // input
    .start                  (memStart),         // input
    .done                   (transactionDone),  // input
    .memclk                 (okClk),            // input
    .memstart               (resetMemPointer),  // input
    .memwrite               (memWrite),         // input
    .memread                (memRead),          // input
    .memdin                 (byteArray[0]),     // input  [7:0]
    .memdout                (outData),          // output [7:0]
    .i2c_sclk               (sclk),             // inout
    .i2c_sdat               (sdata)             // inout
);
endmodule

