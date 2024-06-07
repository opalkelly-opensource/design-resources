/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { useContext } from "react";

import type { Meta, StoryObj, Decorator } from "@storybook/react";

import withApplication from "../../stories/decorators/Application.decorator";
import withFrontPanel from "../../stories/decorators/FrontPanel.decorator";

import FrontPanelRangeSlider from "./FrontPanelRangeSlider";

import { FrontPanelContext } from "../../contexts";

import { WireValue } from "@opalkelly/frontpanel-alloy-core";

// Configure Story metadata
const meta = {
    title: "Components/FrontPanel/FrontPanelRangeSlider",
    component: FrontPanelRangeSlider,
    parameters: {
        layout: "centered" // Center the component in the Canvas
    },
    tags: ["autodocs"], // Automatically generate documentation
    argTypes: {
        maximumValue: {
            control: { type: "number", step: 1 }
        },
        minimumValue: {
            control: { type: "number", step: 1 }
        },
        valueStep: {
            control: { type: "number", step: 1 }
        },
        disabled: { control: "boolean" },
        showThumbLabel: { type: "boolean" },
        showTrackLabels: { type: "boolean" }
    }
} satisfies Meta<typeof FrontPanelRangeSlider>;

export default meta;

type Story = StoryObj<typeof meta>;

const withContainer: Decorator = (Story) => (
    <div style={{ width: "200px" }}>
        <Story />
    </div>
);

// Primary Story
export const Primary: Story = {
    render: (props) => {
        const { device, workQueue } = useContext(FrontPanelContext);

        const setWireInPromises: Promise<void>[] = [];

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

        return <FrontPanelRangeSlider {...props} />;
    },
    decorators: [withApplication, withFrontPanel, withContainer],
    args: {
        fpEndpoint: { epAddress: 0x00, bitOffset: 1 },
        // Optional Properties
        maximumValue: 100,
        minimumValue: 0,
        valueStep: 1,
        showTrackLabels: true,
        showThumbLabel: true,
        disabled: false,
        label: { text: "RangeSlider" },
        tooltip: "Wire endpoint Range slider tooltip"
    }
};
