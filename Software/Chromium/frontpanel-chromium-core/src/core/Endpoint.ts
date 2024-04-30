/**
 * Type representing a count of bytes.
 */
export type ByteCount = number;

/**
 * Type representing a count of bits.
 */
export type BitCount = number;

/**
 * Type representing the address of an endpoint.
 */
export type EndpointAddress = number;

/**
 * Represents the address of a bit within an endpoint.
 */
export type EndpointBitAddress = {
    /**
     * The address of the endpoint.
     */
    epAddress: EndpointAddress;

    /**
     * The offset from the LSB of the endpoint, measured in bits.
     */
    bitOffset: BitCount;
};

/**
 * Type representing a Register address.
 */
export type RegisterAddress = number;

/**
 * Type representing a Register value.
 */
export type RegisterValue = number;

/**
 * Type representing the address of a Pipe endpoint.
 */
export type PipeAddress = EndpointAddress;
