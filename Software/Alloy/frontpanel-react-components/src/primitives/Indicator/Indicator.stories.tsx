/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";

import Indicator from "./Indicator";

// Configure Story metadata
const meta = {
    title: "Components/Indicator",
    component: Indicator,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        },
        state: { control: { type: "boolean" } }
    }
} satisfies Meta<typeof Indicator>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    decorators: [withApplication],
    args: {
        label: "Indicator",
        state: true,
        // Optional Properties
        size: 1,
        tooltip: "Indicator tooltip"
    }
};
