module memory_array #(
    parameter DEPTH = 4096
)(
    input logic clk,

    input logic        write_en,
    input logic [31:0] write_addr,
    input logic [31:0] write_data,

    input logic        read_en,
    input logic [31:0] read_addr,

    output logic [31:0] read_data
);

logic [7:0] mem [0:DEPTH-1]; // compatible with byte addressing

always_ff @(posedge clk) begin
    if (write_en) begin
        mem[write_addr+0] <= write_data[7:0];
        mem[write_addr+1] <= write_data[15:8];
        mem[write_addr+2] <= write_data[23:16];
        mem[write_addr+3] <= write_data[31:24];
    end

    if (read_en) begin
        read_data <= {
            mem[read_addr+3],
            mem[read_addr+2],
            mem[read_addr+1],
            mem[read_addr+0]
        };
    end
end

endmodule