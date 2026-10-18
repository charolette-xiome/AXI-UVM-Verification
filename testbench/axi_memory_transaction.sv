
`ifndef MEMORY_TRANSACTION_SV
`define MEMORY_TRANSACTION_SV

//============================================================
// Memory Transaction
//============================================================
class memory_transaction extends uvm_sequence_item;

    typedef enum bit {
        MEM_READ  = 1'b0,
        MEM_WRITE = 1'b1
    } mem_op_t;

    //========================================================
    // Transaction Fields
    //========================================================
    mem_op_t    op;
    bit [9:0]   addr;
    bit [31:0]  data;

    //========================================================
    // UVM Factory Registration and Field Automation
    //========================================================
    `uvm_object_utils_begin(memory_transaction)

        `uvm_field_enum(
            mem_op_t,
            op,
            UVM_ALL_ON
        )

        `uvm_field_int(
            addr,
            UVM_ALL_ON
        )

        `uvm_field_int(
            data,
            UVM_ALL_ON
        )

    `uvm_object_utils_end

    //========================================================
    // Constructor
    //========================================================
    function new(string name = "memory_transaction");
        super.new(name);

        op   = MEM_READ;
        addr = '0;
        data = '0;
    endfunction

    //========================================================
    // Display Transaction
    //========================================================
    function void display(string tag = "MEM_TR");

        `uvm_info(
            tag,
            $sformatf(
                "op=%s addr=0x%03h data=0x%08h",
                (op == MEM_WRITE) ? "MEM_WRITE" : "MEM_READ",
                addr,
                data
            ),
            UVM_MEDIUM
        )

    endfunction

endclass

`endif
