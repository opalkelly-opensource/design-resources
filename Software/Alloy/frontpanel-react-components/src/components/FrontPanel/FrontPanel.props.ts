/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { IFrontPanel, IFrontPanelEventSource, WorkQueue } from "@opalkelly/frontpanel-alloy-core";

interface FrontPanelProps extends React.PropsWithChildren<NonNullable<unknown>> {
    /**
     * The front panel device to be used
     */
    device?: IFrontPanel;
    /**
     * Optional work queue to be used
     */
    workQueue?: WorkQueue;
    /**
     * Optional event source to be used
     */
    eventSource?: IFrontPanelEventSource;
}

export { FrontPanelProps };
