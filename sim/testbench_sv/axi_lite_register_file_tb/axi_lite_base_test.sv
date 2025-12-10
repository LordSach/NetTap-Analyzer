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
// FILE         :   axi_lite_base_test.sv
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

// --- Base Test ---
class axi_lite_base_test extends uvm_test;
    
    `uvm_component_utils(axi_lite_base_test)
    
    axi_lite_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_lite_env::type_id::create("env", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        axi_lite_read_write_seq seq;
        phase.raise_objection(this);
        
        seq = axi_lite_read_write_seq::type_id::create("seq");
        // Start the sequence on the AXI-Lite Sequencer
        seq.start(env.lite_agent.sequencer); 
        
        #500; // Allow time for transactions and checks to complete
        
        phase.drop_objection(this);
        // UVM will automatically proceed through extract_phase, check_phase, report_phase, and final_phase
        // No need to call $finish - UVM handles simulation termination after all phases complete
    endtask
    
    // Optional: Override report_phase to add custom reporting
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_full_name(), "Test completed - Report phase executed", UVM_MEDIUM)
    endfunction
endclass