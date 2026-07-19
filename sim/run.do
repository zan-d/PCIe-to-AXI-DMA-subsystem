vlib work
vlog ../fifo/rtl/sync_fifo.sv
vlog ../fifo/tb/tb_sync_fifo.sv

vsim -voptargs=+acc work.sync_fifo_tb
