Synchronizer Collection
=======================
This repository contains a collection of useful synchronizers that can
assist in passing various signals between asynchronous clock domains in
an FPGA design.


AutoBusSync
-----------
The AutoBusSync is a simple bus synchronizer used to synchronize a single
bus between two domains. This uses a request/acknowledge architecture and
therefore requires the bus to remain stable for a number of clock cycles
on each clock domain.

SyncReset
---------
The SyncReset module can be used to synchronize the deassertion of any
asynchronous reset signal to a given clock domain.

SyncTrig
--------
The SyncTrig module can be used to synchronize a "trigger" between two
different clock domains. A trigger is defined as a signal that remains
high for a single clock cycle.


Simulation
----------
Each synchronizer includes a basic test fixture to allow simulation and to
demonstrate use of the module. These simulations are not intended to be
exhaustive tests of the modules functionality.