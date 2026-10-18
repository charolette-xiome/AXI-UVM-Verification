
`ifndef AXI_UVM_PKG_SV
`define AXI_UVM_PKG_SV

package axi_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    //==========================================================
    // AXI transaction and sequences
    //==========================================================

    `include "axi_sequence_item.sv"
    `include "axi_sequence.sv"
    `include "axi_sequencer.sv"

    //==========================================================
    // AXI driver and monitor
    //==========================================================

    `include "axi_driver.sv"
    `include "axi_driver_delay.sv"
    `include "axi_monitor.sv"
    `include "axi_agent.sv"

    //==========================================================
    // Reference model, scoreboard and functional coverage
    //==========================================================

    `include "axi_reference_model.sv"
    `include "axi_scoreboard.sv"
    `include "axi_coverage.sv"

    //==========================================================
    // Passive memory verification components
    //==========================================================

    `include "memory_transaction.sv"
    `include "memory_monitor.sv"
    `include "memory_agent.sv"
    `include "memory_checker.sv"
    `include "memory_coverage.sv"

    //==========================================================
    // Environment and test
    //==========================================================

    `include "axi_environment.sv"
    `include "axi_test.sv"

endpackage : axi_uvm_pkg

`endif
