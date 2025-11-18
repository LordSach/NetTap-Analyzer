import cocotb
from cocotb.triggers import RisingEdge


@cocotb.test()
async def axi_basic_test(dut):
dut._log.info("Starting AXI smoke test")
for _ in range(10):
await RisingEdge(dut.clk)
dut._log.info("Completed")
