/**
 * The camera error return codes.
 */
export enum CameraErrorCode {
    Failed = -1,
    Timeout = -2,
    ImageReadoutShort = -3,
    ImageReadoutError = -4
}

/**
 * The camera error class.
 */
export class CameraError extends Error {
    public readonly code: CameraErrorCode;
    public readonly reason: string;

    constructor(code: CameraErrorCode, reason: string) {
        super(`${reason}: ${CameraErrorCode[code]}`);

        this.code = code;
        this.reason = reason;

        // Set the prototype explicitly.
        // See: https://github.com/microsoft/TypeScript-wiki/blob/adb1638fb20073df92b3d4bbd3821c9b78316faa/Breaking-Changes.md#extending-built-ins-like-error-array-and-map-may-no-longer-work
        Object.setPrototypeOf(this, CameraError.prototype);
    }
}
