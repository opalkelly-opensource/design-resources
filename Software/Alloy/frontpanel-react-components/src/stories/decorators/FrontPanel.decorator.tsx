/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import type { Decorator } from "@storybook/react";

import { FrontPanel } from "../../components";

import { MockFrontPanel, ByteCount } from "@opalkelly/frontpanel-alloy-core";

const mockDevice: MockFrontPanel = new MockFrontPanel(32, 32);

const InitializeMockDevice = () => {
    // Initialize the WireOuts with unique values.
    const wireOutBlock = mockDevice.WireOutBlock;

    let byteId: ByteCount = 0;

    for (let elementIndex = 0; elementIndex < wireOutBlock.Count; elementIndex++) {
        let elementValue: number = byteId++;
        for (let byteIndex = 1; byteIndex < 4; byteIndex++) {
            elementValue |= byteId++ << (8 * byteIndex);
        }

        wireOutBlock.SetValue(
            wireOutBlock.BaseAddress + elementIndex,
            elementValue,
            wireOutBlock.Mask
        );
    }
};

const withFrontPanel: Decorator = (Story) => {
    InitializeMockDevice();
    return (
        <FrontPanel device={mockDevice}>
            <Story />
        </FrontPanel>
    );
};

export default withFrontPanel;
