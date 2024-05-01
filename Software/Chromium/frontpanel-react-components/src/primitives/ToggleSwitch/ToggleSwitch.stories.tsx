import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import { useArgs } from "@storybook/preview-api";

import withApplication from "../../stories/decorators/Application.decorator";

import ToggleSwitch from "./ToggleSwitch";

import { ToggleState } from "../../core";

// Configure Story metadata
const meta = {
    title: "Components/ToggleSwitch",
    component: ToggleSwitch,
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
} satisfies Meta<typeof ToggleSwitch>;

export default meta;

type Story = StoryObj<typeof meta>;

// Template for Stories
const ComponentTemplate: Story = {
    render: (args) => {
        const [{ state }, updateArgs] = useArgs();

        function onToggleStateChange(state: ToggleState): void {
            updateArgs({ state: state });
        }

        return <ToggleSwitch {...args} state={state} onToggleStateChanged={onToggleStateChange} />;
    },
    decorators: [withApplication],
    args: {
        label: "Toggle",
        state: ToggleState.On,
        // Optional Properties
        disabled: false,
        size: 1,
        tooltip: "Toggle switch tooltip"
    }
};

// Primary Story
export const Primary: Story = {
    ...ComponentTemplate,
    args: {
        label: "Toggle",
        state: ToggleState.On,
        // Optional Properties
        disabled: false,
        size: 1,
        tooltip: "Toggle switch tooltip"
    }
};
