import dma_pkg::*;

module axi_slave (
    input  logic clk,
    input  logic rst_n,

    axi_if.slave axi_if, // AXI interface instance

    // Interface with memory array
    output logic mem_write_en,
    output logic [31:0] mem_write_addr,
    output logic [31:0] mem_write_data,
    output logic mem_read_en,
    output logic [31:0] mem_read_addr,

    input  logic [31:0] mem_read_data
);

typedef enum logic [2:0] {
	AXI_SLAVE_IDLE,
    // WRITE STATES
    AXI_SLAVE_AWREADY,
    AXI_SLAVE_WREADY,
    AXI_SLAVE_BVALID,
    // READ STATES
    AXI_SLAVE_ARREADY,
    AXI_SLAVE_RBUFFER,
    AXI_SLAVE_RVALID
} AXI_SLAVE_STATE;

AXI_SLAVE_STATE state;

logic [31:0] axi_data_buffer; // Buffer to hold data for read operations
logic [31:0] axi_addr_buffer; // Buffer to hold address for read/write operations

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_if.awready <= 1'b0;
        axi_if.wready  <= 1'b0;
        axi_if.bvalid  <= 1'b0;
        axi_if.bresp   <= 2'b00;
        axi_if.rdata <= 32'b0;
        axi_if.rresp <= 2'b00;
        axi_if.rlast <= 1'b0;
        axi_data_buffer <= 32'b0;
        axi_addr_buffer <= 32'b0;
        mem_write_en <= 1'b0;
        mem_read_en <= 1'b0;
    end else begin
		case (state)
		AXI_SLAVE_IDLE: begin
            axi_if.bvalid <= 1'b0; // Reset bvalid signal
            axi_if.rvalid <= 1'b0;
            if (axi_if.awvalid) begin
                axi_if.awready <= 1'b1; // Indicate that the AXI slave is ready to accept a write address
                axi_addr_buffer <= axi_if.awaddr; // Buffer the write address
                state <= AXI_SLAVE_AWREADY; // Transition to the write address ready state
            end
            if (axi_if.arvalid) begin
                axi_if.arready <= 1'b1; // Indicate that the AXI slave is ready to accept a read address
                axi_addr_buffer <= axi_if.araddr; // Buffer the read address
                state <= AXI_SLAVE_ARREADY; // Transition to the read address ready state
            end    
		end

        // WRITE STATES
        AXI_SLAVE_AWREADY: begin
            axi_if.awready <= 1'b0; // Deassert awready after accepting the address
            axi_if.wready  <= 1'b1; // Indicate that the AXI slave is ready to accept write data
            state <= AXI_SLAVE_WREADY; // Transition to the write data ready state
        end

        AXI_SLAVE_WREADY: begin
            if(axi_if.wvalid && axi_if.wlast) begin // Assume single beat write for simplicity
                axi_if.wready <= 1'b0; // Deassert wready after accepting the data
                mem_write_en <= 1'b1;
                mem_write_addr <= axi_addr_buffer;
                mem_write_data <= axi_if.wdata;
                state <= AXI_SLAVE_BVALID; // Transition to the write response state
            end
        end

        AXI_SLAVE_BVALID: begin
            axi_if.bvalid <= 1'b1; // Indicate that the write response is valid
            axi_if.bresp  <= 2'b00; // OKAY response
            mem_write_en <= 1'b0; // Deassert memory write enable
            state <= AXI_SLAVE_IDLE; // Return to idle state
        end

        // READ STATES
        AXI_SLAVE_ARREADY: begin
            axi_if.arready <= 1'b0; // Deassert arready after accepting the address
            mem_read_en <= 1'b1;
            mem_read_addr <= axi_addr_buffer;
            state <= AXI_SLAVE_RBUFFER; // Transition to the read data valid state
        end

        AXI_SLAVE_RBUFFER: begin
            axi_data_buffer <= mem_read_data; // Buffer the read data from memory
            state <= AXI_SLAVE_RVALID; // Transition to the read data valid state
        end

        AXI_SLAVE_RVALID: begin
            axi_if.rdata <= mem_read_data; // Provide the read data from memory
            axi_if.rresp <= 2'b00; // OKAY response
            axi_if.rlast <= 1'b1; // Indicate that this is the last beat of the read transaction
            axi_if.rvalid <= 1'b1; // Indicate that the read data is valid
            mem_read_en <= 1'b0; // Deassert memory read enable

            if (axi_if.rready) begin
                state <= AXI_SLAVE_IDLE; // Return to idle state
            end
        end

        default: begin
            state <= AXI_SLAVE_IDLE; // Default to idle state on reset or unknown state
        end

        endcase
    end
end


endmodule