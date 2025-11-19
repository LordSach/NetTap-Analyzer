module s2mm_top (
input logic clk,
input logic rst_n,
// AXI-Stream In
input logic [31:0] s_axis_tdata,
input logic [3:0] s_axis_tkeep,
input logic s_axis_tvalid,
output logic s_axis_tready,
input logic s_axis_tlast,
// AXI-MM Write
output logic [31:0] m_axi_awaddr,
output logic [7:0] m_axi_awlen,
output logic m_axi_awvalid,
input logic m_axi_awready,
output logic [31:0] m_axi_wdata,
output logic [3:0] m_axi_wstrb,
output logic m_axi_wvalid,
input logic m_axi_wready,
output logic m_axi_wlast
);


endmodule
// ************************************************************************************************************************
//
// PROJECT      :   NetTap-Analyzer
// PRODUCT      :   NetTap-DMA
// FILE         :   s2mm_top.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   s2mm_top module of DMA core
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

module s2mm_top (
    clk,
    rst_n,

    // AXI-Stream In
    s_axis_tdata,
    s_axis_tkeep,
    s_axis_tvalid,
    s_axis_tready,
    s_axis_tlast,

    // AXI-MM Write
    m_axi_awaddr,
    m_axi_awlen,
    m_axi_awvalid,
    m_axi_awready,
    m_axi_wdata,
    m_axi_wstrb,
    m_axi_wvalid,
    m_axi_wready,
    m_axi_wlast
);

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    input logic clk,
    input logic rst_n,
    // AXI-Stream In
    input logic [31:0] s_axis_tdata,
    input logic [3:0] s_axis_tkeep,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    input logic s_axis_tlast,
    // AXI-MM Write
    output logic [31:0] m_axi_awaddr,
    output logic [7:0] m_axi_awlen,
    output logic m_axi_awvalid,
    input logic m_axi_awready,
    output logic [31:0] m_axi_wdata,
    output logic [3:0] m_axi_wstrb,
    output logic m_axi_wvalid,
    input logic m_axi_wready,
    output logic m_axi_wlast
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
endmodule
