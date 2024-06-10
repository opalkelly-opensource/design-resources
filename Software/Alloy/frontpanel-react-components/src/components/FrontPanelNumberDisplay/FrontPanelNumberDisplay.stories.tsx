/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";
import withFrontPanel from "../../stories/decorators/FrontPanel.decorator";

import FrontPanelNumberDisplay from "./FrontPanelNumberDisplay";

import { NumeralSystem } from "../../core";

// Configure Story metadata
const meta = {
    title: "Components/FrontPanel/FrontPanelNumberDisplay",
    component: FrontPanelNumberDisplay,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
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
        maximumValue: { control: "text" }
    }
} satisfies Meta<typeof FrontPanelNumberDisplay>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    decorators: [withApplication, withFrontPanel],
    args: {
        fpEndpoint: { epAddress: 0x20, bitOffset: 1 },
        maximumValue: 0xffffffffn,
        // Optional Properties
        numeralSystem: NumeralSystem.Decimal,
        decimalScale: 0,
        label: {
            text: "Wire Value",
            verticalPosition: "top",
            horizontalPosition: "left"
        },
        size: 1,
        tooltip: "The wire endpoint value"
    }
};
