module rr_arbiter #(
    parameter int NUM_REQUESTERS = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input logic [NUM_REQUESTERS-1:0] request, // Request signals from each requester
    output logic [NUM_REQUESTERS-1:0] grant // Grant signals to each requester
);

input logic [$clog2(NUM_REQUESTERS)-1:0] grant_ptr; // Current grant index

// Combinational logic to determine which requester gets the grant
always_comb begin
    grant = 0;
    for (int i = 0; i < NUM_REQUESTERS; i++) begin
        int idx = (grant_ptr + i) % NUM_REQUESTERS; // Round-robin index
        if (request[idx]) begin
            grant[idx] = 1;
            break; // Grant to the first requester found
        end
    end
end

endmodule