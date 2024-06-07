/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { EndpointAddress } from "./Endpoint";

/**
 * Type representing the address of a Wire endpoint.
 */
export type WireAddress = EndpointAddress;

/**
 * Type representing the width of a Wire endpoint, measured in bits.
 */
export type WireWidth = number;

/**
 * Type representing the value of a Wire endpoint.
 */
export type WireValue = number;

/*
 * Type representing a mask for a Wire endpoint.
 */
export type WireMask = number;
