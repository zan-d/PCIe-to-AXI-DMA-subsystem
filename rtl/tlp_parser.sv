module tlp_parser (
    input  logic                  clk,
    input  logic                  rst_n,

    // TLP Input Interface
    input logic                   tlp_valid,
    input logic                   tlp_data,

    // TLP Output Interface to DMA engine
    output logic                  dma_valid,
    output logic                  dma_type,
    output logic [31:0]           dma_addr,
    output logic [9:0]            dma_length,
    output logic [31:0]           dma_data,
    output logic [7:0]            dma_tag
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
        dma_valid <= 0;
        dma_type <= 0;
        dma_addr <= 0;
        dma_length <= 0;
        dma_data <= 0;
        dma_tag <= 0;
    end else begin
		case (state)
		TLP_IDLE: begin
			if (tlp_valid == 1'b1) begin
				state <= TLP_STRIP_FILE_HEADER_1;
			end
		end

		TLP_STRIP_FILE_HEADER_1: begin
            if (tlp_valid == 1'b1) begin
                // Process the first TLP header
                tlp_fmt <= tlp_data[29:30];
                tlp_type <= tlp_data[24:28];
                tlp_length <= tlp_data[0:9];

                state <= TLP_STRIP_FILE_HEADER_2;
            end
        end

        TLP_STRIP_FILE_HEADER_2: begin
            if (tlp_valid == 1'b1) begin
                // Process the second TLP header
                tlp_requester_id <= tlp_data[16:31];
                tlp_tag <= tlp_data[15:8];

                // Determine the type of TLP
                if(tlp_type == 2'b00) begin // Memory Read Request
                    state <= TLP_READ_FIRST_BYTE_RECEIVE;
                end else if(tlp_type == 2'b10) begin // Memory Write Request
                    state <= TLP_WRITE_FIRST_BYTE_RECEIVE;
                end
            end
        end

        TLP_WRITE_FIRST_BYTE_RECEIVE: begin
            if (tlp_valid == 1'b1) begin
                tlp_addr <= tlp_data[0:31]; // Extract the address from the TLP data
                state <= TLP_WRITE_SECOND_BYTE_RECEIVE;
            end
        end

        TLP_WRITE_SECOND_BYTE_RECEIVE: begin
            if (tlp_valid == 1'b1) begin
                // Create the DMA write request based on the TLP information
                dma_valid <= 1'b1;
                dma_type <= 1'b0; // Indicate a write operation
                dma_addr <= tlp_addr;
                dma_length <= tlp_length;
                dma_data <= tlp_data; // Assuming the data is in the second byte
                dma_tag <= tlp_tag;

                state <= TLP_IDLE; // Return to idle state after processing
            end
        end

        TLP_READ_FIRST_BYTE_RECEIVE: begin
            if (tlp_valid == 1'b1) begin
                // Create the DMA read request based on the TLP information
                dma_valid <= 1'b1;
                dma_type <= 1'b1; // Indicate a read operation 
                dma_addr <= tlp_data[0:31]; // Extract the address from the TLP data
                dma_length <= tlp_length;
                dma_tag <= tlp_tag;
                
                state <= TLP_IDLE;
            end
        end

        default: begin
            state <= TLP_IDLE;
        end

        endcase
        
    end


endmodule