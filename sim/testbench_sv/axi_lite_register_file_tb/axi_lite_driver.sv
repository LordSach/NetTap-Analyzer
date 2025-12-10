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
// FILE         :   axi_lite_driver.sv
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

// --- AXI-Lite Driver ---
// Implements the AXI4-Lite Master protocol handshake.
class axi_lite_driver extends uvm_driver#(axi_lite_transaction);
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // Enumeration for transaction type

    `uvm_component_utils(axi_lite_driver)
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // Virtual Interface Handle (connect to axi_lite_if)
    virtual axi_lite_if vif;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Constraints
    //---------------------------------------------------------------------------------------------------------------------

    // Constraint:

    //---------------------------------------------------------------------------------------------------------------------
    // Tasks and Functions
    //---------------------------------------------------------------------------------------------------------------------
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Grab virtual interface from config DB
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_full_name(), "Virtual interface not set for axi_lite_driver")
        end
    endfunction

    // Run phase: Main logic loop
    virtual task run_phase(uvm_phase phase);
        forever begin
            axi_lite_transaction tr;
            // 1. Get transaction from sequencer
            seq_item_port.get_next_item(tr);

            // 2. Drive the transaction based on type
            if (tr.type_e == axi_lite_transaction::AXI_WRITE) begin
                drive_write(tr);
            end else begin
                drive_read(tr);
            end

            // 3. Notify sequencer transaction is done
            seq_item_port.item_done();
        end
    endtask : run_phase

    // Drives a single AXI-Lite Write transaction
    virtual protected task drive_write(axi_lite_transaction tr);
        `uvm_info(get_full_name(), 
                  $sformatf("Driving Write: Addr=0x%H, Data=0x%H", tr.addr, tr.wdata), 
                  UVM_MEDIUM)

        // 1. Drive AW Channel - Wait for handshake at clock edge
        @(posedge vif.ACLK);
        vif.awaddr <= tr.addr;
        vif.awvalid <= 1'b1;
        `uvm_info(get_full_name(), $sformatf("[%0t] AW Channel: Set AWADDR=0x%H, AWVALID=1", $time, tr.addr), UVM_LOW);
        
        // Wait for handshake at clock edge (both AWVALID and AWREADY must be high)
        fork
            begin
                // Wait for clock edge where both signals are high (handshake completes)
                @(posedge vif.ACLK);
                while (!(vif.awvalid && vif.awready)) begin
                    @(posedge vif.ACLK);
                end
                `uvm_info(get_full_name(), $sformatf("[%0t] AW Channel: Handshake detected at clock edge", $time), UVM_LOW);
                // Wait one more clock cycle to ensure FSM has time to process
                @(posedge vif.ACLK);
                `uvm_info(get_full_name(), $sformatf("[%0t] AW Channel: Handshake complete, clearing AWVALID", $time), UVM_LOW);
            end
            begin
                #5000ns; // 5us timeout
                `uvm_error(get_full_name(), $sformatf("[%0t] TIMEOUT: AWREADY not asserted after 5us. AWVALID=%b, AWREADY=%b, AWADDR=0x%H", 
                          $time, vif.awvalid, vif.awready, vif.awaddr));
            end
        join_any
        disable fork;
        
        // Clear AWVALID after handshake (non-blocking, takes effect at end of time step)
        vif.awvalid <= 1'b0;

        // 2. Drive W Channel - Wait for handshake at clock edge
        @(posedge vif.ACLK);
        vif.wdata <= tr.wdata;
        vif.wstrb <= tr.wstrb;
        vif.wvalid <= 1'b1;
        `uvm_info(get_full_name(), $sformatf("[%0t] W Channel: Set WDATA=0x%H, WVALID=1", $time, tr.wdata), UVM_LOW);
        
        // Wait for handshake at clock edge (both WVALID and WREADY must be high)
        fork
            begin
                // Wait for clock edge where both signals are high (handshake completes)
                @(posedge vif.ACLK);
                while (!(vif.wvalid && vif.wready)) begin
                    @(posedge vif.ACLK);
                end
                `uvm_info(get_full_name(), $sformatf("[%0t] W Channel: Handshake detected at clock edge", $time), UVM_LOW);
                // Wait one more clock cycle to ensure FSM has time to process
                @(posedge vif.ACLK);
                `uvm_info(get_full_name(), $sformatf("[%0t] W Channel: Handshake complete, clearing WVALID", $time), UVM_LOW);
            end
            begin
                #5000ns; // 5us timeout
                `uvm_error(get_full_name(), $sformatf("[%0t] TIMEOUT: WREADY not asserted after 5us. WVALID=%b, WREADY=%b, WDATA=0x%H", 
                          $time, vif.wvalid, vif.wready, vif.wdata));
            end
        join_any
        disable fork;
        
        // Clear WVALID after handshake (non-blocking, takes effect at end of time step)
        vif.wvalid <= 1'b0;

        // 3. Wait for B Channel Response - Wait for handshake at clock edge
        @(posedge vif.ACLK);
        vif.bready <= 1'b1;
        `uvm_info(get_full_name(), $sformatf("[%0t] B Channel: Set BREADY=1, waiting for BVALID", $time), UVM_LOW);
        
        // Wait for handshake at clock edge (both BVALID and BREADY must be high)
        fork
            begin
                // Wait for clock edge where both signals are high (handshake completes)
                @(posedge vif.ACLK);
                while (!(vif.bvalid && vif.bready)) begin
                    @(posedge vif.ACLK);
                end
                `uvm_info(get_full_name(), $sformatf("[%0t] B Channel: Handshake detected at clock edge, BRESP=0x%H", $time, vif.bresp), UVM_LOW);
                // Wait one more clock cycle to ensure FSM has time to process
                @(posedge vif.ACLK);
                `uvm_info(get_full_name(), $sformatf("[%0t] B Channel: Handshake complete, clearing BREADY", $time), UVM_LOW);
            end
            begin
                #5000ns; // 5us timeout
                `uvm_error(get_full_name(), $sformatf("[%0t] TIMEOUT: BVALID not asserted after 5us. BVALID=%b, BREADY=%b, BRESP=0x%H", 
                          $time, vif.bvalid, vif.bready, vif.bresp));
            end
        join_any
        disable fork;
        
        // Clear BREADY after handshake (non-blocking, takes effect at end of time step)
        vif.bready <= 1'b0;
        
        if (vif.bresp != 2'b00) begin
            `uvm_error(get_full_name(), $sformatf("AXI Write Response Error: BRESP=%0d", vif.bresp))
        end

    endtask

    // Drives a single AXI-Lite Read transaction
    virtual protected task drive_read(axi_lite_transaction tr);
        `uvm_info(get_full_name(), 
                  $sformatf("Driving Read: Addr=0x%H", tr.addr), 
                  UVM_MEDIUM)
        
        // 1. Drive AR Channel
        @(posedge vif.ACLK);
        vif.araddr <= tr.addr;
        vif.arvalid <= 1'b1;
        wait (vif.arready == 1'b1);
        vif.arvalid <= 1'b0;

        // 2. Wait for R Channel Data
        @(posedge vif.ACLK);
        vif.rready <= 1'b1;
        wait (vif.rvalid == 1'b1);
        vif.rready <= 1'b0;

        tr.rdata = vif.rdata;
        
        if (vif.rresp != 2'b00) begin
            `uvm_error(get_full_name(), $sformatf("AXI Read Response Error: RRESP=%0d", vif.rresp))
        end
    endtask

    // Must initialize output signals in the connect phase
    virtual function void connect_phase(uvm_phase phase);
        if (vif != null) begin
            vif.awvalid <= 1'b0;
            vif.wvalid  <= 1'b0;
            vif.bready  <= 1'b0;
            vif.arvalid <= 1'b0;
            vif.rready  <= 1'b0;
        end
    endfunction

endclass