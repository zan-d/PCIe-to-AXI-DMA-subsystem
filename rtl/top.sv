import dma_pkg::*;

module top (
    input logic clk,
    input logic rst_n,
    input logic tlp_valid,
    input logic [31:0] tlp_data,
    output complete_tlp_t tlp_complete,
    output logic tlp_complete_valid
);

dma_cmd_t             dma_cmd;
logic                 cmd_fifo_w_en;

// DMA fetch command from FIFO
logic                  cmd_fifo_r_en;
dma_cmd_t              cmd_fifo_r_data;
logic                  cmd_fifo_empty;

// DMA command/response
axi_cmd_t       axi_cmd;
logic           axi_ready;
logic           axi_done;
read_resp_t     axi_read_resp;

logic                  fifo_r_en;

// Memory interface
logic           mem_write_en;
logic [31:0]    mem_write_addr;
logic [31:0]    mem_write_data;

logic           mem_read_en;
logic [31:0]    mem_read_addr;
logic [31:0]    mem_read_data;

logic                  read_resp_fifo_r_en;
read_resp_t            read_resp_fifo_r_data;
logic                  read_resp_fifo_empty;

axi_if axi_if_inst();

tlp_parser tlp_parser_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tlp_valid(tlp_valid),
    .tlp_data(tlp_data),
    .dma_cmd(dma_cmd),
    .cmd_fifo_w_en(cmd_fifo_w_en)
);

sync_fifo #( .DATA_WIDTH($bits(dma_cmd_t)), .DEPTH(3) ) cmd_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .w_en(cmd_fifo_w_en),
    .w_data(dma_cmd),
    .r_en(cmd_fifo_r_en),
    .r_data(cmd_fifo_r_data),
    .empty(cmd_fifo_empty)
);

dma_controller dma_controller_inst (
    .clk(clk),
    .rst_n(rst_n),
    .cmd_fifo_r_en(cmd_fifo_r_en),
    .cmd_fifo_r_data(cmd_fifo_r_data),
    .cmd_fifo_empty(cmd_fifo_empty),
    .axi_ready(axi_ready),
    .axi_done(axi_done),
    .axi_cmd(axi_cmd)
);

axi_master axi_master_inst (
    .clk(clk),
    .rst_n(rst_n),
    .axi_cmd(axi_cmd),
    .axi_if(axi_if_inst),
    .axi_ready(axi_ready),
    .axi_done(axi_done),
    .axi_read_resp(axi_read_resp),
    .fifo_r_en(fifo_r_en)
);

axi_slave axi_slave_inst (
    .clk(clk),
    .rst_n(rst_n),
    .axi_if(axi_if_inst),
    .mem_write_en(mem_write_en),
    .mem_write_addr(mem_write_addr),
    .mem_write_data(mem_write_data),
    .mem_read_en(mem_read_en),
    .mem_read_addr(mem_read_addr),
    .mem_read_data(mem_read_data)
);

memory_array #(.DEPTH(4096)) memory_array_inst (
    .clk(clk),
    .write_en(mem_write_en),
    .write_addr(mem_write_addr),
    .write_data(mem_write_data),
    .read_en(mem_read_en),
    .read_addr(mem_read_addr),
    .read_data(mem_read_data)
);

sync_fifo #( .DATA_WIDTH($bits(read_resp_t)), .DEPTH(3) ) read_resp_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .w_en(fifo_r_en),
    .w_data(axi_read_resp),
    .r_en(read_resp_fifo_r_en),
    .r_data(read_resp_fifo_r_data),
    .empty(read_resp_fifo_empty)
);

completion_gen completion_gen_inst (
    .clk(clk),
    .rst_n(rst_n),
    .axi_rfifo_r_en(read_resp_fifo_r_en),
    .axi_rfifo_r_data(read_resp_fifo_r_data),
    .axi_rfifo_empty(read_resp_fifo_empty),
    .tlp_complete(tlp_complete),
    .tlp_complete_valid(tlp_complete_valid)
);

endmodule