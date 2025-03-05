/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, RefObject } from "react";

import { MatrixData, DataRow, RowAlignmentBytes } from "./MatrixData";

import { ColorElementMatrix, ColorElementType, ColorRGBA8DataRow } from "./ColorElementMatrix";

/**
 * Enumeration for the different display modes for the frame image.
 */
export enum FrameDisplayMode {
    None,
    RGB,
    RawBayer,
    RawMono
}

/**
 * Properties for the CanvasView component.
 */
export interface CanvasViewProps {
    width: number;
    height: number;

    frameDisplayMode: FrameDisplayMode;
}

/**
 * Class representing a canvas view component that renders Bayer row and column
 * matrix data.
 */
class CanvasView extends Component<CanvasViewProps> {
    private _CanvasRef: RefObject<HTMLCanvasElement>;

    constructor(props: CanvasViewProps) {
        super(props);

        this._CanvasRef = React.createRef();
    }

    componentDidMount() {
        this.ClearFrameImage();
    }

    componentDidUpdate(
        prevProps: Readonly<CanvasViewProps>,
        _prevState: Readonly<NonNullable<unknown>>,
        _snapshot?: NonNullable<unknown>
    ): void {
        if (this.props.width !== prevProps.width || this.props.height !== prevProps.height) {
            this.ClearFrameImage();
        }
    }

    render() {
        return <canvas ref={this._CanvasRef} width={this.props.width} height={this.props.height} />;
    }

    /**
     * Clears the frame image on the canvas.
     */
    public ClearFrameImage() {
        const canvas: HTMLCanvasElement | null = this._CanvasRef.current;

        if (canvas != null) {
            const context: CanvasRenderingContext2D | null = canvas.getContext("2d");

            if (context != null) {
                context.fillStyle = "black";
                context.fillRect(0, 0, canvas.width, canvas.height);
            }
        }
    }

    /**
     * Updates the frame image on the canvas to display the specified data.
     * @param data - The data to display on the canvas.
     */
    public UpdateFrameImage(data: MatrixData) {
        const canvas: HTMLCanvasElement | null = this._CanvasRef.current;

        if (canvas != null) {
            const context: CanvasRenderingContext2D | null = canvas.getContext("2d", {
                alpha: false
            });

            if (context != null) {
                const frameImageData: ImageData = context.createImageData(
                    data.Dimensions.columnCount,
                    data.Dimensions.rowCount
                );

                if (this.props.frameDisplayMode !== FrameDisplayMode.None) {
                    // Create a ColorElementMatrix and attach the frameImageData data buffer to it.
                    const targetData: ColorElementMatrix = new ColorElementMatrix(
                        frameImageData.data.buffer
                    );

                    targetData.Initialize(
                        { columnCount: frameImageData.width, rowCount: frameImageData.height },
                        ColorElementType.RGBA_8,
                        RowAlignmentBytes.Bytes_None
                    );

                    //console.log('Frame image data dimensions: size=' + frameImageData.data.byteLength + ' columnCount=' + frameImageData.width + ' rowCount=' + frameImageData.height);

                    //const startTimeStamp: number = performance.now();

                    switch (this.props.frameDisplayMode) {
                        case FrameDisplayMode.RGB:
                            CanvasView.BayerToRGBA(data, targetData);
                            break;
                        case FrameDisplayMode.RawMono:
                            CanvasView.BayerToMonoRGBA(data, targetData);
                            break;
                        case FrameDisplayMode.RawBayer:
                            CanvasView.BayerToRawRGBA(data, targetData);
                            break;
                    }

                    //const elapsedTime: number = performance.now() - startTimeStamp;

                    //console.log('BayerFilter ElapsedTime=' + elapsedTime);
                }

                context.putImageData(frameImageData, 0, 0);
            }
        }
    }

    //private TestRGBA(target: ColorElementMatrix) {

    //    const colors: ColorRGBA[] = [];

    //    colors.push({ red: 0xff, green: 0x00, blue: 0x00, alpha: 0xff });
    //    colors.push({ red: 0x00, green: 0xff, blue: 0x00, alpha: 0xff });
    //    colors.push({ red: 0x00, green: 0x00, blue: 0xff, alpha: 0xff });
    //    colors.push({ red: 0x00, green: 0xff, blue: 0xff, alpha: 0xff });

    //    //const columnsPerBar: number = target.Dimensions.columnCount / colors.length;
    //    const columnsPerBar: number = 50;

    //    for (let rowIndex = 0; rowIndex < target.Dimensions.rowCount; rowIndex++) {

    //        const targetRow: ColorRGBA8DataRow | undefined = target.GetColorRGBARow(rowIndex);

    //        for (let columnIndex = 0; columnIndex < target.Dimensions.columnCount; columnIndex++) {

    //            const colorIndex = Math.floor(columnIndex / columnsPerBar) % colors.length;
    //            const columnColor = colors[colorIndex];
    //            targetRow?.SetColor(columnIndex, columnColor.red, columnColor.green, columnColor.blue);
    //        }
    //    }
    //}

    /**
     * Converts the Bayer data to RGBA data.
     * @param source - The source Bayer data.
     * @param target - The target RGBA data.
     */
    private static BayerToRGBA(source: MatrixData, target: ColorElementMatrix) {
        const sourceArray: Uint8Array = new Uint8Array(source.Data);
        const targetArray: Uint8Array = new Uint8Array(target.Data);

        let srcThisRow = 0;
        let dstThisRow = 0;

        for (let y = 0; y < target.Dimensions.rowCount / 2; y++) {
            let srcNextRow = srcThisRow + source.RowStride;
            let dstNextRow = dstThisRow + target.RowStride; // RGBA => *4

            for (let x = 0; x < target.Dimensions.columnCount / 2; x++) {
                const g = sourceArray[srcThisRow++];
                const r = sourceArray[srcThisRow++];
                const b = sourceArray[srcNextRow++];
                const h = sourceArray[srcNextRow++];

                for (let n = 0; n < 2; n++) {
                    targetArray[dstThisRow++] = r;
                    targetArray[dstThisRow++] = g;
                    targetArray[dstThisRow++] = b;
                    targetArray[dstThisRow++] = 0xff;

                    targetArray[dstNextRow++] = r;
                    targetArray[dstNextRow++] = h;
                    targetArray[dstNextRow++] = b;
                    targetArray[dstNextRow++] = 0xff;
                }
            }

            srcThisRow = srcNextRow;
            dstThisRow = dstNextRow;
        }
    }

    /**
     * Converts the Bayer data to Monochrome RGBA data.
     * @param source - The source Bayer data.
     * @param target - The target Monochrome RGBA data.
     */
    private static BayerToMonoRGBA(source: MatrixData, target: ColorElementMatrix) {
        for (let rowIndex = 0; rowIndex < target.Dimensions.rowCount; rowIndex++) {
            const sourceRow: DataRow | undefined = source.GetRow(rowIndex);
            const targetRow: ColorRGBA8DataRow | undefined = target.GetColorRGBARow(rowIndex);

            for (let columnIndex = 0; columnIndex < target.Dimensions.columnCount; columnIndex++) {
                const value: number = sourceRow?.data[columnIndex] ?? 0x00;

                targetRow?.SetColor(columnIndex, value, value, value);
            }
        }
    }

    /**
     * Converts the Bayer data to Raw RGBA data.
     * @param source - The source Bayer data.
     * @param target - The target Raw RGBA data.
     */
    private static BayerToRawRGBA(source: MatrixData, target: ColorElementMatrix) {
        const sourceArray: Uint8Array = new Uint8Array(source.Data);
        const targetArray: Uint8Array = new Uint8Array(target.Data);

        let srcThisRow = 0;
        let dstThisRow = 0;

        for (let rowIndex = 0; rowIndex < target.Dimensions.rowCount; rowIndex++) {
            const srcNextRow = srcThisRow + source.RowStride;
            const dstNextRow = dstThisRow + target.RowStride; // RGBA => *4

            for (let columnIndex = 0; columnIndex < target.Dimensions.columnCount; columnIndex++) {
                if (columnIndex % 2 === 1 && rowIndex % 2 === 0) {
                    // Red

                    targetArray[dstThisRow++] = sourceArray[srcThisRow + columnIndex];
                    targetArray[dstThisRow++] = 0;
                    targetArray[dstThisRow++] = 0;
                    targetArray[dstThisRow++] = 0xff;
                } else if (columnIndex % 2 === 0 && rowIndex % 2 === 1) {
                    // Blue

                    targetArray[dstThisRow++] = 0;
                    targetArray[dstThisRow++] = 0;
                    targetArray[dstThisRow++] = sourceArray[srcThisRow + columnIndex];
                    targetArray[dstThisRow++] = 0xff;
                } else {
                    // Green

                    targetArray[dstThisRow++] = 0;
                    targetArray[dstThisRow++] = sourceArray[srcThisRow + columnIndex] * 0.75;
                    targetArray[dstThisRow++] = 0;
                    targetArray[dstThisRow++] = 0xff;
                }
            }

            srcThisRow = srcNextRow;
            dstThisRow = dstNextRow;
        }
    }
}

export default CanvasView;
