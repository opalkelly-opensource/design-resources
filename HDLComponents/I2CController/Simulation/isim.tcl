onerror {resume}

divider add "Toplevel"
wave add            /tf/clk
wave add            /tf/reset
wave add            /tf/start
wave add            /tf/done
wave add            /tf/memclk
wave add            /tf/memstart
wave add            /tf/memwrite
wave add            /tf/memread
wave add -radix hex /tf/memdin
wave add -radix hex /tf/memdout
wave add            /tf/i2c_sdat
wave add            /tf/i2c_sclk

divider add "Memory"
wave add -radix hex /tf/dut/cmem_addr
wave add -radix hex /tf/dut/cmem_dout
wave add            /tf/dut/rmem_write
wave add -radix hex /tf/dut/rmem_addr
wave add -radix hex /tf/dut/tok_dataout
wave add -radix hex /tf/dut/mem_addr

divider add "I2C Controller"
wave add                  /tf/go
wave add                  /tf/dut/i2c_sdat
wave add                  /tf/dut/i2c_sclk
wave add -radix unsigned  /tf/dut/state
wave add                  /tf/dut/twrite
wave add -radix unsigned  /tf/dut/preamble_count
wave add -radix unsigned  /tf/dut/preamble_length
wave add -radix unsigned  /tf/dut/payload_count
wave add -radix unsigned  /tf/dut/payload_length

divider add "I2C Tokenizer"
wave add -radix unsigned /tf/dut/tok/state
wave add                 /tf/dut/tok/tok_dataout
wave add                 /tf/dut/tok/i2c_dout
wave add                 /tf/dut/tok/i2c_sdat_oen
wave add                 /tf/dut/tok/i2c_sclk_oen
wave add                 /tf/dut/tok/stretch_clk
wave add                 /tf/dut/tok/i2c_sclk_oen_d
wave add -radix hex      /tf/dut/tok/divcount
wave add                 /tf/dut/tok/divenable
wave add                 /tf/dut/tok/tok_start
wave add                 /tf/dut/tok/tok_stop
wave add                 /tf/dut/tok/tok_write
wave add                 /tf/dut/tok/tok_read
wave add                 /tf/dut/tok/tok_done
wave add                 /tf/dut/tok/tok_rack
wave add                 /tf/dut/tok/tok_wack
wave add -radix hex      /tf/dut/tok/i2c_shift_count
wave add -radix hex      /tf/dut/tok/i2c_shift_reg

divider add "I2C Slave Emulation"
wave add                  /tf/i2c_start
wave add                  /tf/i2c_stop
wave add                  /tf/i2c_dir
wave add -radix unsigned  /tf/i2c_bitcursor
wave add -radix hex       /tf/i2c_wordcap
wave add -radix hex       /tf/i2c_devaddr
wave add                  /tf/i2c_sdout
wave add                  /tf/i2c_writing
wave add -radix hex       /tf/i2c_readmem
wave add -radix hex       /tf/i2c_readout
wave add -radix unsigned  /tf/i2c_readptr
wave add                  /tf/i2c_sclk_setup
wave add                  /tf/i2c_sclk_intent
wave add                  /tf/i2c_clk_stretch
wave add                  /tf/i2c_clk_stretch_count
 
run 1600us;
