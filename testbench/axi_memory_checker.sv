
`ifndef MEMORY_CHECKER_SV
`define MEMORY_CHECKER_SV

//============================================================
// Memory Checker
//============================================================

class memory_checker extends uvm_scoreboard;

    `uvm_component_utils(memory_checker)

    //========================================================
    // Analysis Implementation
    //========================================================

    uvm_analysis_imp #(
        memory_transaction,
        memory_checker
    ) analysis_export;

    //========================================================
    // Reference Memory
    // Address is assumed to be a word index: 0 to 1023.
    //========================================================

    localparam int unsigned DEPTH = 1024;

    bit [31:0] memory_model [0:DEPTH-1];

    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned write_count;
    int unsigned read_count;

    //========================================================
    // Constructor
    //========================================================

    function new(
        string name = "memory_checker",
        uvm_component parent = null
    );
        super.new(name, parent);

        analysis_export = new("analysis_export", this);

        pass_count  = 0;
        fail_count  = 0;
        write_count = 0;
        read_count  = 0;
    endfunction : new

    //========================================================
    // Build Phase
    //========================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        foreach (memory_model[i])
            memory_model[i] = '0;

    endfunction : build_phase

    //========================================================
    // Receive Memory Transaction
    // Called by the connected monitor's analysis port.
    //========================================================

    function void write(memory_transaction t);

        int unsigned addr;

        if (t == null) begin
            `uvm_error(
                "MEM_CHECKER",
                "Received a null memory transaction"
            )
            fail_count++;
            return;
        end

        // Convert explicitly before checking the array bounds.
        addr = int'(t.addr);

        //====================================================
        // Address Range Check
        //====================================================

        if (addr >= DEPTH) begin

            `uvm_error(
                "MEM_CHECKER_ADDR",
                $sformatf(
                    "Invalid memory address/index: 0x%0h; valid range is 0 to %0d",
                    t.addr,
                    DEPTH-1
                )
            )

            fail_count++;
            return;

        end

        //====================================================
        // Memory WRITE
        //====================================================

        case (t.op)

            memory_transaction::MEM_WRITE: begin

                memory_model[addr] = t.data;
                write_count++;

                `uvm_info(
                    "MEM_CHECKER_WRITE",
                    $sformatf(
                        "Memory model updated: addr=0x%0h data=0x%08h",
                        t.addr,
                        t.data
                    ),
                    UVM_HIGH
                )

            end

            //================================================
            // Memory READ
            //================================================

            memory_transaction::MEM_READ: begin

                read_count++;

                if (t.data === memory_model[addr]) begin

                    pass_count++;

                    `uvm_info(
                        "MEM_CHECKER_PASS",
                        $sformatf(
                            "Memory READ PASS: addr=0x%0h expected=0x%08h actual=0x%08h",
                            t.addr,
                            memory_model[addr],
                            t.data
                        ),
                        UVM_HIGH
                    )

                end
                else begin

                    fail_count++;

                    `uvm_error(
                        "MEM_CHECKER_FAIL",
                        $sformatf(
                            "Memory READ FAIL: addr=0x%0h expected=0x%08h actual=0x%08h",
                            t.addr,
                            memory_model[addr],
                            t.data
                        )
                    )

                end

            end

            //================================================
            // Unsupported Operation
            //================================================

            default: begin

                fail_count++;

                `uvm_error(
                    "MEM_CHECKER_OP",
                    $sformatf(
                        "Unsupported memory operation: %0d",
                        t.op
                    )
                )

            end

        endcase

    endfunction : write

    //========================================================
    // Report Phase
    //========================================================

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(
            "MEM_CHECKER_REPORT",
            $sformatf(
                {
                    "\n=====================================================\n",
                    " MEMORY CHECKER FINAL REPORT\n",
                    "   WRITES      = %0d\n",
                    "   READS       = %0d\n",
                    "   READ PASS   = %0d\n",
                    "   READ FAIL   = %0d\n",
                    "   TOTAL FAIL  = %0d\n",
                    "====================================================="
                },
                write_count,
                read_count,
                pass_count,
                read_count - pass_count,
                fail_count
            ),
            UVM_NONE
        )

    endfunction : report_phase

endclass : memory_checker

`endif
