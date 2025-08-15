/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFPGADataPortClassic } from "@opalkelly/frontpanel-platform-api";

/**
 * Class representing an I2C FrontPanel device.
 */
export class FrontPanelDeviceI2C {
    private readonly _FPGADataPort: IFPGADataPortClassic;
    private readonly _DeviceAddress: number;

    constructor(fpgaDataPort: IFPGADataPortClassic, deviceAddress: number) {
        this._FPGADataPort = fpgaDataPort;
        this._DeviceAddress = deviceAddress;
    }

    // Reads a 16 bit value from a 16 - bit register address on the AR0330 sensor.
    public async Read16(address: number): Promise<number> {
        let u16Data = 0;

        await this._FPGADataPort.activateTriggerIn(0x42, 1);
        // Preamble Length(Bytes)
        this._FPGADataPort.setWireInValue(0x01, 0x0084, 0x00ff); // Address Words
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Starts
        this._FPGADataPort.setWireInValue(0x01, 0x0004, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Stops
        this._FPGADataPort.setWireInValue(0x01, 0x0000, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Payload Length(Bytes)
        this._FPGADataPort.setWireInValue(0x01, 0x0002, 0x00ff); // Data Words
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Device Address(write)
        this._FPGADataPort.setWireInValue(0x01, this._DeviceAddress, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Register Address(high)
        this._FPGADataPort.setWireInValue(0x01, address >> 8, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Register Address(low)
        this._FPGADataPort.setWireInValue(0x01, address, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Device Address(read)
        this._FPGADataPort.setWireInValue(0x01, this._DeviceAddress + 1, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);

        // Start I2C Transaction
        await this._FPGADataPort.activateTriggerIn(0x42, 0);

        //Wait for Transaction to Finish
        do {
            await this._FPGADataPort.updateTriggerOuts();
        } while (this._FPGADataPort.isTriggered(0x61, 0x0001));

        await this._FPGADataPort.activateTriggerIn(0x42, 1);
        // Read result 0
        await this._FPGADataPort.updateWireOuts();

        u16Data = ((this._FPGADataPort.getWireOutValue(0x22)) & 0xff) << 8;

        // Read result 1
        await this._FPGADataPort.activateTriggerIn(0x42, 3);
        await this._FPGADataPort.updateWireOuts();

        u16Data = u16Data | ((this._FPGADataPort.getWireOutValue(0x22)) & 0xff);

        //console.log('Read from I2C device=' + this._DeviceAddress.toString(16) + ' address=' + address.toString(16) + ' value=' + u16Data.toString(16));

        return u16Data;
    }

    // Writes a 16 bit value to a 16 - bit register address on the AR0330 sensor.
    public async Write16(address: number, data: number): Promise<void> {
        await this._FPGADataPort.activateTriggerIn(0x42, 1);
        // Preamble Length(Bytes)
        this._FPGADataPort.setWireInValue(0x01, 0x0003, 0x00ff); // Address Words
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Starts
        this._FPGADataPort.setWireInValue(0x01, 0x0000, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Stops
        this._FPGADataPort.setWireInValue(0x01, 0x0000, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Payload Length(Bytes)
        this._FPGADataPort.setWireInValue(0x01, 0x0002, 0x00ff); // Data Words
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Device Address
        this._FPGADataPort.setWireInValue(0x01, this._DeviceAddress, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Register Address(high)
        this._FPGADataPort.setWireInValue(0x01, address >> 8, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Register Address(low)
        this._FPGADataPort.setWireInValue(0x01, address, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Data 0 MSB
        this._FPGADataPort.setWireInValue(0x01, data >> 8, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);
        // Data 1 LSB
        this._FPGADataPort.setWireInValue(0x01, data, 0x00ff);
        await this._FPGADataPort.updateWireIns();
        await this._FPGADataPort.activateTriggerIn(0x42, 2);

        // Start I2C Transaction
        await this._FPGADataPort.activateTriggerIn(0x42, 0);

        // Wait for Transaction to Finish
        do {
            await this._FPGADataPort.updateTriggerOuts();
        } while (this._FPGADataPort.isTriggered(0x61, 0x0001));

        //console.log('Write to I2C device=' + this._DeviceAddress.toString(16) + ' address=' + address.toString(16) + ' value=' + data.toString(16));
    }
}
