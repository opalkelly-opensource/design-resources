/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import type { Meta, StoryObj } from "@storybook/react";

import { fn } from "@storybook/test";

import { useArgs } from "@storybook/preview-api";

import withApplication from "../../stories/decorators/Application.decorator";

import SelectEntry from "./SelectEntry";

// Configure Story metadata
const meta = {
    title: "Components/SelectEntry",
    component: SelectEntry.Root,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    args: { onValueChange: fn(), onOpenChange: fn() },
    argTypes: {
        size: {
            control: { type: "range", min: 1, max: 3, step: 1 }
        },
        disabled: { control: "boolean" },
        // Disable event callback arguments
        onValueChange: { action: "onValueChange" },
        onOpenChange: { action: "onOpenChange" }
    }
} satisfies Meta<typeof SelectEntry.Root>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: ({ ...args }) => {
        const [{ value }, updateArgs] = useArgs();

        function onValueChange(value: string): void {
            updateArgs({ value: value });
        }

        return (
            <div style={{ width: "150px" }}>
                <SelectEntry.Root {...args} value={value} onValueChange={onValueChange}>
                    <SelectEntry.Trigger />
                    <SelectEntry.Content>
                        <SelectEntry.Group>
                            <SelectEntry.Label>Fruit Group</SelectEntry.Label>
                            <SelectEntry.Item value="apple">Apple</SelectEntry.Item>
                            <SelectEntry.Item value="orange">Orange</SelectEntry.Item>
                            <SelectEntry.Item value="grape" disabled>
                                Grape
                            </SelectEntry.Item>
                        </SelectEntry.Group>
                        <SelectEntry.Separator />
                        <SelectEntry.Group>
                            <SelectEntry.Label>Vegetable Group</SelectEntry.Label>
                            <SelectEntry.Item value="carrot">Carrot</SelectEntry.Item>
                            <SelectEntry.Item value="potato">Potato</SelectEntry.Item>
                        </SelectEntry.Group>
                    </SelectEntry.Content>
                </SelectEntry.Root>
            </div>
        );
    },
    decorators: [withApplication],
    args: {
        value: "carrot",
        disabled: false,
        label: {
            text: "Select Item",
            verticalPosition: "top",
            horizontalPosition: "left"
        },
        size: 1,
        tooltip: "Select an item from the list"
    }
};
