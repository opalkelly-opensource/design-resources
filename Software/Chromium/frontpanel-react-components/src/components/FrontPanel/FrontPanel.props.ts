import {
    IFrontPanel,
    IFrontPanelEventSource,
    WorkQueue
} from "@opalkellytech/frontpanel-chromium-core";

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
