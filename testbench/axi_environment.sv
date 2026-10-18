
`ifndef AXI_ENVIRONMENT_SV
`define AXI_ENVIRONMENT_SV

//============================================================
// AXI UVM Environment
//============================================================

class axi_environment extends uvm_env;

    `uvm_component_utils(axi_environment)

    //========================================================
    // AXI Verification Components
    //========================================================

    axi_agent      agent;
    axi_scoreboard scoreboard;
    axi_coverage   coverage;

    //========================================================
    // Memory Verification Components
    //========================================================

    memory_agent    mem_agent;
    memory_checker  mem_checker;
    memory_coverage mem_coverage;

    //========================================================
    // Constructor
    //========================================================

    function new(
        string name = "axi_environment",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction : new

    //========================================================
    // Build Phase
    //========================================================

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // AXI-side components
        agent = axi_agent::type_id::create(
            "agent",
            this
        );

        scoreboard = axi_scoreboard::type_id::create(
            "scoreboard",
            this
        );

        coverage = axi_coverage::type_id::create(
            "coverage",
            this
        );

        // Memory-side components
        mem_agent = memory_agent::type_id::create(
            "mem_agent",
            this
        );

        mem_checker = memory_checker::type_id::create(
            "mem_checker",
            this
        );

        mem_coverage = memory_coverage::type_id::create(
            "mem_coverage",
            this
        );

    endfunction : build_phase

    //========================================================
    // Connect Phase
    //========================================================

    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        // AXI monitor -> scoreboard
        agent.monitor.ap.connect(
            scoreboard.analysis_export
        );

        // AXI monitor -> functional coverage
        agent.monitor.ap.connect(
            coverage.analysis_export
        );

        // Memory monitor -> memory checker
        mem_agent.monitor.ap.connect(
            mem_checker.analysis_export
        );

        // Memory monitor -> memory coverage
        mem_agent.monitor.ap.connect(
            mem_coverage.analysis_export
        );

    endfunction : connect_phase

endclass : axi_environment

`endif
