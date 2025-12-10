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
// FILE         :   axi_stream_if.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   The virtual interface abstracts the physical wires of the AXI Stream protocol.
//                  This allows UVM components to interact with the DUT without knowing the exact wire names.
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  10-FEB-2023    Sachith Rathnayake      Creation
//
// ************************************************************************************************************************

interface axi_stream_if (
    ACLK,
    ARESETN
);

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    // constants
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    parameter DATA_WIDTH = 32;
    
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // localparams
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // typedefs
    
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    
    input logic ACLK;
    input logic ARESETN;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Signals for the interface ---
    logic tvalid;
    logic tready;
    logic [DATA_WIDTH-1:0] tdata;
    logic tlast;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Modports (The Role Definition) ---
    // Modports define WHO can drive/read which signals.

    // 1. Slave Modport (Used by DUT/Monitor)
    // The DUT is the Slave when RECEIVING data.
    modport SLAVE (
        input  tvalid,  // DUT must READ valid
        output tready,  // DUT must DRIVE ready
        input  tdata,
        input  tlast,
        input  ACLK,
        input  ARESETN
    );

    // 2. Master Modport (Used by Driver/Sequencer)
    // The DRIVER is the Master when SENDING data.
    modport MASTER (
        output tvalid,  // Driver must DRIVE valid
        input  tready,  // Driver must READ ready
        output tdata,
        output tlast,
        input  ACLK,
        input  ARESETN
    );
    
    // 3. Monitor Modport (Passive observation)
    modport MONITOR (
        input  tvalid,
        input  tready,
        input  tdata,
        input  tlast,
        input  ACLK,
        input  ARESETN
    );

endinterface