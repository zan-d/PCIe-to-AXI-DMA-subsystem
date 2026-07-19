vlib work
vlog ../rtl/sync_fifo.sv
vlog ../tb/tb_sync_fifo.sv

vsim -voptargs=+acc work.sync_fifo_tb
