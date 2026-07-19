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

parameter PTR_WIDTH = $clog2(DEPTH);
// $clog2: ceiling of log2(DEPTH) to get the number of bits needed to address DEPTH locations
logic [PTR_WIDTH:0] w_ptr; // write pointer
logic [PTR_WIDTH:0] r_ptr; // read pointer

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
            fifo_mem[w_ptr[PTR_WIDTH-1:0]] <= w_data;
            if(w_ptr[PTR_WIDTH-1:0] == DEPTH - 1) begin
                w_ptr[PTR_WIDTH-1:0] <= 0; // Wrap around if we reach the end of the FIFO
                w_ptr[PTR_WIDTH] <= ~w_ptr[PTR_WIDTH]; // Toggle the wrapper bit to indicate wrap around
            end else begin
                w_ptr <= w_ptr + 1;
            end
        end 
        
        if (r_en && !empty) begin
            // Read data from FIFO and increment read pointer
            r_data <= fifo_mem[r_ptr[PTR_WIDTH-1:0]];
            if(r_ptr[PTR_WIDTH-1:0] == DEPTH - 1) begin
                r_ptr[PTR_WIDTH-1:0] <= 0; // Wrap around if we reach the end of the FIFO
                r_ptr[PTR_WIDTH] <= ~r_ptr[PTR_WIDTH]; // Toggle the wrapper bit to indicate wrap around
            end else begin
                r_ptr <= r_ptr + 1;
            end
        end
    end
end

// Set status flags
assign wrap = w_ptr[PTR_WIDTH] ^ r_ptr[PTR_WIDTH];
assign full = wrap && (w_ptr[PTR_WIDTH-1:0] == r_ptr[PTR_WIDTH-1:0]); // FIFO is full if wrapper bit is different and the lower bits of the write pointer equal the read pointer
assign empty = (w_ptr == r_ptr); // FIFO is empty if the write pointer equals the read pointer

endmodule