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
// FILE         :   axi_lite_transaction.sv
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

// --- AXI-Lite Transaction ---
// Defines a single register access (Read or Write).
class axi_lite_transaction extends uvm_sequence_item;
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // Enumeration for transaction type
    typedef enum {AXI_WRITE, AXI_READ} trans_type_e;

    `uvm_object_utils_begin(axi_lite_transaction)
        `uvm_field_enum(trans_type_e, type_e, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(wstrb, UVM_ALL_ON)
    `uvm_object_utils_end
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    rand    trans_type_e            type_e;
    rand    logic           [31:0]  addr;   // Assuming 32-bit addresses for control
    rand    logic           [31:0]  wdata;  // Write data
    logic                   [31:0]  rdata;  // Read data (returned by driver)
    rand    logic           [ 3:0]  wstrb;  // Byte strobes for 32-bit data
    
    //---------------------------------------------------------------------------------------------------------------------
    // Constraints
    //---------------------------------------------------------------------------------------------------------------------

    // Constraint: Ensure address space is within a reasonable range for a register file
    constraint addr_c { addr[31:10] == 0; } // Confines address to lowest 10 bits (1024 addresses)

    //---------------------------------------------------------------------------------------------------------------------
    // Functions
    //---------------------------------------------------------------------------------------------------------------------
    
    function new(string name = "axi_lite_transaction");
        super.new(name);
    endfunction

endclass