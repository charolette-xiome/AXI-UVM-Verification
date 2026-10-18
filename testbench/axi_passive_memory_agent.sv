
`ifndef MEMORY_AGENT_SV
`define MEMORY_AGENT_SV

//============================================================
// Passive Memory Agent
//============================================================

class memory_agent extends uvm_agent;

    `uvm_component_utils(memory_agent)

    // Passive memory monitor
    memory_monitor monitor;

    //========================================================
    // Constructor
    //========================================================

    function new(
        string name = "memory_agent",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    //========================================================
    // Build Phase
    //========================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // This agent only observes DUT memory activity.
        is_active = UVM_PASSIVE;

        monitor = memory_monitor::type_id::create(
            "monitor",
            this
        );

    endfunction : build_phase

endclass : memory_agent

`endif
