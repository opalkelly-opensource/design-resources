/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

export function CalculateBitLength(value: bigint): number {
    let bitLength = 0;

    if (value > 0n) {
        let targetValue = value;

        while (targetValue > 0n) {
            targetValue >>= 1n; // Divide by 2
            bitLength++;
        }
    } else if (value === 0n) {
        bitLength = 1;
    }

    return bitLength;
}
