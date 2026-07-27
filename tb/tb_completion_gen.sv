import dma_pkg::*;

module completion_gen_tb;
    logic                  clk;
    logic                  rst_n;

    // Read Response FIFO Interface
    logic                  axi_rfifo_r_en;
    read_resp_t            axi_rfifo_r_data;
    logic                  axi_rfifo_empty;

    complete_tlp_t         tlp_complete;

    completion_gen completion_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .axi_rfifo_r_en(axi_rfifo_r_en),
        .axi_rfifo_r_data(axi_rfifo_r_data),
        .axi_rfifo_empty(axi_rfifo_empty),
        .tlp_complete(tlp_complete)
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
        $monitor("Time: %0t | FIFO Read Enable: %b | FIFO Read Data: {tag: %h, data: %h} | FIFO Empty: %b | Completion TLP: {fmt: %h, type: %h, length: %h, completion_id: %h, status: %h, byte_count: %h, requester_id: %h, tag: %h, data: %h}",
                 $time, axi_rfifo_r_en, axi_rfifo_r_data.tag, axi_rfifo_r_data.data, axi_rfifo_empty,
                 tlp_complete.fmt, tlp_complete.tlp_type, tlp_complete.length, tlp_complete.completion_id,
                 tlp_complete.status, tlp_complete.byte_count, tlp_complete.requester_id,
                 tlp_complete.tag, tlp_complete.data);
    end

    initial begin
        // Wait for reset deassertion
        wait(rst_n == 1'b1);
        axi_rfifo_empty = 1'b0; // Initially, FIFO is not empty
        @(posedge clk);
        axi_rfifo_r_data = '{tag: 8'hAA, data: 32'hDEAD_BEEF}; // Simulate a read response in the FIFO
        @(posedge clk);
        // Check if the completion TLP is generated correctly
        #1;
        if (tlp_complete.fmt !== 3'h2 || tlp_complete.tlp_type !== 5'h0a || tlp_complete.length !== 10'b1 ||
            tlp_complete.completion_id !== 16'h0100 || tlp_complete.status !== 3'b000 ||
            tlp_complete.byte_count !== 4'h4 || tlp_complete.requester_id !== 15'h0000 ||
            tlp_complete.tag !== 8'hAA || tlp_complete.data !== 32'hDEAD_BEEF) begin
            $display("Test failed: Completion TLP does not match expected values.");
        end else begin
            $display("Test passed: Completion TLP matches expected values.");
        end

        #20;
    end


endmodule