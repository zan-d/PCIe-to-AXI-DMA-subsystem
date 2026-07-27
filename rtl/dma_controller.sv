import dma_pkg::*;

module dma_controller (
    input  logic clk,
    input  logic rst_n,

    // DMA fetch command from FIFO
    output logic                 cmd_fifo_r_en,
    input dma_cmd_t              cmd_fifo_r_data,
    input logic                  cmd_fifo_empty,

    // DMA Input Interface from AXI Memory Model
    input logic                  axi_ready, // Indicates that the AXI memory model is ready to accept a command
    input logic                  axi_done, // Indicates that the AXI memory model has completed the command
    
    // DMA Output Interface to AXI Memory Model
    output axi_cmd_t             axi_cmd
);

typedef enum logic [1:0] {
	DMA_IDLE,
	DMA_PARSE_CMD,
    DMA_ISSUE_AXI_CMD,
    DMA_WAIT_FOR_AXI_DONE
} DMA_STATE;

DMA_STATE state;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_cmd.op <= READ;
        axi_cmd.valid <= 0;
        axi_cmd.addr <= 0;
        axi_cmd.data <= 0;
        axi_cmd.tag <= 0;
    end else begin
		case (state)
		DMA_IDLE: begin
			if (!cmd_fifo_empty) begin
                cmd_fifo_r_en <= 1'b1; // Enable reading from the FIFO
                state <= DMA_PARSE_CMD;
            end else begin
                cmd_fifo_r_en <= 1'b0; // Disable reading if FIFO is empty
            end
		end

		DMA_PARSE_CMD: begin
            // Fetch the command from the cmd FIFO
            axi_cmd.addr <= cmd_fifo_r_data.addr; // Address from the FIFO
            axi_cmd.op <= cmd_fifo_r_data.op; // Operation type from the FIFO
            axi_cmd.data <= cmd_fifo_r_data.data; // Data from the FIFO
            axi_cmd.tag <= cmd_fifo_r_data.tag; // Tag from the FIFO
            axi_cmd.valid <= 1'b1; // Assert valid
            state <= DMA_ISSUE_AXI_CMD;
        end

        DMA_ISSUE_AXI_CMD: begin
            if (axi_ready == 1'b1) begin
                // AXI memory model is ready to accept the command
                axi_cmd.valid <= 1'b0; // Deassert valid after issuing the command
                state <= DMA_WAIT_FOR_AXI_DONE;
            end
        end

        DMA_WAIT_FOR_AXI_DONE: begin
            if (axi_done == 1'b1) begin
                // AXI memory model has completed the command
                state <= DMA_IDLE; // Return to idle state after completion
            end
        end

        default: begin
            state <= DMA_IDLE; // Default to idle state
        end

        endcase
    end
end


endmodule