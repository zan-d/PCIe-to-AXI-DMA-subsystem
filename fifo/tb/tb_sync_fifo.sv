module sync_fifo_tb;
    // Parameters
    parameter int DATA_WIDTH = 8;
    parameter int DEPTH      = 6;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Write Interface
    logic w_en;
    logic [DATA_WIDTH-1:0] w_data;

    // Read Interface
    logic r_en;
    logic [DATA_WIDTH-1:0] r_data;

    // Status
    logic full;
    logic empty;

    logic [DATA_WIDTH-1:0] data;

    // Instantiate the FIFO
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .w_en(w_en),
        .w_data(w_data),
        .r_en(r_en),
        .r_data(r_data),
        .full(full),
        .empty(empty)
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

    // Monitor
    initial begin
        $monitor("time=%0t full=%b empty=%b w_en=%b r_en=%b w_ptr=%0d r_ptr=%0d", $time, full, empty, w_en, r_en, fifo_inst.w_ptr, fifo_inst.r_ptr);
    end

    task automatic write_fifo(input logic [DATA_WIDTH-1:0] data);
        begin
            // Wait until FIFO is not full
            while(full)
                @(posedge clk);

            w_data = data;
            w_en = 1;

            @(posedge clk);

            w_en = 0;

            @(posedge clk);
        end
    endtask

    task automatic read_fifo(output logic [DATA_WIDTH-1:0] data);
    begin
        while (empty)
            @(posedge clk);

        r_en <= 1;
        @(posedge clk);

        // Wait until DUT updates r_data
        #1;
        data = r_data;

        r_en <= 0;
    end
    endtask

    task automatic reset();
        begin
            @(posedge clk);
            rst_n = 0;
            @(posedge clk);
            rst_n = 1;
        end
    endtask


    // Test read and write operations
    initial begin
        wait(rst_n == 1);

        // Write data to FIFO
        write_fifo(8'h11);
        write_fifo(8'h22);
        write_fifo(8'h33);

        read_fifo(data);
        $display("Read = %h", data);
        if (data !== 8'h11) begin
            $display("Error: Expected 0x11, got %h", data);
        end

        read_fifo(data);
        $display("Read = %h", data);
        if (data !== 8'h22) begin
            $display("Error: Expected 0x22, got %h", data);
        end

        read_fifo(data);
        $display("Read = %h", data);
        if (data !== 8'h33) begin
            $display("Error: Expected 0x33, got %h", data);
        end
        
        reset();

        // Test full
        for (int i = 0; i < DEPTH; i++)
            write_fifo(i);

        if (!full)
            $error("FIFO didn't become full");

        // Test empty
        for (int i = 0; i < DEPTH; i++)
            read_fifo(data);

        if (!empty)
            $error("FIFO didn't become empty");

        // Second round to check wrap around bit behavior
        // Test full
        for (int i = 0; i < DEPTH; i++)
            write_fifo(i);

        if (!full)
            $error("FIFO didn't become full");

        // Test empty
        for (int i = 0; i < DEPTH; i++)
            read_fifo(data);

        if (!empty)
            $error("FIFO didn't become empty");

        #20;
    end
endmodule