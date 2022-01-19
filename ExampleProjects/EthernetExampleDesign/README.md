Ethernet Example Design
=======================
This is the Ethernet Example Design targeting the XEM8320 Opal Kelly development board. At least one SZG-ENET1G is required to run this example design. Product pages for these are at the following:
* [XEM8320 Opal Kelly Development Board](https://opalkelly.com/products/xem8320/)
* [SZG-ENET1G](https://docs.opalkelly.com/syzygy-peripherals/szg-enet1g/)

This example design's overview, requirements, and instructions are located at:
* [Ethernet Example Design](https://docs.opalkelly.com/xem8320/getting-started/ethernet-reference-design/)

The pre-built bitfile is located in the repository's Releases. Note that this was built with with an evaluation license and operation of the IP will halt after 2-8 hours from loading the bitfile:

## Overview
Our modified Xilinx Tri-Mode Ethernet MAC example design sources have been provided. We have annotated changes to the Xilinx sources with comments `// Opal Kelly`.
These comments will either be `// Opal Kelly additions` or `// Opal Kelly edits`.
You can search for these comments within these sources to determine what was changed from the example design provided by Xilinx.

Important changes to these sources are highlighted below.
* PHY configuration state machine now specifically targets the DP83867 PHY onboard the SZG-ENET1G.
* Added controllability and observability of the example design facilitated by the FrontPanel interface.
* Added functionality to set destination and source MAC addresses, inject errors, and count the number of packets sent and received.



## Building the Gateware
A valid license for the Xilinx Tri-Mode Ethernet Media Access Controller (TEMAC) IP is required if you wish to build the project. You can request an evaluation license through the Xilinx website. The pre-built bitfile already includes an entitled evaluation license.

Build instructions:
1. Open the `EthernetExampleDesign.xpr` project file in Vivado 2021.1.1. You must use Vivado 2021.1.1 or later to target the Artix UltraScale+ part.
2. In the reference design’s ‘EthernetExampleDesign’ folder create a folder called "FrontPanel".
3. Into this folder, copy the XEM8320's FrontPanel HDL from your FrontPanel installation directory.
4. Obtain a valid license for the Xilinx Tri-Mode Ethernet Media Access Controller (TEMAC) IP.
5. Generate the bitstream.