/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFrontPanel, AddressRange } from "../core";
import { ByteCount, PipeAddress, WriteDataCallback } from "../core";

import { WireAddress, WireValue, WireMask, WireWidth } from "../core";
import {
    TriggerVectorAddress,
    TriggerVector,
    TriggerVectorMask,
    TriggerVectorWidth
} from "../core";
import { RegisterAddress, RegisterValue } from "../core";

import MockDataBlock from "./MockDataBlock";

/**
 * Class representing a mock implementation of the IFrontPanel interface used for testing.
 */
class MockFrontPanel implements IFrontPanel {
    /**
     * Address range for WireIn endpoints.
     */
    public static readonly WIREIN_ADDRESS_RANGE: AddressRange = { Minimum: 0x00, Maximum: 0x1f };

    /**
     * Address range for WireOut endpoints.
     */
    public static readonly WIREOUT_ADDRESS_RANGE: AddressRange = { Minimum: 0x20, Maximum: 0x3f };

    /**
     * Address range for TriggerIn endpoints.
     */
    public static readonly TRIGGERIN_ADDRESS_RANGE: AddressRange = { Minimum: 0x40, Maximum: 0x5f };

    /**
     * Address range for TriggerOut endpoints.
     */
    public static readonly TRIGGEROUT_ADDRESS_RANGE: AddressRange = {
        Minimum: 0x60,
        Maximum: 0x7f
    };

    /**
     * Address range for PipeIn endpoints.
     */
    public static readonly PIPEIN_ADDRESS_RANGE: AddressRange = { Minimum: 0x80, Maximum: 0x9f };

    /**
     * Address range for PipeOut endpoints
     */
    public static readonly PIPEOUT_ADDRESS_RANGE: AddressRange = { Minimum: 0xa0, Maximum: 0xbf };

    /**
     * Address range for Register endpoints
     */
    public static readonly REGISTER_ADDRESS_RANGE: AddressRange = { Minimum: 0x00, Maximum: 0x1f };

    private readonly _WireInBlock: MockDataBlock;
    private readonly _WireOutBlock: MockDataBlock;

    private readonly _TriggerOutVectors: MockDataBlock;

    private readonly _RegisterBlock: MockDataBlock;

    /**
     * The WireIn data block
     */
    get WireInBlock(): MockDataBlock {
        return this._WireInBlock;
    }

    /**
     * The WireOut data block
     */
    get WireOutBlock(): MockDataBlock {
        return this._WireOutBlock;
    }

    /**
     * The TriggerOut data block
     */
    get TriggerOutBlock(): MockDataBlock {
        return this._TriggerOutVectors;
    }

    /**
     * The Register data block
     */
    get RegisterBlock(): MockDataBlock {
        return this._RegisterBlock;
    }

    /**
     *
     * @param wireWidth - The width of the mock WireIn and WireOut endpoints, measured in bits.
     * @param triggerVectorWidth - The width of the mock TriggerOut vectors, measured in bits.
     */
    constructor(wireWidth: WireWidth, triggerVectorWidth: TriggerVectorWidth) {
        this._WireInBlock = MockDataBlock.FromAddressRange(
            MockFrontPanel.WIREIN_ADDRESS_RANGE,
            wireWidth
        );
        this._WireOutBlock = MockDataBlock.FromAddressRange(
            MockFrontPanel.WIREOUT_ADDRESS_RANGE,
            wireWidth
        );

        this._TriggerOutVectors = MockDataBlock.FromAddressRange(
            MockFrontPanel.TRIGGEROUT_ADDRESS_RANGE,
            triggerVectorWidth
        );

        this._RegisterBlock = MockDataBlock.FromAddressRange(
            MockFrontPanel.REGISTER_ADDRESS_RANGE,
            32
        );
    }

    /**
     * Gets the value of the mock WireIn endpoint at the specified address.
     * @param address - The address of the WireIn endpoint.
     * @returns {Promise<WireValue>} - A promise that resolves to the value of the mock WireIn endpoint.
     */
    public async getWireInValue(address: WireAddress): Promise<WireValue> {
        return this._WireInBlock.GetValue(address) ?? 0;
    }

    /**
     * Sets the value of the mock WireIn endpoint at the specified address.
     * @param address - The address of the mock WireIn endpoint.
     * @param value - The value to set.
     * @param mask - The mask to apply to the value.
     * @returns {Promise<void>} - A promise that resolves when the value has been set.
     */
    public async setWireInValue(
        address: WireAddress,
        value: WireValue,
        mask: WireMask
    ): Promise<void> {
        this._WireInBlock.SetValue(address, value, mask);
    }

    /**
     * Updates all mock WireIn endpoints.
     * @returns {Promise<void>} - A promise that resolves when all mock WireIn endpoints have been updated.
     */
    public async updateWireIns(): Promise<void> {
        return;
    }

    /**
     * Gets the value of the mock WireOut endpoint at the specified address.
     * @param address - The address of the wire out.
     * @returns {Promise<WireValue>} - A promise that resolves to the value of the wire out.
     */
    public async getWireOutValue(address: WireAddress): Promise<WireValue> {
        return this._WireOutBlock.GetValue(address) ?? 0;
    }

    /**
     * Updates all mock WireOut endpoints.
     * @returns {Promise<void>} - A promise that resolves when all mock WireOut endpoints have been updated.
     */
    public async updateWireOuts(): Promise<void> {
        return;
    }

    /**
     * Activates the mock TriggerIn endpoint at the specified address and bit.
     * @param address - The address of the mock TriggerIn vector.
     * @param bit - The bit to activate.
     * @returns {Promise<void>} - A promise that resolves when the mock TriggerIn endpoint has been activated.
     */
    public async activateTriggerIn(address: TriggerVectorAddress, bit: number): Promise<void> {
        console.log(
            "MockFrontPanel.activateTriggerIn: address=" + address.toString(16) + " bit=" + bit
        );

        return;
    }

    /**
     * Gets the mock TriggerOut vector at the specified address.
     * @param address - The address of the mock TriggerOut vector.
     * @returns {Promise<TriggerVector>} - A promise that resolves to the mock TriggerOut vector.
     */
    public async getTriggerOutVector(address: TriggerVectorAddress): Promise<TriggerVector> {
        return this._TriggerOutVectors.GetValue(address) ?? 0;
    }
    /**
     * Checks if the mock TriggerOut endpoint at the specified address is active by applying the mask.
     * @param address - The address of the mock TriggerOut vector.
     * @param mask - The mask to apply to the mock TriggerOut vector.
     * @returns {Promise<boolean>} - A promise that resolves to true if the TriggerOut endpoint is active, or false otherwise.
     */
    public async isTriggered(
        address: TriggerVectorAddress,
        mask: TriggerVectorMask
    ): Promise<boolean> {
        const vector = this._TriggerOutVectors.GetValue(address) ?? 0;

        return (vector & mask) === mask;
    }

    /**
     * Updates all mock TriggerOut vectors.
     * @returns {Promise<void>} - A promise that resolves when all mock TriggerOut vectors have been updated.
     */
    public async updateTriggerOuts(): Promise<void> {
        return;
    }

    /**
     * Writes data to the mock PipeIn endpoint at the specified address.
     * @param address - The address of the mock PipeIn endpoint.
     * @param length - The length of the data to write in bytes.
     * @param writeData - The callback function that is called to perform the write operation.
     * @returns {Promise<void>} - A promise that resolves when the data has been written.
     */
    public async writeToPipeIn(
        _address: PipeAddress,
        _length: ByteCount,
        _writeData: WriteDataCallback
    ): Promise<void> {
        return;
    }

    /**
     * Reads data from the mock PipeOut endpoint at the specified address.
     * @param address - The address of the mock PipeOut endpoint.
     * @param length - The length of the data to read in bytes.
     * @returns {Promise<ArrayBuffer>} - A promise that resolves to the data that was read.
     */
    public async readFromPipeOut(_address: PipeAddress, _length: ByteCount): Promise<ArrayBuffer> {
        return new ArrayBuffer(0);
    }

    /**
     * Reads the value of the mock Register at the specified address.
     * @param address - The address of the mock Register.
     * @returns {Promise<RegisterValue>} - A promise that resolves to the value of the mock Register.
     */
    public async readRegister(address: RegisterAddress): Promise<RegisterValue> {
        return this._RegisterBlock.GetValue(address) ?? 0;
    }

    /**
     * Writes a value to the mock Register at the specified address.
     * @param address - The address of the mock Register.
     * @param value - The value to write.
     * @returns {Promise<void>} - A promise that resolves when the value has been written.
     */
    public async writeRegister(address: RegisterAddress, value: RegisterValue): Promise<void> {
        this._RegisterBlock.SetValue(address, value, 0xffffffff);
    }
}

export default MockFrontPanel;
