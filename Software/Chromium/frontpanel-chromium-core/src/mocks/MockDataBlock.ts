import { AddressRange } from "../core";

/**
 * Type representing the address of a data element.
 */
export type ElementAddress = number;

/**
 * Type representing the value of a data element.
 */
export type ElementValue = number;

/**
 * Type representing the mask for a data element.
 */
export type ElementMask = number;

/**
 * Class representing a block of data elements that mimic FrontPanel endpoints to allow
 * testing using a web browser.
 */
class MockDataBlock {
    private readonly _BaseAddress: ElementAddress;
    private readonly _Mask: ElementMask;
    private readonly _Values: ElementValue[];

    /**
     * Gets the base address of the data block.
     */
    get BaseAddress(): ElementAddress {
        return this._BaseAddress;
    }

    /**
     * Gets the number of data elements in the block.
     */
    get Count(): number {
        return this._Values.length;
    }

    /**
     * Gets the mask for the data elements in the block.
     */
    get Mask(): ElementMask {
        return this._Mask;
    }

    /**
     * Creates a new instance of MockDataBlock.
     * @param baseAddress - The address of the first data element in the block.
     * @param data - The array of data elements that make up the block.
     * @param width - The width of the data elements, measured in bits.
     */
    constructor(baseAddress: ElementAddress, data: ElementValue[], width: number) {
        this._Values = data;

        this._BaseAddress = baseAddress;
        this._Mask = Math.pow(2, width) - 1;
    }

    /**
     * Gets the value of a specific data element.
     * @param address - The address of the element.
     * @returns {Promise<TData | null>} - A promise that resolves to the value of the element, or null if the address is out of range.
     */
    public GetValue(address: ElementAddress): ElementValue | null {
        let retval: ElementValue | null;

        console.log("MockDataBlock.GetValue: address=" + address.toString(16));

        const valueIndex: number = address - this._BaseAddress;

        if (valueIndex >= 0 && valueIndex < this._Values.length) {
            retval = this._Values[valueIndex] & this._Mask;

            console.log("MockDataBlock.GetValue: SUCCESS: value=" + retval.toString(16));
        } else {
            console.log(
                "MockDataBlock.GetValue: ERROR: Element address " +
                    address.toString(16) +
                    " is out of range [" +
                    this._BaseAddress.toString(16) +
                    ".." +
                    (this._BaseAddress + this._Values.length - 1).toString(16) +
                    "]"
            );

            retval = null; // ERROR: Element address is out of range
        }

        return retval;
    }

    /**
     * Sets the value of a specific data element.
     * @param address - The address of the data element.
     * @param value - The value to set.
     * @param mask - The mask to use when setting the value.
     * @returns {Promise<boolean>} - A promise that resolves to true if the value was set successfully, or false otherwise.
     */
    public SetValue(address: ElementAddress, value: ElementValue, mask: ElementMask): boolean {
        let retval: boolean;

        console.log(
            "MockDataBlock.SetValue: address=" +
                address.toString(16) +
                " value=" +
                value.toString(16) +
                " mask=" +
                mask.toString(16)
        );

        const valueIndex: number = address - this._BaseAddress;

        if (valueIndex >= 0 && valueIndex < this._Values.length) {
            const sourceValue: ElementValue = this._Values[valueIndex] & this._Mask;
            const targetValue: ElementValue = value & this._Mask;

            this._Values[valueIndex] = (sourceValue & ~mask) | (targetValue & mask);

            console.log(
                "MockDataBlock.SetValue: SUCCESS: value=" + this._Values[valueIndex].toString(16)
            );

            retval = true;
        } else {
            console.log(
                "MockDataBlock.SetValue: ERROR: Element address is out of range [" +
                    this._BaseAddress.toString(16) +
                    ".." +
                    (this._BaseAddress + this._Values.length - 1).toString(16) +
                    "]"
            );

            retval = false; // ERROR: Element address is out of range
        }

        return retval;
    }

    /**
     * Creates a new instance of MockDataBlock using a range of addresses.
     * @param addressRange - The range of addresses of data elements to associate with the block.
     * @param width - The width of the data elements, measured in bits.
     * @returns {MockDataBlock} - The new instance of MockDataBlock.
     */
    public static FromAddressRange(addressRange: AddressRange, width: number): MockDataBlock {
        const data: ElementValue[] = new Array<ElementValue>(
            addressRange.Maximum - addressRange.Minimum + 1
        );

        return new MockDataBlock(addressRange.Minimum, data, width);
    }
}

export default MockDataBlock;
