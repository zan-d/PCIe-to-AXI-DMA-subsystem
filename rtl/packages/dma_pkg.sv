package dma_pkg;

typedef enum logic {
    READ,
    WRITE
} operation_t;

typedef struct packed {
    operation_t    op;
    logic [31:0]   addr;
    logic [9:0]    length;
    logic [31:0]   data;
    logic [7:0]    tag;          // Needed for read completions
} dma_cmd_t;

typedef struct packed {
    logic [2:0]    fmt;
    logic [4:0]    tlp_type;
    logic [9:0]    length;
    logic [15:0]   completion_id;
    logic [2:0]    status;
    logic [11:0]   byte_count;
    logic [15:0]   requester_id;
    logic [7:0]    tag;
    logic [31:0]   data;         // Needed for read completions
} complete_tlp_t;

typedef struct packed {
    operation_t      op;
    logic         valid;
    logic [31:0]  addr;
    logic [31:0]  data;
    logic [7:0]   tag;          // Needed for read completions
} axi_cmd_t;

typedef struct packed {
    logic [7:0]    tag; 
    logic [31:0]   data;
} read_resp_t;

endpackage