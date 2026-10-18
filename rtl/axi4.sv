
module axi4 #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 16,
    parameter MEMORY_DEPTH = 1024
)(
    input  wire                  ACLK,
    input  wire                  ARESETn,

    // Write address channel
    input  wire [ADDR_WIDTH-1:0] AWADDR,
    input  wire [7:0]            AWLEN,
    input  wire [2:0]            AWSIZE,
    input  wire                  AWVALID,
    output reg                   AWREADY,

    // Write data channel
    input  wire [DATA_WIDTH-1:0] WDATA,
    input  wire                  WVALID,
    input  wire                  WLAST,
    output reg                   WREADY,

    // Write response channel
    output reg [1:0]             BRESP,
    output reg                   BVALID,
    input  wire                  BREADY,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0] ARADDR,
    input  wire [7:0]            ARLEN,
    input  wire [2:0]            ARSIZE,
    input  wire                  ARVALID,
    output reg                   ARREADY,

    // Read data channel
    output reg [DATA_WIDTH-1:0]  RDATA,
    output reg [1:0]             RRESP,
    output reg                   RVALID,
    output reg                   RLAST,
    input  wire                  RREADY
);

    //============================================================
    // Memory interface
    //============================================================

    reg                         mem_en;
    reg                         mem_we;
    reg  [$clog2(MEMORY_DEPTH)-1:0] mem_addr;
    reg  [DATA_WIDTH-1:0]       mem_wdata;
    wire [DATA_WIDTH-1:0]       mem_rdata;

    axi4_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(MEMORY_DEPTH)),
        .DEPTH(MEMORY_DEPTH)
    ) mem_inst (
        .clk       (ACLK),
        .rst_n     (ARESETn),
        .mem_en    (mem_en),
        .mem_we    (mem_we),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rdata (mem_rdata)
    );

    //============================================================
    // Response codes
    //============================================================

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;

    //============================================================
    // Write FSM
    //============================================================

    localparam [1:0] W_IDLE = 2'd0,
                     W_DATA = 2'd1,
                     W_RESP = 2'd2;

    reg [1:0] write_state;

    reg [ADDR_WIDTH-1:0] write_addr;
    reg [7:0]            write_len;
    reg [7:0]            write_count;
    reg [2:0]            write_size;

    reg                  write_error;
    reg                  write_last_error;

    //============================================================
    // Read FSM
    //============================================================

    localparam [1:0] R_IDLE = 2'd0,
                     R_WAIT = 2'd1,
                     R_DATA = 2'd2;

    reg [1:0] read_state;

    reg [ADDR_WIDTH-1:0] read_addr;
    reg [7:0]            read_len;
    reg [7:0]            read_count;
    reg [2:0]            read_size;

    reg                  read_error;

    //============================================================
    // Burst validation
    //
    // This implementation supports:
    //   - 32-bit data bus
    //   - 4-byte aligned word transfers
    //   - Incrementing addresses
    //   - No 4 KB boundary crossing
    //   - Addresses within implemented memory
    //
    // Subword writes cannot be implemented correctly without
    // byte-enable or equivalent write-mask functionality.
    //============================================================

    function automatic burst_valid;

        input [ADDR_WIDTH-1:0] start_addr;
        input [7:0]            burst_len;
        input [2:0]            burst_size;

        reg [32:0] total_bytes;
        reg [32:0] last_addr;
        reg [32:0] memory_bytes;

        begin
            total_bytes =
                ({25'd0, burst_len} + 33'd1)
                << burst_size;

            last_addr =
                {17'd0, start_addr}
                + total_bytes
                - 33'd1;

            memory_bytes = MEMORY_DEPTH * 4;

            burst_valid =
                (burst_size == 3'd2) &&
                (start_addr[1:0] == 2'b00) &&
                (last_addr < memory_bytes) &&
                (({17'd0, start_addr} >> 12)
                    == (last_addr >> 12));
        end

    endfunction

    //============================================================
    // Main sequential logic
    //============================================================

    always @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            // AXI outputs
            AWREADY <= 1'b1;
            WREADY  <= 1'b0;

            BRESP   <= RESP_OKAY;
            BVALID  <= 1'b0;

            ARREADY <= 1'b1;

            RDATA   <= {DATA_WIDTH{1'b0}};
            RRESP   <= RESP_OKAY;
            RVALID  <= 1'b0;
            RLAST   <= 1'b0;

            // Memory controls
            mem_en    <= 1'b0;
            mem_we    <= 1'b0;
            mem_addr  <= {$clog2(MEMORY_DEPTH){1'b0}};
            mem_wdata <= {DATA_WIDTH{1'b0}};

            // Write state
            write_state     <= W_IDLE;
            write_addr      <= {ADDR_WIDTH{1'b0}};
            write_len       <= 8'd0;
            write_count     <= 8'd0;
            write_size      <= 3'd0;
            write_error     <= 1'b0;
            write_last_error <= 1'b0;

            // Read state
            read_state <= R_IDLE;
            read_addr  <= {ADDR_WIDTH{1'b0}};
            read_len   <= 8'd0;
            read_count <= 8'd0;
            read_size  <= 3'd0;
            read_error <= 1'b0;

        end else begin

            // Default: memory access is a one-cycle pulse.
            mem_en <= 1'b0;
            mem_we <= 1'b0;

            //====================================================
            // WRITE CHANNEL
            //====================================================

            case (write_state)

                //------------------------------------------------
                // Accept write address
                //------------------------------------------------

                W_IDLE: begin

                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;

                    if (AWVALID && AWREADY) begin

                        write_addr  <= AWADDR;
                        write_len   <= AWLEN;
                        write_count <= AWLEN;
                        write_size  <= AWSIZE;

                        write_error <= !burst_valid(
                            AWADDR,
                            AWLEN,
                            AWSIZE
                        );

                        write_last_error <= 1'b0;

                        AWREADY <= 1'b0;
                        WREADY  <= 1'b1;

                        write_state <= W_DATA;

                    end

                end

                //------------------------------------------------
                // Accept write data beats
                //------------------------------------------------

                W_DATA: begin

                    if (WVALID && WREADY) begin

                        // Check WLAST against expected beat.
                        if (WLAST != (write_count == 0))
                            write_last_error <= 1'b1;

                        // Perform valid word write.
                        if (!write_error) begin

                            mem_en <= 1'b1;
                            mem_we <= 1'b1;

                            mem_addr <=
                                write_addr >> 2;

                            mem_wdata <= WDATA;

                        end

                        // Final expected beat.
                        // Do not terminate the burst early
                        // merely because WLAST was asserted.
                        if (write_count == 0) begin

                            WREADY <= 1'b0;

                            BRESP <=
                                (write_error ||
                                 write_last_error ||
                                 (WLAST != 1'b1))
                                ? RESP_SLVERR
                                : RESP_OKAY;

                            BVALID <= 1'b1;

                            write_state <= W_RESP;

                        end else begin

                            write_addr <=
                                write_addr + (1 << write_size);

                            write_count <= write_count - 1'b1;

                        end

                    end

                end

                //------------------------------------------------
                // Hold response until handshake
                //------------------------------------------------

                W_RESP: begin

                    if (BVALID && BREADY) begin

                        BVALID <= 1'b0;
                        BRESP  <= RESP_OKAY;

                        AWREADY <= 1'b1;

                        write_state <= W_IDLE;

                    end

                end

                default: begin

                    write_state <= W_IDLE;

                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;

                end

            endcase

            //====================================================
            // READ CHANNEL
            //====================================================

            case (read_state)

                //------------------------------------------------
                // Accept read address
                //------------------------------------------------

                R_IDLE: begin

                    ARREADY <= 1'b1;

                    RVALID <= 1'b0;
                    RLAST  <= 1'b0;

                    if (ARVALID && ARREADY) begin

                        read_addr  <= ARADDR;
                        read_len   <= ARLEN;
                        read_count <= ARLEN;
                        read_size  <= ARSIZE;

                        read_error <= !burst_valid(
                            ARADDR,
                            ARLEN,
                            ARSIZE
                        );

                        ARREADY <= 1'b0;

                        read_state <= R_WAIT;

                        // Start first synchronous memory read.
                        if (burst_valid(ARADDR, ARLEN, ARSIZE)) begin

                            mem_en <= 1'b1;
                            mem_we <= 1'b0;

                            mem_addr <= ARADDR >> 2;

                        end

                    end

                end

                //------------------------------------------------
                // Wait for synchronous memory result
                //------------------------------------------------

                R_WAIT: begin

                    // The memory output has had a clock edge
                    // to update before this state is entered.
                    read_state <= R_DATA;

                end

                //------------------------------------------------
                // Present data and hold until accepted
                //------------------------------------------------

                R_DATA: begin

                    if (!RVALID) begin

                        if (read_error) begin

                            RDATA <= {DATA_WIDTH{1'b0}};
                            RRESP <= RESP_SLVERR;

                        end else begin

                            RDATA <= mem_rdata;
                            RRESP <= RESP_OKAY;

                        end

                        RLAST  <= (read_count == 0);
                        RVALID <= 1'b1;

                    end else if (RVALID && RREADY) begin

                        // Current beat was accepted.
                        if (read_count == 0) begin

                            // End of burst.
                            RVALID <= 1'b0;
                            RLAST  <= 1'b0;
                            RRESP  <= RESP_OKAY;

                            ARREADY <= 1'b1;

                            read_state <= R_IDLE;

                        end else begin

                            // Advance to next beat.
                            read_addr <=
                                read_addr + (1 << read_size);

                            read_count <=
                                read_count - 1'b1;

                            RVALID <= 1'b0;
                            RLAST  <= 1'b0;

                            // Issue the next synchronous read.
                            if (!read_error) begin

                                mem_en <= 1'b1;
                                mem_we <= 1'b0;

                                mem_addr <=
                                    (read_addr + (1 << read_size))
                                    >> 2;

                            end

                            read_state <= R_WAIT;

                        end

                    end

                end

                default: begin

                    read_state <= R_IDLE;

                    ARREADY <= 1'b1;
                    RVALID  <= 1'b0;
                    RLAST   <= 1'b0;

                end

            endcase

        end

    end

endmodule
