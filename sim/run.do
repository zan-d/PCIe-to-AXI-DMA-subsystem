vlib work
vlog ../interfaces/axi_if.sv
vlog ../rtl/sync_fifo.sv
vlog ../rtl/tlp_parser.sv
vlog ../rtl/dma_controller.sv
vlog ../rtl/axi_master.sv
vlog ../rtl/axi_slave.sv
vlog ../rtl/axi_memory_array.sv
vlog ../rtl/completion_gen.sv
vlog ../rtl/top.sv
vlog ../tb/tb_top.sv

vsim -voptargs=+acc work.top_tb
