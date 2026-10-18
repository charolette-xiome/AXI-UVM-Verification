
`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

//============================================================
// AXI UVM Monitor
//
// Features:
//   1. UVM OOP and factory registration
//   2. Independent AW, W, B, AR and R observation
//   3. Supports overlapping AW and W channel activity
//   4. Parameterized interface with 32-bit transaction data
//   5. Reset-aware transaction collection
//   6. WLAST and RLAST checking
//   7. Analysis-port transaction publication
//
// Assumptions:
//   - One outstanding write and one outstanding read.
//   - axi_transaction uses 32-bit data elements.
//   - axi_transaction defines WRITE, READ, beats(), data,
//     read_data, response and saw_last.
//============================================================

class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    //============================================================
    // Virtual Interface
    //============================================================

    virtual axi_interface.MONITOR vif;

    //============================================================
    // Analysis Port
    //============================================================

    uvm_analysis_port #(axi_transaction) ap;

    //============================================================
    // Write Transaction State
    //============================================================

    protected axi_transaction write_tr;

    protected bit write_active;
    protected bit write_aw_seen;
    protected bit write_last_seen;
    protected bit write_last_correct;

    protected int unsigned write_expected_beats;
    protected int unsigned write_beat_count;

    protected bit [31:0] write_data_q[$];

    //============================================================
    // Read Transaction State
    //============================================================

    protected axi_transaction read_tr;

    protected bit read_active;
    protected bit read_last_seen;
    protected bit read_last_correct;

    protected int unsigned read_expected_beats;
    protected int unsigned read_beat_count;

    protected bit [31:0] read_data_q[$];

    protected bit [1:0] last_rresp;

    //============================================================
    // Constructor
    //============================================================

    function new(
        string name = "axi_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

        write_active        = 1'b0;
        write_aw_seen       = 1'b0;
        write_last_seen     = 1'b0;
        write_last_correct  = 1'b0;
        write_expected_beats = 0;
        write_beat_count     = 0;

        read_active         = 1'b0;
        read_last_seen      = 1'b0;
        read_last_correct   = 1'b0;
        read_expected_beats = 0;
        read_beat_count     = 0;

        last_rresp = 2'b00;

    endfunction : new

    //============================================================
    // Build Phase
    //============================================================

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(
                virtual axi_interface.MONITOR
            )::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "AXI_MONITOR",
                "Failed to get virtual interface from uvm_config_db"
            )

        end

        if ($bits(vif.WDATA) != 32) begin

            `uvm_fatal(
                "AXI_MONITOR",
                "axi_transaction requires 32-bit data elements; interface DATA_WIDTH must be 32"
            )

        end

    endfunction : build_phase

    //============================================================
    // Reset Partial Transactions
    //============================================================

    protected function void clear_write_state();

        write_tr = null;

        write_active         = 1'b0;
        write_aw_seen        = 1'b0;
        write_last_seen      = 1'b0;
        write_last_correct   = 1'b0;
        write_expected_beats = 0;
        write_beat_count     = 0;

        write_data_q.delete();

    endfunction : clear_write_state

    protected function void clear_read_state();

        read_tr = null;

        read_active         = 1'b0;
        read_last_seen      = 1'b0;
        read_last_correct   = 1'b0;
        read_expected_beats = 0;
        read_beat_count     = 0;

        read_data_q.delete();

        last_rresp = 2'b00;

    endfunction : clear_read_state

    //============================================================
    // Publish Completed Write Transaction
    //============================================================

    protected function void publish_write();

        axi_transaction completed_tr;

        if (!write_active || !write_aw_seen)
            return;

        if (write_beat_count != write_expected_beats)
            return;

        if (write_data_q.size() != write_expected_beats)
            return;

        completed_tr = write_tr;

        completed_tr.data = new[write_data_q.size()];

        foreach (write_data_q[i])
            completed_tr.data[i] = write_data_q[i];

        completed_tr.saw_last =
            write_last_seen && write_last_correct;

        `uvm_info(
            "AXI_MONITOR",
            $sformatf(
                "WRITE completed: addr=0x%04h len=%0d size=%0d beats=%0d",
                completed_tr.addr,
                completed_tr.len,
                completed_tr.size,
                write_beat_count
            ),
            UVM_MEDIUM
        )

        // Clear monitor state before broadcasting the transaction.
        clear_write_state();

        ap.write(completed_tr);

    endfunction : publish_write

    //============================================================
    // Publish Completed Read Transaction
    //============================================================

    protected function void publish_read();

        axi_transaction completed_tr;

        if (!read_active)
            return;

        if (read_beat_count != read_expected_beats)
            return;

        if (read_data_q.size() != read_expected_beats)
            return;

        completed_tr = read_tr;

        completed_tr.read_data = new[read_data_q.size()];

        foreach (read_data_q[i])
            completed_tr.read_data[i] = read_data_q[i];

        completed_tr.response = last_rresp;

        completed_tr.saw_last =
            read_last_seen && read_last_correct;

        `uvm_info(
            "AXI_MONITOR",
            $sformatf(
                "READ completed: addr=0x%04h len=%0d size=%0d beats=%0d response=%02b",
                completed_tr.addr,
                completed_tr.len,
                completed_tr.size,
                read_beat_count,
                completed_tr.response
            ),
            UVM_MEDIUM
        )

        // Clear monitor state before broadcasting the transaction.
        clear_read_state();

        ap.write(completed_tr);

    endfunction : publish_read

    //============================================================
    // Main Run Phase
    //
    // All five channels are sampled in the same process.
    // AW and W can therefore handshake independently.
    //============================================================

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge vif.ACLK);

            //====================================================
            // Reset Handling
            //====================================================

            if (vif.ARESETn !== 1'b1) begin

                if (write_active || write_data_q.size() != 0) begin

                    `uvm_warning(
                        "AXI_MONITOR",
                        "Discarding incomplete WRITE transaction due to reset"
                    )

                end

                if (read_active) begin

                    `uvm_warning(
                        "AXI_MONITOR",
                        "Discarding incomplete READ transaction due to reset"
                    )

                end

                clear_write_state();
                clear_read_state();

            end
            else begin

                //================================================
                // WRITE ADDRESS CHANNEL
                //================================================

                if (vif.AWVALID === 1'b1 &&
                    vif.AWREADY === 1'b1) begin

                    if (write_aw_seen) begin

                        `uvm_error(
                            "AXI_MONITOR",
                            "New AW handshake while previous write address is outstanding"
                        )

                    end
                    else begin

                        write_tr = axi_transaction::type_id::create(
                            "write_tr",
                            this
                        );

                        write_tr.op   = axi_transaction::WRITE;
                        write_tr.addr = vif.AWADDR;
                        write_tr.len  = vif.AWLEN;
                        write_tr.size = vif.AWSIZE;

                        write_active         = 1'b1;
                        write_aw_seen        = 1'b1;
                        write_expected_beats =
                            int'(vif.AWLEN) + 1;

                        // Any W beats observed before AW are
                        // retained in write_data_q.
                        if (write_beat_count >
                            write_expected_beats) begin

                            `uvm_error(
                                "AXI_MONITOR",
                                "More W beats observed than the AW burst length permits"
                            )

                        end

                        `uvm_info(
                            "AXI_MONITOR",
                            $sformatf(
                                "AW accepted: addr=0x%04h len=%0d size=%0d",
                                vif.AWADDR,
                                vif.AWLEN,
                                vif.AWSIZE
                            ),
                            UVM_HIGH
                        )

                    end

                end

                //================================================
                // WRITE DATA CHANNEL
                //================================================

                if (vif.WVALID === 1'b1 &&
                    vif.WREADY === 1'b1) begin

                    write_data_q.push_back(vif.WDATA);

                    write_beat_count++;

                    if (vif.WLAST === 1'b1) begin

                        write_last_seen = 1'b1;

                        if (write_aw_seen &&
                            write_beat_count ==
                            write_expected_beats) begin

                            write_last_correct = 1'b1;

                        end
                        else if (write_aw_seen) begin

                            `uvm_error(
                                "AXI_MONITOR",
                                $sformatf(
                                    "WLAST at beat %0d, expected final beat %0d",
                                    write_beat_count - 1,
                                    write_expected_beats - 1
                                )
                            )

                        end

                    end
                    else if (write_aw_seen &&
                             write_beat_count ==
                             write_expected_beats) begin

                        `uvm_error(
                            "AXI_MONITOR",
                            "WLAST missing on final write data beat"
                        )

                    end

                    if (write_aw_seen &&
                        write_beat_count >
                        write_expected_beats) begin

                        `uvm_error(
                            "AXI_MONITOR",
                            "Write data beat count exceeds AWLEN + 1"
                        )

                    end

                end

                //================================================
                // WRITE RESPONSE CHANNEL
                //================================================

                if (vif.BVALID === 1'b1 &&
                    vif.BREADY === 1'b1) begin

                    if (write_aw_seen &&
                        write_beat_count ==
                        write_expected_beats &&
                        write_data_q.size() ==
                        write_expected_beats) begin

                        write_tr.response = vif.BRESP;

                        publish_write();

                    end
                    else begin

                        `uvm_error(
                            "AXI_MONITOR",
                            "B response accepted before the expected write address/data transaction completed"
                        )

                    end

                end

                //================================================
                // READ ADDRESS CHANNEL
                //================================================

                if (vif.ARVALID === 1'b1 &&
                    vif.ARREADY === 1'b1) begin

                    if (read_active) begin

                        `uvm_error(
                            "AXI_MONITOR",
                            "New AR handshake while previous read transaction is outstanding"
                        )

                    end
                    else begin

                        read_tr = axi_transaction::type_id::create(
                            "read_tr",
                            this
                        );

                        read_tr.op   = axi_transaction::READ;
                        read_tr.addr = vif.ARADDR;
                        read_tr.len  = vif.ARLEN;
                        read_tr.size = vif.ARSIZE;

                        read_active         = 1'b1;
                        read_expected_beats =
                            int'(vif.ARLEN) + 1;

                        read_beat_count    = 0;
                        read_last_seen     = 1'b0;
                        read_last_correct  = 1'b0;

                        read_data_q.delete();

                        last_rresp = 2'b00;

                        `uvm_info(
                            "AXI_MONITOR",
                            $sformatf(
                                "AR accepted: addr=0x%04h len=%0d size=%0d",
                                vif.ARADDR,
                                vif.ARLEN,
                                vif.ARSIZE
                            ),
                            UVM_HIGH
                        )

                    end

                end

                //================================================
                // READ DATA CHANNEL
                //================================================

                if (vif.RVALID === 1'b1 &&
                    vif.RREADY === 1'b1) begin

                    if (!read_active) begin

                        `uvm_error(
                            "AXI_MONITOR",
                            "R data handshake without an outstanding read address"
                        )

                    end
                    else begin

                        read_data_q.push_back(vif.RDATA);

                        last_rresp = vif.RRESP;

                        read_beat_count++;

                        if (vif.RLAST === 1'b1) begin

                            read_last_seen = 1'b1;

                            if (read_beat_count ==
                                read_expected_beats) begin

                                read_last_correct = 1'b1;

                            end
                            else begin

                                `uvm_error(
                                    "AXI_MONITOR",
                                    $sformatf(
                                        "RLAST asserted early at beat %0d, expected final beat %0d",
                                        read_beat_count - 1,
                                        read_expected_beats - 1
                                    )
                                )

                            end

                        end
                        else if (read_beat_count ==
                                 read_expected_beats) begin

                            `uvm_error(
                                "AXI_MONITOR",
                                "RLAST missing on final read data beat"
                            )

                        end

                        if (read_beat_count >
                            read_expected_beats) begin

                            `uvm_error(
                                "AXI_MONITOR",
                                "Read data beat count exceeds ARLEN + 1"
                            )

                        end

                        if (read_beat_count ==
                            read_expected_beats) begin

                            publish_read();

                        end

                    end

                end

            end

        end

    endtask : run_phase

endclass : axi_monitor

`endif
