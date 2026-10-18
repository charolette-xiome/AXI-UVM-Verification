
class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    //============================================================
    // Class Properties
    //============================================================

    virtual axi_interface.MASTER vif;

    int unsigned driven_transactions;

    //============================================================
    // Constructor
    //============================================================

    function new(
        string name = "axi_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
        driven_transactions = 0;
    endfunction : new

    //============================================================
    // Build Phase
    //============================================================

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(
                virtual axi_interface.MASTER
            )::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "AXI_DRIVER",
                "Failed to get virtual interface from uvm_config_db"
            )

        end

    endfunction : build_phase

    //============================================================
    // Reset Master-Driven Signals
    //============================================================

    virtual task reset_master_signals();

        vif.AWADDR  <= '0;
        vif.AWLEN   <= '0;
        vif.AWSIZE  <= '0;
        vif.AWVALID <= 1'b0;

        vif.WDATA   <= '0;
        vif.WVALID  <= 1'b0;
        vif.WLAST   <= 1'b0;

        vif.BREADY  <= 1'b0;

        vif.ARADDR  <= '0;
        vif.ARLEN   <= '0;
        vif.ARSIZE  <= '0;
        vif.ARVALID <= 1'b0;

        vif.RREADY  <= 1'b0;

    endtask : reset_master_signals

    //============================================================
    // Wait for Reset Release
    //============================================================

    virtual task wait_for_reset_release();

        reset_master_signals();

        wait (vif.ARESETn === 1'b1);

        @(negedge vif.ACLK);

    endtask : wait_for_reset_release

    //============================================================
    // Drive AXI Write Transaction
    //============================================================

    virtual task drive_write(axi_transaction tr);

        int unsigned beat_count;

        // Validate transaction data before driving.
        beat_count = tr.beats();

        if (beat_count == 0) begin
            `uvm_fatal(
                "AXI_DRIVER",
                "Invalid write transaction: zero beats"
            )
        end

        if (tr.data.size() < beat_count) begin
            `uvm_fatal(
                "AXI_DRIVER",
                $sformatf(
                    "Write data array too small: size=%0d expected=%0d",
                    tr.data.size(),
                    beat_count
                )
            )
        end

        //========================================================
        // Write Address Channel
        //========================================================

        @(negedge vif.ACLK);

        vif.AWADDR  <= tr.addr;
        vif.AWLEN   <= tr.len;
        vif.AWSIZE  <= tr.size;
        vif.AWVALID <= 1'b1;

        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.AWVALID && vif.AWREADY));

        @(negedge vif.ACLK);

        vif.AWVALID <= 1'b0;

        //========================================================
        // Write Data Channel
        //========================================================

        for (int i = 0; i < beat_count; i++) begin

            vif.WDATA  <= tr.data[i];
            vif.WLAST  <= (i == beat_count - 1);
            vif.WVALID <= 1'b1;

            // Hold payload and VALID until handshake.
            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.WVALID && vif.WREADY));

            @(negedge vif.ACLK);

            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;

        end

        //========================================================
        // Write Response Channel
        //========================================================

        vif.BREADY <= 1'b1;

        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.BVALID && vif.BREADY));

        tr.response = vif.BRESP;

        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;

        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "WRITE completed: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr,
                tr.len,
                tr.size,
                tr.response
            ),
            UVM_MEDIUM
        )

    endtask : drive_write

    //============================================================
    // Drive AXI Read Transaction
    //============================================================

    virtual task drive_read(axi_transaction tr);

        int unsigned beat_index;
        int unsigned expected_beats;
        bit expected_last;

        expected_beats = tr.beats();

        if (expected_beats == 0) begin
            `uvm_fatal(
                "AXI_DRIVER",
                "Invalid read transaction: zero beats"
            )
        end

        //========================================================
        // Read Address Channel
        //========================================================

        @(negedge vif.ACLK);

        vif.ARADDR  <= tr.addr;
        vif.ARLEN   <= tr.len;
        vif.ARSIZE  <= tr.size;
        vif.ARVALID <= 1'b1;

        vif.RREADY <= 1'b0;

        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.ARVALID && vif.ARREADY));

        @(negedge vif.ACLK);

        vif.ARVALID <= 1'b0;

        //========================================================
        // Allocate Read Data Storage
        //========================================================

        tr.read_data = new[expected_beats];

        beat_index = 0;
        tr.saw_last = 1'b0;

        //========================================================
        // Read Data Channel
        //========================================================

        vif.RREADY <= 1'b1;

        while (beat_index < expected_beats) begin

            @(posedge vif.ACLK);

            if (vif.RVALID && vif.RREADY) begin

                tr.read_data[beat_index] = vif.RDATA;
                tr.response = vif.RRESP;

                expected_last =
                    (beat_index == expected_beats - 1);

                // Check RLAST on the accepted beat.
                if (vif.RLAST !== expected_last) begin

                    `uvm_error(
                        "AXI_DRIVER",
                        $sformatf(
                            "RLAST mismatch at beat %0d of %0d: observed=%0b expected=%0b",
                            beat_index,
                            expected_beats,
                            vif.RLAST,
                            expected_last
                        )
                    )

                end

                if (vif.RLAST === 1'b1)
                    tr.saw_last = 1'b1;

                beat_index++;

            end

        end

        @(negedge vif.ACLK);

        vif.RREADY <= 1'b0;

        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "READ completed: addr=0x%04h len=%0d size=%0d response=%02b saw_last=%0b",
                tr.addr,
                tr.len,
                tr.size,
                tr.response,
                tr.saw_last
            ),
            UVM_MEDIUM
        )

    endtask : drive_read

    //============================================================
    // Run Phase
    //============================================================

    virtual task run_phase(uvm_phase phase);

        axi_transaction tr;

        wait_for_reset_release();

        `uvm_info(
            "AXI_DRIVER",
            "AXI UVM Driver started",
            UVM_LOW
        )

        forever begin

            // Wait for the next sequence item.
            seq_item_port.get_next_item(tr);

            // Execute the selected transaction.
            if (tr.op == axi_transaction::WRITE) begin
                drive_write(tr);
            end
            else begin
                drive_read(tr);
            end

            driven_transactions++;

            // Complete the sequencer-driver handshake.
            seq_item_port.item_done();

        end

    endtask : run_phase

    //============================================================
    // Report Phase
    //============================================================

    virtual function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "AXI_DRIVER_REPORT",
            $sformatf(
                "Total AXI transactions driven = %0d",
                driven_transactions
            ),
            UVM_LOW
        )

    endfunction : report_phase

endclass : axi_driver
