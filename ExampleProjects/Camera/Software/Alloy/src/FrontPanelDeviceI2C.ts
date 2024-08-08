/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFrontPanel } from "@opalkelly/frontpanel-alloy-core";

/**
 * Class representing an I2C FrontPanel device.
 */
export class FrontPanelDeviceI2C {
    private readonly _FrontPanel: IFrontPanel;
    private readonly _DeviceAddress: number;

    constructor(frontpanel: IFrontPanel, deviceAddress: number) {
        this._FrontPanel = frontpanel;
        this._DeviceAddress = deviceAddress;
    }

    // Reads a 16 bit value from a 16 - bit register address on the AR0330 sensor.
    public async Read16(address: number): Promise<number> {
        let u16Data = 0;

        await this._FrontPanel.activateTriggerIn(0x42, 1);
        // Preamble Length(Bytes)
        await this._FrontPanel.setWireInValue(0x01, 0x0084, 0x00ff); // Address Words
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Starts
        await this._FrontPanel.setWireInValue(0x01, 0x0004, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Stops
        await this._FrontPanel.setWireInValue(0x01, 0x0000, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Payload Length(Bytes)
        await this._FrontPanel.setWireInValue(0x01, 0x0002, 0x00ff); // Data Words
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Device Address(write)
        await this._FrontPanel.setWireInValue(0x01, this._DeviceAddress, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Register Address(high)
        await this._FrontPanel.setWireInValue(0x01, address >> 8, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Register Address(low)
        await this._FrontPanel.setWireInValue(0x01, address, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Device Address(read)
        await this._FrontPanel.setWireInValue(0x01, this._DeviceAddress + 1, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);

        // Start I2C Transaction
        await this._FrontPanel.activateTriggerIn(0x42, 0);

        //Wait for Transaction to Finish
        do {
            await this._FrontPanel.updateTriggerOuts();
        } while (await this._FrontPanel.isTriggered(0x61, 0x0001));

        await this._FrontPanel.activateTriggerIn(0x42, 1);
        // Read result 0
        await this._FrontPanel.updateWireOuts();

        u16Data = ((await this._FrontPanel.getWireOutValue(0x22)) & 0xff) << 8;

        // Read result 1
        await this._FrontPanel.activateTriggerIn(0x42, 3);
        await this._FrontPanel.updateWireOuts();

        u16Data = u16Data | ((await this._FrontPanel.getWireOutValue(0x22)) & 0xff);

        //console.log('Read from I2C device=' + this._DeviceAddress.toString(16) + ' address=' + address.toString(16) + ' value=' + u16Data.toString(16));

        return u16Data;
    }

    // Writes a 16 bit value to a 16 - bit register address on the AR0330 sensor.
    public async Write16(address: number, data: number): Promise<void> {
        await this._FrontPanel.activateTriggerIn(0x42, 1);
        // Preamble Length(Bytes)
        await this._FrontPanel.setWireInValue(0x01, 0x0003, 0x00ff); // Address Words
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Starts
        await this._FrontPanel.setWireInValue(0x01, 0x0000, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Stops
        await this._FrontPanel.setWireInValue(0x01, 0x0000, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Payload Length(Bytes)
        await this._FrontPanel.setWireInValue(0x01, 0x0002, 0x00ff); // Data Words
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Device Address
        await this._FrontPanel.setWireInValue(0x01, this._DeviceAddress, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Register Address(high)
        await this._FrontPanel.setWireInValue(0x01, address >> 8, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Register Address(low)
        await this._FrontPanel.setWireInValue(0x01, address, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Data 0 MSB
        await this._FrontPanel.setWireInValue(0x01, data >> 8, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);
        // Data 1 LSB
        await this._FrontPanel.setWireInValue(0x01, data, 0x00ff);
        await this._FrontPanel.updateWireIns();
        await this._FrontPanel.activateTriggerIn(0x42, 2);

        // Start I2C Transaction
        await this._FrontPanel.activateTriggerIn(0x42, 0);

        // Wait for Transaction to Finish
        do {
            await this._FrontPanel.updateTriggerOuts();
        } while (await this._FrontPanel.isTriggered(0x61, 0x0001));

        //console.log('Write to I2C device=' + this._DeviceAddress.toString(16) + ' address=' + address.toString(16) + ' value=' + data.toString(16));
    }
}
