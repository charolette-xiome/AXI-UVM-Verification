
`ifndef AXI_REFERENCE_MODEL_SV
`define AXI_REFERENCE_MODEL_SV

//============================================================
// AXI UVM Reference Model
//============================================================

class axi_reference_model extends uvm_object;

    `uvm_object_utils(axi_reference_model)

    localparam int DEPTH      = 1024;
    localparam int ADDR_WIDTH = 16;
    localparam int DATA_WIDTH = 32;
    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

    localparam int MEM_BYTES = DEPTH * BYTES_PER_WORD;

    // Byte-addressable memory.
    // Supports byte, halfword and word accesses.
    bit [7:0] mem_model [0:MEM_BYTES-1];

    //========================================================
    // Constructor
    //========================================================

    function new(string name = "axi_reference_model");

        super.new(name);

        reset_model();

    endfunction : new

    //========================================================
    // Reset Reference Memory
    //========================================================

    function void reset_model();

        foreach (mem_model[i])
            mem_model[i] = '0;

    endfunction : reset_model

    //========================================================
    // Check Transaction Validity
    //
    // Supports INCR bursts only.
    // Rejects unsupported transfer sizes, unaligned addresses,
    // out-of-range accesses and 4 KB boundary crossings.
    //========================================================

    function bit is_valid(
        bit [ADDR_WIDTH-1:0] addr,
        bit [7:0]            len,
        bit [2:0]            size
    );

        longint unsigned bytes_per_beat;
        longint unsigned total_bytes;
        longint unsigned last_addr;

        bytes_per_beat = 1;

        // The data bus is 32 bits wide.
        if (size > 2)
            return 0;

        bytes_per_beat = 1 << size;

        // Require naturally aligned transfers.
        if ((addr % bytes_per_beat) != 0)
            return 0;

        total_bytes = (longint'(len) + 1) * bytes_per_beat;

        last_addr = longint'(addr) + total_bytes - 1;

        // Check the full burst against the implemented memory.
        if (addr >= MEM_BYTES)
            return 0;

        if (last_addr >= MEM_BYTES)
            return 0;

        // An AXI burst must not cross a 4 KB boundary.
        if ((longint'(addr) >> 12) != (last_addr >> 12))
            return 0;

        return 1;

    endfunction : is_valid

    //========================================================
    // Predict WRITE Transaction
    //
    // Writes only the bytes belonging to each transfer.
    // tr.data[i] contains one 32-bit beat.
    //========================================================

    function void predict_write(
        axi_transaction tr,
        output bit [1:0] exp_response
    );

        longint unsigned beat_addr;
        int unsigned bytes_per_beat;
        int unsigned byte_index;
        int unsigned memory_index;
        int unsigned data_lane;

        if (tr == null) begin
            exp_response = 2'b10;
            `uvm_error("AXI_REF_MODEL", "Null WRITE transaction")
            return;
        end

        exp_response = 2'b10;

        if (tr.op != axi_transaction::WRITE) begin
            `uvm_error("AXI_REF_MODEL", "predict_write called for non-WRITE transaction")
            return;
        end

        if (!is_valid(tr.addr, tr.len, tr.size)) begin
            `uvm_info(
                "AXI_REF_MODEL",
                $sformatf(
                    "WRITE rejected: addr=0x%04h len=%0d size=%0d",
                    tr.addr, tr.len, tr.size
                ),
                UVM_MEDIUM
            )
            return;
        end

        if (tr.data.size() != (int'(tr.len) + 1)) begin
            `uvm_error(
                "AXI_REF_MODEL",
                $sformatf(
                    "WRITE data count mismatch: expected=%0d actual=%0d",
                    int'(tr.len) + 1, tr.data.size()
                )
            )
            return;
        end

        bytes_per_beat = 1 << tr.size;
        beat_addr = tr.addr;

        foreach (tr.data[i]) begin

            for (int j = 0; j < bytes_per_beat; j++) begin

                memory_index = int'(beat_addr) + j;

                // Select the corresponding byte from the
                // 32-bit transaction data beat.
                data_lane = (beat_addr + j) % BYTES_PER_WORD;

                byte_index = data_lane * 8;

                mem_model[memory_index] = tr.data[i][byte_index +: 8];

            end

            beat_addr += bytes_per_beat;

        end

        exp_response = 2'b00;

        `uvm_info(
            "AXI_REF_MODEL",
            $sformatf(
                "WRITE predicted: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr, tr.len, tr.size, exp_response
            ),
            UVM_MEDIUM
        )

    endfunction : predict_write

    //========================================================
    // Predict READ Transaction
    //
    // Returns one 32-bit data value per transfer.
    //========================================================

    function void predict_read(
        axi_transaction tr,
        output bit [31:0] exp_rdata[],
        output bit [1:0] exp_response
    );

        longint unsigned beat_addr;
        int unsigned bytes_per_beat;
        int unsigned memory_index;
        int unsigned data_lane;

        if (tr == null) begin
            exp_rdata = new[0];
            exp_response = 2'b10;
            `uvm_error("AXI_REF_MODEL", "Null READ transaction")
            return;
        end

        exp_response = 2'b10;

        if (tr.op != axi_transaction::READ) begin
            exp_rdata = new[0];
            `uvm_error("AXI_REF_MODEL", "predict_read called for non-READ transaction")
            return;
        end

        exp_rdata = new[int'(tr.len) + 1];

        foreach (exp_rdata[i])
            exp_rdata[i] = '0;

        if (!is_valid(tr.addr, tr.len, tr.size)) begin

            `uvm_info(
                "AXI_REF_MODEL",
                $sformatf(
                    "READ rejected: addr=0x%04h len=%0d size=%0d",
                    tr.addr, tr.len, tr.size
                ),
                UVM_MEDIUM
            )

            return;

        end

        bytes_per_beat = 1 << tr.size;
        beat_addr = tr.addr;

        foreach (exp_rdata[i]) begin

            for (int j = 0; j < bytes_per_beat; j++) begin

                memory_index = int'(beat_addr) + j;

                data_lane = (beat_addr + j) % BYTES_PER_WORD;

                exp_rdata[i][data_lane * 8 +: 8] =
                    mem_model[memory_index];

            end

            beat_addr += bytes_per_beat;

        end

        exp_response = 2'b00;

        `uvm_info(
            "AXI_REF_MODEL",
            $sformatf(
                "READ predicted: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr, tr.len, tr.size, exp_response
            ),
            UVM_MEDIUM
        )

    endfunction : predict_read

    //========================================================
    // Generate Expected Address Sequence
    //========================================================

    function void expected_addr_sequence(
        axi_transaction tr,
        output bit [ADDR_WIDTH-1:0] addrs[]
    );

        longint unsigned current_addr;
        int unsigned bytes_per_beat;

        if (tr == null) begin
            addrs = new[0];
            `uvm_error("AXI_REF_MODEL", "Null transaction in expected_addr_sequence")
            return;
        end

        addrs = new[int'(tr.len) + 1];

        bytes_per_beat = 1 << tr.size;
        current_addr = tr.addr;

        foreach (addrs[i]) begin

            addrs[i] = ADDR_WIDTH'(current_addr);

            current_addr += bytes_per_beat;

        end

    endfunction : expected_addr_sequence

endclass : axi_reference_model

`endif
