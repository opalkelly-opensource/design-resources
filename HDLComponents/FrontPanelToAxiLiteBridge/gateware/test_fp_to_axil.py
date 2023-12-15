# ----------------------------------------------------------------------------------------
# Copyright (c) 2023 Opal Kelly Incorporated
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------
#
# Based on work by Alex Forencich:
#
# Copyright (c) 2020 Alex Forencich
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""
Testbench for fp_to_axil HDL Module

Description:
    This testbench utilizes Cocotb to cosimulate and validate the functionality of the fp_to_axil HDL module.
    It is built upon Alex Forencich's register testbench available on GitHub at verilog-axi/tb/axi_register/test_axi_register.py.
    The testbench also incorporates some of Alex Forencich's AXI interface modules for Cocotb.
    
    Prerequisites: cocotb, cocotbext-axi, cocotb-test
    To run on Linux: `pytest -o log_cli=True` in the current directory.
"""

import itertools
import logging
import os
import random

import cocotb_test.simulator
import pytest

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.regression import TestFactory

from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam

from cocotb.triggers import Lock

exclusive_access_lock = Lock()


class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())

        self.axil_ram = AxiLiteRam(AxiLiteBus.from_prefix(dut, "m_axil"), dut.aclk, dut.aresetn, size=2**16, reset_active_level=False)


    def set_idle_generator(self, generator=None):
        if generator:
            self.axil_ram.write_if.b_channel.set_pause_generator(generator())
            self.axil_ram.read_if.r_channel.set_pause_generator(generator())
            

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axil_ram.write_if.aw_channel.set_pause_generator(generator())
            self.axil_ram.write_if.w_channel.set_pause_generator(generator())
            self.axil_ram.read_if.ar_channel.set_pause_generator(generator())
            

    async def cycle_reset(self):
        self.dut.aresetn.setimmediatevalue(0)
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 0
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 1
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        
        
    async def frontpanel_write_axil_register(self, address, data):
        await exclusive_access_lock.acquire()
        
        self.dut.fp_to_axil_address.value = address
        data_out = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        data_out.buff = data
        self.dut.fp_to_axil_data_out = data_out
        self.dut.fp_to_axil_timeout_value.value = 100000000
        
        wire_out = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        wire_out = self.dut.fp_to_axil_status_out
        busy_flag = wire_out[0]
        while busy_flag == 1:
            await RisingEdge(self.dut.aclk)
            wire_out = self.dut.fp_to_axil_status_out
            busy_flag = wire_out[0]
        
        trigger_in = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        trigger_in[0] = 1
        self.dut.fp_to_axil_trigger_in_operation.value = trigger_in
        await RisingEdge(self.dut.aclk)
        trigger_in[0] = 0
        self.dut.fp_to_axil_trigger_in_operation.value = trigger_in
        await RisingEdge(self.dut.aclk)
        
        wire_out = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        wire_out = self.dut.fp_to_axil_status_out
        busy_flag = wire_out[0]
        while busy_flag == 1:
            await RisingEdge(self.dut.aclk)
            wire_out = self.dut.fp_to_axil_status_out
            busy_flag = wire_out[0]

        error_flag = self.dut.fp_to_axil_status_out.value
        exclusive_access_lock.release()
        return error_flag
        
    
    async def frontpanel_read_axil_register(self, address):
        await exclusive_access_lock.acquire()
        
        self.dut.fp_to_axil_address.value = address
        
        wire_out = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        wire_out = self.dut.fp_to_axil_status_out
        busy_flag = wire_out[0]
        while busy_flag == 1:
            await RisingEdge(self.dut.aclk)
            wire_out = self.dut.fp_to_axil_status_out
            busy_flag = wire_out[0]
            
        trigger_in = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        trigger_in[1] = 1
        self.dut.fp_to_axil_trigger_in_operation.value = trigger_in
        await RisingEdge(self.dut.aclk)
        trigger_in[1] = 0
        self.dut.fp_to_axil_trigger_in_operation.value = trigger_in
        await RisingEdge(self.dut.aclk)
        
        wire_out = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        wire_out = self.dut.fp_to_axil_status_out
        busy_flag = wire_out[0]
        while busy_flag == 1:
            await RisingEdge(self.dut.aclk)
            wire_out = self.dut.fp_to_axil_status_out
            busy_flag = wire_out[0]
        
        error_flag = self.dut.fp_to_axil_status_out.value[1]
        data_little_endian = cocotb.binary.BinaryValue(value=0, n_bits=32, bigEndian=False)
        data_little_endian.value = self.dut.fp_to_axil_data_in.value
        data = bytearray(data_little_endian.buff)
        
        exclusive_access_lock.release()
        return error_flag, data
        
        
async def run_test_write(dut, data_in=None, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    byte_lanes = 4

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for offset in range(0, 24, 4):
        tb.log.info("offset %d", offset)
        addr = offset+0x1000
        test_data = bytearray([x % 256 for x in range(byte_lanes)])

        tb.axil_ram.write(addr-128, b'\xaa'*(byte_lanes+256))

        error_code = await tb.frontpanel_write_axil_register(addr, test_data)

        tb.log.debug("%s", tb.axil_ram.hexdump_str((addr & ~0xf)-16, (((addr & 0xf)+byte_lanes-1) & ~0xf)+48))

        assert error_code == 0
        assert tb.axil_ram.read(addr, byte_lanes) == test_data
        assert tb.axil_ram.read(addr-1, 1) == b'\xaa'
        assert tb.axil_ram.read(addr+byte_lanes, 1) == b'\xaa'

    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)


async def run_test_read(dut, data_in=None, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    byte_lanes = 4

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for offset in range(0, 24, 4):
        tb.log.info("offset %d", offset)
        addr = offset+0x1000
        tb.axil_ram.write(addr-128, b'\xaa'*(byte_lanes+256))
        
        test_data = bytearray([x % 256 for x in range(byte_lanes)])

        tb.axil_ram.write(addr, test_data)
        tb.log.debug("%s", tb.axil_ram.hexdump_str((addr & ~0xf)-16, (((addr & 0xf)+byte_lanes-1) & ~0xf)+48))
        
        error_code, data = await tb.frontpanel_read_axil_register(addr)
        
        assert error_code == 0
        assert data == test_data

    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)


async def run_stress_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    async def worker(offset, aperture, count=16):
        byte_lanes = 4
        for k in range(count):
            addr = offset+random.randint(0, aperture)
            test_data = bytearray([random.randint(0, 255) for _ in range(4)])

            await Timer(random.randint(1, 100), 'ns')

            error_code = await tb.frontpanel_write_axil_register(addr, test_data)
            assert error_code == 0

            await Timer(random.randint(1, 100), 'ns')

            error_code, data = await tb.frontpanel_read_axil_register(addr)
            assert data == test_data
            assert error_code == 0

    workers = []

    for k in range(16):
        workers.append(cocotb.start_soon(worker(k*0x1000, 0x1000, count=16)))

    while workers:
        await workers.pop(0).join()

    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if cocotb.SIM_NAME:

    for test in [run_test_write, run_test_read]:

        factory = TestFactory(test)
        factory.add_option("idle_inserter", [None, cycle_pause])
        factory.add_option("backpressure_inserter", [None, cycle_pause])
        factory.generate_tests()

    factory = TestFactory(run_stress_test)
    factory.generate_tests()


# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))


def test_fp_to_axil(request):
    dut = "fp_to_axil"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(tests_dir, f"{dut}.v"),
    ]

    parameters = {}

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
        waves=1,
    )
    