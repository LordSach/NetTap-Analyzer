// ************************************************************************************************************************
//
// Copyright (c) 2025 Sachith Rathnayake
// All Rights Reserved.
//
// This software, HDL source code, hardware designs, documentation, and all
// associated files (collectively, the "Work") are provided for viewing purposes
// only.
//
// No permission is granted to copy, reproduce, modify, merge, publish,
// distribute, sublicense, create derivative works from, or use the Work, in
// whole or in part, for any purpose without explicit written permission from
// the copyright holder.
//
// Commercial use requires a separate license agreement. Unauthorized use,
// reproduction, modification, or distribution of the Work may result in civil
// and criminal penalties.
//
// THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE, AND NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDER
// BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE WORK
// OR THE USE OR OTHER DEALINGS IN THE WORK.
//
// For commercial licensing inquiries or support, please contact:
// Phone:      +94 778 911 111
// Email:      sachith.rathnayake.92@gmail.com
// LinkedIn:   https://www.linkedin.com/in/sachith-rathnayake-profile-link/
// GitHub:     https://github.com/LordSach
//
// ************************************************************************************************************************
//
// PROJECT      :   NetTap Analyzer
// PRODUCT      :   DMA_SG_Engine
// FILE         :   axi_lite_read_write_seq.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   // --- Test Sequence (Test Scenario 1) ---
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  05-DEC-2025    Sachith Rathnayake      Design and Implementation
//
// ************************************************************************************************************************

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------


class axi_lite_read_write_seq extends uvm_sequence#(axi_lite_transaction);
    `uvm_object_utils(axi_lite_read_write_seq)
    
    function new(string name = "axi_lite_read_write_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        axi_lite_transaction tr;
        logic [31:0] write_val;
        logic [31:0] read_val;
        
        // Use a set of target registers based on the DMA specification
        // Assume addresses 0x000, 0x004, 0x008 are R/W registers
        logic [31:0] addresses[] = {32'h000, 32'h004, 32'h008};
        
        // --- 1. Perform Write Cycle ---
        foreach(addresses[i]) begin
            // Create and randomize write transaction
            `uvm_do_with(tr, { 
                tr.type_e == axi_lite_transaction::AXI_WRITE;
                tr.addr == addresses[i];
                tr.wdata inside {[32'hA0000000:32'hAFFFFFFF]}; // Use recognizable data
                tr.wstrb == 4'hF; // Write all bytes
            })
            `uvm_info(get_full_name(), 
                      $sformatf("Write Seq: Addr=0x%H, Data=0x%H", tr.addr, tr.wdata), 
                      UVM_LOW)
        end
        
        // --- 2. Perform Read Cycle and Verify ---
        `uvm_info(get_full_name(), "Starting Readback and Verification", UVM_LOW)
        foreach(addresses[i]) begin
            write_val = get_transaction_by_addr(addresses[i]); // Requires transaction history/scoreboard
            
            // Create read transaction
            `uvm_do_with(tr, { 
                tr.type_e == axi_lite_transaction::AXI_READ;
                tr.addr == addresses[i];
            })
            read_val = tr.rdata;
            
            // Simple self-check (Scoreboard should do this formally)
            // if (read_val == write_val)
            //     `uvm_info(get_full_name(), $sformatf("PASS: Readback from 0x%H matches.", addresses[i]), UVM_NONE)
            // else
            //     `uvm_error(get_full_name(), $sformatf("FAIL: Readback from 0x%H. Expected 0x%H, Got 0x%H", 
            //                                         addresses[i], write_val, read_val))
        end
    endtask
    
    // Placeholder function (requires linking to a history queue/scoreboard)
    function logic [31:0] get_transaction_by_addr(logic [31:0] addr);
        return 32'hFFFF0000 | addr; // Dummy value for demonstration
    endfunction
endclass