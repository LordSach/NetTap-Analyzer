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
// FILE         :   axi_full_if.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   Interface for the AXI4 Protocol (Memory Mapped Data and Descriptor Access)
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  3-DEC-2025    Sachith Rathnayake      Design and Implementation
//
// ************************************************************************************************************************

interface axi_full_if (
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
    
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 64; // DMA uses 64-bit access to DDR
    parameter ID_WIDTH   = 4;
    
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
    
    // --- Signals for the six independent channels (Includes ID and Burst) ---

    // 1. Write Address Channel (AW)
    logic [ID_WIDTH-1:0]    awid;
    logic [ADDR_WIDTH-1:0]  awaddr;
    logic [7:0]             awlen;    // Burst length (up to 256)
    // ... other AW signals (size, burst, cache, prot, etc.) excluded for clarity
    logic                   awvalid;
    logic                   awready;

    // 2. Write Data Channel (W)
    logic [DATA_WIDTH-1:0]  wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                   wlast;    // End of the burst
    logic                   wvalid;
    logic                   wready;

    // 3. Write Response Channel (B)
    logic [ID_WIDTH-1:0]    bid;
    logic [1:0]             bresp;
    logic                   bvalid;
    logic                   bready;

    // 4. Read Address Channel (AR)
    logic [ID_WIDTH-1:0]    arid;
    logic [ADDR_WIDTH-1:0]  araddr;
    logic [7:0]             arlen;    // Burst length
    // ... other AR signals
    logic                   arvalid;
    logic                   arready;

    // 5. Read Data Channel (R)
    logic [ID_WIDTH-1:0]    rid;
    logic [DATA_WIDTH-1:0]  rdata;
    logic [1:0]             rresp;
    logic                   rlast;    // End of the burst
    logic                   rvalid;
    logic                   rready;

    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Modports for Agents ---

    // 1. Master Modport (DMA - Drives requests to DDR/Memory)
    modport MASTER (
        output awid, awaddr, awlen, awvalid, wdata, wstrb, wlast, wvalid, bready,
        input  awready, wready, bid, bresp, bvalid,

        output arid, araddr, arlen, arvalid, rready,
        input  arready, rid, rdata, rresp, rlast, rvalid,
        
        input  ACLK, ARESETN
    );

    // 2. Slave Modport (Memory Model - Responds with data/descriptors)
    modport SLAVE (
        input  awid, awaddr, awlen, awvalid, wdata, wstrb, wlast, wvalid, bready,
        output awready, wready, bid, bresp, bvalid,

        input  arid, araddr, arlen, arvalid, rready,
        output arready, rid, rdata, rresp, rlast, rvalid,

        input  ACLK, ARESETN
    );

endinterface