/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { NumeralSystem } from "./Types";

/**
 * Class representing numeric digits in various numeral systems.
 */
export class NumericDigits {
    /**
     * Maximum number of digits.
     */
    static readonly MAX_DIGITS: number = 1024;

    /**
     * Binary digit values.
     */
    static readonly BINARY_DIGITVALUES = ["0", "1"];

    /**
     * Octal digit values.
     */
    static readonly OCTAL_DIGITVALUES = ["0", "1", "2", "3", "4", "5", "6", "7"];

    /**
     * Decimal digit values.
     */
    static readonly DECIMAL_DIGITVALUES = [...NumericDigits.OCTAL_DIGITVALUES, "8", "9"];

    /**
     * Hexadecimal digit values.
     */
    static readonly HEXADECIMAL_DIGITVALUES = [
        ...NumericDigits.DECIMAL_DIGITVALUES,
        "A",
        "B",
        "C",
        "D",
        "E",
        "F"
    ];

    private readonly _DigitCount: bigint;
    private readonly _NumeralSystem: NumeralSystem;
    private readonly _DigitChars: string[];

    /**
     * Gets the count of digits.
     */
    public get DigitCount() {
        return this._DigitCount;
    }

    /**
     * Gets the numeral system.
     */
    public get NumeralSystem() {
        return this._NumeralSystem;
    }

    /**
     * Gets the digit characters.
     */
    public get DigitChars() {
        return this._DigitChars;
    }

    /**
     * Creates a new instance of NumericDigits.
     * @param digitCount - The count of digits.
     * @param numeralSystem - The numeral system.
     */
    constructor(digitCount: bigint, numeralSystem: NumeralSystem) {
        this._DigitCount = digitCount;
        this._NumeralSystem = numeralSystem;
        this._DigitChars = NumericDigits.GetDigitChars(numeralSystem);
    }

    /**
     * Gets the character representation of the digit corresponding
     * to the value specified.
     * @param value - The value.
     * @returns {string} - The digit as represented in the numeral system.
     */
    public GetDigitFromValue(value: number): string {
        let targetDigitValue: number = value % this._NumeralSystem;

        if (targetDigitValue < 0) {
            targetDigitValue += this._NumeralSystem;
        }

        return targetDigitValue.toString(this._NumeralSystem);
    }

    /**
     * Gets the digit characters from the numeral.
     * @param numeral - The numeral system.
     * @returns {string[]} - The digit characters.
     */
    public static GetDigitChars(numeral: NumeralSystem): string[] {
        let retval: string[];

        switch (numeral) {
            case NumeralSystem.Binary:
                retval = NumericDigits.BINARY_DIGITVALUES;
                break;
            case NumeralSystem.Octal:
                retval = NumericDigits.OCTAL_DIGITVALUES;
                break;
            case NumeralSystem.Decimal:
                retval = NumericDigits.DECIMAL_DIGITVALUES;
                break;
            case NumeralSystem.Hexadecimal:
                retval = NumericDigits.HEXADECIMAL_DIGITVALUES;
                break;
            default:
                retval = [];
                break;
        }

        return retval;
    }

    /**
     * Computes the digit count from the bits.
     * @param bitcount - The bit count.
     * @param numeral - The numeral.
     * @returns {bigint} - The digit count.
     */
    public static ComputeDigitCountFromBits(bitcount: number, numeral: NumeralSystem) {
        const maxValue: bigint = (1n << BigInt(bitcount)) - 1n;

        return this.ComputeDigitCountFromValue(maxValue, numeral);
    }

    /**
     * Computes the digit count from the value.
     * @param value - The value.
     * @param numeral - The numeral.
     * @returns {bigint} - The digit count.
     */
    public static ComputeDigitCountFromValue(value: bigint, numeral: NumeralSystem): bigint {
        // The following equation computes the number of digits necessary to represent the value
        // given the radix. However, an iterative solution is used because Math.log operates on
        // the number type and therefore limits the value to 52 bits. This solution should allow
        // value to be any number of bits.
        //
        // d = ceiling(log[radix](value))
        // v = value
        // d = digits

        const radix: bigint = BigInt(numeral);

        let val: bigint = value;

        let digitIndex: bigint;

        for (digitIndex = 0n; digitIndex < NumericDigits.MAX_DIGITS && val !== 0n; digitIndex++) {
            val = val / radix;
        }

        return digitIndex > 0n ? digitIndex : 1n;
    }
}
