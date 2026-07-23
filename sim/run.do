vlib work
vlog ../rtl/rr_arbiter.sv
vlog ../tb/tb_rr_arbiter.sv

vsim -voptargs=+acc work.rr_arbiter_tb
