/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import { fn } from "@storybook/test";

import { useArgs } from "@storybook/preview-api";

import withApplication from "../../stories/decorators/Application.decorator";

import NumberEntry from "./NumberEntry";

import { NumeralSystem } from "../../core";

// Configure Story metadata
const meta = {
    title: "Components/NumberEntry",
    component: NumberEntry,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    args: { onValueChange: fn() },
    argTypes: {
        variant: {
            control: "radio",
            options: ["standard", "compact"]
        },
        disabled: { control: "boolean" },
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
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
        valueString: { control: "text" },
        maximumValueString: { control: "text" },
        minimumValueString: { control: "text" },
        // Disable event callback arguments
        onValueChange: {
            control: { disable: true }
        }
    }
} satisfies Meta<typeof NumberEntry>;

export default meta;

type Story = StoryObj<typeof meta>;

const convertToBigInt = (value: string) => {
    return BigInt(value);
};

// Template for Stories
const ComponentTemplate: Story = {
    render: (args) => {
        const [{ valueString }, updateArgs] = useArgs();

        const { maximumValueString, minimumValueString } = args;

        const value = convertToBigInt(valueString);
        const maximum = convertToBigInt(maximumValueString);
        const minimum = convertToBigInt(minimumValueString);

        function onValueChange(value: bigint): void {
            updateArgs({ valueString: value.toString() });
        }

        return (
            <NumberEntry
                {...args}
                value={value}
                maximumValue={maximum}
                minimumValue={minimum}
                onValueChange={onValueChange}
            />
        );
    },
    decorators: [withApplication],
    args: {
        variant: "standard",
        disabled: false,
        label: {
            text: "Value",
            verticalPosition: "top",
            horizontalPosition: "left"
        },
        size: 1,
        tooltip: "Set the value",
        numeralSystem: NumeralSystem.Decimal,
        decimalScale: 3,
        valueString: "8000",
        maximumValueString: "1000000",
        minimumValueString: "-1000000"
    }
};

// Primary Story
export const Decimal: Story = {
    ...ComponentTemplate,
    args: {
        valueString: "8000",
        maximumValueString: "1000000",
        minimumValueString: "-1000000",
        // Optional Properties
        disabled: false,
        variant: "standard",
        numeralSystem: NumeralSystem.Decimal,
        decimalScale: 3,
        size: 1,
        label: {
            text: "Decimal Value",
            verticalPosition: "top",
            horizontalPosition: "left"
        },
        tooltip: "Set the decimal value"
    }
};
