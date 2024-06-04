/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { AddressRange } from "./AddressRange";

/**
 * Address range for WireIn endpoints.
 */
export const WIREIN_ADDRESS_RANGE: AddressRange = { Minimum: 0x00, Maximum: 0x1f };

/**
 * Address range for WireOut endpoints.
 */
export const WIREOUT_ADDRESS_RANGE: AddressRange = { Minimum: 0x20, Maximum: 0x3f };

/**
 * Address range for TriggerIn endpoints.
 */
export const TRIGGERIN_ADDRESS_RANGE: AddressRange = { Minimum: 0x40, Maximum: 0x5f };

/**
 * Address range for TriggerOut endpoints.
 */
export const TRIGGEROUT_ADDRESS_RANGE: AddressRange = {
    Minimum: 0x60,
    Maximum: 0x7f
};

/**
 * Address range for PipeIn endpoints.
 */
export const PIPEIN_ADDRESS_RANGE: AddressRange = { Minimum: 0x80, Maximum: 0x9f };

/**
 * Address range for PipeOut endpoints
 */
export const PIPEOUT_ADDRESS_RANGE: AddressRange = { Minimum: 0xa0, Maximum: 0xbf };
