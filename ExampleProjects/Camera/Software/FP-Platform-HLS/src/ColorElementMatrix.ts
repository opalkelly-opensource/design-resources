/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { ByteCount } from "@opalkelly/frontpanel-platform-api";

import {
    MatrixData,
    IMatrixDimensions,
    RowAlignmentBytes,
    MatrixRowIndex,
    DataRow
} from "./MatrixData";

/**
 * Enumeration for the different color element types.
 */
export enum ColorElementType {
    Unspecified,
    // 8-bit color element types
    RGB_8,
    RGBA_8,
    GRAYSCALE_8,
    // 16-bit color element types
    RGB_16,
    RGBA_16,
    GRAYSCALE_16
}

/**
 * Class representing a row of color RGBA8 data.
 */
export class ColorRGBA8DataRow {
    private readonly _DataRow: DataRow;

    constructor(data: DataRow) {
        this._DataRow = data;
    }

    /**
     * Sets the color of the pixel at the specified index of the row.
     * @param index - The index of the pixel.
     * @param red - The red color component.
     * @param green - The green color component.
     * @param blue - The blue color component.
     * @param alpha - The alpha color component.
     */
    public SetColor(index: number, red: number, green: number, blue: number, alpha = 0xff) {
        const byteOffset: ByteCount = index * 4;

        this._DataRow.data[byteOffset] = red;
        this._DataRow.data[byteOffset + 1] = green;
        this._DataRow.data[byteOffset + 2] = blue;
        this._DataRow.data[byteOffset + 3] = alpha;
    }
}

/**
 * Class representing a row and column matrix of color elements.
 */
export class ColorElementMatrix extends MatrixData {
    private readonly _ElementType: ColorElementType;

    constructor(data: ArrayBufferLike) {
        super(data);

        this._ElementType = ColorElementType.Unspecified;
    }

    /**
     * Gets the color element type of the elements in the matrix.
     */
    get ElementType() {
        return this._ElementType;
    }

    /**
     * Initializes the matrix with the specified dimensions, element type, and row alignment.
     * @param dimensions - The row and column dimensions of the matrix.
     * @param elementType - The color element type.
     * @param rowAligment - The row alignment.
     */
    public Initialize(
        dimensions: IMatrixDimensions,
        elementType: ColorElementType,
        rowAligment: RowAlignmentBytes
    ) {
        const elementSize: ByteCount = ColorElementMatrix.GetSizeOfElement(elementType);

        super.Initialize(dimensions, elementSize, rowAligment);
    }

    /**
     * Retrieves the row of color RGBA8 data elements at the specified row index.
     * @param rowIndex - The index of the row to retrieve.
     * @returns - The row of color RGBA8 data elements.
     */
    public GetColorRGBARow(rowIndex: MatrixRowIndex): ColorRGBA8DataRow | undefined {
        const dataRow: DataRow | undefined = super.GetRow(rowIndex);

        if (dataRow !== undefined) {
            return new ColorRGBA8DataRow(dataRow);
        } else {
            return undefined;
        }
    }

    /**
     * Calculates the size of a color element of the specified type, measured in bytes.
     * @param elementType - The color element type.
     * @returns - The size of a color element, measured in bytes.
     */
    public static GetSizeOfElement(elementType: ColorElementType): ByteCount {
        let retval: ByteCount;

        switch (elementType) {
            //
            case ColorElementType.RGB_8:
                retval = 3;
                break;
            case ColorElementType.RGBA_8:
                retval = 4;
                break;
            case ColorElementType.GRAYSCALE_8:
                retval = 1;
                break;
            //
            case ColorElementType.RGB_16:
                retval = 6;
                break;
            case ColorElementType.RGBA_16:
                retval = 8;
                break;
            case ColorElementType.GRAYSCALE_16:
                retval = 2;
                break;
            //
            default:
                retval = 0;
                break;
        }

        return retval;
    }

    /**
     * Calculates the size of the data in the matrix, measured in bytes.
     * @param dimensions - The row and column dimensions of the matrix.
     * @param elementType - The color element type.
     * @param rowAlignment - The row alignment.
     */
    public static ComputeDataSize(
        dimensions: IMatrixDimensions,
        elementType: ColorElementType,
        rowAlignment: RowAlignmentBytes
    ): ByteCount {
        const elementSize: ByteCount = ColorElementMatrix.GetSizeOfElement(elementType);

        return MatrixData.ComputeDataSize(dimensions, elementSize, rowAlignment);
    }
}
