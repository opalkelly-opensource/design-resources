/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFrontPanel, ByteCount } from "@opalkelly/frontpanel-platform-api";

import { FrontPanelDeviceI2C } from "./FrontPanelDeviceI2C";
import { FrontPanelCamera } from "./FrontPanelCamera";
import { CameraShutterWidth, FrameConfiguration, MatrixDimensions, TestMode } from "./ICamera";

import * as AR0330Device from "./AR0330Device";

export class SZYGYCamera extends FrontPanelCamera {
    private readonly _DeviceI2C: FrontPanelDeviceI2C;

    constructor(frontpanel: IFrontPanel, deviceI2C: FrontPanelDeviceI2C) {
        super(frontpanel, AR0330Device.AR0330_DEFAULT_SIZE);

        this._DeviceI2C = deviceI2C;
    }

    // FrontPanelCamera Accessor Methods
    public get DefaultSize(): MatrixDimensions {
        return AR0330Device.AR0330_DEFAULT_SIZE;
    }

    public get SupportedSkips(): MatrixDimensions[] {
        return [
            { rowCount: 0, columnCount: 0 },
            { rowCount: 1, columnCount: 1 },
            { rowCount: 2, columnCount: 2 }
        ];
    }

    public get SupportedTestModes(): TestMode[] {
        return [
            TestMode.Classic,
            TestMode.ColorField,
            TestMode.VerticalColorBars,
            TestMode.Walking1s
        ];
    }

    public get SupportedFrameConfigurations(): FrameConfiguration[] {
        const retval: FrameConfiguration[] = [];

        this.SupportedSkips.forEach((skips) => {
            const frameDimensions: MatrixDimensions = FrontPanelCamera.CalculateFrameDimensions(
                AR0330Device.AR0330_DEFAULT_SIZE,
                skips
            );

            retval.push({ dimensions: frameDimensions, skips: skips });
        });

        return retval;
    }

    // FrontPanelCamera Overrides

    // Performs full reset of SZG-CAMERA device
    public override async Initialize(): Promise<number> {
        await this.AssertResets();
        await this.ReleaseResets();

        // Perform Logic Reset
        await this.LogicReset();

        // Setup image sensor registers
        await this.SetupOptimizedRegisterSet();

        console.log("SYZYGY::Initialize() Complete");

        return await super.Initialize();
    }

    public override async SetGains(r: number, g1: number, g2: number, b: number): Promise<void> {
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_RED_GAIN, r & 0xffff);
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_GREEN1_GAIN, g1 & 0xffff);
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_GREEN2_GAIN, g2 & 0xffff);
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_BLUE_GAIN, b & 0xffff);
    }

    public override async SetShutterWidth(u32shutter: CameraShutterWidth): Promise<void> {
        const pix_clk_ns = 34;
        const shutter_ms: number = (u32shutter * 250) / 10000;

        const line_length_pck: number = await this._DeviceI2C.Read16(
            AR0330Device.AR0330_REG_LINE_LENGTH_PCK
        );

        const shutter_llpck: number = Math.floor(
            (shutter_ms * 1000000) / (line_length_pck * pix_clk_ns)
        );

        await this._DeviceI2C.Write16(
            AR0330Device.AR0330_REG_COARSE_INTEGRATION_TIME,
            shutter_llpck & 0xffff
        );
    }

    public override async SetSize(size: MatrixDimensions): Promise<void> {
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_X_ADDR_END, size.columnCount + 6 - 1);
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_Y_ADDR_END, size.rowCount + 124 - 1);

        console.log(
            "Size: columnCount=" + this.Size.columnCount + " rowCount=" + this.Size.rowCount
        );

        this.Size = size;

        console.log(
            "Size: columnCount=" + this.Size.columnCount + " rowCount=" + this.Size.rowCount
        );
    }

    public override async SetSkips(skips: MatrixDimensions): Promise<void> {
        if (skips.columnCount === 0) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_X_ODD_INC, 1);
        } else if (skips.columnCount === 1) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_X_ODD_INC, 3);
        } else if (skips.columnCount === 2) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_X_ODD_INC, 5);
        }

        if (skips.rowCount === 0) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_Y_ODD_INC, 1);
        } else if (skips.rowCount === 1) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_Y_ODD_INC, 3);
        } else if (skips.rowCount === 2) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_Y_ODD_INC, 5);
        }

        this.Skips = skips;

        //
        const frameBufferSize: ByteCount = this.FrameBufferSize;

        this.FrontPanel.setWireInValue(0x02, frameBufferSize & 0xffff, 0xffffffff);
        this.FrontPanel.setWireInValue(0x03, frameBufferSize >> 16, 0xffffffff);

        //
        await this.LogicReset();
    }

    public override async SetTestMode(enable: boolean, mode: TestMode): Promise<void> {
        if (!enable) {
            await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_PATTERN_MODE, 0x0);
        } else {
            switch (mode) {
                case TestMode.ColorField:
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_DATA_RED, 0x0dd0);
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_DATA_GREENR, 0x0ee0);
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_DATA_GREENB, 0x0ee0);
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_DATA_BLUE, 0x0bb0);
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_PATTERN_MODE, 0x1);
                    break;
                case TestMode.Classic:
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_PATTERN_MODE, 0x2);
                    break;
                case TestMode.Walking1s:
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_PATTERN_MODE, 0xff);
                    break;
                case TestMode.VerticalColorBars:
                    await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_PATTERN_MODE, 0x3);
                    break;
            }
        }
    }

    //
    protected async SetupOptimizedRegisterSet(): Promise<void> {
        // Setup sensor for 1080p 30fps
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_HISPI_CONTROL_STATUS, 0x8400); // hispi_control setting
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_SMIA_TEST, 0x1802); // Disable embedded Data
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_DATA_FORMAT_BITS, 0x0a0a); // Data Width
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_COMPRESSION, 0x0000); // Disable compression
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_DATAPATH_SELECT, 0x0210); // Datapath select
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_VT_PIX_CLK_DIV, 0x0005); // vt_pix_clk_div originally 0x0005
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_PLL_MULTIPLIER, 0x0031); // pll_multiplier originally 0x0031
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_OP_PIX_CLK_DIV, 0x000a); // op_pix_clk_div(data width)
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_COARSE_INTEGRATION_TIME, 0x0400); // Increase exposure 400 for sensor + lens, 20 for bare sensor
        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_ANALOG_GAIN, 0x0018); // Set gain to ISO 400

        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_TEST_PATTERN_MODE, 0x0000); // 1 = Solid color test pattern, 2 = vertical color bars

        await this._DeviceI2C.Write16(AR0330Device.AR0330_REG_MODE_SELECT, 0x0100); // Enable streaming
    }
}
