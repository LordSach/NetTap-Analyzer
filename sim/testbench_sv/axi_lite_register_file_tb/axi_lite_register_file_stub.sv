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
// FILE         :   axi_lite_register_file_stub.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   Simple DUT stub that models a register file for the AXI-Lite Unit Test.
//                  It implements basic Read/Write functionality for three addresses.
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

module axi_lite_register_file_stub (
    ACLK,
    ARESETN,

    s_axil_awaddr,
    s_axil_awvalid,
    s_axil_awready,

    s_axil_wdata,
    s_axil_wstrb,
    s_axil_wvalid,
    s_axil_wready,

    s_axil_bresp,
    s_axil_bvalid,
    s_axil_bready,

    s_axil_araddr,
    s_axil_arvalid,
    s_axil_arready,

    s_axil_rdata,
    s_axil_rresp,
    s_axil_rvalid,
    s_axil_rready
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
    
    // Internal Register Bank (Modeling 3 R/W registers)
    localparam R0_ADDR = 32'h000;
    localparam R1_ADDR = 32'h004;
    localparam R2_ADDR = 32'h008;
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // AXI4-Lite Internal State Machines
    // Need at least 3 bits to represent six states
    typedef enum logic [2:0] {IDLE, WRITE_ADDR, WRITE_DATA, WRITE_RESP, READ_ADDR, READ_DATA} axi_lite_state_e;
    
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    
    input  logic                    ACLK;
    input  logic                    ARESETN;

    // S_AXILITE Interface (Slave)
    // AXI4-lite Write Address channel
    input  logic [ADDR_WIDTH-1:0]   s_axil_awaddr;
    input  logic                    s_axil_awvalid;
    output logic                    s_axil_awready;

    // AXI4-lite Write Data channel
    input  logic [DATA_WIDTH-1:0]   s_axil_wdata;
    input  logic [DATA_WIDTH/8-1:0] s_axil_wstrb;
    input  logic                    s_axil_wvalid;
    output logic                    s_axil_wready;

    // AXI4-lite Write Respond channel
    output logic [1:0]              s_axil_bresp;
    output logic                    s_axil_bvalid;
    input  logic                    s_axil_bready;

    // AXI4-lite Read Address channel
    input  logic [ADDR_WIDTH-1:0]   s_axil_araddr;
    input  logic                    s_axil_arvalid;
    output logic                    s_axil_arready;

    // AXI4-lite Read Data channel
    output logic [DATA_WIDTH-1:0]   s_axil_rdata;
    output logic [1:0]              s_axil_rresp;
    output logic                    s_axil_rvalid;
    input  logic                    s_axil_rready;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    logic [DATA_WIDTH-1:0] reg_bank [3];

    axi_lite_state_e w_state_reg, r_state_reg;
    logic [ADDR_WIDTH-1:0] current_w_addr, current_r_addr;
    logic [DATA_WIDTH-1:0] r_data_reg;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- State Machine Logic ---
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            w_state_reg <= IDLE;
            r_state_reg <= IDLE;
            current_w_addr <= '0;
            current_r_addr <= '0;
            reg_bank[0] <= '0;
            reg_bank[1] <= '0;
            reg_bank[2] <= '0;
        end else begin
            // --- Write Channel FSM ---
            case (w_state_reg)
                IDLE: begin
                    // Transition when handshake completes (both AWVALID and AWREADY are high)
                    // This ensures we only transition when the address is actually accepted
                    if (s_axil_awvalid && s_axil_awready) begin
                        $display("[%0t] STUB: Write FSM IDLE->WRITE_DATA: AWADDR=0x%H, AWVALID=%b, AWREADY=%b", 
                                 $time, s_axil_awaddr, s_axil_awvalid, s_axil_awready);
                        current_w_addr <= s_axil_awaddr;
                        w_state_reg <= WRITE_DATA;
                    end
                end
                WRITE_DATA: begin
                    // Transition when handshake completes (both WVALID and WREADY are high)
                    if (s_axil_wvalid && s_axil_wready) begin
                        $display("[%0t] STUB: Write FSM WRITE_DATA->WRITE_RESP: WDATA=0x%H, WVALID=%b, WREADY=%b", 
                                 $time, s_axil_wdata, s_axil_wvalid, s_axil_wready);
                        // *** REGISTER WRITE ACTION ***
                        case (current_w_addr)
                            R0_ADDR: reg_bank[0] <= s_axil_wdata;
                            R1_ADDR: reg_bank[1] <= s_axil_wdata;
                            R2_ADDR: reg_bank[2] <= s_axil_wdata;
                        endcase
                        w_state_reg <= WRITE_RESP;
                    end
                end
                WRITE_RESP: begin
                    // Transition back to IDLE when handshake completes (both BVALID and BREADY are high)
                    if (s_axil_bvalid && s_axil_bready) begin
                        $display("[%0t] STUB: Write FSM WRITE_RESP->IDLE: BVALID=%b, BREADY=%b", 
                                 $time, s_axil_bvalid, s_axil_bready);
                        w_state_reg <= IDLE;
                    end
                end
                default: begin
                    $display("[%0t] STUB: Write FSM: Invalid state, resetting to IDLE", $time);
                    w_state_reg <= IDLE;
                end
            endcase

            // --- Read Channel FSM ---
            case (r_state_reg)
                IDLE: begin
                    if (s_axil_arvalid) r_state_reg <= READ_ADDR;
                end
                READ_ADDR: begin
                    if (s_axil_arvalid && s_axil_arready) begin
                        current_r_addr <= s_axil_araddr;
                        r_state_reg <= READ_DATA;
                        // *** REGISTER READ ACTION ***
                        case (s_axil_araddr)
                            R0_ADDR: r_data_reg <= reg_bank[0];
                            R1_ADDR: r_data_reg <= reg_bank[1];
                            R2_ADDR: r_data_reg <= reg_bank[2];
                            default: r_data_reg <= '0; // Default to zero for undefined addresses
                        endcase
                    end
                end
                READ_DATA: begin
                    if (s_axil_rvalid && s_axil_rready) r_state_reg <= IDLE;
                end
                default: r_state_reg <= IDLE;
            endcase
        end
    end

    // --- Combinational Assignments (Handshakes) ---
    // Ready signals
    // Accept address while idle; this clears the earlier hang that left the FSM in WRITE_ADDR
    assign s_axil_awready = (w_state_reg == IDLE) && s_axil_awvalid;
    assign s_axil_wready  = (w_state_reg == WRITE_DATA) && s_axil_wvalid;
    assign s_axil_arready = (r_state_reg == IDLE) && s_axil_arvalid;
    

    // Write Response (B) channel
    assign s_axil_bvalid = (w_state_reg == WRITE_RESP);
    assign s_axil_bresp  = 2'b00; // Always OKAY response

    // Read Response (R) channel
    assign s_axil_rvalid = (r_state_reg == READ_DATA);
    assign s_axil_rresp  = 2'b00; // Always OKAY response
    assign s_axil_rdata  = r_data_reg;

endmodule