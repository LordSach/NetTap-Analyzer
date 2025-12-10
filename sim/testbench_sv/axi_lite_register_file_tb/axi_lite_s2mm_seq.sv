class axi_lite_s2mm_seq extends uvm_sequence #(axi_lite_transaction);
    `uvm_object_utils(axi_lite_s2mm_seq)

    // --- Register Offsets (Matching DUT S2MM Map) ---
    localparam ADDR_CTRL_REG    = 32'h00;
    localparam ADDR_STATUS_REG  = 32'h04;
    localparam ADDR_S2MM_ADDR   = 32'h10; // Destination Address Register
    localparam ADDR_S2MM_LENGTH = 32'h14; // Length Register

    // --- Configuration Variables ---
    rand logic [31:0] ddr_dest_addr;
    rand logic [31:0] transfer_length;

    function new(string name = "axi_lite_s2mm_seq");
        super.new(name);
    endfunction

    // --- Helper Task for Writes ---
    task write_reg(input logic [31:0] addr, input logic [31:0] data);
        axi_lite_transaction tr;
        tr = axi_lite_transaction::type_id::create("tr");
        
        start_item(tr);
        if (!tr.randomize() with {
            type_e == axi_lite_transaction::AXI_WRITE;
            addr   == local::addr;
            wdata  == local::data;
            wstrb  == 4'hF; 
        }) `uvm_error("SEQ", "Randomization failed");
        finish_item(tr);
        
        `uvm_info("S2MM_SEQ", $sformatf("Write Register: Addr=0x%h, Data=0x%h", addr, data), UVM_LOW)
    endtask

    // --- Helper Task for Reads (Status Polling) ---
    task poll_status_busy();
        axi_lite_transaction tr;
        logic busy_bit;
        int timeout = 100;

        do begin
            tr = axi_lite_transaction::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize() with {
                type_e == axi_lite_transaction::AXI_READ;
                addr   == ADDR_STATUS_REG;
            }) `uvm_error("SEQ", "Randomization failed");
            finish_item(tr);

            // Check S2MM Busy Bit (Bit 1)
            busy_bit = tr.rdata[1];
            
            if (busy_bit) begin
                `uvm_info("S2MM_SEQ", "S2MM DMA is Busy...", UVM_HIGH)
                #100ns; // Wait before polling again
            end
            timeout--;
        end while (busy_bit && timeout > 0);

        if (timeout == 0) 
            `uvm_error("S2MM_SEQ", "Timeout waiting for S2MM to complete!")
        else
            `uvm_info("S2MM_SEQ", "S2MM Transfer Complete (Idle).", UVM_LOW)
    endtask

    // --- Main Sequence Body ---
    virtual task body();
        // 1. Configure Destination Address (e.g., 0x2000_0000)
        write_reg(ADDR_S2MM_ADDR, ddr_dest_addr);

        // 2. Configure Length (e.g., 64 bytes)
        write_reg(ADDR_S2MM_LENGTH, transfer_length);

        // 3. Trigger Start (Bit 1 = 1 for S2MM)
        // Note: Using Read-Modify-Write in a real driver is safer, but direct write is fine for unit test
        write_reg(ADDR_CTRL_REG, 32'h0000_0002);

        // 4. Wait for Hardware to Finish
        // poll_status_busy(); 
    endtask

endclass