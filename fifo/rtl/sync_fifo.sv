module sync_fifo #(
    parameter int DATA_WIDTH = 8, // Width of the data bus, how many bits each entry in the FIFO can hold
    parameter int DEPTH      = 16 // Number of entries in the FIFO
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Write Interface
    input  logic                  w_en,
    input  logic [DATA_WIDTH-1:0] w_data,

    // Read Interface
    input  logic                  r_en,
    output logic [DATA_WIDTH-1:0] r_data,

    // Status
    output logic                  full,
    output logic                  empty
);

// $clog2: ceiling of log2(DEPTH) to get the number of bits needed to address DEPTH locations
logic [$clog2(DEPTH)-1:0] w_ptr; // write pointer
logic [$clog2(DEPTH)-1:0] r_ptr; // read pointer

logic [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];

// On reset, initialize pointers, clear FIFO memory
always_ff@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_ptr <= 0;
        r_ptr <= 0;
        fifo_mem <= '{default: 0}; // Clear FIFO memory
    end else begin
        if (w_en && !full) begin
            // Write data to FIFO and increment write pointer
            fifo_mem[w_ptr] <= w_data;
            if(w_ptr == DEPTH - 1) begin
                w_ptr <= 0; // Wrap around if we reach the end of the FIFO
            end else begin
                w_ptr <= w_ptr + 1;
            end
        end 
        
        if (r_en && !empty) begin
            // Read data from FIFO and increment read pointer
            r_data <= fifo_mem[r_ptr];
            if(r_ptr == DEPTH - 1) begin
                r_ptr <= 0; // Wrap around if we reach the end of the FIFO
            end else begin
                r_ptr <= r_ptr + 1;
            end
        end
    end
end

// Set status flags
assign full = (w_ptr + 1) % DEPTH == r_ptr; // FIFO is full if the next write pointer equals the read pointer
                                            // Modulo operation ensures pointer wraps around at the end of the FIFO
assign empty = (w_ptr == r_ptr); // FIFO is empty if the write pointer equals the read pointer

endmodule