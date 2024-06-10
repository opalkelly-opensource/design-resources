/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
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
