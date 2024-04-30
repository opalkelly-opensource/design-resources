import { IFrontPanel } from "../core";

declare global {
    interface Window {
        /**
         * The FrontPanel object.
         */
        FrontPanel: IFrontPanel;
    }
}

export {}; // this file needs to be a module
