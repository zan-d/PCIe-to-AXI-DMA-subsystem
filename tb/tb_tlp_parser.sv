module tlp_parser_tb;
    logic                  clk;
    logic                  rst_n;

    // TLP Input Interface
    logic                   tlp_valid;
    logic [31:0]            tlp_data;

    // TLP Output Interface to DMA engine
    logic                  dma_valid;
    logic                  dma_type;
    logic [31:0]           dma_addr;
    logic [9:0]            dma_length;
    logic [31:0]           dma_data;
    logic [7:0]            dma_tag;

    // Instantiate the TLP Parser
    tlp_parser tlp_parser_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tlp_valid(tlp_valid),
        .tlp_data(tlp_data),
        .dma_valid(dma_valid),
        .dma_type(dma_type),
        .dma_addr(dma_addr),
        .dma_length(dma_length),
        .dma_data(dma_data),
        .dma_tag(dma_tag)
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
        $monitor("Time: %0t | TLP Valid: %b | TLP Data: %h | DMA Valid: %b | DMA Type: %b | DMA Addr: %h | DMA Length: %d | DMA Data: %h | DMA Tag: %h",
                 $time, tlp_valid, tlp_data, dma_valid, dma_type, dma_addr, dma_length, dma_data, dma_tag);    
    end

    task automatic write_tlp(
        input logic [31:0] addr,
        input logic [31:0] data
        );
        begin
            tlp_valid <= 1'b1;
            @(posedge clk);
            tlp_data <= 32'h40000001; // TLP Header 1: Fmt=0b010, Type=0b00001 (Memory Write)
            @(posedge clk);
            tlp_data <= 32'h0000000f; // TLP Header 2: Requester ID=0x0000, Tag=0x00
            @(posedge clk);
            tlp_data <= addr;
            @(posedge clk);
            tlp_data <= data;
            @(posedge clk);
            tlp_valid <= 1'b0;
            
        end
    endtask

    task automatic read_tlp(
        input logic [7:0] tag,
        input logic [31:0] addr
        );
        begin
            tlp_valid <= 1'b1;
            @(posedge clk);
            tlp_data <=  32'h00000001; // TLP Header 1: Fmt=0b000, Type=0b00001 (Memory Read)
            @(posedge clk);
            tlp_data <=  {16'h0000, tag, 8'h00}; // TLP Header 2: Requester ID=0x0000, Tag=tag
            @(posedge clk);
            tlp_data <= addr;
            @(posedge clk);
            tlp_valid <= 1'b0;
            
        end
    endtask

    initial begin
        // Wait for reset deassertion
        wait(rst_n == 1'b1);

        // Write TLP
        write_tlp(32'h0000_1000, 32'hDEAD_BEEF);
        @(posedge clk);
        @(posedge clk);

        // Read TLP
        read_tlp(8'h01, 32'h0000_1000);
        @(posedge clk);
        @(posedge clk);

        // Finish simulation
        $finish;
    end


endmodule