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
