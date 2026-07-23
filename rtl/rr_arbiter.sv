module rr_arbiter #(
    parameter int NUM_REQUESTERS = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input logic [NUM_REQUESTERS-1:0] request, // Request signals from each requester
    output logic [NUM_REQUESTERS-1:0] grant // Grant signals to each requester
);

logic [$clog2(NUM_REQUESTERS)-1:0] grant_ptr; // Current grant index
logic [$clog2(NUM_REQUESTERS)-1:0] last_ptr; // Next grant index

// Combinational logic to determine which requester gets the grant
always_comb begin
    for (int i = (NUM_REQUESTERS-1); i >= 0; i--) begin
        automatic int idx = (last_ptr + i) % NUM_REQUESTERS;
        if (request[idx]) begin
            grant_ptr <= idx % NUM_REQUESTERS;
            break;
        end
    end
end

always_ff@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        last_ptr <= 0; // Reset the last granted pointer
        grant <= 0; // Reset the grant signals
    end else begin
        if (request != 0) begin
            grant <= 1 << grant_ptr; // Grant to the current requester if it has a request
            last_ptr <= grant_ptr; // Update the last granted pointer
        end else begin
            grant <= 0; // No requests, no grants
        end
    end
end

endmodule