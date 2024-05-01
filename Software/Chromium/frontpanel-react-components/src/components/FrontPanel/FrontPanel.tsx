import React from "react";

import { FrontPanelPeriodicUpdateTimer, WorkQueue } from "@opalkellytech/frontpanel-chromium-core";

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
