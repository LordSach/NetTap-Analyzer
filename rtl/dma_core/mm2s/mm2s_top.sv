module mm2s_top (
input logic clk,
input logic rst_n,
// AXI-MM Read
output logic [31:0] m_axi_araddr,
output logic [7:0] m_axi_arlen,
output logic m_axi_arvalid,
input logic m_axi_arready,
input logic [31:0] m_axi_rdata,
input logic m_axi_rvalid,
output logic m_axi_rready,
input logic m_axi_rlast,
// AXI-Stream Out
output logic [31:0] m_axis_tdata,
output logic [3:0] m_axis_tkeep,
output logic m_axis_tvalid,
input logic m_axis_tready,
output logic m_axis_tlast
);


endmodule
