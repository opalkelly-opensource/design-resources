import { EndpointAddress, EndpointBitAddress } from "./Endpoint";

/**
 * Type representing the address of a Trigger vector endpoint.
 */
export type TriggerVectorAddress = EndpointAddress;

/**
 * Type representing a Trigger vector.
 */
export type TriggerVector = number;

/**
 * Type representing the width of a Trigger vector, measured in bits.
 */
export type TriggerVectorWidth = number;

/**
 * Type representing a Trigger vector mask.
 */
export type TriggerVectorMask = number;

/**
 * Type representing the state of a Trigger, which is a boolean.
 */
export type TriggerState = boolean;

/**
 * Type representing the address of a Trigger.
 */
export type TriggerAddress = EndpointBitAddress;
