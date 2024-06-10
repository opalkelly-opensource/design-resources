/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import { IFrontPanel, IFrontPanelEventSource, WorkQueue } from "@opalkelly/frontpanel-alloy-core";

export type FrontPanelContextValue = {
    device: IFrontPanel;
    workQueue: WorkQueue;
    eventSource?: IFrontPanelEventSource;
};

const FrontPanelContext = React.createContext<FrontPanelContextValue>({
    device: window.FrontPanel,
    workQueue: new WorkQueue()
});

export default FrontPanelContext;
