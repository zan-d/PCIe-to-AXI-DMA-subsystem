vlib work
vlog ../interfaces/axi_if.sv
vlog ../rtl/axi_master.sv
vlog ../rtl/axi_slave.sv
vlog ../rtl/axi_memory_array.sv
vlog ../tb/tb_axi_interface.sv

vsim -voptargs=+acc work.axi_interface_tb
