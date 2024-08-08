-- Image sensor communication scripting functions.
--
-- Copyright (c) 2016 Opal Kelly Incorporated

-- Constants
DEVICE_ADDRESS_MT9P031                = 0xBA
DEVICE_ADDRESS_AR0330                 = 0x30

MT9P031_REG_CHIP_VERSION              = 0x00
MT9P031_REG_ROW_START                 = 0x01
MT9P031_REG_COLUMN_START              = 0x02
MT9P031_REG_ROW_SIZE                  = 0x03
MT9P031_REG_COLUMN_SIZE               = 0x04
MT9P031_REG_HORIZONTAL_BLANK          = 0x05
MT9P031_REG_VERTICAL_BLANK            = 0x06
MT9P031_REG_OUTPUT_CONTROL            = 0x07
MT9P031_REG_SHUTTER_WIDTH_UPPER       = 0x08
MT9P031_REG_SHUTTER_WIDTH_LOWER       = 0x09
MT9P031_REG_PIXEL_CLOCK_CONTROL       = 0x0A
MT9P031_REG_RESTART                   = 0x0B
MT9P031_REG_SHUTTER_DELAY             = 0x0C
MT9P031_REG_RESET                     = 0x0D
MT9P031_REG_PLL_CONTROL               = 0x10
MT9P031_REG_PLL_CONFIG1               = 0x11
MT9P031_REG_PLL_CONFIG2               = 0x12
MT9P031_REG_READ_MODE1                = 0x1E
MT9P031_REG_READ_MODE2                = 0x20
MT9P031_REG_ROW_ADDRESS_MODE          = 0x22
MT9P031_REG_COLUMN_ADDRESS_MODE       = 0x23
MT9P031_REG_GREEN1_GAIN               = 0x2B
MT9P031_REG_BLUE_GAIN                 = 0x2C
MT9P031_REG_RED_GAIN                  = 0x2D
MT9P031_REG_GREEN2_GAIN               = 0x2E
MT9P031_REG_GLOBAL_GAIN               = 0x35
MT9P031_REG_ROW_BLACK_TARGET          = 0x49
MT9P031_REG_ROW_BLACK_DEFAULT_OFFSET  = 0x4B
MT9P031_REG_BLC_SAMPLE_SIZE           = 0x5B
MT9P031_REG_BLC_TUNE_1                = 0x5C
MT9P031_REG_BLC_DELTA_THRESHOLDS      = 0x5D
MT9P031_REG_BLC_TUNE_2                = 0x5E
MT9P031_REG_BLC_TARGET_THRESHOLDS     = 0x5F
MT9P031_REG_GREEN1_OFFSET             = 0x60
MT9P031_REG_GREEN2_OFFSET             = 0x61
MT9P031_REG_RED_OFFSET                = 0x63
MT9P031_REG_BLUE_OFFSET               = 0x64
MT9P031_REG_TEST_PATTERN_CONTROL      = 0xA0
MT9P031_REG_TEST_PATTERN_GREEN        = 0xA1
MT9P031_REG_TEST_PATTERN_RED          = 0xA2
MT9P031_REG_TEST_PATTERN_BLUE         = 0xA3
MT9P031_REG_TEST_PATTERN_BAR_WIDTH    = 0xA4
MT9P031_REG_CHIP_VERSION_ALT          = 0xFF

AR0330_REG_CHIP_VERSION               = 0x3000
AR0330_REG_Y_ADDR_START               = 0x3002
AR0330_REG_X_ADDR_START               = 0x3004
AR0330_REG_Y_ADDR_END                 = 0x3006
AR0330_REG_X_ADDR_END                 = 0x3008
AR0330_REG_FRAME_LENGTH_LINES         = 0x300A
AR0330_REG_LINE_LENGTH_PCK            = 0x300C
AR0330_REG_REVISION_NUMBER            = 0x300E
AR0330_REG_LOCK_CONTROL               = 0x3010
AR0330_REG_COARSE_INTEGRATION_TIME    = 0x3012
AR0330_REG_FINE_INTEGRATION_TIME      = 0x3014
AR0330_REG_RESET_REGISTER             = 0x301A
AR0330_REG_MODE_SELECT                = 0x301C
AR0330_REG_IMAGE_ORIENTATION          = 0x301D
AR0330_REG_DATA_PEDESTAL              = 0x301E
AR0330_REG_SOFTWARE_RESET             = 0x3021
AR0330_REG_ROW_SPEED                  = 0x3028
AR0330_REG_VT_PIX_CLK_DIV             = 0x302A
AR0330_REG_VT_SYS_CLK_DIV             = 0x302C
AR0330_REG_PRE_PLL_CLK_DIV            = 0x302E
AR0330_REG_PLL_MULTIPLIER             = 0x3030
AR0330_REG_OP_PIX_CLK_DIV             = 0x3036
AR0330_REG_OP_SYS_CLK_DIV             = 0x3038
AR0330_REG_FRAME_COUNT                = 0x303A
AR0330_REG_FRAME_STATUS               = 0x303C
AR0330_REG_LINE_LENGTH_PCK_CB         = 0x303E
AR0330_REG_READ_MODE                  = 0x3040
AR0330_REG_EXTRA_DELAY                = 0x3042
AR0330_REG_FLASH                      = 0x3046
AR0330_REG_FLASH2                     = 0x3048
AR0330_REG_GREEN1_GAIN                = 0x3056
AR0330_REG_BLUE_GAIN                  = 0x3058
AR0330_REG_RED_GAIN                   = 0x305A
AR0330_REG_GREEN2_GAIN                = 0x305C
AR0330_REG_GLOBAL_GAIN                = 0x305E
AR0330_REG_ANALOG_GAIN                = 0x3060
AR0330_REG_SMIA_TEST                  = 0x3064
AR0330_REG_DATAPATH_STATUS            = 0x306A
AR0330_REG_DATAPATH_SELECT            = 0x306E
AR0330_REG_TEST_PATTERN_MODE          = 0x3070
AR0330_REG_TEST_DATA_RED              = 0x3072
AR0330_REG_TEST_DATA_GREENR           = 0x3074
AR0330_REG_TEST_DATA_BLUE             = 0x3076
AR0330_REG_TEST_DATA_GREENB           = 0x3078
AR0330_REG_TEST_RAW_MODE              = 0x307A
AR0330_REG_OPERATION_MODE_CTRL        = 0x3082
AR0330_REG_SEQ_DATA_PORT              = 0x3086
AR0330_REG_SEQ_CTRL_PORT              = 0x3088
AR0330_REG_X_ADDR_START_CB            = 0x308A
AR0330_REG_Y_ADDR_START_CB            = 0x308C
AR0330_REG_X_ADDR_END_CB              = 0x308E
AR0330_REG_Y_ADDR_END_CB              = 0x3090
AR0330_REG_X_EVEN_INC                 = 0x30A0
AR0330_REG_X_ODD_INC                  = 0x30A2
AR0330_REG_Y_EVEN_INC                 = 0x30A4
AR0330_REG_Y_ODD_INC                  = 0x30A6
AR0330_REG_Y_ODD_INC_CB               = 0x30A8
AR0330_REG_FRAME_LENGTH_LINES_CB      = 0x30AA
AR0330_REG_X_ODD_INC_CB               = 0x30AE
AR0330_REG_DIGITAL_TEST               = 0x30B0
AR0330_REG_DIGITAL_CTRL               = 0x30BA
AR0330_REG_GREEN1_GAIN_CB             = 0x30BC
AR0330_REG_BLUE_GAIN_CB               = 0x30BE
AR0330_REG_RED_GAIN_CB                = 0x30C0
AR0330_REG_GREEN2_GAIN_CB             = 0x30C2
AR0330_REG_GLOBAL_GAIN_CB             = 0x30C4
AR0330_REG_GRR_CONTROL1               = 0x30CE
AR0330_REG_GRR_CONTROL2               = 0x30D0
AR0330_REG_GRR_CONTROL3               = 0x30D2
AR0330_REG_GRR_CONTROL4               = 0x30DA
AR0330_REG_DATA_FORMAT_BITS           = 0x31AC
AR0330_REG_HISPI_TIMING               = 0x31C0
AR0330_REG_HISPI_CONTROL_STATUS       = 0x31C6
AR0330_REG_COMPRESSION                = 0x31D0
AR0330_REG_STAT_FRAME_ID              = 0x31D2
AR0330_REG_I2C_WRT_CHECKSUM           = 0x31D6
AR0330_REG_HORIZONTAL_CURSOR_POSITION = 0x31E8
AR0330_REG_VERITCAL_CURSOR_POSITION   = 0x31EA
AR0330_REG_HORIZONTAL_CURSOR_WIDTH    = 0x31EC
AR0330_REG_VERTICAL_CURSOR_WIDTH      = 0x31EE

Error_Failed            = -1
Error_Timeout           = -2
Error_ImageReadoutShort = -3
Error_ImageReadoutError = -4

BufferMode_LowLatency   = 0
BufferMode_MaxSize      = 1
BufferMode_Programmable = 2


-- Make Sleep() function more convenient to call.
Sleep = OpalKelly.Sleep


-- Performs full reset of the current device and remap names of camera board
-- specific functions.
function InitAfterConfigure()
	if OpalKelly.FrontPanel_brdXEM7320A75T == okFP:GetBoardModel() then
		-- Set SZG-CAMERA board specific functions.
		SetTestMode = SetTestModeSZG
		SetGains = SetGainsSZG
		SetOffsets = SetOffsetsSZG
		SetShutterWidth = SetShutterWidthSZG
		SetSize = SetSizeSZG
		SetSkips = SetSkipsSZG

		-- Init.
		return InitAfterConfigureSZG()
	else
		-- Set EVB100x boards specific functions.
		SetTestMode = SetTestModeEVB100x
		SetGains = SetGainsEVB100x
		SetOffsets = SetOffsetsEVB100x
		SetShutterWidth = SetShutterWidthEVB100x
		SetSize = SetSizeEVB100x
		SetSkips = SetSkipsEVB100x

		-- Init.
		return InitAfterConfigureEVB100x()
	end
end


-- Writes given 16 bit value to an 8-bit register address on an MT9P031 sensor.
function I2CWrite8(addr, data)
	okFP:ActivateTriggerIn(0x42, 1)
	-- Num of Data Words
	okFP:SetWireInValue(0x01, 0x0030, 0x00ff) -- Address + Data Words
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Device Address
	okFP:SetWireInValue(0x01, DEVICE_ADDRESS_MT9P031, 0x00ff) -- 0xBA for MT9P031
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Register Address
	okFP:SetWireInValue(0x01, addr, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Data 0 MSB
	okFP:SetWireInValue(0x01, data >> 8, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Data 1 LSB
	okFP:SetWireInValue(0x01, data, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)

	-- Start I2C Transaction
	okFP:ActivateTriggerIn(0x42, 0)

	-- Wait for Transaction to Finish
	repeat
		okFP:UpdateTriggerOuts()
	until okFP:IsTriggered(0x61, 0x0001)
end


-- Writes a 16 bit value to a 16-bit register address on the AR0330 sensor.
function I2CWrite16(addr, data)
	okFP:ActivateTriggerIn(0x42, 1)
	-- Preamble Length (Bytes)
	okFP:SetWireInValue(0x01, 0x0003, 0x00ff) -- Address Words
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Starts
	okFP:SetWireInValue(0x01, 0x0000, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Stops
	okFP:SetWireInValue(0x01, 0x0000, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Payload Length (Bytes)
	okFP:SetWireInValue(0x01, 0x0002, 0x00ff) -- Data Words
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Device Address
	okFP:SetWireInValue(0x01, DEVICE_ADDRESS_AR0330, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Register Address (high)
	okFP:SetWireInValue(0x01, addr >> 8, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Register Address (low)
	okFP:SetWireInValue(0x01, addr, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Data 0 MSB
	okFP:SetWireInValue(0x01, data >> 8, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Data 1 LSB
	okFP:SetWireInValue(0x01, data, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)

	-- Start I2C Transaction
	okFP:ActivateTriggerIn(0x42, 0)

	-- Wait for Transaction to Finish
	repeat
		okFP:UpdateTriggerOuts()
	until okFP:IsTriggered(0x61, 0x0001)
end

-- Reads a 16 bit value from a 16-bit register address on the AR0330 sensor.
function I2CRead16(addr, data)
	u16Data = 0

	okFP:ActivateTriggerIn(0x42, 1)
	-- Preamble Length (Bytes)
	okFP:SetWireInValue(0x01, 0x0084, 0x00ff) -- Address Words
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Starts
	okFP:SetWireInValue(0x01, 0x0004, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Stops
	okFP:SetWireInValue(0x01, 0x0000, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Payload Length (Bytes)
	okFP:SetWireInValue(0x01, 0x0002, 0x00ff) -- Data Words
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Device Address (write)
	okFP:SetWireInValue(0x01, DEVICE_ADDRESS_AR0330, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Register Address (high)
	okFP:SetWireInValue(0x01, addr >> 8, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Register Address (low)
	okFP:SetWireInValue(0x01, addr, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)
	-- Device Address (read)
	okFP:SetWireInValue(0x01, DEVICE_ADDRESS_AR0330 + 1, 0x00ff)
	okFP:UpdateWireIns()
	okFP:ActivateTriggerIn(0x42, 2)

	-- Start I2C Transaction
	okFP:ActivateTriggerIn(0x42, 0)

	-- Wait for Transaction to Finish
	repeat
		okFP:UpdateTriggerOuts()
	until okFP:IsTriggered(0x61, 0x0001)

	okFP:ActivateTriggerIn(0x42, 1)
	-- Read result 0
	okFP:UpdateWireOuts()
	u16Data = (okFP:GetWireOutValue(0x22) & 0xff) << 8
	-- Read result 1
	okFP:ActivateTriggerIn(0x42, 3)
	okFP:UpdateWireOuts()
	u16Data = u16Data | (okFP:GetWireOutValue(0x22) & 0xff)

	return u16Data
end



-- Assert all RESETs: System PLL, Image Sensor, Pixel Clock DCM, Logic.
function AssertResets()
	-- Assert all RESETs:
	-- + System PLL
	-- + Image Sensor
	-- + Pixel Clock DCM
	-- + Logic
	okFP:SetWireInValue(0x00, 0x000f, 0x000f)
	okFP:UpdateWireIns()
	Sleep(1)
	okFP:SetWireInValue(0x00, 0x0000, 0x0001)  -- Release system PLL RESET
	okFP:UpdateWireIns()
	Sleep(1)
	okFP:SetWireInValue(0x00, 0x0000, 0x0002)  -- Release image sensor RESET
	okFP:UpdateWireIns()
	Sleep(1)
	okFP:SetWireInValue(0x00, 0x0000, 0x0008)  -- Release logic RESET
	okFP:UpdateWireIns()
	Sleep(10)
end


-- Release PIXCLK DCM RESET.
function ReleaseResets()
	-- Release PIXCLK DCM RESET
	Sleep(10)
	okFP:SetWireInValue(0x00, 0x0000, 0x0004)
	okFP:SetWireInValue(0x00, 0x0010, 0x0010)
	okFP:UpdateWireIns()
end


function SetupOptimizedRegisterSetEVB100x()
	-- Setup on-chip output FIFO to clock out at 72 MHz.  The internal pixel
	-- array still runs at 96 MHz.  This is documented in TN-09-148.
	-- + Configure horizontal blanking to 450
	-- + Enable the output FIFO
	I2CWrite8(MT9P031_REG_HORIZONTAL_BLANK, 0x01c2)
	I2CWrite8(MT9P031_REG_OUTPUT_CONTROL, 0x1f8e)

	-- Fix "Blue Strip" issue documented in TN-09-148.
	I2CWrite8(0x7f, 0x0000)

	-- Optimize sensor performance for full-resolution at 15 fps as
	-- documented in TN-09-148.
	I2CWrite8(0x70, 0x0079)
	I2CWrite8(0x71, 0x7800)
	I2CWrite8(0x72, 0x7800)
	I2CWrite8(0x73, 0x0300)
	I2CWrite8(0x74, 0x0300)
	I2CWrite8(0x75, 0x3c00)
	I2CWrite8(0x76, 0x4e3d)
	I2CWrite8(0x77, 0x4e3d)
	I2CWrite8(0x78, 0x774f)
	I2CWrite8(0x79, 0x7900)
	I2CWrite8(0x7a, 0x7904)
	I2CWrite8(0x7b, 0x7800)
	I2CWrite8(0x7c, 0x7800)
	I2CWrite8(0x7e, 0x7800)
	I2CWrite8(0x7f, 0x0000)
	I2CWrite8(0x06, 0x0000)
	I2CWrite8(0x29, 0x0481)
	I2CWrite8(0x3e, 0x0087)
	I2CWrite8(0x3f, 0x0007)
	I2CWrite8(0x41, 0x0003)
	I2CWrite8(0x48, 0x0018)
	I2CWrite8(0x5f, 0x1c16)
	I2CWrite8(0x57, 0x0007)
end

function SetupOptimizedRegisterSetSZG()
	-- Setup sensor for 1080p 30fps
	I2CWrite16(AR0330_REG_HISPI_CONTROL_STATUS, 0x8400) -- hispi_control setting
	I2CWrite16(AR0330_REG_SMIA_TEST, 0x1802) -- Disable embedded Data
	I2CWrite16(AR0330_REG_DATA_FORMAT_BITS, 0x0A0A) -- Data Width
	I2CWrite16(AR0330_REG_COMPRESSION, 0x0000) -- Disable compression
	I2CWrite16(AR0330_REG_DATAPATH_SELECT, 0x0210) -- Datapath select
	I2CWrite16(AR0330_REG_VT_PIX_CLK_DIV, 0x0005) -- vt_pix_clk_div originally 0x0005
	I2CWrite16(AR0330_REG_PLL_MULTIPLIER, 0x0031) -- pll_multiplier originally 0x0031
	I2CWrite16(AR0330_REG_OP_PIX_CLK_DIV, 0x000A) -- op_pix_clk_div (data width)
	I2CWrite16(AR0330_REG_COARSE_INTEGRATION_TIME, 0x0400) -- Increase exposure 400 for sensor+lens, 20 for bare sensor
	I2CWrite16(AR0330_REG_ANALOG_GAIN, 0x0018) -- Set gain to ISO 400

	I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x0000) -- 1 = Solid color test pattern, 2 = vertical color bars

	I2CWrite16(AR0330_REG_MODE_SELECT, 0x0100) -- Enable streaming
end


-- Performs full reset of EVB100x device.
function InitAfterConfigureEVB100x()
	-- Load the default PLL configuration for some boards.
	local devInfo = OpalKelly.okTDeviceInfo()
	okFP:GetDeviceInfo(devInfo)
	if devInfo.isPLL22150Supported or devInfo.isPLL22393Supported then
		okFP:LoadDefaultPLLConfiguration()
	end

	AssertResets()

	-- Note: Pixel clock DCM remains in RESET until we've setup the image
	-- sensor's PIXCLK output.

	-- Power on the PLL
	I2CWrite8(MT9P031_REG_PLL_CONTROL, 0x0051)

	--          EXTCLK           >> /N  >> *M   >> /P1 >>        PIXCLK
	-- XEM6006: EXTCLK =  24 MHz >> /6  >> *72  >> /3  >> 96 MHz PIXCLK
	-- XEM6010: EXTCLK =  20 MHz >> /5  >> *72  >> /3  >> 96 MHz PIXCLK
	-- XEM6110: EXTCLK =  20 MHz >> /5  >> *72  >> /3  >> 96 MHz PIXCLK
	local config = {
		[ OpalKelly.FrontPanel_brdXEM6006LX9   ] = 6,
		[ OpalKelly.FrontPanel_brdXEM6006LX16  ] = 6,
		[ OpalKelly.FrontPanel_brdXEM6006LX25  ] = 6,
		[ OpalKelly.FrontPanel_brdXEM6010LX45  ] = 5,
		[ OpalKelly.FrontPanel_brdXEM6010LX150 ] = 5,
		[ OpalKelly.FrontPanel_brdXEM6310LX45  ] = 5,
		[ OpalKelly.FrontPanel_brdXEM6310LX150 ] = 5,
		[ OpalKelly.FrontPanel_brdXEM7010A50   ] = 5,
		[ OpalKelly.FrontPanel_brdXEM7010A200  ] = 5,
		[ OpalKelly.FrontPanel_brdXEM7310A75   ] = 5,
		[ OpalKelly.FrontPanel_brdXEM7310A200  ] = 5,
		[ OpalKelly.FrontPanel_brdXEM7350K70T  ] = 5,
		[ OpalKelly.FrontPanel_brdXEM7350K160T ] = 5,
		[ OpalKelly.FrontPanel_brdZEM4310      ] = 5
	}

	local N = config[okFP:GetBoardModel()]
	if not N then
		return -1
	end

	local M=72
	local P1=3
	I2CWrite8(MT9P031_REG_PLL_CONFIG1, ((N-1)<<0) | (M<<8))
	I2CWrite8(MT9P031_REG_PLL_CONFIG2, ((P1-1)<<0))

	-- Wait to allow PLL to lock, then select PLL output as the system clock
	Sleep(1)
	I2CWrite8(MT9P031_REG_PLL_CONTROL, 0x0053)

	-- Setup image sensor registers
	SetupOptimizedRegisterSetEVB100x()

	ReleaseResets()

	-- Turn off programmable empty setting in hardware, this is not used in
	-- this implementation, this wire is updated in LogicReset().
	okFP:SetWireInValue(0x04, 0, 0xfff)

	-- Finally perform logic reset
	LogicReset()

	-- Determine which version of HDL do we use.
	okFP:UpdateWireOuts()

	return okFP:GetWireOutValue(0x3f)
end


-- Performs full reset of SZG-CAMERA device.
function InitAfterConfigureSZG()
	AssertResets()
	ReleaseResets()

	-- Perform logic reset
	LogicReset()

	-- Setup image sensor registers
	SetupOptimizedRegisterSetSZG()

	-- Determine which version of HDL do we use.
	okFP:UpdateWireOuts()

	return okFP:GetWireOutValue(0x3f)
end


function GetCapabilities()
	return okFP:GetWireOutValue(0x3e)
end


function LogicReset()
	okFP:SetWireInValue(0x00, 0x0008, 0x0008)
	okFP:UpdateWireIns()
	okFP:SetWireInValue(0x00, 0x0000, 0x0008)
	okFP:UpdateWireIns()
end


function SetImageBufferDepth(frames)
	-- Set the bit #11 to switch to programmable mode and put the number of
	-- frames to use in the lower 10 bits.
	okFP:SetWireInValue(0x05, 0x400 | frames, 0x7ff)

	-- Notice that we don't need to call UpdateWireIns() before calling
	-- LogicReset() as it will do it internally anyhow.
	LogicReset()
end


function SetTestModeEVB100x(enable, mode)
	if not enable then
		I2CWrite8(MT9P031_REG_READ_MODE2, 1<<6)
		I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, 0x0000)
	else
		-- Turn Off BLC
		I2CWrite8(MT9P031_REG_READ_MODE2, 0<<6)
		I2CWrite8(MT9P031_REG_ROW_BLACK_DEFAULT_OFFSET, 0x0000)

		local modes = {
			[0] = function() -- Color Field
				I2CWrite8(MT9P031_REG_TEST_PATTERN_RED,   0x0dd0)
				I2CWrite8(MT9P031_REG_TEST_PATTERN_GREEN, 0x0ee0)
				I2CWrite8(MT9P031_REG_TEST_PATTERN_BLUE,  0x0bb0)
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[1] = function() -- Horizontal Gradient
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[2] = function() -- Vertical Gradient
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[3] = function() -- Diagonal Gradient
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[4] = function() -- Classic
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[5] = function() -- Walking 1s
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[6] = function() -- Monochrome Horizontal Bars
				I2CWrite8(MT9P031_REG_TEST_PATTERN_BAR_WIDTH, 0x0a)
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[7] = function() -- Monochrome Vertical Bars
				I2CWrite8(MT9P031_REG_TEST_PATTERN_BAR_WIDTH, 0x0a)
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end,
			[8] = function() -- Vertical Color Bars
				I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode&0x0f)<<3 | 0x01)
			end
		}

		if modes[mode] then
			modes[mode]()
		end
	end
end


function SetTestModeSZG(enable, mode)
	if not enable then
		I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x0)
	else
		local modes = {
			[0] = function() -- Color field
				I2CWrite16(AR0330_REG_TEST_DATA_RED, 0x0dd0)
				I2CWrite16(AR0330_REG_TEST_DATA_GREENR, 0x0ee0)
				I2CWrite16(AR0330_REG_TEST_DATA_GREENB, 0x0ee0)
				I2CWrite16(AR0330_REG_TEST_DATA_BLUE, 0x0bb0)
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x1)
			end,
			[4] = function() -- Classic
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x2)
			end,
			[5] = function() -- Walking 1s
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0xFF)
			end,
			[8] = function() -- Vertical color bars
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x3)
			end,
		}

		if modes[mode] then
			modes[mode]()
		else
			modes[1]()
		end
	end
end


function SetGainsEVB100x(r, g1, g2, b)
	I2CWrite8(MT9P031_REG_RED_GAIN, (r & 0x7f) << 8)
	I2CWrite8(MT9P031_REG_GREEN1_GAIN, (g1 & 0x7f) << 8)
	I2CWrite8(MT9P031_REG_GREEN2_GAIN, (g2 & 0x7f) << 8)
	I2CWrite8(MT9P031_REG_BLUE_GAIN, (b & 0x7f) << 8)
end


function SetGainsSZG(r, g1, g2, b)
	I2CWrite16(AR0330_REG_RED_GAIN, r & 0xFFFF)
	I2CWrite16(AR0330_REG_GREEN1_GAIN, g1 & 0xFFFF)
	I2CWrite16(AR0330_REG_GREEN2_GAIN, g2 & 0xFFFF)
	I2CWrite16(AR0330_REG_BLUE_GAIN, b & 0xFFFF)
end


function SetOffsetsEVB100x(r, g1, g2, b)
	I2CWrite8(MT9P031_REG_RED_OFFSET, r)
	I2CWrite8(MT9P031_REG_GREEN1_OFFSET, g1)
	I2CWrite8(MT9P031_REG_GREEN2_OFFSET, g2)
	I2CWrite8(MT9P031_REG_BLUE_OFFSET, b)
end


function SetOffsetsSZG(r, g1, g2, b)
	-- TODO: Unsupported by sensor
end


function SetShutterWidthEVB100x(u32shutter)
	I2CWrite8(MT9P031_REG_SHUTTER_WIDTH_UPPER, (u32shutter & 0xffff0000)>>16)
	I2CWrite8(MT9P031_REG_SHUTTER_WIDTH_LOWER,  u32shutter & 0xffff)
end


function SetShutterWidthSZG(u32shutter)
	pix_clk_ns = 34
	shutter_ms = (u32shutter * 250) / 10000

	line_length_pck = I2CRead16(AR0330_REG_LINE_LENGTH_PCK)

	shutter_llpck = math.floor((shutter_ms * 1000000) / (line_length_pck * pix_clk_ns))

	I2CWrite16(AR0330_REG_COARSE_INTEGRATION_TIME, shutter_llpck & 0xFFFF)
end


function SetSizeEVB100x(x, y)
	I2CWrite8(MT9P031_REG_COLUMN_SIZE, x-1)
	I2CWrite8(MT9P031_REG_ROW_SIZE, y-1)
end


function SetSizeSZG(x, y)
	I2CWrite16(AR0330_REG_X_ADDR_END, x + 6 - 1)
	I2CWrite16(AR0330_REG_Y_ADDR_END, y + 124 - 1)
end


function SetSkipsEVB100x(x, y, ulLen)
	I2CWrite8(MT9P031_REG_COLUMN_ADDRESS_MODE, (x<<4) | x)
	I2CWrite8(MT9P031_REG_ROW_ADDRESS_MODE, (y<<4) | y)

	okFP:SetWireInValue(0x02, ulLen & 0xffff)
	okFP:SetWireInValue(0x03, ulLen >> 16)

	LogicReset()
end


function SetSkipsSZG(x, y, ulLen)
	if (x == 0) then
		I2CWrite16(AR0330_REG_X_ODD_INC, 1)
	elseif (x == 1) then
		I2CWrite16(AR0330_REG_X_ODD_INC, 3)
	elseif (x == 2) then
		I2CWrite16(AR0330_REG_X_ODD_INC, 5)
	end

	if (y == 0) then
		I2CWrite16(AR0330_REG_Y_ODD_INC, 1)
	elseif (y == 1) then
		I2CWrite16(AR0330_REG_Y_ODD_INC, 3)
	elseif (y == 2) then
		I2CWrite16(AR0330_REG_Y_ODD_INC, 5)
	end

	okFP:SetWireInValue(0x02, ulLen & 0xffff)
	okFP:SetWireInValue(0x03, ulLen >> 16)

	LogicReset()
end


function GetBufferedImageCount()
	return okFP:GetWireOutValue(0x24)
end


function EnablePingPong(enable)
	if enable then
		okFP:SetWireInValue(0x00, 1<<4, 1<<4)
		okFP:UpdateWireIns()
	else
		okFP:SetWireInValue(0x00, 0<<4, 1<<4)
		okFP:UpdateWireIns()
	end

	-- Reset things
	okFP:SetWireInValue(0x00, 1<<3, 1<<3)
	okFP:UpdateWireIns()
	okFP:SetWireInValue(0x00, 0<<3, 1<<3)
	okFP:UpdateWireIns()
end


function BufferedCaptureV1(ulLen)
	okFP:UpdateWireOuts()

	full = false
	for i = 1, 100 do
		if (okFP:GetWireOutValue(0x23) & 0x0300) > 0 then  -- Frame buffer full?
			full = true
			break
		end

		Sleep(2)
		okFP:UpdateWireOuts()
	end

	if not full then return Error_Timeout end

	local buf = OpalKelly.Buffer(ulLen)

	if (okFP:GetWireOutValue(0x23) & 0x0100) > 0 then   -- Frame ready (buffer A)
		okFP:SetWireInValue(0x04, 0x0000)
		okFP:SetWireInValue(0x05, 0x0000)
		okFP:UpdateWireIns()
		okFP:ActivateTriggerIn(0x40, 1)  -- Readout start trigger
		if OpalKelly.FrontPanel_brdZEM4310 == okFP:GetBoardModel() then
			len = okFP:ReadFromBlockPipeOut(0xA0, 128, ulLen, buf)
		else
			len = okFP:ReadFromPipeOut(0xA0, ulLen, buf)
		end

		if len < 0 then return Error_ImageReadoutError end
		if len ~= ulLen then return Error_ImageReadoutShort end

		okFP:ActivateTriggerIn(0x40, 2)  -- Readout done (buffer A)
	elseif (okFP:GetWireOutValue(0x23) & 0x0200) > 0 then   -- Frame ready (buffer B)
		okFP:SetWireInValue(0x04, 0x0000)
		okFP:SetWireInValue(0x05, 0x0080)
		okFP:UpdateWireIns()
		okFP:ActivateTriggerIn(0x40, 1)  -- Readout start trigger
		if OpalKelly.FrontPanel_brdZEM4310 == okFP:GetBoardModel() or
			OpalKelly.FrontPanel_brdXEM7350K70T == okFP:GetBoardModel() or
			OpalKelly.FrontPanel_brdXEM7350K160T == okFP:GetBoardModel() then
			len = okFP:ReadFromBlockPipeOut(0xA0, 128, ulLen, buf)
		else
			len = okFP:ReadFromPipeOut(0xA0, ulLen, buf)
		end

		if len < 0 then return Error_ImageReadoutError end
		if len < ulLen then return Error_ImageReadoutShort end

		okFP:ActivateTriggerIn(0x40, 3)  -- Readout done (buffer B)
	end

	return buf
end


function SingleCaptureV1(ulLen)
	-- PINGPONG = 0
	okFP:SetWireInValue(0x00, 0<<4, 1<<4)
	-- Set data length
	okFP:SetWireInValue(0x02, ulLen & 0xffff)
	okFP:SetWireInValue(0x03, ulLen >> 16)
	-- Readout address = 0x00000000
	okFP:SetWireInValue(0x04, 0x0000)
	okFP:SetWireInValue(0x05, 0x0000)
	okFP:UpdateWireIns()

	okFP:UpdateTriggerOuts()
	okFP:ActivateTriggerIn(0x40, 0)  -- Capture trigger

	done = false
	for i = 1, 1000 do
		Sleep(2)
		okFP:UpdateTriggerOuts()
		if okFP:IsTriggered(0x60, 1<<0) then   -- Frame done trigger
			done = true
			break
		end
	end

	if not done then return Error_Timeout end

	local buf = OpalKelly.Buffer(ulLen)

	okFP:ActivateTriggerIn(0x40, 1)  -- Readout start trigger
	if OpalKelly.FrontPanel_brdZEM4310 == okFP:GetBoardModel() or
		OpalKelly.FrontPanel_brdXEM7350K70T == okFP:GetBoardModel() then
		len = okFP:ReadFromBlockPipeOut(0xA0, 128, ulLen, buf)
	else
		len = okFP:ReadFromPipeOut(0xA0, ulLen, buf)
	end

	if len < 0 then return Error_ImageReadoutError end
	if len < ulLen then return Error_ImageReadoutShort end

	okFP:ActivateTriggerIn(0x40, 2)  -- Readout done trigger

	return buf
end

function BufferedCaptureV2(ulLen)
	okFP:UpdateWireOuts()

	done = false
	for i = 0, 100 do
		if (okFP:GetWireOutValue(0x23) & 0x0100) ~= 0 then -- Frame avail?
			done = true
			break
		end
		Sleep(2)
		okFP:UpdateWireOuts()
	end
	if not done then return Error_Timeout end

	local buf = OpalKelly.Buffer(ulLen)

	okFP:ActivateTriggerIn(0x40, 0)
	if OpalKelly.FrontPanel_brdZEM4310 == okFP:GetBoardModel() then
		len = okFP:ReadFromBlockPipeOut(0xA0, 128, ulLen, buf)
	else
		len = okFP:ReadFromPipeOut(0xA0, ulLen, buf)
	end
	okFP:ActivateTriggerIn(0x40, 1)

	if len < 0 then return Error_ImageReadoutError end
	if len < ulLen then return Error_ImageReadoutShort end

	return buf
end
