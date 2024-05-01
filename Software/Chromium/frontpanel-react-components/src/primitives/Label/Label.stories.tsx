import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import Label from "./Label";

// Configure Story metadata
const meta = {
    title: "Components/Label",
    component: Label,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        horizontalPosition: {
            control: "radio",
            options: ["left", "right"]
        },
        verticalPosition: {
            control: "radio",
            options: ["top", "bottom"]
        }
    }
} satisfies Meta<typeof Label>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: ({ ...args }) => {
        return (
            <Label {...args}>
                <input type="text" />
            </Label>
        );
    },
    args: {
        text: "Label Text",
        // Optional Properties
        horizontalPosition: "left",
        verticalPosition: "top"
    }
};
