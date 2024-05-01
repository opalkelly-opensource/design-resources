import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";

import NumberDisplay from "./NumberDisplay";

import { NumeralSystem } from "../../core";

// Configure Story metadata
const meta = {
    title: "Components/NumberDisplay",
    component: NumberDisplay,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
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
        minimumValueString: { control: "text" }
    }
} satisfies Meta<typeof NumberDisplay>;

export default meta;

type Story = StoryObj<typeof meta>;

const convertToBigInt = (value: string) => {
    return BigInt(value);
};

// Primary Story
export const Primary: Story = {
    decorators: [withApplication],
    render: (args) => {
        const { valueString, maximumValueString, minimumValueString } = args;

        const value = convertToBigInt(valueString);
        const maximum = convertToBigInt(maximumValueString);
        const minimum = convertToBigInt(minimumValueString);

        return (
            <NumberDisplay {...args} value={value} maximumValue={maximum} minimumValue={minimum} />
        );
    },
    args: {
        valueString: "8000",
        maximumValueString: "1000000",
        minimumValueString: "-1000000",
        // Optional Properties
        numeralSystem: NumeralSystem.Decimal,
        decimalScale: 3,
        label: {
            text: "Decimal Value",
            verticalPosition: "top",
            horizontalPosition: "left"
        },
        size: 1,
        tooltip: "Set the decimal value"
    }
};
