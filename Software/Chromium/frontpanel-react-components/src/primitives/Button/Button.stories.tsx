import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";

import Button from "./Button";

// Configure Story metadata
const meta = {
    title: "Components/Button",
    component: Button,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        },
        disabled: { control: "boolean" },
        // Disable event callback arguments
        onButtonClick: {
            control: { disable: true }
        },
        onButtonDown: {
            control: { disable: true }
        },
        onButtonUp: {
            control: { disable: true }
        }
    }
} satisfies Meta<typeof Button>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    decorators: [withApplication],
    args: {
        label: "Button",
        // Optional Properties
        size: 1,
        disabled: false,
        tooltip: "Button tooltip"
    }
};
