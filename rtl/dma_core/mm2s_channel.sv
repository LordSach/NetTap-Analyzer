// ************************************************************************************************************************
//
// PROJECT      :   NetTap-Analyzer
// PRODUCT      :   NetTap-DMA
// FILE         :   mm2s_channel.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   mm2s_channel module of DMA core
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

module mm2s_channel (
    // ----------------------------------------------------------------------
    // 1. Global Signals (Clock and Reset)
    // ----------------------------------------------------------------------
    clk_i,
    rst_ni, // Active-low reset

    // ----------------------------------------------------------------------
    // 2. Control & Status Interface (Connected to AXI-Lite Register File)
    // ----------------------------------------------------------------------
    mm2s_start_i,        // Start transfer signal
    mm2s_src_addr_i,   // Source address (start of buffer)
    mm2s_length_i,       // Length of transfer
    mm2s_reset_i,        // Soft reset from register file

    mm2s_busy_o,         // Status: Channel is actively running
    mm2s_irq_o,          // Interrupt: Transfer completion/error


    // ----------------------------------------------------------------------
    // 3. AXI Memory Mapped Master Interface (M_AXI - Reads data from DDR)
    //    Flow: Data IN (Master)
    // ----------------------------------------------------------------------

    // --- Read Address Channel (AR) ---
    m_axi_arid_o,
    m_axi_araddr_o,
    m_axi_arlen_o,
    m_axi_arsize_o,
    m_axi_arburst_o,
    m_axi_arcache_o,
    m_axi_arprot_o,
    m_axi_arvalid_o,
    m_axi_arready_i,

    // --- Read Data Channel (R) ---
    m_axi_rid_i,
    m_axi_rdata_i,
    m_axi_rresp_i,
    m_axi_rlast_i,
    m_axi_rvalid_i,
    m_axi_rready_o,


    // ----------------------------------------------------------------------
    // 4. AXI-Stream Master Interface (M_AXIS - Pushes data to PL peripheral)
    //    Flow: Data OUT
    // ----------------------------------------------------------------------
    m_axis_tdata_o,
    m_axis_tstrb_o,
    m_axis_tlast_o,
    m_axis_tvalid_o,
    m_axis_tready_i
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
    parameter C_AXI_MM_DATA_WIDTH       = 64;  // Typically wider than AXI-Lite
    parameter C_AXI_STREAM_DATA_WIDTH   = 32; // Matches the peripheral's stream data width
    
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
    input  logic                                    mm2s_start_i;        // Start transfer signal
    input  logic [C_AXI_MM_ADDR_WIDTH-1:0]          mm2s_src_addr_i;   // Source address (start of buffer)
    input  logic [C_LENGTH_WIDTH-1:0]               mm2s_length_i;       // Length of transfer
    input  logic                                    mm2s_reset_i;        // Soft reset from register file

    output logic                                    mm2s_busy_o;         // Status: Channel is actively running
    output logic                                    mm2s_irq_o;          // Interrupt: Transfer completion/error


    // ----------------------------------------------------------------------
    // 3. AXI Memory Mapped Master Interface (M_AXI - Reads data from DDR)
    //    Flow: Data IN (Master)
    // ----------------------------------------------------------------------

    // --- Read Address Channel (AR) ---
    output logic [C_AXI_MM_ID_WIDTH-1:0]            m_axi_arid_o;
    output logic [C_AXI_MM_ADDR_WIDTH-1:0]          m_axi_araddr_o;
    output logic [C_AXI_LEN_WIDTH-1:0]              m_axi_arlen_o;
    output logic [C_AXI_SIZE_WIDTH-1:0]             m_axi_arsize_o;
    output logic [C_AXI_BURST_WIDTH-1:0]            m_axi_arburst_o;
    output logic [C_AXI_CACHE_WIDTH-1:0]            m_axi_arcache_o;
    output logic [C_AXI_PROT_WIDTH-1:0]             m_axi_arprot_o;
    output logic                                    m_axi_arvalid_o;
    input  logic                                    m_axi_arready_i;

    // --- Read Data Channel (R) ---
    input  logic [C_AXI_MM_ID_WIDTH-1:0]            m_axi_rid_i;
    input  logic [C_AXI_MM_DATA_WIDTH-1:0]          m_axi_rdata_i;
    input  logic [C_AXI_RESP_WIDTH-1:0]             m_axi_rresp_i;
    input  logic                                    m_axi_rlast_i;
    input  logic                                    m_axi_rvalid_i;
    output logic                                    m_axi_rready_o;


    // ----------------------------------------------------------------------
    // 4. AXI-Stream Master Interface (M_AXIS - Pushes data to PL peripheral)
    //    Flow: Data OUT
    // ----------------------------------------------------------------------
    output logic [C_AXI_STREAM_DATA_WIDTH-1:0]      m_axis_tdata_o;
    output logic [C_AXI_STREAM_DATA_WIDTH/8-1:0]    m_axis_tstrb_o;
    output logic                                    m_axis_tlast_o;
    output logic                                    m_axis_tvalid_o;
    input  logic                                    m_axis_tready_i;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // Implementation of FSM, Address Generation, and AXI Protocol Logic goes here.
    
endmodule