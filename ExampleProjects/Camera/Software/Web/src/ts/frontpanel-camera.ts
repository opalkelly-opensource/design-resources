import * as frontpanelWs from '@opalkelly/frontpanel-ws';
import { CameraError, CameraErrorCode } from './camera-error';

export const IMAGE_BUFFER_DEPTH_MAX = 1023;
export const IMAGE_BUFFER_DEPTH_MIN = 5;
export const IMAGE_BUFFER_DEPTH_AUTO = -1;
const ONE_MEBIBYTE = 1024 * 1024;
const MT9P031_DEFAULT_WIDTH = 2592;
const MT9P031_DEFAULT_HEIGHT = 1944;
const AR0330_DEFAULT_WIDTH = 2304;
const AR0330_DEFAULT_HEIGHT = 1296;

export enum TestMode {
    ColorField = 0,
    HorizontalGradient = 1,
    VerticalGradient = 2,
    DiagonalGradient = 3,
    Classic = 4,
    Walking1s = 5,
    MonochromeHorizontalBars = 6,
    MonochromeVerticalBars = 7,
    VerticalColorBars = 8
}

export interface ISize {
    width: number;
    height: number;
}

function _fillAlpha(width: number, height: number, dst: Uint8ClampedArray) {
    const alpha = 0xff;
    for (let y = 0; y < height; y++) {
        const rowOffset = y * width * 4;
        for (let x = 0; x < width; x++) {
            dst[rowOffset + x * 4 + 3] = alpha;
        }
    }
}

/**
 * Transform raw Bayer data from the camera into RGBA:
 *
 * ```
 *  +---+---+       +---+---+
 *  + g + r +       + c + c +
 *  +---+---+ ----> +---+---+
 *  + b + h +       + d + d +
 *  +---+---+       +---+---+
 * ```
 *
 * where c=RGB(r,g,b) and d=RGB(r,h,b).
 */
export function bayerToRGBA(
    width: number,
    height: number,
    src: Uint8Array,
    dst: Uint8ClampedArray
) {
    let srcThisRow = 0;
    let dstThisRow = 0;
    for (let y = 0; y < height / 2; y++) {
        let srcNextRow = srcThisRow + width;
        let dstNextRow = dstThisRow + 4 * width; // RGBA => *4

        for (let x = 0; x < width / 2; x++) {
            const g = src[srcThisRow++];
            const r = src[srcThisRow++];
            const b = src[srcNextRow++];
            const h = src[srcNextRow++];

            for (let n = 0; n < 2; n++) {
                dst[dstThisRow++] = r;
                dst[dstThisRow++] = g;
                dst[dstThisRow++] = b;
                // Skip the alpha.
                dstThisRow++;

                dst[dstNextRow++] = r;
                dst[dstNextRow++] = h;
                dst[dstNextRow++] = b;
                // Skip the alpha.
                dstNextRow++;
            }
        }

        srcThisRow = srcNextRow;
        dstThisRow = dstNextRow;
    }

    _fillAlpha(width, height, dst);
}

/**
 * Fill the image data with exact pixels as Bayer pattern.
 */
export function fillBayerData(
    width: number,
    height: number,
    src: Uint8Array,
    dst: Uint8ClampedArray
) {
    let dstIndex = 0;
    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            let r: number;
            let g: number;
            let b: number;
            // Use exact pixels as Bayer pattern
            if (x % 2 === 1 && y % 2 === 0) {
                // Red
                r = src[x + y * width];
                g = 0;
                b = 0;
            } else if (x % 2 === 0 && y % 2 === 1) {
                // Blue
                r = 0;
                g = 0;
                b = src[x + y * width];
            } else {
                // Green
                r = 0;
                g = Math.trunc(src[x + y * width] * 0.75);
                b = 0;
            }

            dst[dstIndex++] = r;
            dst[dstIndex++] = g;
            dst[dstIndex++] = b;
            // Skip the alpha.
            dstIndex++;
        }
    }

    _fillAlpha(width, height, dst);
}

/**
 * Transform raw Bayer data from the camera into mono (grayscale) image.
 */
export function bayerToMono(
    width: number,
    height: number,
    src: Uint8Array,
    dst: Uint8ClampedArray
) {
    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const baseDstIndex = 4 * (x + y * width);
            dst[baseDstIndex] = dst[baseDstIndex + 1] = dst[baseDstIndex + 2] =
                src[x + y * width];
        }
    }

    _fillAlpha(width, height, dst);
}

export class Camera {
    /**
     * The instance of [[FrontPanel]]. Throws an exception if the variable is
     * `undefined` (use [[initialize]] to initialize it).
     */
    get dev(): frontpanelWs.FrontPanel {
        if (this._dev === undefined) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'The camera is not initialized'
            );
        }
        return this._dev;
    }

    /**
     * The script engine id. Throws an exception if the variable is
     * `undefined` (use [[initialize]] to initialize it).
     */
    get scriptEngine(): number {
        if (this._scriptEngine === undefined) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'The camera is not initialized'
            );
        }
        return this._scriptEngine;
    }

    /**
     * The final width of the image calculated from the real image size
     * and the value of skipped pixels.
     * See [[setSize]], [[setSkips]].
     */
    get width(): number {
        return Camera._getLengthWithSkips(this._xSize, this._xSkip);
    }

    /**
     * The final height of the image calculated from the real image size
     * and the value of skipped pixels.
     * See [[setSize]], [[setSkips]].
     */
    get height(): number {
        return Camera._getLengthWithSkips(this._ySize, this._ySkip);
    }

    public static getMinDepth(): number {
        return IMAGE_BUFFER_DEPTH_MIN;
    }

    /**
     * Returns the name of the bit file for the given device or `undefined`
     * if the board is not supported.
     */
    public static async getBitfileName(
        dev: frontpanelWs.FrontPanel
    ): Promise<string | undefined> {
        const deviceInfo = await dev.getDeviceInfo();

        switch (deviceInfo.productID) {
            case frontpanelWs.ProductID.PRODUCT_XEM6006LX9:
                return 'evb1006-xem6006-lx9.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM6006LX16:
                return 'evb1006-xem6006-lx16.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM6006LX25:
                return 'evb1006-xem6006-lx25.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM6010LX45:
                return 'evb1005-xem6010-lx45.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM6010LX150:
                return 'evb1005-xem6010-lx150.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7010A50:
                return 'evb1005-xem7010-a50.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7010A200:
                return 'evb1005-xem7010-a200.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM6310LX45:
                return 'evb1005-xem6310-lx45.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM6310LX150:
                return 'evb1005-xem6310-lx150.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7310A75:
                return 'evb1005-xem7310-a75.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7310A200:
                return 'evb1005-xem7310-a200.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7320A75T:
                return 'szg-camera-xem7320-a75.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7350K70T:
                return 'evb1006-xem7350-k70t.bit';
            case frontpanelWs.ProductID.PRODUCT_XEM7350K160T:
                return 'evb1006-xem7350-k160t.bit';
            case frontpanelWs.ProductID.PRODUCT_ZEM4310:
                return 'evb1007-zem4310.rbf';
        }

        return undefined;
    }

    /**
     * Get the size from the full size when using the specified skip values.
     */
    public static getSizeWithSkips(
        fullSize: ISize,
        xSkips: number,
        ySkips: number
    ): ISize {
        return {
            width: Camera._getLengthWithSkips(fullSize.width, xSkips),
            height: Camera._getLengthWithSkips(fullSize.height, ySkips)
        };
    }

    private static _getLengthWithSkips(
        fullLength: number,
        skips: number
    ): number {
        return 2 * Math.ceil(fullLength / (2 * (skips + 1)));
    }

    private _dev?: frontpanelWs.FrontPanel;
    private _scriptEngine?: number;

    private _isSZGCamera = false;
    private _xSize = 0;
    private _ySize = 0;
    private _xSkip = 0;
    private _ySkip = 0;
    private _bytesPerPixel = 1;

    // The HDL Version is pulled as a single Wire Output from the HDL.
    // The lower 8-bits represent the minor version while the upper 8-bits are
    // used to represent the major version (ie Version 2.4 is 0x0204)
    private _HDLVersion = 0;
    private _memSize = 0;
    private _imageBufferDepth = IMAGE_BUFFER_DEPTH_AUTO;

    /**
     * Initialize the camera object with the opened device. No real work done
     * here.
     *
     * Note that the device should be already configured with the correct
     * bit file.
     *
     * @param dev The configured device.
     * @param luaScriptPath Path to the camera Lua script.
     */
    public async initialize(
        dev: frontpanelWs.FrontPanel,
        scriptEngine: number,
        scriptPath: string,
        scriptContent: string
    ): Promise<void> {
        this._dev = dev;
        this._scriptEngine = scriptEngine;

        const deviceInfo = await this._dev.getDeviceInfo();
        switch (deviceInfo.productID) {
            case frontpanelWs.ProductID.PRODUCT_XEM6006LX9:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM6006LX16:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM6006LX25:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM6010LX45:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM6010LX150:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7010A50:
                this._memSize = 512 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7010A200:
                this._memSize = 512 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM6310LX45:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM6310LX150:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7310A75:
                this._memSize = 1024 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7310A200:
                this._memSize = 1024 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7320A75T:
                this._memSize = 1024 * ONE_MEBIBYTE;
                this._isSZGCamera = true;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7350K70T:
                this._memSize = 512 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_XEM7350K160T:
                this._memSize = 512 * ONE_MEBIBYTE;
                break;
            case frontpanelWs.ProductID.PRODUCT_ZEM4310:
                this._memSize = 128 * ONE_MEBIBYTE;
                break;

            default:
                throw new frontpanelWs.FrontPanelError(
                    frontpanelWs.ErrorCode.Failed,
                    'Unknown device model'
                );
        }

        await this._dev.loadScript(scriptEngine, scriptPath, scriptContent);

        const initResult = await this._runScriptFunction('InitAfterConfigure');
        this._HDLVersion = initResult[0] as number;
        if (this._HDLVersion === -1) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'Failed to retrieve HDL version'
            );
        } else if (this._HDLVersion < 0x0200) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                `HDL version ${this._HDLVersion} is too old and not supported`
            );
        }

        await this.setImageBufferDepth(IMAGE_BUFFER_DEPTH_AUTO);

        // Turn off the programmable empty setting in hardware, this is not used in
        // this implementation.
        this.dev.setWireInValue(0x04, 0, 0xfff);
        await this.dev.updateWireIns();

        // Init the size.
        const size = this.getDefaultSize();
        this._xSize = size.width;
        this._ySize = size.height;
    }

    public getDefaultSize(): ISize {
        if (this._isSZGCamera) {
            return {
                width: AR0330_DEFAULT_WIDTH,
                height: AR0330_DEFAULT_HEIGHT
            };
        }
        return {
            width: MT9P031_DEFAULT_WIDTH,
            height: MT9P031_DEFAULT_HEIGHT
        };
    }

    public async logicReset(): Promise<void> {
        await this._runScriptFunction('LogicReset');
    }

    public getSupportedSkips(): number[] {
        if (this._isSZGCamera) {
            return [0, 1, 2];
        }
        return [0, 1, 3];
    }

    public getSupportedTestModes(): TestMode[] {
        if (this._isSZGCamera) {
            return [
                TestMode.ColorField,
                TestMode.Classic,
                TestMode.Walking1s,
                TestMode.VerticalColorBars
            ];
        }
        return [
            TestMode.ColorField,
            TestMode.HorizontalGradient,
            TestMode.VerticalGradient,
            TestMode.DiagonalGradient,
            TestMode.Classic,
            TestMode.Walking1s,
            TestMode.MonochromeHorizontalBars,
            TestMode.MonochromeVerticalBars,
            TestMode.VerticalColorBars
        ];
    }

    /**
     * Whether [[setOffsets]] supported by the sensor.
     */
    public SupportsOffsets(): boolean {
        return !this._isSZGCamera;
    }

    public async setTestMode(
        enable: boolean,
        mode: TestMode = TestMode.VerticalColorBars
    ): Promise<void> {
        await this._runScriptFunction('SetTestMode', enable, mode);
    }

    public async setGains(
        r: number,
        g1: number,
        g2: number,
        b: number
    ): Promise<void> {
        await this._runScriptFunction('SetGains', r, g1, g2, b);
    }

    public async setOffsets(
        r: number,
        g1: number,
        g2: number,
        b: number
    ): Promise<void> {
        if (!this.SupportsOffsets()) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                `The camera sensor doesn't support setOffsets()`
            );
        }
        await this._runScriptFunction('SetOffsets', r, g1, g2, b);
    }

    public async setShutterWidth(shutter: number): Promise<void> {
        await this._runScriptFunction('SetShutterWidth', shutter);
    }

    public async setSize(x: number, y: number): Promise<void> {
        this._xSize = x;
        this._ySize = y;

        await this._runScriptFunction('SetSize', x, y);
    }

    public async setSkips(x: number, y: number): Promise<void> {
        this._xSkip = x;
        this._ySkip = y;

        // We want to ensure that any changes to resolution haven't reduced
        // our available buffers. If so, shrink the number of buffers to match.
        await this.setImageBufferDepth(this._imageBufferDepth);

        const bufferSize = this.getFrameBufferSize();
        await this._runScriptFunction('SetSkips', x, y, bufferSize);
    }

    /**
     * Check the provided depth against the maximum number of available
     * buffers. If there are not enough buffers allocate as many as possible.
     */
    public async setImageBufferDepth(depth: number): Promise<void> {
        const maxFrames = this.getMaxDepthForResolution();
        let frames;
        if (depth === IMAGE_BUFFER_DEPTH_AUTO) {
            frames = Math.max(maxFrames, IMAGE_BUFFER_DEPTH_MIN);
        } else if (
            depth > IMAGE_BUFFER_DEPTH_MAX ||
            depth < IMAGE_BUFFER_DEPTH_MIN
        ) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                `Invalid depth value ${depth}`
            );
        } else {
            // The depth is within the acceptable range and is not AUTO, so pass it on
            frames = Math.min(depth, maxFrames);
        }

        await this._runScriptFunction('SetImageBufferDepth', frames);

        this._imageBufferDepth = depth;
    }

    public async enablePingPong(enable: boolean): Promise<void> {
        await this._runScriptFunction('EnablePingPong', enable);
    }

    public getFrameBufferSize(): number {
        let len = this.width * this.height * this._bytesPerPixel;

        // Round up to 256 (burst length * 8 bytes)
        len += 256 - (len % 256);

        return len;
    }

    /**
     * Helper function used to provide the maximum Depth value for the current
     * resolution.
     */
    public getMaxDepthForResolution(): number {
        const frameSize = this.getFrameBufferSize();
        let maxDepth = 0;

        if (frameSize > 0) {
            // We subtract two from the maximum number of buffers that can be stored
            // in DRAM (given by MEM_SIZE/FRAME_SIZE) to account for the buffers
            // reserved by the read and write paths.
            maxDepth = Math.ceil(this._memSize / frameSize - 2);
        }

        return Math.min(maxDepth, IMAGE_BUFFER_DEPTH_MAX);
    }

    public async getBufferedImageCount(): Promise<number> {
        const result = await this._runScriptFunction('GetBufferedImageCount');

        const count = result[0];
        if (typeof count !== 'number') {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'Failed to get buffered images count'
            );
        }

        return count as number;
    }

    public async singleCapture(): Promise<Uint8Array> {
        if ((this._HDLVersion & 0xff00) >= 0x0200) {
            return this._doCapture('BufferedCaptureV2');
        }
        return this._doCapture('SingleCaptureV1');
    }

    public async bufferedCapture(): Promise<Uint8Array> {
        if ((this._HDLVersion & 0xff00) >= 0x0200) {
            return this._doCapture('BufferedCaptureV2');
        }
        return this._doCapture('BufferedCaptureV1');
    }

    private async _doCapture(func: string): Promise<Uint8Array> {
        const len = this.getFrameBufferSize();

        const result = await this._runScriptFunction(func, len);

        if (result.length !== 1) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'Failed to capture image'
            );
        }

        if (typeof result[0] === 'number') {
            const err = result[0] as number;
            if (err > 0 || err < -4) {
                // Invalid error value, replace it with a generic error.
                throw new frontpanelWs.FrontPanelError(
                    frontpanelWs.ErrorCode.Failed,
                    'Failed to capture image'
                );
            }

            throw new CameraError(
                err,
                `Failed to capture image with code ${CameraErrorCode[err]}`
            );
        }

        return result[0] as Uint8Array;
    }

    private async _runScriptFunction(
        name: string,
        ...args: any
    ): Promise<any[]> {
        return this.dev.runScriptFunction(this.scriptEngine, name, ...args);
    }
}
