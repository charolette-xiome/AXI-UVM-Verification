
`ifndef AXI_INTERFACE_SV
`define AXI_INTERFACE_SV

//============================================================
// AXI SystemVerilog Interface
//============================================================

interface axi_interface #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16
)(
    input logic ACLK,
    input logic ARESETn
);

    //========================================================
    // Write Address Channel
    //========================================================

    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0]            AWLEN;
    logic [2:0]            AWSIZE;
    logic                  AWVALID;
    logic                  AWREADY;

    //========================================================
    // Write Data Channel
    //========================================================

    logic [DATA_WIDTH-1:0] WDATA;
    logic                  WVALID;
    logic                  WLAST;
    logic                  WREADY;

    //========================================================
    // Write Response Channel
    //========================================================

    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    //========================================================
    // Read Address Channel
    //========================================================

    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0]            ARLEN;
    logic [2:0]            ARSIZE;
    logic                  ARVALID;
    logic                  ARREADY;

    //========================================================
    // Read Data Channel
    //========================================================

    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RLAST;
    logic                  RREADY;

    //========================================================
    // MASTER Modport
    //========================================================

    modport MASTER (
        input  ACLK,
        input  ARESETn,

        // Write address
        output AWADDR,
        output AWLEN,
        output AWSIZE,
        output AWVALID,
        input  AWREADY,

        // Write data
        output WDATA,
        output WVALID,
        output WLAST,
        input  WREADY,

        // Write response
        input  BRESP,
        input  BVALID,
        output BREADY,

        // Read address
        output ARADDR,
        output ARLEN,
        output ARSIZE,
        output ARVALID,
        input  ARREADY,

        // Read data
        input  RDATA,
        input  RRESP,
        input  RVALID,
        input  RLAST,
        output RREADY
    );

    //========================================================
    // SLAVE Modport
    //========================================================

    modport SLAVE (
        input  ACLK,
        input  ARESETn,

        // Write address
        input  AWADDR,
        input  AWLEN,
        input  AWSIZE,
        input  AWVALID,
        output AWREADY,

        // Write data
        input  WDATA,
        input  WVALID,
        input  WLAST,
        output WREADY,

        // Write response
        output BRESP,
        output BVALID,
        input  BREADY,

        // Read address
        input  ARADDR,
        input  ARLEN,
        input  ARSIZE,
        input  ARVALID,
        output ARREADY,

        // Read data
        output RDATA,
        output RRESP,
        output RVALID,
        output RLAST,
        input  RREADY
    );

    //========================================================
    // MONITOR Modport
    //========================================================

    modport MONITOR (
        input ACLK,
        input ARESETn,

        input AWADDR,
        input AWLEN,
        input AWSIZE,
        input AWVALID,
        input AWREADY,

        input WDATA,
        input WVALID,
        input WLAST,
        input WREADY,

        input BRESP,
        input BVALID,
        input BREADY,

        input ARADDR,
        input ARLEN,
        input ARSIZE,
        input ARVALID,
        input ARREADY,

        input RDATA,
        input RRESP,
        input RVALID,
        input RLAST,
        input RREADY
    );

endinterface : axi_interface

`endif
