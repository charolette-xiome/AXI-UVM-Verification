//============================================================
// AXI Base Sequence
//============================================================
class axi_base_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_base_sequence)

    function new(string name = "axi_base_sequence");
        super.new(name);
    endfunction


    // ---------------------------------------------------------
    // Send one AXI transaction through the UVM sequencer
    // ---------------------------------------------------------
    task send_transaction(axi_transaction tr);

        start_item(tr);
        finish_item(tr);

    endtask

endclass


//============================================================
// Single Write Sequence
//============================================================
class axi_single_write_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_single_write_sequence)

    bit [15:0] addr  = 16'h0020;
    bit [31:0] value = 32'hA5A5_1234;


    function new(string name = "axi_single_write_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;

        tr = axi_transaction::type_id::create("tr");

        tr.op   = axi_transaction::WRITE;
        tr.addr = addr;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = value;

        send_transaction(tr);

    endtask

endclass


//============================================================
// Single Read Sequence
//============================================================
class axi_single_read_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_single_read_sequence)

    bit [15:0] addr = 16'h0020;


    function new(string name = "axi_single_read_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;

        tr = axi_transaction::type_id::create("tr");

        tr.op   = axi_transaction::READ;
        tr.addr = addr;
        tr.len  = 0;
        tr.size = 2;

        tr.data = new[1];
        tr.data[0] = '0;

        send_transaction(tr);

    endtask

endclass


//============================================================
// Burst Write Sequence
//============================================================
class axi_burst_write_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_burst_write_sequence)

    bit [15:0]   addr       = 16'h0100;
    int unsigned beat_count = 4;


    function new(string name = "axi_burst_write_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;
        int unsigned beats;

        beats = beat_count;

        if (beats < 1)
            beats = 1;

        if (beats > 256)
            beats = 256;

        tr = axi_transaction::type_id::create("tr");

        tr.op   = axi_transaction::WRITE;
        tr.addr = addr;
        tr.len  = beats - 1;
        tr.size = 2;

        tr.data = new[beats];

        foreach (tr.data[i])
            tr.data[i] = 32'h1000_0000 + i;

        send_transaction(tr);

    endtask

endclass


//============================================================
// Burst Read Sequence
//============================================================
class axi_burst_read_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_burst_read_sequence)

    bit [15:0]   addr       = 16'h0100;
    int unsigned beat_count = 4;


    function new(string name = "axi_burst_read_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;
        int unsigned beats;

        beats = beat_count;

        if (beats < 1)
            beats = 1;

        if (beats > 256)
            beats = 256;

        tr = axi_transaction::type_id::create("tr");

        tr.op   = axi_transaction::READ;
        tr.addr = addr;
        tr.len  = beats - 1;
        tr.size = 2;

        tr.data = new[beats];

        foreach (tr.data[i])
            tr.data[i] = '0;

        send_transaction(tr);

    endtask

endclass


//============================================================
// Invalid Address Sequence
//============================================================
class axi_invalid_address_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_invalid_address_sequence)


    function new(string name = "axi_invalid_address_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction write_tr;
        axi_transaction read_tr;


        //======================================================
        // Invalid Address WRITE
        // Expected response: SLVERR
        // Covers WRITE + SLVERR
        //======================================================

        write_tr =
            axi_transaction::type_id::create(
                "invalid_write_tr"
            );

        write_tr.op   = axi_transaction::WRITE;
        write_tr.addr = 16'h2000;
        write_tr.len  = 0;
        write_tr.size = 2;

        write_tr.data = new[1];
        write_tr.data[0] = 32'hDEAD_BEEF;

        send_transaction(write_tr);


        //======================================================
        // Invalid Address READ
        // Expected response: SLVERR
        // Covers READ + SLVERR
        //======================================================

        read_tr =
            axi_transaction::type_id::create(
                "invalid_read_tr"
            );

        read_tr.op   = axi_transaction::READ;
        read_tr.addr = 16'h2000;
        read_tr.len  = 0;
        read_tr.size = 2;

        read_tr.data = new[1];
        read_tr.data[0] = '0;

        send_transaction(read_tr);

    endtask

endclass


//============================================================
// 4 KB Boundary Crossing Sequence
//============================================================
class axi_boundary_cross_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_boundary_cross_sequence)

    axi_transaction::op_t op = axi_transaction::WRITE;


    function new(string name = "axi_boundary_cross_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;

        tr = axi_transaction::type_id::create("tr");

        tr.op = op;


        //======================================================
        // Boundary Crossing WRITE
        //======================================================

        if (op == axi_transaction::WRITE) begin

            tr.addr = 16'h0FFF;
            tr.len  = 0;
            tr.size = 2;

            tr.data = new[1];
            tr.data[0] = 32'hCAFE_0001;

        end


        //======================================================
        // Boundary Crossing READ
        //======================================================

        else begin

            tr.addr = 16'h0FFC;
            tr.len  = 1;
            tr.size = 2;

            tr.data = new[2];

            foreach (tr.data[i])
                tr.data[i] = '0;

        end


        send_transaction(tr);

    endtask

endclass


//============================================================
// AXI Functional Coverage Closure Sequence
//============================================================
class axi_coverage_closure_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_coverage_closure_sequence)


    function new(string name = "axi_coverage_closure_sequence");
        super.new(name);
    endfunction


    //==========================================================
    // Send one directed op x len x size combination
    //==========================================================

    task send_combo(
        axi_transaction::op_t op,
        bit [15:0]            addr,
        bit [7:0]             len,
        bit [2:0]             size,
        bit [31:0]            data_seed
    );

        axi_transaction tr;
        int unsigned beats;

        beats = len + 1;

        tr = axi_transaction::type_id::create(
            $sformatf(
                "tr_%0h_%0d_%0d",
                addr,
                len,
                size
            )
        );

        tr.op   = op;
        tr.addr = addr;
        tr.len  = len;
        tr.size = size;

        tr.data = new[beats];


        if (op == axi_transaction::WRITE) begin

            foreach (tr.data[i])
                tr.data[i] = data_seed + i;

        end

        else begin

            foreach (tr.data[i])
                tr.data[i] = '0;

        end


        send_transaction(tr);

    endtask


    //==========================================================
    // Main AXI Coverage Sequence
    //==========================================================

    task body();

        `uvm_info(
            "AXI_COVERAGE_CLOSURE",
            "Targeted AXI coverage closure sequence started",
            UVM_MEDIUM
        )


        //======================================================
        // SINGLE : LEN = 0
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0100,
            0,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0110,
            0,
            0,
            32'h1000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0120,
            0,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0130,
            0,
            1,
            32'h1000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0140,
            0,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0150,
            0,
            2,
            32'h1000_0020
        );


        //======================================================
        // SMALL : LEN = 2
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0200,
            2,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0210,
            2,
            0,
            32'h2000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0220,
            2,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0230,
            2,
            1,
            32'h2000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0240,
            2,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0250,
            2,
            2,
            32'h2000_0020
        );


        //======================================================
        // MID : LEN = 4
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0300,
            4,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0310,
            4,
            0,
            32'h3000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0320,
            4,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0330,
            4,
            1,
            32'h3000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0340,
            4,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0350,
            4,
            2,
            32'h3000_0020
        );


        //======================================================
        // LARGE : LEN = 16
        //======================================================

        send_combo(
            axi_transaction::READ,
            16'h0400,
            16,
            0,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0420,
            16,
            0,
            32'h4000_0000
        );

        send_combo(
            axi_transaction::READ,
            16'h0440,
            16,
            1,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h0460,
            16,
            1,
            32'h4000_0010
        );

        send_combo(
            axi_transaction::READ,
            16'h0480,
            16,
            2,
            32'h0000_0000
        );

        send_combo(
            axi_transaction::WRITE,
            16'h04A0,
            16,
            2,
            32'h4000_0020
        );


        `uvm_info(
            "AXI_COVERAGE_CLOSURE",
            "Targeted AXI coverage closure sequence completed",
            UVM_MEDIUM
        )

    endtask

endclass


//============================================================
// Memory Coverage Closure Sequence
//
// This sequence targets the remaining memory coverage bins:
//
//   AXI address 0x0800 -> memory address 512 -> MID2 region
//   AXI address 0x0C00 -> memory address 768 -> HIGH region
//
// It also writes 0xFFFF_FFFF to cover the all_ones data bin.
//============================================================
class axi_memory_coverage_sequence extends axi_base_sequence;

    `uvm_object_utils(axi_memory_coverage_sequence)


    function new(
        string name = "axi_memory_coverage_sequence"
    );

        super.new(name);

    endfunction


    task body();

        axi_transaction mid2_write_tr;
        axi_transaction mid2_read_tr;

        axi_transaction high_write_tr;
        axi_transaction high_read_tr;


        `uvm_info(
            "MEMORY_COVERAGE_CLOSURE",
            "Targeted memory coverage closure sequence started",
            UVM_MEDIUM
        )


        //======================================================
        // MID2 REGION WRITE
        //
        // AXI address   = 0x0800
        // Memory address = 0x0800 >> 2 = 512
        // Covers WRITE x MID2
        //======================================================

        mid2_write_tr =
            axi_transaction::type_id::create(
                "mid2_write_tr"
            );

        mid2_write_tr.op   = axi_transaction::WRITE;
        mid2_write_tr.addr = 16'h0800;
        mid2_write_tr.len  = 0;
        mid2_write_tr.size = 2;

        mid2_write_tr.data = new[1];

        mid2_write_tr.data[0] =
            32'hA5A5_5A5A;

        send_transaction(mid2_write_tr);


        //======================================================
        // MID2 REGION READ
        //
        // Covers READ x MID2
        //======================================================

        mid2_read_tr =
            axi_transaction::type_id::create(
                "mid2_read_tr"
            );

        mid2_read_tr.op   = axi_transaction::READ;
        mid2_read_tr.addr = 16'h0800;
        mid2_read_tr.len  = 0;
        mid2_read_tr.size = 2;

        mid2_read_tr.data = new[1];
        mid2_read_tr.data[0] = '0;

        send_transaction(mid2_read_tr);


        //======================================================
        // HIGH REGION WRITE
        //
        // AXI address    = 0x0C00
        // Memory address = 0x0C00 >> 2 = 768
        //
        // Covers:
        //   WRITE x HIGH
        //   all_ones data bin
        //======================================================

        high_write_tr =
            axi_transaction::type_id::create(
                "high_write_tr"
            );

        high_write_tr.op   = axi_transaction::WRITE;
        high_write_tr.addr = 16'h0C00;
        high_write_tr.len  = 0;
        high_write_tr.size = 2;

        high_write_tr.data = new[1];

        high_write_tr.data[0] =
            32'hFFFF_FFFF;

        send_transaction(high_write_tr);


        //======================================================
        // HIGH REGION READ
        //
        // Covers:
        //   READ x HIGH
        //   all_ones data observed during read
        //======================================================

        high_read_tr =
            axi_transaction::type_id::create(
                "high_read_tr"
            );

        high_read_tr.op   = axi_transaction::READ;
        high_read_tr.addr = 16'h0C00;
        high_read_tr.len  = 0;
        high_read_tr.size = 2;

        high_read_tr.data = new[1];
        high_read_tr.data[0] = '0;

        send_transaction(high_read_tr);


        `uvm_info(
            "MEMORY_COVERAGE_CLOSURE",
            "Targeted memory coverage closure sequence completed",
            UVM_MEDIUM
        )

    endtask

endclass
