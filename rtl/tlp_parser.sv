import dma_pkg::*;

module tlp_parser (
    input  logic                  clk,
    input  logic                  rst_n,

    // TLP Input Interface
    input logic                   tlp_valid,
    input logic [31:0]            tlp_data,

    // TLP Output Interface to DMA engine
    output dma_cmd_t              dma_cmd,
    output logic                  cmd_fifo_w_en
);

typedef enum logic [2:0] {
	TLP_IDLE,
	TLP_STRIP_FILE_HEADER_1,
	TLP_STRIP_FILE_HEADER_2,
	TLP_WRITE_FIRST_BYTE_RECEIVE,
	TLP_WRITE_SECOND_BYTE_RECEIVE,
	TLP_READ_FIRST_BYTE_RECEIVE,
    TLP_READ_COMPLETION
} TLP_STATE;

TLP_STATE state;

// TLP Header 1
logic [1:0] tlp_fmt;
logic [4:0] tlp_type;
logic [9:0] tlp_length;

// TLP Header 2
logic [15:0] tlp_requester_id;
logic [7:0] tlp_tag;

// TLP Address
logic [31:0] tlp_addr;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dma_cmd.op <= READ;
        dma_cmd.addr <= 0;
        dma_cmd.length <= 0;
        dma_cmd.data <= 0;
        dma_cmd.tag <= 0;
        cmd_fifo_w_en <= 1'b0;
    end else begin
		case (state)
		TLP_IDLE: begin
            cmd_fifo_w_en <= 1'b0; // Default to not writing to FIFO
			if (tlp_valid == 1'b1) begin
				state <= TLP_STRIP_FILE_HEADER_1;
			end
		end

		TLP_STRIP_FILE_HEADER_1: begin
            if (tlp_valid == 1'b1) begin
                // Process the first TLP header
                tlp_fmt <= tlp_data[30:29];
                tlp_type <= tlp_data[28:24];
                tlp_length <= tlp_data[9:0];

                state <= TLP_STRIP_FILE_HEADER_2;
            end
        end

        TLP_STRIP_FILE_HEADER_2: begin
            if (tlp_valid == 1'b1) begin
                // Process the second TLP header
                tlp_requester_id <= tlp_data[31:16];
                tlp_tag <= tlp_data[15:8];

                // Determine the type of TLP
                if({tlp_fmt,tlp_type} == 8'h00) begin // Memory Read Request
                    state <= TLP_READ_FIRST_BYTE_RECEIVE;
                end else if({tlp_fmt,tlp_type} == 8'h40) begin // Memory Write Request
                    state <= TLP_WRITE_FIRST_BYTE_RECEIVE;
                end
            end
        end

        TLP_WRITE_FIRST_BYTE_RECEIVE: begin
            if (tlp_valid == 1'b1) begin
                tlp_addr <= tlp_data[31:0]; // Extract the address from the TLP data
                state <= TLP_WRITE_SECOND_BYTE_RECEIVE;
            end
        end

        TLP_WRITE_SECOND_BYTE_RECEIVE: begin
            if (tlp_valid == 1'b1) begin
                // Create the DMA write request based on the TLP information
                dma_cmd.op <= WRITE;
                dma_cmd.addr <= tlp_addr;
                dma_cmd.length <= tlp_length;
                dma_cmd.data <= tlp_data; // Assuming the data is in the second byte
                dma_cmd.tag <= tlp_tag;
                cmd_fifo_w_en <= 1'b1; // Enable write to the command FIFO

                state <= TLP_IDLE; // Return to idle state after processing
            end
        end

        TLP_READ_FIRST_BYTE_RECEIVE: begin
            if (tlp_valid == 1'b1) begin
                // Create the DMA read request based on the TLP information
                dma_cmd.op <= READ;
                dma_cmd.addr <= tlp_data[31:0]; // Extract the address from the TLP data
                dma_cmd.length <= tlp_length;
                dma_cmd.data <= 0;
                dma_cmd.tag <= tlp_tag;
                cmd_fifo_w_en <= 1'b1; // Enable write to the command FIFO
                
                state <= TLP_IDLE;
            end
        end

        default: begin
            state <= TLP_IDLE;
        end

        endcase
        
    end
end

endmodule