/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { useContext } from "react";

import type { Meta, StoryObj } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";
import withFrontPanel from "../../stories/decorators/FrontPanel.decorator";

import FrontPanelSelectEntry from "./FrontPanelSelectEntry";

import { FrontPanelContext } from "../../contexts";

import { WireValue } from "@opalkelly/frontpanel-alloy-core";

// Configure Story metadata
const meta = {
    title: "Components/FrontPanel/FrontPanelSelectEntry",
    component: FrontPanelSelectEntry.Root,
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
} satisfies Meta<typeof FrontPanelSelectEntry.Root>;

export default meta;

type Story = StoryObj<typeof meta>;

// Primary Story
export const Primary: Story = {
    render: ({ ...args }) => {
        const { device, workQueue } = useContext(FrontPanelContext);

        const setWireInPromises: Promise<void>[] = [];

        // Initialize the WireIns with unique values.
        workQueue.Post(async (): Promise<void> => {
            let byteId = 0;

            for (let address = 0x0; address < 0x20; address++) {
                let wireValue: WireValue = byteId++;
                for (let byteIndex = 1; byteIndex < 4; byteIndex++) {
                    wireValue |= byteId++ << (8 * byteIndex);
                }
                setWireInPromises.push(device.setWireInValue(address, wireValue, 0xffffffff));
            }

            await Promise.all(setWireInPromises);
            await device.updateWireIns();
        });

        const { maximumValue, ...props } = args;

        return (
            <FrontPanelSelectEntry.Root maximumValue={0xffffffffn} {...props}>
                <FrontPanelSelectEntry.Trigger />
                <FrontPanelSelectEntry.Content>
                    <FrontPanelSelectEntry.Group>
                        <FrontPanelSelectEntry.Label>Fruit Group</FrontPanelSelectEntry.Label>
                        <FrontPanelSelectEntry.Item value="0">Apple</FrontPanelSelectEntry.Item>
                        <FrontPanelSelectEntry.Item value="4294967295">
                            Orange
                        </FrontPanelSelectEntry.Item>
                        <FrontPanelSelectEntry.Item value="3740249613" disabled>
                            Grape
                        </FrontPanelSelectEntry.Item>
                    </FrontPanelSelectEntry.Group>
                    <FrontPanelSelectEntry.Separator />
                    <FrontPanelSelectEntry.Group>
                        <FrontPanelSelectEntry.Label>Vegetable Group</FrontPanelSelectEntry.Label>
                        <FrontPanelSelectEntry.Item value="3735928559">
                            Carrot
                        </FrontPanelSelectEntry.Item>
                        <FrontPanelSelectEntry.Item value="4272750592">
                            Potato
                        </FrontPanelSelectEntry.Item>
                    </FrontPanelSelectEntry.Group>
                </FrontPanelSelectEntry.Content>
            </FrontPanelSelectEntry.Root>
        );
    },
    decorators: [withApplication, withFrontPanel],
    args: {
        fpEndpoint: { epAddress: 0x00, bitOffset: 1 },
        // Optional Properties
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
