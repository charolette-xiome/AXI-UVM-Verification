
`ifndef MEMORY_INTERFACE_SV
`define MEMORY_INTERFACE_SV

//============================================================
// Passive Memory Interface
//============================================================

interface memory_interface #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 10
) (
    input logic clk,
    input logic rst_n
);

    //========================================================
    // Memory-Side Signals
    //========================================================

    logic                  mem_en;
    logic                  mem_we;
    logic [ADDR_WIDTH-1:0] mem_addr;
    logic [DATA_WIDTH-1:0] mem_wdata;
    logic [DATA_WIDTH-1:0] mem_rdata;

    //========================================================
    // Passive Monitor Modport
    // All signals are observed, never driven by the monitor.
    //========================================================

    modport MONITOR (
        input clk,
        input rst_n,

        input mem_en,
        input mem_we,
        input mem_addr,
        input mem_wdata,
        input mem_rdata
    );

endinterface : memory_interface

`endif
