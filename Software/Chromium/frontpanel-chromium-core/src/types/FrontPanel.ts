/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
