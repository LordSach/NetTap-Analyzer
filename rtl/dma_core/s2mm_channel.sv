// ************************************************************************************************************************
//
// PROJECT      :   NetTap-Analyzer
// PRODUCT      :   NetTap-DMA
// FILE         :   s2mm_channel.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   s2mm_channel module of DMA core
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  19-Nov-2025    Sachith Rathnayake      Design
//
//
//*************************************************************************************************************************

`timescale 1ns/1ps

module s2mm_channel (
    // ----------------------------------------------------------------------
    // 1. Global Signals (Clock and Reset)
    // ----------------------------------------------------------------------
    clk_i,
    rst_ni, // Active-low reset
    // ----------------------------------------------------------------------
    // 2. Control & Status Interface (Connected to AXI-Lite Register File)
    // ----------------------------------------------------------------------
    s2mm_start_i,        // Start transfer signal
    s2mm_dest_addr_i,  // Destination address (start of buffer)
    s2mm_length_i,       // Length of transfer
    s2mm_reset_i,        // Soft reset from register file
    s2mm_busy_o,         // Status: Channel is actively running
    s2mm_irq_o,          // Interrupt: Transfer completion/error
    // ----------------------------------------------------------------------
    // 3. AXI-Stream Slave Interface (S_AXIS - Receives data from PL peripheral)
    //    Flow: Data IN
    // ----------------------------------------------------------------------
    s_axis_tdata_i,
    s_axis_tstrb_i,
    s_axis_tlast_i,
    s_axis_tvalid_i,
    s_axis_tready_o,
    // ----------------------------------------------------------------------
    // 4. AXI Memory Mapped Master Interface (M_AXI - Writes data to DDR)
    //    Flow: Data OUT (Master)
    // ----------------------------------------------------------------------
    // --- Write Address Channel (AW) ---
    m_axi_awid_o,
    m_axi_awaddr_o,
    m_axi_awlen_o,
    m_axi_awsize_o,
    m_axi_awburst_o,
    m_axi_awcache_o,
    m_axi_awprot_o,
    m_axi_awvalid_o,
    m_axi_awready_i,
    // --- Write Data Channel (W) ---
    m_axi_wdata_o,
    m_axi_wstrb_o,
    m_axi_wlast_o,
    m_axi_wvalid_o,
    m_axi_wready_i,
    // --- Write Response Channel (B) ---
    m_axi_bid_i,
    m_axi_bresp_i,
    m_axi_bvalid_i,
    m_axi_bready_o
);

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Interface Parameters ---
    parameter C_AXI_MM_ID_WIDTH         = 4;
    parameter C_AXI_MM_ADDR_WIDTH       = 32;
    parameter C_AXI_MM_DATA_WIDTH       = 64;   // Typically wider than AXI-Lite (e.g., 64, 128, 256 bits)
    parameter C_AXI_STREAM_DATA_WIDTH   = 32;   // Matches the peripheral's stream data width
    
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------
    // Local Constants (AXI MM Protocol Fixed Widths)
    // ----------------------------------------------------------------------
    localparam C_LENGTH_WIDTH           = 32; // Width of transfer length register
    localparam C_AXI_LEN_WIDTH          = 8;  // AXI AWLEN/ARLEN width (0 to 255 beats)
    localparam C_AXI_SIZE_WIDTH         = 3;  // AXI AWSIZE/ARSIZE width (Byte size)
    localparam C_AXI_BURST_WIDTH        = 2;  // AXI AWBURST/ARBURST width
    localparam C_AXI_CACHE_WIDTH        = 4;  // AXI AWCACHE/ARCACHE width
    localparam C_AXI_PROT_WIDTH         = 3;  // AXI AWPROT/ARPROT width
    localparam C_AXI_RESP_WIDTH         = 2;  // AXI BRESP/RRESP width
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------
    // 1. Global Signals (Clock and Reset)
    // ----------------------------------------------------------------------
    input  logic                                    clk_i;
    input  logic                                    rst_ni; // Active-low reset

    // ----------------------------------------------------------------------
    // 2. Control & Status Interface (Connected to AXI-Lite Register File)
    // ----------------------------------------------------------------------
    input  logic                                    s2mm_start_i;        // Start transfer signal
    input  logic [C_AXI_MM_ADDR_WIDTH-1:0]          s2mm_dest_addr_i;  // Destination address (start of buffer)
    input  logic [C_LENGTH_WIDTH-1:0]               s2mm_length_i;       // Length of transfer
    input  logic                                    s2mm_reset_i;        // Soft reset from register file

    output logic                                    s2mm_busy_o;         // Status: Channel is actively running
    output logic                                    s2mm_irq_o;          // Interrupt: Transfer completion/error


    // ----------------------------------------------------------------------
    // 3. AXI-Stream Slave Interface (S_AXIS - Receives data from PL peripheral)
    //    Flow: Data IN
    // ----------------------------------------------------------------------
    input  logic [C_AXI_STREAM_DATA_WIDTH-1:0]      s_axis_tdata_i;
    input  logic [C_AXI_STREAM_DATA_WIDTH/8-1:0]    s_axis_tstrb_i;
    input  logic                                    s_axis_tlast_i;
    input  logic                                    s_axis_tvalid_i;
    output logic                                    s_axis_tready_o;


    // ----------------------------------------------------------------------
    // 4. AXI Memory Mapped Master Interface (M_AXI - Writes data to DDR)
    //    Flow: Data OUT (Master)
    // ----------------------------------------------------------------------

    // --- Write Address Channel (AW) ---
    output logic [C_AXI_MM_ID_WIDTH-1:0]            m_axi_awid_o;
    output logic [C_AXI_MM_ADDR_WIDTH-1:0]          m_axi_awaddr_o;
    output logic [C_AXI_LEN_WIDTH-1:0]              m_axi_awlen_o;
    output logic [C_AXI_SIZE_WIDTH-1:0]             m_axi_awsize_o;
    output logic [C_AXI_BURST_WIDTH-1:0]            m_axi_awburst_o;
    output logic [C_AXI_CACHE_WIDTH-1:0]            m_axi_awcache_o;
    output logic [C_AXI_PROT_WIDTH-1:0]             m_axi_awprot_o;
    output logic                                    m_axi_awvalid_o;
    input  logic                                    m_axi_awready_i;

    // --- Write Data Channel (W) ---
    output logic [C_AXI_MM_DATA_WIDTH-1:0]          m_axi_wdata_o;
    output logic [C_AXI_MM_DATA_WIDTH/8-1:0]        m_axi_wstrb_o;
    output logic                                    m_axi_wlast_o;
    output logic                                    m_axi_wvalid_o;
    input  logic                                    m_axi_wready_i;

    // --- Write Response Channel (B) ---
    input  logic [C_AXI_MM_ID_WIDTH-1:0]            m_axi_bid_i;
    input  logic [C_AXI_RESP_WIDTH-1:0]             m_axi_bresp_i;
    input  logic                                    m_axi_bvalid_i;
    output logic                                    m_axi_bready_o;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // Implementation of FSM, Address Generation, and AXI Protocol Logic goes here.
    
endmodule
