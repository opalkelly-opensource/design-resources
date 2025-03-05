/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFrontPanel, ByteCount } from "@opalkelly/frontpanel-platform-api";

import ICamera, {
    FrameConfiguration,
    FrameCaptureResult,
    FrameCaptureResultCode,
    FrameCount,
    TestMode,
    CameraShutterWidth,
    MatrixDimensions
} from "./ICamera";
import { IMatrixDimensions, MatrixData, RowAlignmentBytes } from "./MatrixData";

import { sleep } from "./Utilities";

const DEFAULT_MASK = 0xffffffff;

const ONE_MEBIBYTE = 1024 * 1024;

export const IMAGE_BUFFER_DEPTH_MAX = 1023;
export const IMAGE_BUFFER_DEPTH_MIN = 5;
export const IMAGE_BUFFER_DEPTH_AUTO = -1;

/**
 * Class representing the base for a FrontPanel camera device.
 */
export abstract class FrontPanelCamera implements ICamera {
    private readonly _FrontPanel: IFrontPanel;

    //
    // The HDL Version is pulled as a single Wire Output from the HDL.
    // The lower 8-bits represent the minor version while the upper 8-bits are
    // used to represent the major version (ie Version 2.4 is 0x0204)
    private _HDLVersion;
    private readonly _MemorySize;
    private _ImageBufferDepth: number;
    private _Size: IMatrixDimensions;
    private _Skips: IMatrixDimensions;
    private _FrameDimensions: IMatrixDimensions;

    constructor(frontpanel: IFrontPanel, size: IMatrixDimensions) {
        this._FrontPanel = frontpanel;
        this._HDLVersion = 0;
        this._MemorySize = 1024 * ONE_MEBIBYTE;
        this._ImageBufferDepth = IMAGE_BUFFER_DEPTH_AUTO;

        this._Size = size;
        this._Skips = { columnCount: 0, rowCount: 0 };
        this._FrameDimensions = FrontPanelCamera.CalculateFrameDimensions(this._Size, this._Skips);
    }

    // Accessor Methods
    protected get FrontPanel() {
        return this._FrontPanel;
    }

    public get HDLVersion() {
        return this._HDLVersion;
    }

    public get MemorySize() {
        return this._MemorySize;
    }

    public get ImageBufferDepth() {
        return this._ImageBufferDepth;
    }

    public get Size() {
        return this._Size;
    }

    protected set Size(size: IMatrixDimensions) {
        this._Size = size;
        this._FrameDimensions = FrontPanelCamera.CalculateFrameDimensions(this._Size, this._Skips);
    }

    public get Skips() {
        return this._Skips;
    }

    protected set Skips(skips: IMatrixDimensions) {
        this._Skips = skips;
        this._FrameDimensions = FrontPanelCamera.CalculateFrameDimensions(this._Size, this._Skips);
    }

    public get FrameDimensions(): IMatrixDimensions {
        return this._FrameDimensions;
    }

    public get FrameBufferSize() {
        let length: ByteCount = MatrixData.ComputeDataSize(
            this._FrameDimensions,
            4,
            RowAlignmentBytes.Bytes_None
        );

        // Round up to 256 (burst length * 8 bytes)
        length += 256 - (length % 256);

        console.log("FrameBufferSize length=" + length);

        return length;
    }

    // Abstract Accessor Methods
    public abstract get DefaultSize(): MatrixDimensions;
    public abstract get SupportedSkips(): MatrixDimensions[];
    public abstract get SupportedTestModes(): TestMode[];
    public abstract get SupportedFrameConfigurations(): FrameConfiguration[];

    // Operations
    public async Initialize(): Promise<number> {
        // Determine which version of HDL is in use
        await this._FrontPanel.updateWireOuts();

        this._HDLVersion = this._FrontPanel.getWireOutValue(0x3f);

        console.log("FrontPanelCamera::Initialize() Complete");

        return this._HDLVersion;
    }

    public async SetImageBufferDepth(depth: FrameCount): Promise<void> {
        const maxFrameCount = this.GetMaxDepth(this.FrameBufferSize);

        let frameCount;

        if (depth === IMAGE_BUFFER_DEPTH_AUTO) {
            frameCount = Math.max(maxFrameCount, IMAGE_BUFFER_DEPTH_MIN);
        } else if (depth > IMAGE_BUFFER_DEPTH_MAX || depth < IMAGE_BUFFER_DEPTH_MIN) {
            throw new Error(`Invalid depth value ${depth}`);
        } else {
            // The depth is within the acceptable range and is not AUTO, so pass it on
            frameCount = Math.min(depth, maxFrameCount);
        }

        // Set the bit #11 to switch to programmable mode and put the number of
        // frames to use in the lower 10 bits.
        this._FrontPanel.setWireInValue(0x05, 0x400 | frameCount, 0x7ff);

        // Notice that we don't need to call UpdateWireIns() before calling
        // LogicReset() as it will do it internally anyhow.
        await this.LogicReset();

        this._ImageBufferDepth = depth;
    }

    public GetCapabilities(): number {
        return this._FrontPanel.getWireOutValue(0x3e);
    }

    public async GetMissedFrameCount(): Promise<FrameCount> {
        await this._FrontPanel.updateWireOuts();

        return (this._FrontPanel.getWireOutValue(0x23)) & 0xff;
    }

    public async GetBufferedFrameCount(): Promise<FrameCount> {
        await this._FrontPanel.updateWireOuts();

        return this._FrontPanel.getWireOutValue(0x24);
    }

    public async LogicReset(): Promise<void> {
        this._FrontPanel.setWireInValue(0x00, 0x0008, 0x0008);
        await this._FrontPanel.updateWireIns();

        // Add a delay of 50 milliseconds
        await new Promise((resolve) => setTimeout(resolve, 50));

        this._FrontPanel.setWireInValue(0x00, 0x0000, 0x0008);
        await this._FrontPanel.updateWireIns();
    }

    public async EnablePingPong(enable: boolean): Promise<void> {
        if (enable) {
            this._FrontPanel.setWireInValue(0x00, 1 << 4, 1 << 4);
            await this._FrontPanel.updateWireIns();
        } else {
            this._FrontPanel.setWireInValue(0x00, 0 << 4, 1 << 4);
            await this._FrontPanel.updateWireIns();
        }

        // Reset things
        this._FrontPanel.setWireInValue(0x00, 1 << 3, 1 << 3);
        await this._FrontPanel.updateWireIns();

        // Add a delay of 50 milliseconds
        await new Promise((resolve) => setTimeout(resolve, 50));

        this._FrontPanel.setWireInValue(0x00, 0 << 3, 1 << 3);
        await this._FrontPanel.updateWireIns();
    }

    //
    public async SingleFrameCapture(): Promise<FrameCaptureResult> {
        const dataSize: ByteCount = this.FrameBufferSize;
        // const hist: ArrayBuffer = await this._FrontPanel.readFromPipeOut(0xa1, 1);
        // const uint32Array = new Uint32Array(hist);
        // console.log(uint32Array);
        if ((this._HDLVersion & 0xff00) >= 0x0200) {
            return this.BufferedCaptureV2(dataSize);
        } else {
            return this.SingleCaptureV1(dataSize);
        }
    }

    public async BufferedFrameCapture(): Promise<FrameCaptureResult> {
        const dataSize: ByteCount = this.FrameBufferSize;

        // const hist : ArrayBuffer = await this._FrontPanel.readFromPipeOut(0xa1, 256*4);
        // const uint32Array = new Uint32Array(hist);
        // const dataView = new Uint32Array(hist);
        // console.log(dataView);
        if ((this._HDLVersion & 0xff00) >= 0x0200) {
            return this.BufferedCaptureV2(dataSize);
        } else {
            return this.SingleCaptureV1(dataSize);
        }
    }

    //
    public async BufferedCaptureV1(ulLen: number): Promise<FrameCaptureResult> {
        await this._FrontPanel.updateWireOuts();
        let done: boolean = ((this._FrontPanel.getWireOutValue(0x23)) & 0x0300) > 0;

        for (let i = 1; i < 100 && !done; i++) {
            await sleep(2);
            await this._FrontPanel.updateWireOuts();

            done = ((this._FrontPanel.getWireOutValue(0x23)) & 0x0300) > 0;
        }

        if (!done) {
            return { result: FrameCaptureResultCode.Timeout, data: null };
        }

        let retval: FrameCaptureResult;

        const frameBufferId: number = this._FrontPanel.getWireOutValue(0x23);

        if ((frameBufferId & 0x0100) > 0) {
            // Frame ready(buffer A)
            this._FrontPanel.setWireInValue(0x04, 0x0000, 0xffffffff);
            this._FrontPanel.setWireInValue(0x05, 0x0000, 0xffffffff);
            await this._FrontPanel.updateWireIns();
            await this._FrontPanel.activateTriggerIn(0x40, 1);

            // Readout start trigger
            const data: ArrayBuffer = new ArrayBuffer(ulLen);

            await this._FrontPanel.readFromPipeOut(0xa0, ulLen, data);

            //     const hist: ArrayBuffer = await this._FrontPanel.readFromPipeOut(0xa1, 256*4);
            // const uint32Array = new Uint32Array(hist);
            // console.log(uint32Array);

            if (data.byteLength < 0) {
                return { result: FrameCaptureResultCode.ImageReadoutError, data: null };
            } else if (data.byteLength < ulLen) {
                return { result: FrameCaptureResultCode.ImageReadoutShort, data: null };
            }

            await this._FrontPanel.activateTriggerIn(0x40, 2); // Readout done(buffer A)

            const matrix: MatrixData = new MatrixData(data);

            matrix.Initialize(this.Size, 1, RowAlignmentBytes.Bytes_None);

            retval = { result: FrameCaptureResultCode.Success, data: matrix };
        } else if ((frameBufferId & 0x0200) > 0) {
            // Frame ready(buffer B)
            this._FrontPanel.setWireInValue(0x04, 0x0000, 0xffffffff);
            this._FrontPanel.setWireInValue(0x05, 0x0080, 0xffffffff);
            await this._FrontPanel.updateWireIns();
            await this._FrontPanel.activateTriggerIn(0x40, 1);

            //Readout start trigger
            const data: ArrayBuffer = new ArrayBuffer(ulLen);

            await this._FrontPanel.readFromPipeOut(0xa0, ulLen, data);

            //     const hist: ArrayBuffer = await this._FrontPanel.readFromPipeOut(0xa1, 256*4);
            // const uint32Array = new Uint32Array(hist);
            // console.log(uint32Array);

            if (data.byteLength < 0) {
                return { result: FrameCaptureResultCode.ImageReadoutError, data: null };
            } else if (data.byteLength < ulLen) {
                return { result: FrameCaptureResultCode.ImageReadoutShort, data: null };
            }

            await this._FrontPanel.activateTriggerIn(0x40, 3); // Readout done(buffer B)

            const matrix: MatrixData = new MatrixData(data);

            matrix.Initialize(this.Size, 1, RowAlignmentBytes.Bytes_None);

            retval = { result: FrameCaptureResultCode.Success, data: matrix };
        } else {
            retval = { result: FrameCaptureResultCode.Failure, data: null };
        }

        return retval;
    }
    public async SingleCaptureV1(ulLen: number): Promise<FrameCaptureResult> {
        //--PINGPONG = 0
        this._FrontPanel.setWireInValue(0x00, 0 << 4, 1 << 4);
        //--Set data length
        this._FrontPanel.setWireInValue(0x02, ulLen & 0xffff, DEFAULT_MASK);
        this._FrontPanel.setWireInValue(0x03, ulLen >> 16, DEFAULT_MASK);
        //--Readout address = 0x00000000
        this._FrontPanel.setWireInValue(0x04, 0x0000, DEFAULT_MASK);
        this._FrontPanel.setWireInValue(0x05, 0x0000, DEFAULT_MASK);
        await this._FrontPanel.updateWireIns();

        await this._FrontPanel.updateTriggerOuts();
        await this._FrontPanel.activateTriggerIn(0x40, 0); // Capture trigger

        //
        await this._FrontPanel.updateTriggerOuts();
        let done: boolean = this._FrontPanel.isTriggered(0x60, 1 << 0); // Frame done trigger

        for (let index = 1; index < 500 && !done; index++) {
            await sleep(1);
            await this._FrontPanel.updateTriggerOuts();

            done = this._FrontPanel.isTriggered(0x60, 1 << 0); // Frame done trigger
        }

        if (!done) {
            return { result: FrameCaptureResultCode.Timeout, data: null };
        }

        await this._FrontPanel.activateTriggerIn(0x40, 1); // Readout start trigger

        const data: ArrayBuffer = new ArrayBuffer(ulLen);

        await this._FrontPanel.readFromPipeOut(0xa0, ulLen, data);

        if (data.byteLength < 0) {
            return { result: FrameCaptureResultCode.ImageReadoutError, data: null };
        } else if (data.byteLength < ulLen) {
            return { result: FrameCaptureResultCode.ImageReadoutShort, data: null };
        }

        await this._FrontPanel.activateTriggerIn(0x40, 2); // Readout done trigger

        const matrix: MatrixData = new MatrixData(data);

        matrix.Initialize(this.Size, 1, RowAlignmentBytes.Bytes_None);

        return { result: FrameCaptureResultCode.Success, data: matrix };
    }

    //
    public async BufferedCaptureV2(ulLen: number): Promise<FrameCaptureResult> {
        await this._FrontPanel.updateWireOuts();
        let done: boolean = ((this._FrontPanel.getWireOutValue(0x23)) & 0x0100) !== 0; // Frame avail ?

        for (let index = 0; index < 100 && !done; index++) {
            await sleep(2);
            await this._FrontPanel.updateWireOuts();

            done = ((this._FrontPanel.getWireOutValue(0x23)) & 0x0100) !== 0; // Frame avail ?
        }

        if (!done) {
            return { result: FrameCaptureResultCode.Timeout, data: null };
        }

        await this._FrontPanel.activateTriggerIn(0x40, 0);

        const data: ArrayBuffer = new ArrayBuffer(ulLen);

        await this._FrontPanel.readFromPipeOut(0xa0, ulLen, data);

        if (data.byteLength < 0) {
            return { result: FrameCaptureResultCode.ImageReadoutError, data: null };
        } else if (data.byteLength < ulLen) {
            return { result: FrameCaptureResultCode.ImageReadoutShort, data: null };
        }

        await this._FrontPanel.activateTriggerIn(0x40, 1);

        //console.log('Read ' + data.byteLength + ' bytes.')
        //console.log('Size: columnCount=' + this.Size.columnCount + ' rowCount=' + this.Size.rowCount);

        const matrix: MatrixData = new MatrixData(data);

        matrix.Initialize(this.FrameDimensions, 1, RowAlignmentBytes.Bytes_None);

        return { result: FrameCaptureResultCode.Success, data: matrix };
    }

    public async readFromBuffer(length: number): Promise<ArrayBuffer> {
        try {
            const hist = new ArrayBuffer(length);
            await this._FrontPanel.readFromPipeOut(0xa1, length, hist);
            console.log("Data read from FPGA:", hist);
            return hist;
        } catch (error) {
            console.error("Error reading from FPGA:", error);
            throw error;
        }
    }

    // Abstract Methods
    public abstract SetGains(r: number, g1: number, g2: number, b: number): Promise<void>;
    public abstract SetShutterWidth(u32shutter: CameraShutterWidth): Promise<void>;
    public abstract SetSize(dimensions: MatrixDimensions): Promise<void>;
    public abstract SetSkips(dimensions: MatrixDimensions): Promise<void>;
    public abstract SetTestMode(enable: boolean, mode: TestMode): Promise<void>;

    // Assert all RESETs: System PLL, Image Sensor, Pixel Clock DCM, Logic.
    protected async AssertResets(): Promise<void> {
        //Assert all RESETs:
        // + System PLL
        // + Image Sensor
        // + Pixel Clock DCM
        // + Logic
        this._FrontPanel.setWireInValue(0x00, 0x000f, 0x000f);
        await this._FrontPanel.updateWireIns();
        await sleep(1);
        this._FrontPanel.setWireInValue(0x00, 0x0000, 0x0001); // Release system PLL RESET
        await this._FrontPanel.updateWireIns();
        await sleep(1);
        this._FrontPanel.setWireInValue(0x00, 0x0000, 0x0002); // Release image sensor RESET
        await this._FrontPanel.updateWireIns();
        await sleep(1);
        this._FrontPanel.setWireInValue(0x00, 0x0000, 0x0008); // Release logic RESET
        await this._FrontPanel.updateWireIns();
        await sleep(10);
    }

    // Release PIXCLK DCM RESET.
    protected async ReleaseResets(): Promise<void> {
        //Release PIXCLK DCM RESET
        await sleep(10);
        this._FrontPanel.setWireInValue(0x00, 0x0000, 0x0004);
        this._FrontPanel.setWireInValue(0x00, 0x0010, 0x0010);
        await this._FrontPanel.updateWireIns();
    }

    /**
     * Helper function used to provide the maximum Depth value for the current
     * resolution.
     */
    public GetMaxDepth(frameSize: ByteCount): number {
        let maxDepth = 0;

        if (frameSize > 0) {
            // We subtract two from the maximum number of buffers that can be stored
            // in DRAM (given by MEM_SIZE/FRAME_SIZE) to account for the buffers
            // reserved by the read and write paths.
            maxDepth = Math.ceil(this._MemorySize / frameSize - 2);
        }

        return Math.min(maxDepth, IMAGE_BUFFER_DEPTH_MAX);
    }

    // Static Methods
    public static CalculateFrameDimensions(size: IMatrixDimensions, skips: IMatrixDimensions) {
        const frameDimensions: IMatrixDimensions = {
            columnCount: FrontPanelCamera.GetLengthWithSkips(size.columnCount, skips.columnCount),
            rowCount: FrontPanelCamera.GetLengthWithSkips(size.rowCount, skips.rowCount)
        };

        return frameDimensions;
    }

    private static GetLengthWithSkips(fullLength: number, skips: number): number {
        return 2 * Math.ceil(fullLength / (2 * (skips + 1)));
    }
}
