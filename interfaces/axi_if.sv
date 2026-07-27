interface axi_if #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32);
    // Write Address Channel
    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0] wdata;
    logic                  wlast;
    logic                  wvalid;
    logic                  wready;

    // Write Response Channel
    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;

    // Read Address Channel
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

    // Read Data Channel
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rlast;
    logic                  rvalid;
    logic                  rready;

    // Modport for Master
    modport master (
        output awaddr, awvalid,
        input awready,
        output wdata, wlast, wvalid,
        input wready,
        input bresp, bvalid,
        output bready,
        output araddr, arvalid,
        input arready,
        input rdata, rresp, rvalid, rlast,
        output rready
    );

    // Modport for Slave
    modport slave (
        input awaddr, awvalid,
        output awready,
        input wdata, wlast, wvalid,
        output wready,
        output bresp, bvalid,
        input bready,
        input araddr, arvalid,
        output arready,
        output rdata, rresp, rvalid, rlast,
        input rready
    );
endinterface