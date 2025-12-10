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
// FILE         :   axi_lite_agent.sv
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

// --- AXI-Lite Agent ---
// Encapsulates the core components of the AXI-Lite interface.
class axi_lite_agent extends uvm_agent;
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    `uvm_component_utils(axi_lite_agent)
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    axi_lite_driver    driver;
    axi_lite_sequencer sequencer;
    axi_lite_monitor   monitor;
    
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
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Build Sequencer and Monitor always
        sequencer = axi_lite_sequencer::type_id::create("sequencer", this);
        monitor   = axi_lite_monitor::type_id::create("monitor", this);

        // Build Driver only if the agent is active (Master mode)
        // We assume Master mode for this unit test
        driver    = axi_lite_driver::type_id::create("driver", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        // Connect Driver and Sequencer
        if (driver != null) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        // NOTE: The virtual interface connection is done in the top module/test
    endfunction

endclass