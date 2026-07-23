module rr_arbiter_tb;
    // Parameters
    parameter int NUM_REQUESTERS = 4;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Request and Grant signals
    logic [NUM_REQUESTERS-1:0] request;
    logic [NUM_REQUESTERS-1:0] grant;

    // Instantiate the Round-Robin Arbiter
    rr_arbiter #(
        .NUM_REQUESTERS(NUM_REQUESTERS)
    ) arbiter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .request(request),
        .grant(grant)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // Test reset
    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;
    end

    // Monitor
    initial begin
        $monitor("time=%0t request=%b grant=%b", $time, request, grant);
    end

    // Test sequence
    initial begin
        // Initialize request signals
        request = 0;
        wait(rst_n == 1);

        // Test case 1: Single requester
        $display("\nTest case 1: Single requester");
        @(posedge clk);
        request = 4'b1000;
        @(posedge clk);
        #1;
        $display("request=%b grant = %b", request, grant);
        if (grant !== request) begin
            $display("Error: Expected 4'b1000, got %b", grant);
        end
        request = 0;
        @(posedge clk);

        // Test case 2: Multiple requesters
        $display("\nTest case 2: Multiple requesters");
        request = 4'b0110;
        @(posedge clk);
        #1;
        $display("request=%b grant = %b", request, grant);
        if (grant !== 4'b0100) begin
            $display("Error: Expected 4'b0100, got %b", grant);
        end
        request = 4'b0010;
        @(posedge clk);
        #1;
        $display("request=%b grant = %b", request, grant);
        if (grant !== 4'b0010) begin
            $display("Error: Expected 4'b0010, got %b", grant);
        end
        request = 0;
        @(posedge clk);

        // Test case 3: All requesters
        $display("\nTest case 3: All requesters");
        request = 4'b1111;
        @(posedge clk);
        #1;
        $display("request=%b grant = %b", request, grant);
        if (grant !== 4'b0001) begin
            $display("Error: Expected 4'b0001, got %b", grant);
        end
        request = 4'b1110;
        @(posedge clk);
        #1;
        $display("request=%b grant = %b", request, grant);
        if (grant !== 4'b1000) begin
            $display("Error: Expected 4'b1000, got %b", grant);
        end
        request = 0;

        // Finish simulation
        #20;
        // $finish;
    end
    
endmodule