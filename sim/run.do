vlib work
vlog ../rtl/dma_controller.sv
vlog ../tb/tb_dma_controller.sv

vsim -voptargs=+acc work.dma_controller_tb
