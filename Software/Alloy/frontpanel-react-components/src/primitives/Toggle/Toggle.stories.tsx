/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import Toggle from "./Toggle";

import { ToggleState } from "../../core";

// Configure Story metadata
const meta = {
    title: "Components/Toggle",
    component: Toggle,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        },
        state: {
            control: "radio",
            options: ["On", "Off"],
            mapping: {
                On: ToggleState.On,
                Off: ToggleState.Off
            }
        },
        disabled: { control: "boolean" },
        // Disable event callback arguments
        onToggleStateChanged: {
            control: { disable: true }
        }
    }
} satisfies Meta<typeof Toggle>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: (args) => (
        <Toggle {...args}>
            <span>Toggle</span>
        </Toggle>
    ),
    args: {
        state: ToggleState.Off,
        // Optional Properties
        disabled: false,
        size: 1
    }
};
