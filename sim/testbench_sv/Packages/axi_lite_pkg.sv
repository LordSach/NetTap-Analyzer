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
// FILE         :   axi_lite_pkg.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   The package that ties all UVM components together.
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

package axi_lite_pkg;

    // Global UVM import and macros
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // --- Component Definitions ---
    // Forward declarations required for compilation order
    `include "axi_lite_transaction.sv"
    `include "axi_lite_sequencer.sv"
    `include "axi_lite_driver.sv"
    `include "axi_lite_monitor.sv"
    `include "axi_lite_agent.sv"
    `include "axi_lite_env.sv"
    `include "axi_lite_read_write_seq.sv"
    `include "axi_lite_base_test.sv"

endpackage