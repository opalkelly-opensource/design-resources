import { IFrontPanelEvent } from "./IFrontPanelEvent";

/**
 * Interface representing an object that provides FrontPanel events used
 * to monitor updates to WireOuts and TriggerOuts.
 */
interface IFrontPanelEventSource {
    /**
     * Event that notifies subscribers when WireOut values change.
     */
    get WireOutValuesChangedEvent(): IFrontPanelEvent;

    /**
     * Event that notifies subscribers when TriggerOut values change.
     */
    get TriggerOutValuesChangedEvent(): IFrontPanelEvent;
}

export default IFrontPanelEventSource;
