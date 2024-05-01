import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";
import withFrontPanel from "../../stories/decorators/FrontPanel.decorator";

import FrontPanelPushButton from "./FrontPanelPushButton";

// Configure Story metadata
const meta = {
    title: "Components/FrontPanel/FrontPanelPushButton",
    component: FrontPanelPushButton,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        },
        disabled: { control: "boolean" }
    }
} satisfies Meta<typeof FrontPanelPushButton>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    decorators: [withApplication, withFrontPanel],
    args: {
        label: "Pushbutton",
        fpEndpoint: { epAddress: 0x00, bitOffset: 1 },
        // Optional Properties
        disabled: false,
        size: 1,
        tooltip: "Wire endpoint assert button"
    }
};
