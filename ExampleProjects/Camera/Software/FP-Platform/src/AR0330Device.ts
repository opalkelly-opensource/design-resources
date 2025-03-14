/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { MatrixDimensions } from "./ICamera";

export const AR0330_DEFAULT_SIZE: MatrixDimensions = { columnCount: 2304, rowCount: 1296 };

export const DEVICE_ADDRESS_AR0330 = 0x30;

export const AR0330_REG_CHIP_VERSION = 0x3000;
export const AR0330_REG_Y_ADDR_START = 0x3002;
export const AR0330_REG_X_ADDR_START = 0x3004;
export const AR0330_REG_Y_ADDR_END = 0x3006;
export const AR0330_REG_X_ADDR_END = 0x3008;
export const AR0330_REG_FRAME_LENGTH_LINES = 0x300a;
export const AR0330_REG_LINE_LENGTH_PCK = 0x300c;
export const AR0330_REG_REVISION_NUMBER = 0x300e;
export const AR0330_REG_LOCK_CONTROL = 0x3010;
export const AR0330_REG_COARSE_INTEGRATION_TIME = 0x3012;
export const AR0330_REG_FINE_INTEGRATION_TIME = 0x3014;
export const AR0330_REG_RESET_REGISTER = 0x301a;
export const AR0330_REG_MODE_SELECT = 0x301c;
export const AR0330_REG_IMAGE_ORIENTATION = 0x301d;
export const AR0330_REG_DATA_PEDESTAL = 0x301e;
export const AR0330_REG_SOFTWARE_RESET = 0x3021;
export const AR0330_REG_ROW_SPEED = 0x3028;
export const AR0330_REG_VT_PIX_CLK_DIV = 0x302a;
export const AR0330_REG_VT_SYS_CLK_DIV = 0x302c;
export const AR0330_REG_PRE_PLL_CLK_DIV = 0x302e;
export const AR0330_REG_PLL_MULTIPLIER = 0x3030;
export const AR0330_REG_OP_PIX_CLK_DIV = 0x3036;
export const AR0330_REG_OP_SYS_CLK_DIV = 0x3038;
export const AR0330_REG_FRAME_COUNT = 0x303a;
export const AR0330_REG_FRAME_STATUS = 0x303c;
export const AR0330_REG_LINE_LENGTH_PCK_CB = 0x303e;
export const AR0330_REG_READ_MODE = 0x3040;
export const AR0330_REG_EXTRA_DELAY = 0x3042;
export const AR0330_REG_FLASH = 0x3046;
export const AR0330_REG_FLASH2 = 0x3048;
export const AR0330_REG_GREEN1_GAIN = 0x3056;
export const AR0330_REG_BLUE_GAIN = 0x3058;
export const AR0330_REG_RED_GAIN = 0x305a;
export const AR0330_REG_GREEN2_GAIN = 0x305c;
export const AR0330_REG_GLOBAL_GAIN = 0x305e;
export const AR0330_REG_ANALOG_GAIN = 0x3060;
export const AR0330_REG_SMIA_TEST = 0x3064;
export const AR0330_REG_DATAPATH_STATUS = 0x306a;
export const AR0330_REG_DATAPATH_SELECT = 0x306e;
export const AR0330_REG_TEST_PATTERN_MODE = 0x3070;
export const AR0330_REG_TEST_DATA_RED = 0x3072;
export const AR0330_REG_TEST_DATA_GREENR = 0x3074;
export const AR0330_REG_TEST_DATA_BLUE = 0x3076;
export const AR0330_REG_TEST_DATA_GREENB = 0x3078;
export const AR0330_REG_TEST_RAW_MODE = 0x307a;
export const AR0330_REG_OPERATION_MODE_CTRL = 0x3082;
export const AR0330_REG_SEQ_DATA_PORT = 0x3086;
export const AR0330_REG_SEQ_CTRL_PORT = 0x3088;
export const AR0330_REG_X_ADDR_START_CB = 0x308a;
export const AR0330_REG_Y_ADDR_START_CB = 0x308c;
export const AR0330_REG_X_ADDR_END_CB = 0x308e;
export const AR0330_REG_Y_ADDR_END_CB = 0x3090;
export const AR0330_REG_X_EVEN_INC = 0x30a0;
export const AR0330_REG_X_ODD_INC = 0x30a2;
export const AR0330_REG_Y_EVEN_INC = 0x30a4;
export const AR0330_REG_Y_ODD_INC = 0x30a6;
export const AR0330_REG_Y_ODD_INC_CB = 0x30a8;
export const AR0330_REG_FRAME_LENGTH_LINES_CB = 0x30aa;
export const AR0330_REG_X_ODD_INC_CB = 0x30ae;
export const AR0330_REG_DIGITAL_TEST = 0x30b0;
export const AR0330_REG_DIGITAL_CTRL = 0x30ba;
export const AR0330_REG_GREEN1_GAIN_CB = 0x30bc;
export const AR0330_REG_BLUE_GAIN_CB = 0x30be;
export const AR0330_REG_RED_GAIN_CB = 0x30c0;
export const AR0330_REG_GREEN2_GAIN_CB = 0x30c2;
export const AR0330_REG_GLOBAL_GAIN_CB = 0x30c4;
export const AR0330_REG_GRR_CONTROL1 = 0x30ce;
export const AR0330_REG_GRR_CONTROL2 = 0x30d0;
export const AR0330_REG_GRR_CONTROL3 = 0x30d2;
export const AR0330_REG_GRR_CONTROL4 = 0x30da;
export const AR0330_REG_DATA_FORMAT_BITS = 0x31ac;
export const AR0330_REG_HISPI_TIMING = 0x31c0;
export const AR0330_REG_HISPI_CONTROL_STATUS = 0x31c6;
export const AR0330_REG_COMPRESSION = 0x31d0;
export const AR0330_REG_STAT_FRAME_ID = 0x31d2;
export const AR0330_REG_I2C_WRT_CHECKSUM = 0x31d6;
export const AR0330_REG_HORIZONTAL_CURSOR_POSITION = 0x31e8;
export const AR0330_REG_VERITCAL_CURSOR_POSITION = 0x31ea;
export const AR0330_REG_HORIZONTAL_CURSOR_WIDTH = 0x31ec;
export const AR0330_REG_VERTICAL_CURSOR_WIDTH = 0x31ee;
