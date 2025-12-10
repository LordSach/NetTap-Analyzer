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
// FILE         :   dma_engine_top.sv
// AUTHOR       :   Sachith Rathayake
// DESCRIPTION  :   The Top Level of the Custom Scatter-Gather DMA Engine.
//                  This module integrates the Control (AXI-Lite), Memory (AXI-Full), 
//                  and Data (AXI-Stream) interfaces, along with the core MM2S and S2MM channels.
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  3-DEC-2025    Sachith Rathnayake        Design and Implementation
//
// ************************************************************************************************************************

`timescale 1ns/1ps`

module dma_engine_top (
    // =========================================================
    // 0. Global Signals
    // =========================================================
    ACLK,
    ARESETN, // Active Low Reset

    // =========================================================
    // 1. AXI4-Lite Slave Interface (Control Plane from PS/CPU)
    // The CPU accesses DMA Registers (e.g., MM2S_DMACR, MM2S_TAILDESC).
    // The DMA is the SLAVE here.
    // =========================================================

    // Write Address Channel (AW)
    s_axil_awaddr,
    s_axil_awvalid,
    s_axil_awready,

    // Write Data Channel (W)
    s_axil_wdata,
    s_axil_wstrb,
    s_axil_wvalid,
    s_axil_wready,

    // Write Response Channel (B)
    s_axil_bresp,
    s_axil_bvalid,
    s_axil_bready,

    // Read Address Channel (AR)
    s_axil_araddr,
    s_axil_arvalid,
    s_axil_arready,

    // Read Data Channel (R)
    s_axil_rdata,
    s_axil_rresp,
    s_axil_rvalid,
    s_axil_rready,

    // =========================================================
    // 2. AXI4-Full Master Interface (Memory Plane to DDR)
    // The DMA accesses DDR for Descriptors and Bulk Data.
    // The DMA is the MASTER here.
    // =========================================================

    // Common signals for MM2S (Read) and S2MM (Write) memory access
    // MM2S uses AR/R channels (Read from DDR)
    // S2MM uses AW/W/B channels (Write to DDR)

    // Read Address Channel (AR - MM2S Fetch)
    m_axi_arid,
    m_axi_araddr,
    m_axi_arlen,
    // (Other AR signals omitted for brevity: size, burst, cache, prot, etc.)
    m_axi_arvalid,
    m_axi_arready,

    // Read Data Channel (R - MM2S Fetch)
    m_axi_rid,
    m_axi_rdata,
    m_axi_rresp,
    m_axi_rlast,
    m_axi_rvalid,
    m_axi_rready,

    // Write Address Channel (AW - S2MM Status/Data Write)
    m_axi_awid,
    m_axi_awaddr,
    m_axi_awlen,
    // (Other AW signals omitted)
    m_axi_awvalid,
    m_axi_awready,

    // Write Data Channel (W - S2MM Data Write)
    m_axi_wdata,
    m_axi_wstrb,
    m_axi_wlast,
    m_axi_wvalid,
    m_axi_wready,

    // Write Response Channel (B - S2MM Status)
    m_axi_bid,
    m_axi_bresp,
    m_axi_bvalid,
    m_axi_bready,

    // =========================================================
    // 3. AXI-Stream Interfaces (Data Plane to/from PE)
    // =========================================================

    // M_AXIS (MM2S Output Stream - Data FROM DDR, TO PE)
    m_axis_mm2s_tvalid, // DMA asserts valid
    m_axis_mm2s_tready, // PE asserts ready
    m_axis_mm2s_tdata,
    m_axis_mm2s_tlast,

    // S_AXIS (S2MM Input Stream - Data FROM PE, TO DDR)
    s_axis_s2mm_tvalid, // PE asserts valid
    s_axis_s2mm_tready, // DMA asserts ready
    s_axis_s2mm_tdata,
    s_axis_s2mm_tlast,

    // =========================================================
    // 4. Interrupts (Optional, but essential for efficiency)
    // =========================================================
    irq_mm2s,
    irq_s2mm
);

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    // constants
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Interface Parameters ---
    parameter AXI_LITE_ADDR_WIDTH   = 10;  // Register Map Size (e.g., 1KB address space)
    parameter AXI_LITE_DATA_WIDTH   = 32;

    parameter AXI_FULL_ADDR_WIDTH   = 32;
    parameter AXI_FULL_DATA_WIDTH   = 64;  // Data/Descriptor width to DDR
    parameter AXI_FULL_ID_WIDTH     = 4;

    parameter AXI_STREAM_DATA_WIDTH = 32;   // Data width to/from Processing Element (PE)
    
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
    
    // =========================================================
    // 0. Global Signals
    // =========================================================
    input  logic                                ACLK;
    input  logic                                ARESETN; // Active Low Reset
    
    // =========================================================
    // 1. AXI4-Lite Slave Interface (Control Plane from PS/CPU)
    // The CPU accesses DMA Registers (e.g., MM2S_DMACR, MM2S_TAILDESC).
    // The DMA is the SLAVE here.
    // =========================================================
    
    // Write Address Channel (AW)
    input  logic [AXI_LITE_ADDR_WIDTH-1:0]      s_axil_awaddr;
    input  logic                                s_axil_awvalid;
    output logic                                s_axil_awready;
    
    // Write Data Channel (W)
    input  logic [AXI_LITE_DATA_WIDTH-1:0]      s_axil_wdata;
    input  logic [AXI_LITE_DATA_WIDTH/8-1:0]    s_axil_wstrb;
    input  logic                                s_axil_wvalid;
    output logic                                s_axil_wready;
    
    // Write Response Channel (B)
    output logic [1:0]                          s_axil_bresp;
    output logic                                s_axil_bvalid;
    input  logic                                s_axil_bready;
    
    // Read Address Channel (AR)
    input  logic [AXI_LITE_ADDR_WIDTH-1:0]      s_axil_araddr;
    input  logic                                s_axil_arvalid;
    output logic                                s_axil_arready;
    
    // Read Data Channel (R)
    output logic [AXI_LITE_DATA_WIDTH-1:0]      s_axil_rdata;
    output logic [1:0]                          s_axil_rresp;
    output logic                                s_axil_rvalid;
    input  logic                                s_axil_rready;

    // =========================================================
    // 2. AXI4-Full Master Interface (Memory Plane to DDR)
    // The DMA accesses DDR for Descriptors and Bulk Data.
    // The DMA is the MASTER here.
    // =========================================================
    
    // Common signals for MM2S (Read) and S2MM (Write) memory access
    // MM2S uses AR/R channels (Read from DDR)
    // S2MM uses AW/W/B channels (Write to DDR)
    
    // Read Address Channel (AR - MM2S Fetch)
    output logic [AXI_FULL_ID_WIDTH-1:0]        m_axi_arid;
    output logic [AXI_FULL_ADDR_WIDTH-1:0]      m_axi_araddr;
    output logic [7:0]                          m_axi_arlen;
    // (Other AR signals omitted for brevity: size, burst, cache, prot, etc.)
    output logic                                m_axi_arvalid;
    input  logic                                m_axi_arready;
    
    // Read Data Channel (R - MM2S Fetch)
    input  logic [AXI_FULL_ID_WIDTH-1:0]        m_axi_rid;
    input  logic [AXI_FULL_DATA_WIDTH-1:0]      m_axi_rdata;
    input  logic [1:0]                          m_axi_rresp;
    input  logic                                m_axi_rlast;
    input  logic                                m_axi_rvalid;
    output logic                                m_axi_rready;
    
    // Write Address Channel (AW - S2MM Status/Data Write)
    output logic [AXI_FULL_ID_WIDTH-1:0]        m_axi_awid;
    output logic [AXI_FULL_ADDR_WIDTH-1:0]      m_axi_awaddr;
    output logic [7:0]                          m_axi_awlen;
    // (Other AW signals omitted)
    output logic                                m_axi_awvalid;
    input  logic                                m_axi_awready;
    
    // Write Data Channel (W - S2MM Data Write)
    output logic [AXI_FULL_DATA_WIDTH-1:0]      m_axi_wdata;
    output logic [AXI_FULL_DATA_WIDTH/8-1:0]    m_axi_wstrb;
    output logic                                m_axi_wlast;
    output logic                                m_axi_wvalid;
    input  logic                                m_axi_wready;
    
    // Write Response Channel (B - S2MM Status)
    input  logic [AXI_FULL_ID_WIDTH-1:0]        m_axi_bid;
    input  logic [1:0]                          m_axi_bresp;
    input  logic                                m_axi_bvalid;
    output logic                                m_axi_bready;

    // =========================================================
    // 3. AXI-Stream Interfaces (Data Plane to/from PE)
    // =========================================================
    
    // M_AXIS (MM2S Output Stream - Data FROM DDR, TO PE)
    output logic                                m_axis_mm2s_tvalid; // DMA asserts valid
    input  logic                                m_axis_mm2s_tready; // PE asserts ready
    output logic [AXI_STREAM_DATA_WIDTH-1:0]    m_axis_mm2s_tdata;
    output logic                                m_axis_mm2s_tlast;
    
    // S_AXIS (S2MM Input Stream - Data FROM PE, TO DDR)
    input  logic                                s_axis_s2mm_tvalid; // PE asserts valid
    output logic                                s_axis_s2mm_tready; // DMA asserts ready
    input  logic [AXI_STREAM_DATA_WIDTH-1:0]    s_axis_s2mm_tdata;
    input  logic                                s_axis_s2mm_tlast;

    // =========================================================
    // 4. Interrupts (Optional, but essential for efficiency)
    // =========================================================
    output logic                                irq_mm2s;
    output logic                                irq_s2mm;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Internal Wires ---
    // Wires needed to connect the AXI-Lite registers to the two channels
    logic [AXI_LITE_DATA_WIDTH-1:0] mm2s_cr_val, s2mm_cr_val; // Control Register values
    logic [AXI_LITE_DATA_WIDTH-1:0] mm2s_sr_val, s2mm_sr_val; // Status Register values
    // ... other internal signals for descriptor pointers, etc.
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // =========================================================
    // 5. DMA Control Register (AXI-Lite SLAVE Logic)
    // This block handles the decoding of AXI-Lite addresses and updates
    // the internal state/control registers of MM2S and S2MM channels.
    // =========================================================
    
    // PLACEHOLDER: Instantiate an AXI-Lite Decoder/Register File
    /*
    axi_lite_register_file 
    #(
        .ADDR_WIDTH(AXI_LITE_ADDR_WIDTH), 
        // ... (etc.)
    ) 
    i_axi_lite_reg_file (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .s_axil_awaddr(s_axil_awaddr),
        // ... all s_axil ports
        .mm2s_cr_out(mm2s_cr_val),
        .s2mm_cr_out(s2mm_cr_val),
        // ... connections for all register maps
    );
    */
    
    // =========================================================
    // 6. MM2S Channel (Memory to Stream - Data Read from DDR)
    // Handles descriptor fetch, data read bursts, and stream output.
    // =========================================================
    
    mm2s_channel 
    #(
        .AXI_FULL_DATA_WIDTH(AXI_FULL_DATA_WIDTH),
        .AXI_STREAM_DATA_WIDTH(AXI_STREAM_DATA_WIDTH)
        // ... other parameters
    ) 
    i_mm2s_channel (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        
        // Control Input from AXI-Lite Decoder
        .cr_in(mm2s_cr_val), // DMA Control Register
        // ... other register inputs (CURDESC, TAILDESC)
        
        // AXI4-Full Master Ports (DDR Read)
        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        // ... (other AXI-Full ports)

        // AXI-Stream Master Port (PE Write)
        .m_axis_tvalid(m_axis_mm2s_tvalid),
        .m_axis_tready(m_axis_mm2s_tready),
        .m_axis_tdata(m_axis_mm2s_tdata),
        .m_axis_tlast(m_axis_mm2s_tlast),
        
        // Status Output
        .sr_out(mm2s_sr_val),
        .irq_out(irq_mm2s)
    );
    
    // =========================================================
    // 7. S2MM Channel (Stream to Memory - Data Write to DDR)
    // Handles stream input, data write bursts, and status/descriptor update writes.
    // =========================================================
    
    s2mm_channel 
    #(
        .AXI_FULL_DATA_WIDTH(AXI_FULL_DATA_WIDTH),
        .AXI_STREAM_DATA_WIDTH(AXI_STREAM_DATA_WIDTH)
        // ... other parameters
    ) 
    i_s2mm_channel (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        
        // Control Input from AXI-Lite Decoder
        .cr_in(s2mm_cr_val), // DMA Control Register
        // ... other register inputs
        
        // AXI4-Full Master Ports (DDR Write)
        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        // ... (other AXI-Full ports)
        
        // AXI-Stream Slave Port (PE Read)
        .s_axis_tvalid(s_axis_s2mm_tvalid),
        .s_axis_tready(s_axis_s2mm_tready),
        .s_axis_tdata(s_axis_s2mm_tdata),
        .s_axis_tlast(s_axis_s2mm_tlast),

        // Status Output
        .sr_out(s2mm_sr_val),
        .irq_out(irq_s2mm)
    );

endmodule