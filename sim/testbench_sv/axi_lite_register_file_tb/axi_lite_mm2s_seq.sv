class axi_lite_mm2s_seq extends uvm_sequence #(axi_lite_transaction);
    `uvm_object_utils(axi_lite_mm2s_seq)

    // --- Register Offsets (Matching DUT) ---
    localparam ADDR_CTRL_REG    = 32'h00;
    localparam ADDR_STATUS_REG  = 32'h04;
    localparam ADDR_MM2S_ADDR   = 32'h20;
    localparam ADDR_MM2S_LENGTH = 32'h24;

    // --- Configuration Variables ---
    rand logic [31:0] ddr_source_addr;
    rand logic [31:0] transfer_length;

    function new(string name = "axi_lite_mm2s_seq");
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
        
        `uvm_info("MM2S_SEQ", $sformatf("Write Register: Addr=0x%h, Data=0x%h", addr, data), UVM_LOW)
    endtask

    // --- Helper Task for Reads ---
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

            // Check MM2S Busy Bit (Bit 0)
            busy_bit = tr.rdata[0];
            
            if (busy_bit) begin
                `uvm_info("MM2S_SEQ", "DMA is Busy...", UVM_HIGH)
                #100ns; // Wait before polling again
            end
            timeout--;
        end while (busy_bit && timeout > 0);

        if (timeout == 0) 
            `uvm_error("MM2S_SEQ", "Timeout waiting for DMA to complete!")
        else
            `uvm_info("MM2S_SEQ", "DMA Transfer Complete (Idle).", UVM_LOW)
    endtask

    // --- Main Sequence Body ---
    virtual task body();
        // 1. Configure Source Address (e.g., 0x1000_0000)
        write_reg(ADDR_MM2S_ADDR, ddr_source_addr);

        // 2. Configure Length (e.g., 128 bytes)
        write_reg(ADDR_MM2S_LENGTH, transfer_length);

        // 3. Trigger Start (Bit 0 = 1)
        write_reg(ADDR_CTRL_REG, 32'h0000_0001);

        // 4. Wait for Hardware to Finish
        // (Note: In a unit test of just the register file, the Busy bit won't 
        // clear unless we force the input pin 'mm2s_busy_i' low in the testbench harness)
        // poll_status_busy(); 
    endtask

endclass