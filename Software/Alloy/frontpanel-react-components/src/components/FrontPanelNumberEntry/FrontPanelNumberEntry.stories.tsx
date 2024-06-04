/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { useContext } from "react";

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";
import withFrontPanel from "../../stories/decorators/FrontPanel.decorator";

import FrontPanelNumberEntry from "./FrontPanelNumberEntry";

import { FrontPanelContext } from "../../contexts";

import { NumeralSystem } from "../../core";

import { WireValue } from "@opalkellytech/frontpanel-chromium-core";

// Configure Story metadata
const meta = {
    title: "Components/FrontPanel/FrontPanelNumberEntry",
    component: FrontPanelNumberEntry,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        variant: {
            control: "radio",
            options: ["standard", "compact"]
        },
        disabled: { control: "boolean" },
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        },
        decimalScale: {
            control: { type: "range", min: 0, max: 20, step: 1 }
        },
        numeralSystem: {
            control: "radio",
            options: ["Decimal", "Hexadecimal", "Binary", "Octal"],
            mapping: {
                Decimal: NumeralSystem.Decimal,
                Hexadecimal: NumeralSystem.Hexadecimal,
                Binary: NumeralSystem.Binary,
                Octal: NumeralSystem.Octal
            }
        },
        maximumValue: { control: "text" },
        minimumValue: { control: "text" }
    }
} satisfies Meta<typeof FrontPanelNumberEntry>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: (props) => {
        const { device, workQueue } = useContext(FrontPanelContext);

        const setWireInPromises: Promise<void>[] = [];

        // Initialize the WireIns with unique values.
        workQueue.Post(async (): Promise<void> => {
            let byteId = 0;

            for (let address = 0x0; address < 0x20; address++) {
                let wireValue: WireValue = byteId++;
                for (let byteIndex = 1; byteIndex < 4; byteIndex++) {
                    wireValue |= byteId++ << (8 * byteIndex);
                }
                setWireInPromises.push(device.setWireInValue(address, wireValue, 0xffffffff));
            }

            await Promise.all(setWireInPromises);
            await device.updateWireIns();
        });

        return <FrontPanelNumberEntry {...props} />;
    },
    decorators: [withApplication, withFrontPanel],
    args: {
        fpEndpoint: { epAddress: 0x00, bitOffset: 1 },
        maximumValue: 0xffffffffn,
        // Optional Properties
        disabled: false,
        variant: "standard",
        numeralSystem: NumeralSystem.Decimal,
        decimalScale: 0,
        label: {
            text: "Wire Value",
            verticalPosition: "top",
            horizontalPosition: "left"
        },
        size: 1,
        tooltip: "Set the wire endpoint value"
    }
};
