import dma_pkg::*;

module top_tb;

    logic clk;
    logic rst_n;

    // TLP Input Interface
    logic                   tlp_valid;
    logic [31:0]            tlp_data;

    complete_tlp_t         tlp_complete;
    logic                  tlp_complete_valid;

    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .tlp_valid(tlp_valid),
        .tlp_data(tlp_data),
        .tlp_complete(tlp_complete),
        .tlp_complete_valid(tlp_complete_valid)
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
        $monitor("Time: %0t | TLP Valid: %b | TLP Data: %h | TLP Complete: {data: %h, tag: %h}",
                 $time, tlp_valid, tlp_data, tlp_complete.data, tlp_complete.tag);    
    end

    initial begin
        // Wait for reset deassertion
        wait(rst_n == 1'b1);
        
        // Simulate a command in the FIFO
        @(posedge clk);
        tlp_valid = 1'b1;
        @(posedge clk);
        tlp_data = 32'h40000001; // TLP Header 1
        @(posedge clk);
        tlp_data = 32'h0000000f; // TLP Header 2
        @(posedge clk);
        tlp_data = 32'h00000008; // Address
        @(posedge clk);
        tlp_data = 32'h12345678; // Data
        @(posedge clk);
        tlp_valid = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);


        // Simulate a read command in the FIFO
        tlp_valid = 1'b1;
        @(posedge clk);
        tlp_data = 32'h00000001; // TLP Header 1
        @(posedge clk);
        tlp_data = 32'h00000c0f; // TLP Header 2
        @(posedge clk);
        tlp_data = 32'h00000008; // Address
        @(posedge clk);
        tlp_valid = 1'b0;
        @(posedge clk);

        // Wait for some time to observe the outputs
        wait(tlp_complete_valid == 1'b1);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        if (tlp_complete.fmt !== 3'h2 || 
            tlp_complete.tlp_type !== 5'h0a || 
            tlp_complete.length !== 10'b1 ||
            tlp_complete.completion_id !== 16'h0100 || 
            tlp_complete.status !== 3'b000 ||
            tlp_complete.byte_count !== 12'h4 || 
            tlp_complete.requester_id !== 16'h0000 ||
            tlp_complete.tag !== 8'h0c || 
            tlp_complete.data !== 32'h12345678) begin
            $display("Test failed: Completion TLP does not match expected values. expected: {fmt: 3'h2, tlp_type: 5'h0a, length: 10'b1, completion_id: 16'h0100, status: 3'b000, byte_count: 12'h4, requester_id: 16'h0000, tag: 8'h0c, data: 32'h12345678}, Got: {fmt: %h, tlp_type: %h, length: %h, completion_id: %h, status: %h, byte_count: %h, requester_id: %h, tag: %h, data: %h}",
                     tlp_complete.fmt,
                     tlp_complete.tlp_type,
                     tlp_complete.length,
                     tlp_complete.completion_id,
                     tlp_complete.status,
                     tlp_complete.byte_count,
                     tlp_complete.requester_id,
                     tlp_complete.tag,
                     tlp_complete.data);
        end else begin
            $display("Test passed: Completion TLP matches expected values.");
        end

        #20;

    end

endmodule