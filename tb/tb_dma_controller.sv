import dma_pkg::*;

module dma_controller_tb;
    logic                  clk;
    logic                  rst_n;

    // DMA fetch command from FIFO
    logic                  cmd_fifo_r_en;
    dma_cmd_t              cmd_fifo_r_data;
    logic                  cmd_fifo_empty;

    // DMA Input Interface from AXI Memory Model
    logic                  axi_ready;
    logic                  axi_done;
    
    // DMA Output Interface to AXI Memory Model
    axi_cmd_t              axi_cmd;

    // Instantiate the DMA Controller
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
        $monitor("Time: %0t | FIFO Read Enable: %b | FIFO Read Data: %h | FIFO Empty: %b | AXI Ready: %b | AXI Done: %b | AXI Command: {op: %b, valid: %b, addr: %h, data: %h, tag: %h}",
                 $time, cmd_fifo_r_en, cmd_fifo_r_data, cmd_fifo_empty, axi_ready, axi_done, axi_cmd.op, axi_cmd.valid, axi_cmd.addr, axi_cmd.data, axi_cmd.tag);    
    end

    initial begin
        // Wait for reset deassertion
        wait(rst_n == 1'b1);
        axi_ready = 1'b0; // Initially, AXI is not ready
        axi_done = 1'b0; // Initially, AXI is not done
        
        // Simulate a command in the FIFO
        @(posedge clk);
        cmd_fifo_empty = 1'b0; // FIFO is not empty initially
        cmd_fifo_r_data = '{
            op: WRITE,
            addr: 32'h0000_1000,
            length: 10'h001,
            data: 32'hDEAD_BEEF,
            tag: 8'h01
        };
        
        @(posedge clk);
        @(posedge clk);
        cmd_fifo_empty = 1'b1; // FIFO becomes empty after some time

        @(posedge clk);
        // Simulate AXI ready and done signals
        axi_ready = 1'b1; // AXI is ready to accept command
        @(posedge clk);
        axi_done = 1'b0; // AXI is not done
        @(posedge clk);
        axi_ready = 1'b0; // AXI is not ready
        @(posedge clk);
        axi_done = 1'b1; // AXI has completed the command

        #20;
    end


endmodule