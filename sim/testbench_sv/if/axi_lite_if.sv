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
// FILE         :   axi_lite_if.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   Interface for the AXI4-Lite Protocol (Control and Status Registers)
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

`timescale 1ns/1ps

interface axi_lite_if (
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
    
    // --- Signals for the five independent channels (No ID, No Burst) ---

    // 1. Write Address Channel (AW)
    logic [ADDR_WIDTH-1:0]  awaddr;
    logic                   awvalid;
    logic                   awready;

    // 2. Write Data Channel (W)
    logic [DATA_WIDTH-1:0]  wdata;
    logic [DATA_WIDTH/8-1:0] wstrb; // Byte strobes
    logic                   wvalid;
    logic                   wready;

    // 3. Write Response Channel (B)
    logic [1:0]             bresp;  // 00 = OKAY
    logic                   bvalid;
    logic                   bready;

    // 4. Read Address Channel (AR)
    logic [ADDR_WIDTH-1:0]  araddr;
    logic                   arvalid;
    logic                   arready;

    // 5. Read Data Channel (R)
    logic [DATA_WIDTH-1:0]  rdata;
    logic [1:0]             rresp;  // 00 = OKAY
    logic                   rvalid;
    logic                   rready;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Modports for Agents ---

    // 1. Master Modport (CPU/Config Agent - Drives requests)
    modport MASTER (
        // Write: Drives AWVALID, AWADDR, WVALID, WDATA, BREADY
        output awvalid, awaddr, wvalid, wdata, wstrb, bready,
        input  awready, wready, bvalid, bresp,
        // Read: Drives ARVALID, ARADDR, RREADY
        output arvalid, araddr, rready,
        input  arready, rvalid, rdata, rresp,
        input  ACLK, ARESETN
    );

    // 2. Slave Modport (DMA/DUT - Responds to requests)
    modport SLAVE (
        // Write: Drives AWREADY, WREADY, BVALID, BRESP
        input  awvalid, awaddr, wvalid, wdata, wstrb, bready,
        output awready, wready, bvalid, bresp,
        // Read: Drives ARREADY, RVALID, RDATA, RRESP
        input  arvalid, araddr, rready,
        output arready, rvalid, rdata, rresp,
        input  ACLK, ARESETN
    );

endinterface