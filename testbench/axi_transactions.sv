
`ifndef AXI_TRANSACTION_SV
`define AXI_TRANSACTION_SV

class axi_transaction extends uvm_sequence_item;

    //============================================================
    // Operation Type
    //============================================================

    typedef enum bit {
        READ  = 1'b0,
        WRITE = 1'b1
    } op_t;

    //============================================================
    // Transaction Fields
    //============================================================

    rand op_t       op;
    rand bit [15:0] addr;
    rand bit [7:0]  len;
    rand bit [2:0]  size;
    rand bit [31:0] data[];

    //============================================================
    // Fields Filled by Driver / Monitor
    //============================================================

    bit [31:0] read_data[];
    bit [1:0]  response;
    bit        saw_last;

    // End-of-test compatibility field.
    bit end_of_test = 0;

    //============================================================
    // UVM Factory Registration and Field Automation
    //============================================================

    `uvm_object_utils_begin(axi_transaction)

        `uvm_field_enum(op_t, op, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(len, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)

        `uvm_field_array_int(data, UVM_ALL_ON)
        `uvm_field_array_int(read_data, UVM_ALL_ON)

        `uvm_field_int(response, UVM_ALL_ON)
        `uvm_field_int(saw_last, UVM_ALL_ON)
        `uvm_field_int(end_of_test, UVM_ALL_ON)

    `uvm_object_utils_end

    //============================================================
    // Constraints
    //============================================================

    constraint c_supported_size {
        size inside {[0:2]};
    }

    constraint c_reasonable_len {
        len inside {[0:7]};
    }

    constraint c_data_size {
        data.size() == (int'(len) + 1);
    }

    constraint c_alignment {
        (addr % (1 << size)) == 0;
    }

    constraint c_mostly_valid_addr {
        addr dist {
            [16'h0000:16'h0FFF] :/ 90,
            [16'h1000:16'hFFFF] :/ 10
        };
    }

    //============================================================
    // Constructor
    //============================================================

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    //============================================================
    // Number of Beats
    // AXI LEN encoding: beats = LEN + 1
    //============================================================

    function int unsigned beats();
        return int'(len) + 1;
    endfunction

    //============================================================
    // Explicit Transaction Copy Helper
    //============================================================

    function axi_transaction copy_transaction();

        axi_transaction c;

        c = axi_transaction::type_id::create(
            "transaction_copy"
        );

        c.op          = this.op;
        c.addr        = this.addr;
        c.len         = this.len;
        c.size        = this.size;
        c.response    = this.response;
        c.saw_last    = this.saw_last;
        c.end_of_test = this.end_of_test;

        c.data = new[this.data.size()];

        foreach (this.data[i])
            c.data[i] = this.data[i];

        c.read_data = new[this.read_data.size()];

        foreach (this.read_data[i])
            c.read_data[i] = this.read_data[i];

        return c;

    endfunction

    //============================================================
    // Display Transaction
    //============================================================

    function void display(string tag = "AXI_TR");

        `uvm_info(
            tag,
            $sformatf(
                "op=%s addr=0x%04h len=%0d beats=%0d size=%0d response=%02b saw_last=%0b",
                (op == WRITE) ? "WRITE" : "READ",
                addr,
                len,
                beats(),
                size,
                response,
                saw_last
            ),
            UVM_MEDIUM
        )

        if (op == WRITE) begin

            foreach (data[i]) begin

                `uvm_info(
                    tag,
                    $sformatf(
                        "WDATA[%0d] = 0x%08h",
                        i,
                        data[i]
                    ),
                    UVM_MEDIUM
                )

            end

        end
        else begin

            foreach (read_data[i]) begin

                `uvm_info(
                    tag,
                    $sformatf(
                        "RDATA[%0d] = 0x%08h",
                        i,
                        read_data[i]
                    ),
                    UVM_MEDIUM
                )

            end

        end

    endfunction

endclass

`endif
