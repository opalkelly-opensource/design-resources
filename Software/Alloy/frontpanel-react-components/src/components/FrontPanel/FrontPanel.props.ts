/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
