import { ByteCount } from "@opalkelly/frontpanel-alloy-core";

/**
 * Interface for matrix row and column dimensions.
 */
export interface IMatrixDimensions {
    rowCount: number;
    columnCount: number;
}

/**
 * Type representing the index of a matrix row.
 */
export type MatrixRowIndex = number;

/**
 * Type representing the index of a matrix column.
 */
export type MatrixColumnIndex = number;

/**
 * Enumeration for the byte alignment of matrix rows.
 */
export enum RowAlignmentBytes {
    Unspecified = 0,
    Bytes_None = 1,
    Bytes_8 = 8,
    Bytes_4 = 4,
    Bytes_2 = 2
}

/**
 * Type representing the data for a matrix row.
 */
export type DataRow = {
    index: number;
    data: Uint8Array;
};

/**
 * Class representing the data for a matrix.
 */
export class MatrixData {
    private readonly _Data: ArrayBuffer;

    private _Dimensions: IMatrixDimensions;

    private _RowDataSize: ByteCount;
    private _RowStride: ByteCount;

    private _RowAlignment: RowAlignmentBytes;

    private _ColumnWidth: ByteCount;

    constructor(data: ArrayBuffer) {
        this._Data = data;
        this._Dimensions = { columnCount: 0, rowCount: 0 };

        this._RowDataSize = 0;
        this._RowStride = 0;
        this._RowAlignment = RowAlignmentBytes.Unspecified;

        this._ColumnWidth = 0;
    }

    //
    get Data() {
        return this._Data;
    }

    get DataSize() {
        return this._Data.byteLength;
    }

    get Dimensions() {
        return this._Dimensions;
    }

    get RowDataSize() {
        return this._RowDataSize;
    }

    get RowStride() {
        return this._RowStride;
    }

    get RowAlignment() {
        return this._RowAlignment;
    }

    get ColumnWidth() {
        return this._ColumnWidth;
    }

    //
    public Initialize(
        dimensions: IMatrixDimensions,
        columnWidth: ByteCount,
        rowAligment: RowAlignmentBytes
    ) {
        const rowDataSize: ByteCount = dimensions.columnCount * columnWidth;
        const unalignedByteCount: ByteCount = rowDataSize % rowAligment;

        const rowStride: ByteCount =
            unalignedByteCount === 0
                ? rowDataSize
                : rowDataSize + (rowAligment - unalignedByteCount);

        const targetSize: ByteCount = dimensions.rowCount * rowStride;

        if (targetSize <= this._Data.byteLength) {
            this._Dimensions = dimensions;

            this._RowDataSize = rowDataSize;
            this._RowStride = rowStride;
            this._RowAlignment = rowAligment;

            this._ColumnWidth = columnWidth;
        }
    }

    //
    public GetRow(rowIndex: MatrixRowIndex): DataRow | undefined {
        let targetRow: DataRow | undefined;

        if (rowIndex < this._Dimensions.rowCount) {
            targetRow = {
                index: rowIndex,
                data: new Uint8Array(this._Data, this._RowStride * rowIndex, this._RowDataSize)
            };
        } else {
            targetRow = undefined;
        }

        return targetRow;
    }

    //
    public static ComputeDataSize(
        dimensions: IMatrixDimensions,
        columnWidth: ByteCount,
        rowAlignment: RowAlignmentBytes
    ): ByteCount {
        let targetRowStride: ByteCount = dimensions.columnCount * columnWidth;

        const unalignedByteCount: ByteCount = targetRowStride % rowAlignment;

        if (unalignedByteCount > 0) {
            targetRowStride += rowAlignment - unalignedByteCount;
        }

        return dimensions.rowCount * targetRowStride;
    }
}
