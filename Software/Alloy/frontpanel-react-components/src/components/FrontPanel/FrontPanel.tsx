/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
