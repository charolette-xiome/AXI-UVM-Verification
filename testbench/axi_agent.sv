
class axi_agent extends uvm_agent;

    `uvm_component_utils(axi_agent)

    //============================================================
    // Component Handles
    //============================================================

    axi_sequencer sequencer;
    axi_driver    driver;
    axi_monitor   monitor;

    //============================================================
    // Constructor
    //============================================================

    function new(string name = "axi_agent",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //============================================================
    // Build Phase
    //============================================================

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Monitor is instantiated in both active and passive modes.
        monitor = axi_monitor::type_id::create(
            "monitor",
            this
        );

        // Driver and sequencer are required only in active mode.
        if (is_active == UVM_ACTIVE) begin

            sequencer = axi_sequencer::type_id::create(
                "sequencer",
                this
            );

            driver = axi_driver::type_id::create(
                "driver",
                this
            );

        end
    endfunction : build_phase

    //============================================================
    // Connect Phase
    //============================================================

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect the driver to the sequencer in active mode.
        if (is_active == UVM_ACTIVE) begin

            driver.seq_item_port.connect(
                sequencer.seq_item_export
            );

        end
    endfunction : connect_phase

endclass : axi_agent
