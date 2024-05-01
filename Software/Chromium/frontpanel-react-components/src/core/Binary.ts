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
