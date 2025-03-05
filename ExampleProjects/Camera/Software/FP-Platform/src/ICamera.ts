/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IMatrixDimensions, MatrixData } from "./MatrixData";

/**
 * Enumeration for the code representing the result of a frame capture operation.
 */
export enum FrameCaptureResultCode {
    Success = 0,
    Failure,
    Timeout,
    ImageReadoutError,
    ImageReadoutShort
}

/**
 * Type representing the result of a frame capture operation. The result code indicates
 * the outcome of the operation, and the data contains the captured frame data.
 */
export type FrameCaptureResult = {
    result: FrameCaptureResultCode;
    data: MatrixData | null;
};

/**
 * Type representing the configuration for a frame capture operation. The configuration
 * specifies the row and column dimensions of the frame to capture and skips specifies
 * the number of rows and columns of the sensor to skip for each pixel.
 */
export type FrameConfiguration = {
    dimensions: MatrixDimensions;
    skips: MatrixDimensions;
};

/**
 * Type representing a frame count.
 */
export type FrameCount = number;

/**
 * Enumeration for the different test modes that can be enabled on the camera.
 */
export enum TestMode {
    ColorField,
    Classic,
    Walking1s,
    VerticalColorBars
}

/**
 * Type representing the width of the camera shutter.
 */
export type CameraShutterWidth = number;

/**
 * Type representing the row and column dimensions of a matrix.
 */
export type MatrixDimensions = IMatrixDimensions;

/**
 * Interface for a camera device.
 */
interface ICamera {
    // Accessors
    get DefaultSize(): MatrixDimensions;
    get SupportedSkips(): MatrixDimensions[];
    get SupportedTestModes(): TestMode[];
    get SupportedFrameConfigurations(): FrameConfiguration[];

    // Methods
    Initialize(): Promise<number>;

    SetImageBufferDepth(frames: FrameCount): Promise<void>;
    SetGains(r: number, g1: number, g2: number, b: number): Promise<void>;
    SetShutterWidth(u32shutter: CameraShutterWidth): Promise<void>;
    SetSize(dimensions: MatrixDimensions): Promise<void>;
    SetSkips(dimensions: MatrixDimensions): Promise<void>;
    SetTestMode(enable: boolean, mode: TestMode): Promise<void>;

    GetMissedFrameCount(): Promise<FrameCount>;
    GetBufferedFrameCount(): Promise<FrameCount>;

    LogicReset(): Promise<void>;
    EnablePingPong(enable: boolean): Promise<void>;

    SingleFrameCapture(): Promise<FrameCaptureResult>;
    BufferedFrameCapture(): Promise<FrameCaptureResult>;
}

export default ICamera;
