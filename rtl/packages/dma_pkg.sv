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
    operation_t      op;
    logic         valid;
    logic [31:0]  addr;
    logic [31:0]  data;
    logic [7:0]   tag;          // Needed for read completions
} axi_cmd_t;

endpackage