/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { ByteCount } from "./Endpoint";

import { WireAddress, WireValue, WireMask } from "./WireEndpoint";
import { TriggerVectorAddress, TriggerVector, TriggerVectorMask } from "./TriggerEndpoint";
import { PipeAddress } from "./Endpoint";
import { RegisterAddress, RegisterValue } from "./Endpoint";

/**
 * Type representing a callback function that writes data.
 * @param data - The data to write.
 */
export type WriteDataCallback = (data: ArrayBuffer) => void;

/**
 * Interface that provides the methods that may be used to interact
 * with a FrontPanel device.
 */
interface IFrontPanel {
    /**
     * Gets the value of a WireIn at the specified address.
     * @param address - The address of the WireIn endpoint.
     * @returns {Promise<WireValue>} - A promise that resolves to the value of the WireIn.
     */
    getWireInValue(address: WireAddress): Promise<WireValue>;
    /**
     * Sets the value of the WireIn at the specified address.
     * @param address - The address of the WireIn endpoint.
     * @param value - The value to set.
     * @param mask - The mask to apply to the value.
     * @returns {Promise<void>} - A promise that resolves when the value of the WireIn has been set.
     */
    setWireInValue(address: WireAddress, value: WireValue, mask: WireMask): Promise<void>;
    /**
     * Transfers current WireIn values to the FPGA.
     * @returns {Promise<void>} - A promise that resolves when all WireIns have been transfered.
     */
    updateWireIns(): Promise<void>;
    /**
     * Gets the value of the WireOut at the specified address.
     * @param address - The address of the WireOut endpoint.
     * @returns {Promise<WireValue>} - A promise that resolves to the value of the WireOut.
     */
    getWireOutValue(address: WireAddress): Promise<WireValue>;
    /**
     * Retrieves current WireOut values from the FPGA.
     * @returns {Promise<void>} - A promise that resolves when all WireOuts have been updated.
     */
    updateWireOuts(): Promise<void>;
    /**
     * Activates the TriggerIn at the specified address and bit.
     * @param address - The address of the TriggerIn vector endpoint.
     * @param bit - The bit of the TriggerIn vector to activate.
     * @returns {Promise<void>} - A promise that resolves when the TriggerIn has been activated.
     */
    activateTriggerIn(address: TriggerVectorAddress, bit: number): Promise<void>;
    /**
     * Gets the TriggerOut vector at the specified address.
     * @param address - The address of the TriggerOut vector endpoint.
     * @returns {Promise<TriggerVector>} - A promise that resolves to the TriggerOut vector.
     */
    getTriggerOutVector(address: TriggerVectorAddress): Promise<TriggerVector>;
    /**
     * Checks if the TriggerOut at the specified address and mask is active.
     * @param address - The address of the TriggerOut vector endpoint.
     * @param mask - The mask to apply to the TriggerOut vector.
     * @returns {Promise<boolean>} - A promise that resolves to true if the TriggerOut is active, or false otherwise.
     */
    isTriggered(address: TriggerVectorAddress, mask: TriggerVectorMask): Promise<boolean>;
    /**
     * Retrieves the current TriggerOut vectors from the FPGA.
     * @returns {Promise<void>} - A promise that resolves when all TriggerOuts have been updated.
     */
    updateTriggerOuts(): Promise<void>;
    /**
     * Writes data to the PipIn at the specified address.
     * @param address - The address of the PipeIn endpoint.
     * @param length - The length of the data to write in bytes.
     * @param writeData - The callback function that will be called to write the data.
     * @returns {Promise<void>} - A promise that resolves when the data has been written.
     */
    writeToPipeIn(
        address: PipeAddress,
        length: ByteCount,
        writeData: WriteDataCallback
    ): Promise<void>;
    /**
     * Reads data from the PipeOut at the specified address.
     * @param address - The address of the PipeOut endpoint.
     * @param length - The length of the data to read in bytes.
     * @returns {Promise<ArrayBuffer>} - A promise that resolves to the read data.
     */
    readFromPipeOut(address: PipeAddress, length: ByteCount): Promise<ArrayBuffer>;
    /**
     * Reads the value of the Register at the specified address.
     * @param address - The address of the Register.
     * @returns {Promise<RegisterValue>} - A promise that resolves to the value of the Register.
     */
    readRegister(address: RegisterAddress): Promise<RegisterValue>;
    /**
     * Writes a value to the Register at the specified address.
     * @param address - The address of the Register.
     * @param value - The value to write.
     * @returns {Promise<void>} - A promise that resolves when the value has been written.
     */
    writeRegister(address: RegisterAddress, value: RegisterValue): Promise<void>;
}

export default IFrontPanel;
