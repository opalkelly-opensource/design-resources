/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import {
    IFrontPanel,
    IFrontPanelEventSource,
    WorkQueue
} from "@opalkellytech/frontpanel-chromium-core";

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
