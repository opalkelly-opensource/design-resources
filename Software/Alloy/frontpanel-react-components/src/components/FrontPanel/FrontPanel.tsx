/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import { FrontPanelPeriodicUpdateTimer, WorkQueue } from "@opalkelly/frontpanel-alloy-core";

import { FrontPanelProps } from "./FrontPanel.props";

import { FrontPanelContext } from "../../contexts";

const FrontPanel: React.FC<FrontPanelProps> = (props) => {
    const {
        device = window.FrontPanel,
        workQueue = new WorkQueue(),
        eventSource = new FrontPanelPeriodicUpdateTimer(device, 10)
    } = props;

    return (
        <FrontPanelContext.Provider
            value={{ device: device, workQueue: workQueue, eventSource: eventSource }}>
            {props.children}
        </FrontPanelContext.Provider>
    );
};

FrontPanel.displayName = "FrontPanel";

export default FrontPanel;
