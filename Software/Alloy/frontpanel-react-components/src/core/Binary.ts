/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
