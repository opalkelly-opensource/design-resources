/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";
import withFrontPanel from "../../stories/decorators/FrontPanel.decorator";

import FrontPanelIndicator from "./FrontPanelIndicator";

// Configure Story metadata
const meta = {
    title: "Components/FrontPanel/FrontPanelIndicator",
    component: FrontPanelIndicator,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        }
    }
} satisfies Meta<typeof FrontPanelIndicator>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    decorators: [withApplication, withFrontPanel],
    args: {
        label: "Wire Indicator",
        fpEndpoint: { epAddress: 0x20, bitOffset: 1 },
        // Optional Properties
        size: 1,
        tooltip: "Indicator for wire endpoint"
    }
};
