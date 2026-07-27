import dma_pkg::*;

module axi_interface_tb;

    logic clk;
    logic rst_n;

    // DUT interface
    axi_if axi_if_inst();

    // DMA command/response
    axi_cmd_t       axi_cmd;
    logic           axi_ready;
    logic           axi_done;
    read_resp_t     axi_read_resp;

    // Memory interface
    logic           mem_write_en;
    logic [31:0]    mem_write_addr;
    logic [31:0]    mem_write_data;

    logic           mem_read_en;
    logic [31:0]    mem_read_addr;
    logic [31:0]    mem_read_data;

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

    memory_array #(
        .DEPTH(4096)
    ) memory_array_inst (
        .clk(clk),
        .write_en(mem_write_en),
        .write_addr(mem_write_addr),
        .write_data(mem_write_data),
        .read_en(mem_read_en),
        .read_addr(mem_read_addr),
        .read_data(mem_read_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test reset
    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;
    end

    initial begin
        $monitor("Time: %0t | AXI Ready: %b | AXI Done: %b | AXI Command: {op: %b, valid: %b, addr: %h, data: %h, tag: %h} | AXI Read Response: {tag: %h, data: %h}",
                 $time, axi_ready, axi_done, axi_cmd.op, axi_cmd.valid, axi_cmd.addr, axi_cmd.data, axi_cmd.tag,
                 axi_read_resp.tag, axi_read_resp.data);
    end

    initial begin
        wait(rst_n);

        @(posedge clk);
        // Write
        wait(axi_ready);
        axi_cmd <= '{
            op    : WRITE,
            valid : 1'b1,
            addr  : 32'h0000_0004,
            data  : 32'hDEAD_BEEF,
            tag   : 8'h01
        };

        @(posedge clk);
        axi_cmd.valid = 1'b0;

        wait(axi_done);

        // Read
        wait(axi_ready);
        axi_cmd = '{
            op    : READ,
            valid : 1'b1,
            addr  : 32'h0000_0004,
            data  : '0,
            tag   : 8'h01
        };

        @(posedge clk);
        axi_cmd.valid = 1'b0;

        wait(axi_done);

        if (axi_read_resp.data == 32'hDEAD_BEEF)
            $display("PASS: Read data = %h", axi_read_resp.data);
        else
            $display("FAIL: Expected DEAD_BEEF, got %h",
                     axi_read_resp.data);

        #20;
    end

endmodule