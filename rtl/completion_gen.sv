import dma_pkg::*;

module completion_gen (
    input  logic clk,
    input  logic rst_n,

    // Read Response FIFO Interface
    output logic                 axi_rfifo_r_en,
    input read_resp_t            axi_rfifo_r_data,
    input logic                  axi_rfifo_empty,

    output complete_tlp_t         tlp_complete,
    output logic                  tlp_complete_valid
);

always_ff@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tlp_complete.fmt <= 0;
        tlp_complete.tlp_type <= 0;
        tlp_complete.length <= 0;
        tlp_complete.completion_id <= 0;
        tlp_complete.status <= 0;
        tlp_complete.byte_count <= 0;
        tlp_complete.requester_id <= 0;
        tlp_complete.tag <= 0;
        tlp_complete.data <= 0;
        tlp_complete_valid <= 1'b0;
    end else begin
        if (!axi_rfifo_empty) begin
            axi_rfifo_r_en <= 1'b1; // Enable read from FIFO
            tlp_complete.fmt <= 3'h2; // Set format for completion TLP
            tlp_complete.tlp_type <= 5'h0a;
            tlp_complete.length <= 10'b1;
            tlp_complete.completion_id <= 16'h0100; // Set completion ID, bus number and device/function number can be set as needed
            tlp_complete.status <= 3'b000; // Set status to success, no error handling for simplicity
            tlp_complete.byte_count <= 4'h4; // Set byte count to 4 bytes for a single DWORD
            tlp_complete.requester_id <= 15'h0000; // Set requester ID, can be set as needed
            tlp_complete.tag <= axi_rfifo_r_data.tag;
            tlp_complete.data <= axi_rfifo_r_data.data; // Capture data for read completions
            tlp_complete_valid <= 1'b1; // Indicate that a valid completion TLP is available
        end else begin
            axi_rfifo_r_en <= 1'b0; // Disable read from FIFO when empty
        end
    end
end

endmodule