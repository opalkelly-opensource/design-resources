import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";

import RangeSlider from "./RangeSlider";

// Configure Story metadata
const meta = {
    title: "Components/RangeSlider",
    component: RangeSlider,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        defaultValue: {
            control: { type: "number", step: 1 }
        },
        valueStep: {
            control: { type: "number", step: 1 }
        },
        maximumValue: {
            control: { type: "number", step: 1 }
        },
        minimumValue: {
            control: { type: "number", step: 1 }
        },
        showThumbLabel: { type: "boolean" },
        showTrackLabels: { type: "boolean" },
        disabled: { type: "boolean" },
        // Disable event callback arguments
        onValueChange: {
            control: { disable: true }
        },
        onValueCommit: {
            control: { disable: true }
        }
    }
} satisfies Meta<typeof RangeSlider>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: (args) => {
        return (
            <div style={{ minWidth: "200px" }}>
                <RangeSlider {...args} />
            </div>
        );
    },
    decorators: [withApplication],
    args: {
        defaultValue: 50,
        value: undefined,
        maximumValue: 100,
        minimumValue: 0,
        valueStep: 1,
        showTrackLabels: true,
        showThumbLabel: true,
        disabled: false,
        label: { text: "RangeSlider" },
        tooltip: "Set value within range"
    }
};
