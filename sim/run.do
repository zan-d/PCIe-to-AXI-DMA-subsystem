vlib work
vlog ../rtl/tlp_parser.sv
vlog ../tb/tb_tlp_parser.sv

vsim -voptargs=+acc work.tlp_parser_tb
