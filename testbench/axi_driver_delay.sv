
class axi_driver_delay extends axi_driver;

    `uvm_component_utils(axi_driver_delay)


    //==========================================================
    // Configuration
    //==========================================================

    int unsigned address_delay_cycles = 1;

    int unsigned bready_delay_cycles = 2;
    int unsigned rready_delay_cycles = 2;


    //==========================================================
    // Constructor
    //==========================================================

    function new(
        string name = "axi_driver_delay",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    //==========================================================
    // One-Time Assertion Stress
    //
    // Generates two real writes and two real reads.
    //
    // The second AW/AR request is presented while the DUT is
    // still processing the first request. Therefore READY is
    // naturally LOW and VALID/payload are legally held until
    // the DUT becomes ready again.
    //==========================================================

    task assertion_stress();

        `uvm_info(
            "AXI_ASSERTION_STRESS",
            "Starting legal AW/W/AR assertion stress",
            UVM_LOW
        )


        //------------------------------------------------------
        // WRITE #1 - Address
        //------------------------------------------------------

        @(negedge vif.ACLK);

        vif.AWADDR  <= 16'h0600;
        vif.AWLEN   <= 8'd0;
        vif.AWSIZE  <= 3'd2;
        vif.AWVALID <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.AWVALID && vif.AWREADY));


        //------------------------------------------------------
        // After WRITE #1 AW handshake:
        //
        // - remove AWVALID for request #1
        // - immediately present WVALID for request #1
        // - present AW request #2 while DUT is busy
        //
        // AWREADY will be LOW naturally.
        //------------------------------------------------------

        @(negedge vif.ACLK);

        vif.AWVALID <= 1'b0;

        vif.WDATA   <= 32'h1111_AAAA;
        vif.WLAST   <= 1'b1;
        vif.WVALID  <= 1'b1;


        // Real second write address
        vif.AWADDR  <= 16'h0610;
        vif.AWLEN   <= 8'd0;
        vif.AWSIZE  <= 3'd2;
        vif.AWVALID <= 1'b1;


        //------------------------------------------------------
        // Complete WRITE #1 data
        //
        // WVALID is already HIGH before WREADY becomes HIGH,
        // exercising:
        //
        //   assert_wvalid_stable
        //   assert_wdata_stable
        //   assert_wlast_stable
        //------------------------------------------------------

        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.WVALID && vif.WREADY));


        @(negedge vif.ACLK);

        vif.WVALID <= 1'b0;
        vif.WLAST  <= 1'b0;


        //------------------------------------------------------
        // WRITE #1 response
        //------------------------------------------------------

        vif.BREADY <= 1'b0;


        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.BVALID);


        repeat (bready_delay_cycles)
            @(posedge vif.ACLK);


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.BVALID && vif.BREADY));


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;


        //------------------------------------------------------
        // WRITE #2 address has remained asserted and stable
        // while DUT was busy.
        //
        // Wait until DUT finally accepts it.
        //------------------------------------------------------

        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.AWVALID && vif.AWREADY));


        //------------------------------------------------------
        // Important:
        //
        // AWVALID remained HIGH until the real handshake.
        // Therefore no protocol violation is introduced.
        //------------------------------------------------------

        @(negedge vif.ACLK);

        vif.AWVALID <= 1'b0;


        //------------------------------------------------------
        // WRITE #2 data
        //------------------------------------------------------

        vif.WDATA  <= 32'h2222_BBBB;
        vif.WLAST  <= 1'b1;
        vif.WVALID <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.WVALID && vif.WREADY));


        @(negedge vif.ACLK);

        vif.WVALID <= 1'b0;
        vif.WLAST  <= 1'b0;


        //------------------------------------------------------
        // WRITE #2 response
        //------------------------------------------------------

        vif.BREADY <= 1'b0;


        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.BVALID);


        repeat (bready_delay_cycles)
            @(posedge vif.ACLK);


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.BVALID && vif.BREADY));


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;


        //======================================================
        // READ STRESS
        //======================================================


        //------------------------------------------------------
        // READ #1 address
        //------------------------------------------------------

        vif.ARADDR  <= 16'h0600;
        vif.ARLEN   <= 8'd0;
        vif.ARSIZE  <= 3'd2;
        vif.ARVALID <= 1'b1;

        vif.RREADY  <= 1'b0;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.ARVALID && vif.ARREADY));


        //------------------------------------------------------
        // Present READ #2 while READ #1 is still active.
        //
        // ARREADY is naturally LOW while the read FSM is busy.
        //------------------------------------------------------

        @(negedge vif.ACLK);

        vif.ARVALID <= 1'b0;

        vif.ARADDR  <= 16'h0610;
        vif.ARLEN   <= 8'd0;
        vif.ARSIZE  <= 3'd2;
        vif.ARVALID <= 1'b1;


        //------------------------------------------------------
        // Complete READ #1 with backpressure
        //------------------------------------------------------

        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.RVALID);


        repeat (rready_delay_cycles)
            @(posedge vif.ACLK);


        @(negedge vif.ACLK);

        vif.RREADY <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.RVALID && vif.RREADY));


        @(negedge vif.ACLK);

        vif.RREADY <= 1'b0;


        //------------------------------------------------------
        // READ #2 address has remained asserted while the
        // DUT was busy.
        //
        // Wait for the real AR handshake.
        //------------------------------------------------------

        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.ARVALID && vif.ARREADY));


        @(negedge vif.ACLK);

        vif.ARVALID <= 1'b0;


        //------------------------------------------------------
        // Complete READ #2 with backpressure
        //------------------------------------------------------

        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.RVALID);


        repeat (rready_delay_cycles)
            @(posedge vif.ACLK);


        @(negedge vif.ACLK);

        vif.RREADY <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.RVALID && vif.RREADY));


        @(negedge vif.ACLK);

        vif.RREADY <= 1'b0;


        `uvm_info(
            "AXI_ASSERTION_STRESS",
            "Legal AW/W/AR assertion stress completed",
            UVM_LOW
        )

    endtask


    //==========================================================
    // Normal Delayed WRITE
    //==========================================================

    virtual task drive_write(
        axi_transaction tr
    );

        int unsigned beat_count;


        `uvm_info(
            "AXI_DRIVER_DELAY",
            $sformatf(
                "Starting delayed WRITE: addr=0x%04h len=%0d size=%0d",
                tr.addr,
                tr.len,
                tr.size
            ),
            UVM_MEDIUM
        )


        //======================================================
        // AW Channel
        //======================================================

        repeat (address_delay_cycles)
            @(posedge vif.ACLK);


        @(negedge vif.ACLK);

        vif.AWADDR  <= tr.addr;
        vif.AWLEN   <= tr.len;
        vif.AWSIZE  <= tr.size;
        vif.AWVALID <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.AWVALID && vif.AWREADY));


        //======================================================
        // AW handshake is complete.
        //
        // Deassert AWVALID normally.
        //
        // At the same negedge, present first W beat EARLY.
        // DUT is entering W_ADDR and WREADY is still LOW.
        //======================================================

        beat_count = tr.beats();


        @(negedge vif.ACLK);

        vif.AWVALID <= 1'b0;

        vif.WDATA  <= tr.data[0];
        vif.WLAST  <= (beat_count == 1);
        vif.WVALID <= 1'b1;


        //======================================================
        // W Channel
        //======================================================

        for (int i = 0; i < beat_count; i++) begin


            //--------------------------------------------------
            // For i=0, WVALID was already asserted above.
            //
            // For later beats, present the next beat after
            // the previous handshake.
            //--------------------------------------------------

            if (i > 0) begin

                vif.WDATA  <= tr.data[i];
                vif.WLAST  <= (i == beat_count - 1);
                vif.WVALID <= 1'b1;

            end


            //--------------------------------------------------
            // Hold WVALID/WDATA/WLAST until handshake.
            //--------------------------------------------------

            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.WVALID && vif.WREADY));


            @(negedge vif.ACLK);

            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;


            //--------------------------------------------------
            // Prepare next beat without inserting an
            // unnecessary full-cycle gap.
            //--------------------------------------------------

            if (i < beat_count - 1) begin

                vif.WDATA  <= tr.data[i + 1];
                vif.WLAST  <= (i + 1 == beat_count - 1);
                vif.WVALID <= 1'b1;

            end

        end


        //======================================================
        // B Channel Backpressure
        //======================================================

        vif.BREADY <= 1'b0;


        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.BVALID);


        repeat (bready_delay_cycles)
            @(posedge vif.ACLK);


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!(vif.BVALID && vif.BREADY));


        tr.response = vif.BRESP;


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;


        `uvm_info(
            "AXI_DRIVER_DELAY",
            $sformatf(
                "Delayed WRITE completed: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr,
                tr.len,
                tr.size,
                tr.response
            ),
            UVM_MEDIUM
        )

    endtask


    //==========================================================
    // Normal Delayed READ
    //==========================================================

    virtual task drive_read(
        axi_transaction tr
    );

        int unsigned beat_index;
        int unsigned expected_beats;


        `uvm_info(
            "AXI_DRIVER_DELAY",
            $sformatf(
                "Starting delayed READ: addr=0x%04h len=%0d size=%0d",
                tr.addr,
                tr.len,
                tr.size
            ),
            UVM_MEDIUM
        )


        //======================================================
        // AR Channel
        //======================================================

        repeat (address_delay_cycles)
            @(posedge vif.ACLK);


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


        //------------------------------------------------------
        // Normal legal AR completion.
        //------------------------------------------------------

        @(negedge vif.ACLK);

        vif.ARVALID <= 1'b0;


        //======================================================
        // Prepare storage
        //======================================================

        expected_beats = tr.beats();

        tr.read_data = new[expected_beats];

        beat_index  = 0;
        tr.saw_last = 1'b0;


        //======================================================
        // R Channel
        //======================================================

        while (beat_index < expected_beats) begin


            vif.RREADY <= 1'b0;


            do begin
                @(posedge vif.ACLK);
            end
            while (!vif.RVALID);


            //--------------------------------------------------
            // Legal read backpressure
            //--------------------------------------------------

            repeat (rready_delay_cycles)
                @(posedge vif.ACLK);


            @(negedge vif.ACLK);

            vif.RREADY <= 1'b1;


            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.RVALID && vif.RREADY));


            //--------------------------------------------------
            // Capture beat
            //--------------------------------------------------

            tr.read_data[beat_index] = vif.RDATA;
            tr.response              = vif.RRESP;


            if (vif.RLAST)
                tr.saw_last = 1'b1;


            beat_index++;


            @(negedge vif.ACLK);

            vif.RREADY <= 1'b0;

        end


        `uvm_info(
            "AXI_DRIVER_DELAY",
            $sformatf(
                "Delayed READ completed: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr,
                tr.len,
                tr.size,
                tr.response
            ),
            UVM_MEDIUM
        )

    endtask


    //==========================================================
    // Run Phase
    //==========================================================

    task run_phase(
        uvm_phase phase
    );

        axi_transaction tr;


        //======================================================
        // Reset
        //======================================================

        wait_for_reset_release();


        `uvm_info(
            "AXI_DRIVER_DELAY",
            "Delayed AXI UVM Driver started",
            UVM_LOW
        )


        //======================================================
        // ONE-TIME ASSERTION CLOSURE
        //
        // Executed before normal sequencer traffic.
        //
        // These are real AXI operations and are visible to:
        //
        //   Monitor
        //   Scoreboard
        //   Coverage
        //   Memory Agent
        //======================================================

        assertion_stress();


        //======================================================
        // Normal UVM Sequence Traffic
        //======================================================

        forever begin


            seq_item_port.get_next_item(tr);


            if (tr.op == axi_transaction::WRITE) begin

                drive_write(tr);

            end

            else begin

                drive_read(tr);

            end


            driven_transactions++;


            seq_item_port.item_done();

        end

    endtask


    //==========================================================
    // Report Phase
    //==========================================================

    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);


        `uvm_info(
            "AXI_DRIVER_DELAY_REPORT",
            "axi_driver_delay was selected through the UVM factory override; legal assertion-stress traffic was enabled",
            UVM_LOW
        )

    endfunction


endclass
