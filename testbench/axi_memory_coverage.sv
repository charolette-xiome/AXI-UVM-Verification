
`ifndef MEMORY_COVERAGE_SV
`define MEMORY_COVERAGE_SV

//============================================================
// Memory Functional Coverage
//============================================================

class memory_coverage extends uvm_subscriber #(
    memory_transaction
);

    `uvm_component_utils(memory_coverage)

    //========================================================
    // Coverage Sampling Variables
    //========================================================

    bit        op_flag;
    bit [9:0]  addr_flag;
    bit [31:0] data_flag;

    //========================================================
    // Memory Covergroup
    //========================================================

    covergroup mem_cg;

        option.per_instance = 1;

        // Operation coverage
        cp_op : coverpoint op_flag {
            bins read  = {0};
            bins write = {1};
        }

        // Address-region coverage
        cp_addr : coverpoint addr_flag {
            bins low  = {[0:255]};
            bins mid1 = {[256:511]};
            bins mid2 = {[512:767]};
            bins high = {[768:1023]};
        }

        // Data-pattern coverage
        cp_data : coverpoint data_flag {
            bins zero     = {32'h0000_0000};
            bins all_ones = {32'hFFFF_FFFF};
            bins other    = default;
        }

        // Operation versus address region
        cx_op_addr : cross cp_op, cp_addr;

        // Operation, address region and data pattern
        cx_op_addr_data : cross cp_op, cp_addr, cp_data;

    endgroup : mem_cg

    //========================================================
    // Constructor
    //========================================================

    function new(
        string name = "memory_coverage",
        uvm_component parent = null
    );
        super.new(name, parent);

        mem_cg = new();

    endfunction : new

    //========================================================
    // Receive and Sample Transaction
    //========================================================

    function void write(memory_transaction t);

        if (t == null) begin
            `uvm_error(
                "MEM_COVERAGE",
                "Received a null memory transaction"
            )
            return;
        end

        // Map supported operations to coverage values.
        case (t.op)

            memory_transaction::MEM_READ:
                op_flag = 1'b0;

            memory_transaction::MEM_WRITE:
                op_flag = 1'b1;

            default: begin
                `uvm_error(
                    "MEM_COVERAGE",
                    $sformatf(
                        "Unsupported memory operation: %0d",
                        t.op
                    )
                )
                return;
            end

        endcase

        // Assumes t.addr is a word index from 0 to 1023.
        addr_flag = t.addr;
        data_flag = t.data;

        // Sample this transaction.
        mem_cg.sample();

    endfunction : write

    //========================================================
    // Report Phase
    //========================================================

    function void report_phase(uvm_phase phase);

        real coverage_pct;

        super.report_phase(phase);

        coverage_pct = mem_cg.get_inst_coverage();

        `uvm_info(
            "MEM_COVERAGE_REPORT",
            $sformatf(
                {
                    "\n=====================================================\n",
                    " MEMORY FUNCTIONAL COVERAGE REPORT\n",
                    "   COVERAGE = %0.2f %%\n",
                    "====================================================="
                },
                coverage_pct
            ),
            UVM_LOW
        )

    endfunction : report_phase

endclass : memory_coverage

`endif
