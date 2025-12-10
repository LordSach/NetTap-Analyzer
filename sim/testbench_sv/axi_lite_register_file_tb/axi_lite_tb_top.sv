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
// FILE         :   axi_lite_tb_top.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   Top-level module for the AXI-Lite Register File Unit Testbench.
//                  This module provides the clock/reset and instantiates the DUT, Interface, and the UVM Test.
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

`timescale 1ns/1ps

import uvm_pkg::*;
import axi_lite_pkg::*;

module axi_lite_tb_top;

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    // constants
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Time and Configuration ---
    parameter CLK_PERIOD = 10ns;
    
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
    
    // IO signals
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Clock and Reset Signals ---
    logic ACLK;
    logic ARESETN;

    // --- Interface Instantiation ---
    // Note: The interface parameters must match those used in the DUT/Agents
    axi_lite_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) lite_vif (
        .ACLK(ACLK),
        .ARESETN(ARESETN)
    );


    
    //---------------------------------------------------------------------------------------------------------------------
    // DUT INstantiation
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- DUT Instantiation ---
    // The AXI-Lite Register File Stub is the Device Under Test
    axi_lite_register_file_stub #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) dut (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        
        // Connect DUT slave ports to the interface slave modport signals
        .s_axil_awaddr(lite_vif.awaddr),
        .s_axil_awvalid(lite_vif.awvalid),
        .s_axil_awready(lite_vif.awready),
        .s_axil_wdata(lite_vif.wdata),
        .s_axil_wstrb(lite_vif.wstrb),
        .s_axil_wvalid(lite_vif.wvalid),
        .s_axil_wready(lite_vif.wready),
        .s_axil_bresp(lite_vif.bresp),
        .s_axil_bvalid(lite_vif.bvalid),
        .s_axil_bready(lite_vif.bready),
        .s_axil_araddr(lite_vif.araddr),
        .s_axil_arvalid(lite_vif.arvalid),
        .s_axil_arready(lite_vif.arready),
        .s_axil_rdata(lite_vif.rdata),
        .s_axil_rresp(lite_vif.rresp),
        .s_axil_rvalid(lite_vif.rvalid),
        .s_axil_rready(lite_vif.rready)
    );

    //---------------------------------------------------------------------------------------------------------------------
    // Clock Generation
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Clock Generation ---
    always #(CLK_PERIOD/2) ACLK = ~ACLK;

    //---------------------------------------------------------------------------------------------------------------------
    // Reset Generation and Test Execution
    //---------------------------------------------------------------------------------------------------------------------

    // --- Reset Generation ---
    initial begin
        ACLK = 0;
        ARESETN = 0;
        # (2 * CLK_PERIOD);
        ARESETN = 1;
    end

    // --- Test Kickoff at Time 0 (required by UVM) ---
    initial begin
        uvm_config_db#(virtual axi_lite_if)::set(null, "*", "vif", lite_vif);
        run_test("axi_lite_base_test");
    end

    // --- Timeout Watchdog ---
    initial begin
        #10000ns; // 10us timeout
        $display("\n==========================================");
        $display("TIMEOUT DETECTED: Simulation exceeded 10us");
        $display("==========================================");
        $display("Current Simulation Time: %0t", $time);
        $display("\n--- AXI-Lite Interface Signal States ---");
        $display("Write Address Channel (AW):");
        $display("  AWADDR  = 0x%08h", lite_vif.awaddr);
        $display("  AWVALID = %b", lite_vif.awvalid);
        $display("  AWREADY = %b", lite_vif.awready);
        $display("Write Data Channel (W):");
        $display("  WDATA   = 0x%08h", lite_vif.wdata);
        $display("  WSTRB   = 0x%02h", lite_vif.wstrb);
        $display("  WVALID  = %b", lite_vif.wvalid);
        $display("  WREADY  = %b", lite_vif.wready);
        $display("Write Response Channel (B):");
        $display("  BRESP   = 0x%02h", lite_vif.bresp);
        $display("  BVALID  = %b", lite_vif.bvalid);
        $display("  BREADY  = %b", lite_vif.bready);
        $display("Read Address Channel (AR):");
        $display("  ARADDR  = 0x%08h", lite_vif.araddr);
        $display("  ARVALID = %b", lite_vif.arvalid);
        $display("  ARREADY = %b", lite_vif.arready);
        $display("Read Data Channel (R):");
        $display("  RDATA   = 0x%08h", lite_vif.rdata);
        $display("  RRESP   = 0x%02h", lite_vif.rresp);
        $display("  RVALID  = %b", lite_vif.rvalid);
        $display("  RREADY  = %b", lite_vif.rready);
        $display("\n--- System Signals ---");
        $display("  ACLK    = %b", ACLK);
        $display("  ARESETN = %b", ARESETN);
        $display("==========================================\n");
        $finish(2);
    end

    // --- Signal State Monitor (Diagnostic) ---
    always @(posedge ACLK) begin
        if (lite_vif.awvalid || lite_vif.wvalid || lite_vif.bvalid || 
            lite_vif.arvalid || lite_vif.rvalid) begin
            $display("[%0t] AXI Activity: AW(v=%b,r=%b) W(v=%b,r=%b) B(v=%b,r=%b) AR(v=%b,r=%b) R(v=%b,r=%b)",
                     $time,
                     lite_vif.awvalid, lite_vif.awready,
                     lite_vif.wvalid, lite_vif.wready,
                     lite_vif.bvalid, lite_vif.bready,
                     lite_vif.arvalid, lite_vif.arready,
                     lite_vif.rvalid, lite_vif.rready);
        end
    end

endmodule