import dma_pkg::*;

module axi_master (
    input  logic clk,
    input  logic rst_n,

    // AXI Input Interface from DMA Controller
    input axi_cmd_t axi_cmd,
    axi_if.master axi_if, // AXI interface instance

    // AXI Output Interface to DMA Controller
    output logic axi_ready, // Indicates that the AXI memory model is ready to accept a command
    output logic axi_done, // Indicates that the AXI memory model has completed the command

    output read_resp_t axi_read_resp, // Read response structure to hold the read data and tag
    output logic fifo_r_en // Read enable signal for the read response FIFO
);

typedef enum logic [2:0] {
	AXI_MASTER_IDLE,
    // WRITE STATES
    AXI_MASTER_AWVALID,
    AXI_MASTER_WAIT_AWREADY,
    AXI_MASTER_WDATA,
    AXI_MASTER_WAIT_BVALID,
    // READ STATES
    AXI_MASTER_ARVALID,
    AXI_MASTER_WAIT_ARREADY,
    AXI_MASTER_WAIT_RDATA
} AXI_MASTER_STATE;

AXI_MASTER_STATE state;

logic [31:0] axi_wdata_buffer; // Buffer to hold data for write operations
logic [31:0] axi_addr_buffer; // Buffer to hold address for read/write operations
logic [7:0]  axi_tag_buffer;  // Buffer to hold tag for read operations

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_if.awvalid <= 1'b0;
        axi_if.wvalid  <= 1'b0;
        axi_if.bready  <= 1'b0;
        axi_if.arvalid <= 1'b0;
        axi_if.rready  <= 1'b0;
        axi_if.awaddr <= 32'b0;
        axi_if.wdata <= 32'b0;
        axi_if.araddr <= 32'b0;
        axi_if.wlast <= 1'b0;
        axi_wdata_buffer <= 32'b0;
        axi_addr_buffer <= 32'b0;
        axi_tag_buffer  <= 8'b0;
        axi_done <= 1'b0;
        axi_ready <= 1'b1; // Ready to accept a command after reset
    end else begin
		case (state)
		AXI_MASTER_IDLE: begin
            axi_ready <= 1'b1; // Indicate that the AXI master is ready to accept a command
            axi_done <= 1'b0; // Reset done signal
			if (axi_cmd.valid) begin
                axi_ready <= 1'b0; // Change to not ready when a command is being processed
                axi_addr_buffer <= axi_cmd.addr; // Buffer the address
                axi_wdata_buffer <= axi_cmd.data; // Buffer the data
                axi_tag_buffer  <= axi_cmd.tag;  // Buffer the tag
                if (axi_cmd.op == WRITE) begin
                    state <= AXI_MASTER_AWVALID;
                end else if (axi_cmd.op == READ) begin
                    state <= AXI_MASTER_ARVALID;
                end
            end
		end

        // WRITE STATES
        AXI_MASTER_AWVALID: begin
            axi_if.awaddr <= axi_cmd.addr;
            axi_if.awvalid <= 1'b1;
            state <= AXI_MASTER_WAIT_AWREADY;
        end

        AXI_MASTER_WAIT_AWREADY: begin
            if (axi_if.awready) begin
                axi_if.awvalid <= 1'b0; // Deassert awvalid after address is accepted
                state <= AXI_MASTER_WDATA;
            end
        end

        AXI_MASTER_WDATA: begin
            if(axi_if.wready) begin
                axi_if.wdata <= axi_cmd.data;
                axi_if.wlast <= 1'b1; // Assuming single beat write for simplicity
                axi_if.wvalid <= 1'b1;
                axi_if.bready <= 1'b1; // Ready to accept the write response
                state <= AXI_MASTER_WAIT_BVALID;
            end
        end

        AXI_MASTER_WAIT_BVALID: begin
            if (axi_if.bvalid) begin
                axi_if.wvalid <= 1'b0; // Deassert wvalid after data is accepted
                axi_if.bready <= 1'b0; // Deassert bready after response is received
                axi_if.wlast <= 1'b0; // Deassert wlast after write is complete
                axi_done <= 1'b1; // Indicate that the write operation is done
                state <= AXI_MASTER_IDLE; // Return to idle state
            end
        end

        // READ STATES
        AXI_MASTER_ARVALID: begin
            axi_if.araddr <= axi_cmd.addr;
            axi_if.arvalid <= 1'b1;
            state <= AXI_MASTER_WAIT_ARREADY; // Transition to wait for read data
        end

        AXI_MASTER_WAIT_ARREADY: begin
            if (axi_if.arready) begin
                axi_if.arvalid <= 1'b0; // Deassert arvalid after address is accepted
                axi_if.rready <= 1'b1; // Ready to accept the read data
                state <= AXI_MASTER_WAIT_RDATA;
            end
        end

        AXI_MASTER_WAIT_RDATA: begin
            if (axi_if.rvalid && axi_if.rlast) begin // Assuming single beat read for simplicity
                axi_if.rready <= 1'b0; // Deassert rready after data is received
                axi_done <= 1'b1; // Indicate that the read operation is done
                axi_read_resp.tag <= axi_tag_buffer; // Capture the tag for the read response
                axi_read_resp.data <= axi_if.rdata; // Capture the read data for the read
                fifo_r_en <= 1'b1; // Assert read enable for the read response FIFO
                state <= AXI_MASTER_IDLE; // Return to idle state
            end
        end

        default: begin
            state <= AXI_MASTER_IDLE; // Default to idle state
        end

        endcase
    end
end


endmodule