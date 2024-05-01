import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import { useArgs } from "@storybook/preview-api";

import DigitEntry from "./DigitEntry";

import { NumeralSystem } from "../../core";

// Configure Story metadata
const meta = {
    title: "Components/DigitEntry",
    component: DigitEntry,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        variant: {
            control: "radio",
            options: ["standard", "compact"]
        },
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
        value: {
            control: { type: "number", step: 1 }
        },
        maximum: {
            control: { type: "number", step: 1 }
        },
        minimum: {
            control: { type: "number", step: 1 }
        },
        // Disable event callback arguments
        onValueChanged: {
            control: { disable: true }
        }
    }
} satisfies Meta<typeof DigitEntry>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: (args) => {
        const [{ value }, updateArgs] = useArgs();

        function onValueChanged(value: number, _isKeyDown: boolean): void {
            updateArgs({ value: value });
        }

        return <DigitEntry {...args} value={value} onValueChanged={onValueChanged} />;
    },
    args: {
        value: 8,
        // Optional Properties
        size: 1,
        numeralSystem: NumeralSystem.Decimal,
        variant: "standard",
        maximum: undefined,
        minimum: undefined
    }
};
