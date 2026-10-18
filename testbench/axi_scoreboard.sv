
`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

//============================================================
// AXI UVM Scoreboard
//============================================================

class axi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_scoreboard)

    // Analysis implementation receives monitored transactions.
    uvm_analysis_imp #(axi_transaction, axi_scoreboard) analysis_export;

    // Object-oriented reference model.
    axi_reference_model ref_model;

    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned checked_count;

    //========================================================
    // Constructor
    //========================================================

    function new(
        string name = "axi_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);

        pass_count    = 0;
        fail_count    = 0;
        checked_count = 0;
    endfunction

    //========================================================
    // Build Phase
    //========================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_export = new("analysis_export", this);

        ref_model = axi_reference_model::type_id::create(
            "ref_model"
        );
    endfunction

    //========================================================
    // Analysis Callback
    //========================================================

    virtual function void write(axi_transaction tr);

        if (tr == null) begin
            `uvm_error(
                "AXI_SCB",
                "Received a null transaction"
            )
            fail_count++;
            return;
        end

        check_transaction(tr);

    endfunction

    //========================================================
    // Transaction Checker
    //========================================================

    virtual function void check_transaction(
        axi_transaction tr
    );

        bit ok;
        bit [1:0] exp_response;

        ok = 1'b1;

        checked_count++;

        //====================================================
        // WRITE Transaction
        //====================================================

        if (tr.op == axi_transaction::WRITE) begin

            // Validate the observed write burst length.
            if (tr.data.size() != (int'(tr.len) + 1)) begin

                `uvm_error(
                    "AXI_SCB_WRITE",
                    $sformatf(
                        "Address=0x%04h: expected %0d write beats, observed %0d",
                        tr.addr,
                        int'(tr.len) + 1,
                        tr.data.size()
                    )
                )

                ok = 1'b0;
            end

            // Check WLAST was observed on the final beat.
            if (!tr.saw_last) begin

                `uvm_error(
                    "AXI_SCB_WRITE",
                    $sformatf(
                        "Address=0x%04h: final WLAST was not observed",
                        tr.addr
                    )
                )

                ok = 1'b0;
            end

            // Predict response and update reference memory
            // only according to the reference model's rules.
            ref_model.predict_write(
                tr,
                exp_response
            );

            // Compare observed BRESP with predicted BRESP.
            if (tr.response !== exp_response) begin

                `uvm_error(
                    "AXI_SCB_WRITE",
                    $sformatf(
                        "Address=0x%04h: BRESP mismatch, expected=%02b observed=%02b",
                        tr.addr,
                        exp_response,
                        tr.response
                    )
                )

                ok = 1'b0;
            end

        end

        //====================================================
        // READ Transaction
        //====================================================

        else if (tr.op == axi_transaction::READ) begin

            bit [31:0] exp_rdata[];
            bit [1:0]  exp_read_response;
            bit [15:0] exp_addrs[];

            // Predict expected read response and data.
            ref_model.predict_read(
                tr,
                exp_rdata,
                exp_read_response
            );

            ref_model.expected_addr_sequence(
                tr,
                exp_addrs
            );

            // Validate the number of returned beats.
            if (tr.read_data.size() != (int'(tr.len) + 1)) begin

                `uvm_error(
                    "AXI_SCB_READ",
                    $sformatf(
                        "Address=0x%04h: expected %0d read beats, observed %0d",
                        tr.addr,
                        int'(tr.len) + 1,
                        tr.read_data.size()
                    )
                )

                ok = 1'b0;
            end

            // Check RLAST observation.
            if (!tr.saw_last) begin

                `uvm_error(
                    "AXI_SCB_READ",
                    $sformatf(
                        "Address=0x%04h: final RLAST was not observed",
                        tr.addr
                    )
                )

                ok = 1'b0;
            end

            // Compare only beats that exist in both arrays.
            for (
                int unsigned i = 0;
                i < tr.read_data.size() &&
                     i < exp_rdata.size();
                i++
            ) begin

                if (tr.read_data[i] !== exp_rdata[i]) begin

                    `uvm_error(
                        "AXI_SCB_READ",
                        $sformatf(
                            "Base=0x%04h beat=%0d expected_addr=0x%04h expected=0x%08h observed=0x%08h",
                            tr.addr,
                            i,
                            exp_addrs[i],
                            exp_rdata[i],
                            tr.read_data[i]
                        )
                    )

                    ok = 1'b0;
                end

            end

            // Compare observed RRESP with predicted response.
            if (tr.response !== exp_read_response) begin

                `uvm_error(
                    "AXI_SCB_READ",
                    $sformatf(
                        "Address=0x%04h: RRESP mismatch, expected=%02b observed=%02b",
                        tr.addr,
                        exp_read_response,
                        tr.response
                    )
                )

                ok = 1'b0;
            end

        end

        //====================================================
        // Invalid Operation
        //====================================================

        else begin

            `uvm_error(
                "AXI_SCB",
                "Transaction contains an unsupported operation"
            )

            ok = 1'b0;

        end

        //====================================================
        // PASS / FAIL Accounting
        //====================================================

        if (ok) begin

            pass_count++;

            `uvm_info(
                "AXI_SCB_PASS",
                $sformatf(
                    "PASS: operation=%s address=0x%04h",
                    tr.op.name(),
                    tr.addr
                ),
                UVM_MEDIUM
            )

        end
        else begin

            fail_count++;

            `uvm_info(
                "AXI_SCB_FAIL",
                $sformatf(
                    "FAIL: operation=%s address=0x%04h",
                    tr.op.name(),
                    tr.addr
                ),
                UVM_LOW
            )

        end

    endfunction

    //========================================================
    // Report Phase
    //========================================================

    virtual function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "AXI_SCOREBOARD_REPORT",
            $sformatf(
                "\n=====================================================\nAXI SCOREBOARD FINAL REPORT\nChecked = %0d\nPassed  = %0d\nFailed  = %0d\n=====================================================",
                checked_count,
                pass_count,
                fail_count
            ),
            UVM_NONE
        )

        if (fail_count != 0) begin
            `uvm_error(
                "AXI_SCOREBOARD_REPORT",
                "One or more transactions failed scoreboard checks"
            )
        end

    endfunction

endclass : axi_scoreboard

`endif
