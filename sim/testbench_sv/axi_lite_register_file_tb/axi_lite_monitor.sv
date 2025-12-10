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
// FILE         :   axi_lite_monitor.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   Defines a single register access (Read or Write).
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  04-DEC-2025    Sachith Rathnayake      Design and Implementation
//
// ************************************************************************************************************************

//---------------------------------------------------------------------------------------------------------------------
// Global constant headers
//---------------------------------------------------------------------------------------------------------------------
    
import uvm_pkg::*;
`include "uvm_macros.svh"
import axi_lite_pkg::*;

// --- AXI-Lite Monitor ---
// Passively observes the interface and publishes observed transactions.
class axi_lite_monitor extends uvm_monitor;
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    `uvm_component_utils(axi_lite_monitor)
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // Virtual Interface Handle (to connect to the axi_lite_if MONITOR modport)
    virtual axi_lite_if vif; // Use the base interface for monitoring all signals

    // TLM port to send observed data
    uvm_analysis_port#(axi_lite_transaction) ap;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Constraints
    //---------------------------------------------------------------------------------------------------------------------

    // Constraint:

    //---------------------------------------------------------------------------------------------------------------------
    // Tasks and Functions
    //---------------------------------------------------------------------------------------------------------------------
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    // Grab virtual interface from config DB
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_full_name(), "Virtual interface not set for axi_lite_monitor")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        fork
            monitor_writes();
            monitor_reads();
        join
    endtask
    
    // Task to monitor AXI Write cycles (AW, W, B)
    virtual protected task monitor_writes();
        forever begin
            axi_lite_transaction tr;
            
            // Wait for a valid AW request
            wait (vif.awvalid == 1'b1 && vif.awready == 1'b1);
            
            // Wait for W data
            wait (vif.wvalid == 1'b1 && vif.wready == 1'b1);

            // Create transaction item
            tr = axi_lite_transaction::type_id::create("tr", this);
            tr.type_e = axi_lite_transaction::AXI_WRITE;
            tr.addr = vif.awaddr;
            tr.wdata = vif.wdata;
            tr.wstrb = vif.wstrb;
            
            // Wait for B response (optional to monitor, but good for completion)
            wait (vif.bvalid == 1'b1 && vif.bready == 1'b1);
            
            `uvm_info(get_full_name(), 
                      $sformatf("Monitored Write: Addr=0x%H, Data=0x%H", tr.addr, tr.wdata), 
                      UVM_HIGH)
            ap.write(tr);

            @(posedge vif.ACLK);
        end
    endtask
    
    // Task to monitor AXI Read cycles (AR, R)
    virtual protected task monitor_reads();
        forever begin
            axi_lite_transaction tr;
            
            // Wait for a valid AR request
            wait (vif.arvalid == 1'b1 && vif.arready == 1'b1);
            
            // Wait for R data
            wait (vif.rvalid == 1'b1 && vif.rready == 1'b1);

            // Create transaction item
            tr = axi_lite_transaction::type_id::create("tr", this);
            tr.type_e = axi_lite_transaction::AXI_READ;
            tr.addr = vif.araddr;
            tr.rdata = vif.rdata; // Capture the returned data
            
            `uvm_info(get_full_name(), 
                      $sformatf("Monitored Read: Addr=0x%H, Data=0x%H", tr.addr, tr.rdata), 
                      UVM_HIGH)
            ap.write(tr);

            @(posedge vif.ACLK);
        end
    endtask

endclass