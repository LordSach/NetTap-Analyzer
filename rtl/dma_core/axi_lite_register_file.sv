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
// FILE         :   axi_lite_register_file.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   Project Description
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  10-FEB-2023    Sachith Rathnayake      Design and Implementation
//
// ************************************************************************************************************************

`timescale 1ns/1ps`

module axi_lite_register_file (
    // ----------------------------------------------------------------------
    // 1. Global Signals
    // ----------------------------------------------------------------------
    clk_i,
    rst_ni, // Active-low reset

    // ----------------------------------------------------------------------
    // 2. AXI-Lite Slave Interface (Connected to PS/AXI Interconnect)
    //    Prefix: s_axi_
    // ----------------------------------------------------------------------

    // --- Write Address Channel (AW) ---
    s_axi_awaddr_i,
    s_axi_awvalid_i,
    s_axi_awready_o,

    // --- Write Data Channel (W) ---
    s_axi_wdata_i,
    s_axi_wstrb_i,
    s_axi_wvalid_i,
    s_axi_wready_o,

    // --- Write Response Channel (B) ---
    s_axi_bresp_o, // OKAY (00), SLVERR (01)
    s_axi_bvalid_o,
    s_axi_bready_i,

    // --- Read Address Channel (AR) ---
    s_axi_araddr_i,
    s_axi_arvalid_i,
    s_axi_arready_o,

    // --- Read Data Channel (R) ---
    s_axi_rdata_o,
    s_axi_rresp_o, // OKAY (00), SLVERR (01)
    s_axi_rvalid_o,
    s_axi_rready_i,


    // ----------------------------------------------------------------------
    // 3. Control & Configuration Outputs (to MM2S/S2MM Channels)
    // ----------------------------------------------------------------------

    // --- S2MM (Stream to Memory Map) Channel Control/Config ---
    s2mm_start_o,       // Trigger to start S2MM transfer
    s2mm_dest_addr_o,   // Buffer start address in memory
    s2mm_length_o,      // Transfer length (bytes or data beats)
    s2mm_reset_o,       // Soft reset for S2MM channel

    // --- MM2S (Memory Map to Stream) Channel Control/Config ---
    mm2s_start_o,       // Trigger to start MM2S transfer
    mm2s_src_addr_o,    // Buffer start address in memory
    mm2s_length_o,      // Transfer length (bytes or data beats)
    mm2s_reset_o,       // Soft reset for MM2S channel


    // ----------------------------------------------------------------------
    // 4. Status and Interrupt Inputs (from MM2S/S2MM Channels)
    // ----------------------------------------------------------------------

    // --- Status Inputs ---
    s2mm_busy_i,        // S2MM reports it is actively running
    mm2s_busy_i,        // MM2S reports it is actively running

    // --- Interrupt Output (to PS) ---
    s2mm_irq_i,         // S2MM completion interrupt flag
    irq_o               // Combined/Masked Interrupt signal to PS
);

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    // constants
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- AXI-LITE Interface Parameters ---
    parameter C_AXI_LITE_DATA_WIDTH = 32;
    parameter C_AXI_LITE_ADDR_WIDTH = 32;
    
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------
    // Local Constants
    // ----------------------------------------------------------------------
    localparam C_AXI_RESP_WIDTH = 2; // Width of AXI Response signals (BRESP, RRESP)
    localparam C_LENGTH_WIDTH   = 32; // Width of DMA Length registers

    // --- Register Address Map ---
    localparam ADDR_CTRL_REG    = 'h00; // [0]:MM2S Start, [1]:S2MM Start, [8]:MM2S Rst, [9]:S2MM Rst
    localparam ADDR_STATUS_REG  = 'h04; // [0]:MM2S Busy, [1]:S2MM Busy, [2]:S2MM IRQ
    localparam ADDR_S2MM_ADDR   = 'h10; // S2MM Destination Address
    localparam ADDR_S2MM_LENGTH = 'h14; // S2MM Transfer Length (Beats/Bytes)
    localparam ADDR_MM2S_ADDR   = 'h20; // MM2S Source Address
    localparam ADDR_MM2S_LENGTH = 'h24; // MM2S Transfer Length (Beats/Bytes)
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    typedef enum logic [3:0] {
        WR_IDLE,    // Waiting for a new write transaction to begin, if available address will been accepted (awvalid and awready asserted). Waiting for the write data.
        WR_REGISTERING,    // Data has been accepted (wvalid and wready asserted). Performing the register write and preparing the response.
        WR_RESP    // Response is being asserted (bvalid asserted). Waiting for the Master (PS) to accept the response (bready).
    } w_state_t;
    
    typedef enum logic [3:0] {
        RD_IDLE,    // Waiting for a new read transaction to begin. If available address is been accepted. Waiting for data to be retrieved from the register.
        RD_RESP    // Data is ready (rdata_o and rresp_o are valid). Asserting rvalid and waiting for the Master (PS) to accept the data (rready).     
    } r_state_t;

    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------
    // 1. Global Signals
    // ----------------------------------------------------------------------
    input  logic                                clk_i;
    input  logic                                rst_ni; // Active-low reset

    // ----------------------------------------------------------------------
    // 2. AXI-Lite Slave Interface (Connected to PS/AXI Interconnect)
    //    Prefix: s_axi_
    // ----------------------------------------------------------------------

    // --- Write Address Channel (AW) ---
    input  logic [C_AXI_LITE_ADDR_WIDTH-1:0]    s_axi_awaddr_i;
    input  logic                                s_axi_awvalid_i;
    output logic                                s_axi_awready_o;

    // --- Write Data Channel (W) ---
    input  logic [C_AXI_LITE_DATA_WIDTH-1:0]    s_axi_wdata_i;
    input  logic [C_AXI_LITE_DATA_WIDTH/8-1:0]  s_axi_wstrb_i;
    input  logic                                s_axi_wvalid_i;
    output logic                                s_axi_wready_o;

    // --- Write Response Channel (B) ---
    output logic [C_AXI_RESP_WIDTH-1:0]         s_axi_bresp_o; // OKAY (00), SLVERR (01)
    output logic                                s_axi_bvalid_o;
    input  logic                                s_axi_bready_i;

    // --- Read Address Channel (AR) ---
    input  logic [C_AXI_LITE_ADDR_WIDTH-1:0]    s_axi_araddr_i;
    input  logic                                s_axi_arvalid_i;
    output logic                                s_axi_arready_o;

    // --- Read Data Channel (R) ---
    output logic [C_AXI_LITE_DATA_WIDTH-1:0]    s_axi_rdata_o;
    output logic [C_AXI_RESP_WIDTH-1:0]         s_axi_rresp_o; // OKAY (00), SLVERR (01)
    output logic                                s_axi_rvalid_o;
    input  logic                                s_axi_rready_i;


    // ----------------------------------------------------------------------
    // 3. Control & Configuration Outputs (to MM2S/S2MM Channels)
    // ----------------------------------------------------------------------

    // --- S2MM (Stream to Memory Map) Channel Control/Config ---
    output logic                                s2mm_start_o;       // Trigger to start S2MM transfer
    output logic [C_AXI_LITE_ADDR_WIDTH-1:0]    s2mm_dest_addr_o;   // Buffer start address in memory
    output logic [C_LENGTH_WIDTH-1:0]           s2mm_length_o;      // Transfer length (bytes or data beats)
    output logic                                s2mm_reset_o;       // Soft reset for S2MM channel

    // --- MM2S (Memory Map to Stream) Channel Control/Config ---
    output logic                                mm2s_start_o;       // Trigger to start MM2S transfer
    output logic [C_AXI_LITE_ADDR_WIDTH-1:0]    mm2s_src_addr_o;    // Buffer start address in memory
    output logic [C_LENGTH_WIDTH-1:0]           mm2s_length_o;      // Transfer length (bytes or data beats)
    output logic                                mm2s_reset_o;       // Soft reset for MM2S channel


    // ----------------------------------------------------------------------
    // 4. Status and Interrupt Inputs (from MM2S/S2MM Channels)
    // ----------------------------------------------------------------------

    // --- Status Inputs ---
    input  logic                                s2mm_busy_i;        // S2MM reports it is actively running
    input  logic                                mm2s_busy_i;        // MM2S reports it is actively running

    // --- Interrupt Output (to PS) ---
    input  logic                                s2mm_irq_i;         // S2MM completion interrupt flag
    output logic                                irq_o;               // Combined/Masked Interrupt signal to PS

    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    // --- Internal Registers (Placeholder) ---
    // These registers hold the values that the PS writes and the DMA channels read.
    logic [C_AXI_LITE_DATA_WIDTH-1:0]           reg_control; // Control register (Start, Reset, IRQ Mask)
    logic [C_AXI_LITE_ADDR_WIDTH-1:0]           wr_addr_latched;

    logic [C_AXI_LITE_ADDR_WIDTH-1:0]           reg_s2mm_addr;    // Address register
    logic [C_LENGTH_WIDTH-1:0]                  reg_s2mm_length;

    logic [C_AXI_LITE_ADDR_WIDTH-1:0]           reg_mm2s_addr;
    logic [C_LENGTH_WIDTH-1:0]                  reg_mm2s_length;
    // ... other internal registers for MM2S and Status ...
    logic [C_AXI_LITE_DATA_WIDTH-1:0]           w_strb_mask;

    logic [C_AXI_LITE_DATA_WIDTH-1:0]           rd_data_mux; // Data selected for read output

    // FSM status logics
    w_state_t w_state;
    r_state_t r_state;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    // ----------------------------------------------------------------------
    // AXI-Lite Decoding and Finite State Machine (Placeholder)
    // ----------------------------------------------------------------------
    // The main body of the module would implement:
    // 1. FSMs to handle AXI-Lite read/write transactions.
    // 2. Address decoding logic to map s_axi_awaddr_i/s_axi_araddr_i to specific registers.
    // 3. Register write logic (updating internal registers on write transactions).
    // 4. Register read logic (multiplexing status/config registers onto s_axi_rdata_o).

    always_ff @(posedge clk_i or negedge rst_ni) begin: WRITE_FSM
        if (~rst_ni) begin: WRITE_RESET_BLOCK

            w_state         <= WR_IDLE;
            s_axi_awready_o <= 1'b0;
            s_axi_wready_o  <= 1'b0;
            s_axi_bvalid_o  <= 1'b0;

            reg_control     <= '0;
            reg_s2mm_addr   <= '0;
            reg_s2mm_length <= '0;
            reg_mm2s_addr   <= '0;
            reg_mm2s_length <= '0;

            wr_addr_latched <= {C_AXI_LITE_ADDR_WIDTH{1'b0}};

        end: WRITE_RESET_BLOCK
        else begin: WRITE_FSM_LOGIC
            unique case (w_state)
                WR_IDLE:begin
                    s_axi_awready_o <= 1'b1;
                    if (s_axi_awvalid_i & s_axi_awready_o) begin
                        w_state         <= WR_REGISTERING;
                        wr_addr_latched <= s_axi_awaddr_i;

                        s_axi_awready_o <= 1'b0;
                        s_axi_wready_o  <= 1'b1;
                    end
                end
                WR_REGISTERING:begin
                    if (s_axi_wvalid_i & s_axi_wready_o) begin
                        w_state         <= WR_RESP;
                        s_axi_wready_o  <= 1'b0;
                        s_axi_bvalid_o  <= 1'b1;
                        s_axi_bresp_o   <= {C_AXI_RESP_WIDTH{1'b0}};
                        

                        // Address decoding and register update
                        case (wr_addr_latched)
                            ADDR_CTRL_REG:    begin
                                reg_control[7:0]        <= (s_axi_wstrb_i[0])? s_axi_wdata_i[7:0]   : reg_control[7:0];
                                reg_control[15:8]       <= (s_axi_wstrb_i[1])? s_axi_wdata_i[15:8]  : reg_control[15:8];
                                reg_control[23:16]      <= (s_axi_wstrb_i[2])? s_axi_wdata_i[23:16] : reg_control[23:16];
                                reg_control[31:24]      <= (s_axi_wstrb_i[3])? s_axi_wdata_i[31:24] : reg_control[31:24];
                            end
                            ADDR_S2MM_ADDR:   begin
                                reg_s2mm_addr[7:0]      <= (s_axi_wstrb_i[0])? s_axi_wdata_i[7:0]   : reg_s2mm_addr[7:0];
                                reg_s2mm_addr[15:8]     <= (s_axi_wstrb_i[1])? s_axi_wdata_i[15:8]  : reg_s2mm_addr[15:8];
                                reg_s2mm_addr[23:16]    <= (s_axi_wstrb_i[2])? s_axi_wdata_i[23:16] : reg_s2mm_addr[23:16];
                                reg_s2mm_addr[31:24]    <= (s_axi_wstrb_i[3])? s_axi_wdata_i[31:24] : reg_s2mm_addr[31:24];
                            end
                            ADDR_S2MM_LENGTH: begin
                                reg_s2mm_length[7:0]    <= (s_axi_wstrb_i[0])? s_axi_wdata_i[7:0]   : reg_s2mm_length[7:0];
                                reg_s2mm_length[15:8]   <= (s_axi_wstrb_i[1])? s_axi_wdata_i[15:8]  : reg_s2mm_length[15:8];
                                reg_s2mm_length[23:16]  <= (s_axi_wstrb_i[2])? s_axi_wdata_i[23:16] : reg_s2mm_length[23:16];
                                reg_s2mm_length[31:24]  <= (s_axi_wstrb_i[3])? s_axi_wdata_i[31:24] : reg_s2mm_length[31:24];
                            end
                            ADDR_MM2S_ADDR:   begin
                                reg_mm2s_addr[7:0]      <= (s_axi_wstrb_i[0])? s_axi_wdata_i[7:0]   : reg_mm2s_addr[7:0];
                                reg_mm2s_addr[15:8]     <= (s_axi_wstrb_i[1])? s_axi_wdata_i[15:8]  : reg_mm2s_addr[15:8];
                                reg_mm2s_addr[23:16]    <= (s_axi_wstrb_i[2])? s_axi_wdata_i[23:16] : reg_mm2s_addr[23:16];
                                reg_mm2s_addr[31:24]    <= (s_axi_wstrb_i[3])? s_axi_wdata_i[31:24] : reg_mm2s_addr[31:24];
                            end
                            ADDR_MM2S_LENGTH: begin
                                reg_mm2s_length[7:0]    <= (s_axi_wstrb_i[0])? s_axi_wdata_i[7:0]   : reg_mm2s_length[7:0];
                                reg_mm2s_length[15:8]   <= (s_axi_wstrb_i[1])? s_axi_wdata_i[15:8]  : reg_mm2s_length[15:8];
                                reg_mm2s_length[23:16]  <= (s_axi_wstrb_i[2])? s_axi_wdata_i[23:16] : reg_mm2s_length[23:16];
                                reg_mm2s_length[31:24]  <= (s_axi_wstrb_i[3])? s_axi_wdata_i[31:24] : reg_mm2s_length[31:24];
                            end
                            default:  // Ignore writes to unmapped addresses
                        endcase
                    end
                end
                WR_RESP:begin
                    if (s_axi_bready_i & s_axi_bvalid_o) begin
                        s_axi_bvalid_o  <= 1'b0;

                        w_state         <= WR_IDLE;

                        s_axi_awready_o <= 1'b0;
                        s_axi_wready_o  <= 1'b0;
                        s_axi_bvalid_o  <= 1'b0;

                        reg_control     <= '0;
                        reg_s2mm_addr   <= '0;
                        reg_s2mm_length <= '0;
                        reg_mm2s_addr   <= '0;
                        reg_mm2s_length <= '0;

                        wr_addr_latched <= {C_AXI_LITE_ADDR_WIDTH{1'b0}};
                    end
                end
                default:begin
                    w_state         <= WR_IDLE;

                    s_axi_awready_o <= 1'b0;
                    s_axi_wready_o  <= 1'b0;
                    s_axi_bvalid_o  <= 1'b0;

                    reg_control     <= '0;
                    reg_s2mm_addr   <= '0;
                    reg_s2mm_length <= '0;
                    reg_mm2s_addr   <= '0;
                    reg_mm2s_length <= '0;

                    wr_addr_latched <= {C_AXI_LITE_ADDR_WIDTH{1'b0}};
                end 
            endcase
        end: WRITE_FSM_LOGIC
    end: WRITE_FSM


    always_ff @(posedge clk_i or negedge rst_ni) begin: READ_FSM
        if (~rst_ni) begin: READ_RESET_BLOCK
            
            r_state         <= RD_IDLE;
            s_axi_arready_o <= 1'b0;
            s_axi_rvalid_o  <= 1'b0;
            s_axi_rresp_o   <= {C_AXI_RESP_WIDTH{1'b0}};
            rd_data_mux     <= '0;

        end: READ_RESET_BLOCK
        else begin: READ_FSM_LOGIC
            unique case (r_state)
                RD_IDLE:begin
                    s_axi_arready_o     <= 1'b1;

                    if (s_axi_arvalid_i & s_axi_arready_o) begin
                        r_state         <= RD_RESP;
                        s_axi_rvalid_o  <= 1'b1;
                        s_axi_rresp_o   <= {C_AXI_RESP_WIDTH{1'b0}};

                        // Select the appropriate register content based on current read address
                        case (s_axi_araddr_i)
                            ADDR_CTRL_REG:    rd_data_mux <= reg_control;
                            ADDR_S2MM_ADDR:   rd_data_mux <= reg_s2mm_addr;
                            ADDR_S2MM_LENGTH: rd_data_mux <= reg_s2mm_length;
                            ADDR_MM2S_ADDR:   rd_data_mux <= reg_mm2s_addr;
                            ADDR_MM2S_LENGTH: rd_data_mux <= reg_mm2s_length;
                            ADDR_STATUS_REG: begin
                                // Combine status inputs into a readable status word
                                rd_data_mux <= {
                                    {(C_AXI_LITE_DATA_WIDTH-3){1'b0}}, // Reserved bits (3 bits used)
                                    s2mm_irq_i,                      // Bit 2: S2MM IRQ
                                    s2mm_busy_i,                     // Bit 1: S2MM Busy
                                    mm2s_busy_i                      // Bit 0: MM2S Busy
                                };
                            end
                            default: // rd_data_mux remains '0'
                        endcase

                        s_axi_arready_o <= 1'b0;
                    end
                end
                RD_RESP:begin
                    if (s_axi_rready_i & s_axi_rvalid_o) begin
                        r_state         <= RD_IDLE;
                        s_axi_rvalid_o  <= 1'b0;
                        rd_data_mux     <= '0;
                    end
                end
                default:begin
                    r_state         <= RD_IDLE;
                    s_axi_arready_o <= 1'b0;
                    s_axi_rvalid_o  <= 1'b0;
                    s_axi_rresp_o   <= {C_AXI_RESP_WIDTH{1'b0}};
                    rd_data_mux     <= '0;
                end 
            endcase
        end: READ_FSM_LOGIC
    end: READ_FSM
    
    // --- AXI Read Channel Output Connection ---
    assign s_axi_rdata_o = rd_data_mux;


    // ======================================================================
    // 3. DMA Control Signal Generation (Mapping Registers to DMA Channels)
    // ======================================================================

    // Map control register bits to DMA control outputs
    assign mm2s_start_o = reg_control[0];
    assign s2mm_start_o = reg_control[1];

    assign mm2s_reset_o = reg_control[8];
    assign s2mm_reset_o = reg_control[9];

    // Map configuration registers to DMA configuration outputs
    assign s2mm_dest_addr_o = reg_s2mm_addr;
    assign s2mm_length_o    = reg_s2mm_length;
    assign mm2s_src_addr_o  = reg_mm2s_addr;
    assign mm2s_length_o    = reg_mm2s_length;

    // Interrupt output: Simple pass-through (in a final design, this should be gated/masked)
    assign irq_o = s2mm_irq_i;

endmodule