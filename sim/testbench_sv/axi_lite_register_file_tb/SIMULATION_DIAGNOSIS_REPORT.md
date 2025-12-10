# Simulation Hang Diagnosis Report
**Date:** 2025-12-05  
**Testbench:** AXI-Lite Register File UVM Testbench  
**Simulator:** Xilinx XSim (Vivado 2024.2)

## Executive Summary
The simulation hangs indefinitely at the W channel handshake stage. The root cause is that the Write FSM in `axi_lite_register_file_stub.sv` never transitions from IDLE to WRITE_DATA state, preventing WREADY from being asserted.

## Problem Timeline

### Time 0ns
- UVM test starts, sequence begins
- Driver receives write transaction: Addr=0x00000000, Data=0xa1d7ff82

### Time 5000ns
- Driver sets AWADDR=0x00000000, AWVALID=1 (non-blocking assignment)
- AWREADY is asserted immediately (combinational: `(w_state_reg == IDLE) && s_axil_awvalid`)
- Driver waits for AWREADY at clock edge using `do @(posedge vif.ACLK); while (vif.awready != 1'b1);`

### Time 10000ns (Clock Edge)
- **EXPECTED:** FSM should transition IDLE → WRITE_DATA when it sees AWVALID=1
- **ACTUAL:** FSM remains in IDLE state (no transition message observed)
- AWVALID is still high (not cleared until 15000ns)

### Time 15000ns (Clock Edge)
- Driver detects AWREADY=1 at clock edge
- Driver clears AWVALID=0
- AW handshake completes
- **PROBLEM:** FSM is still in IDLE state, never transitioned

### Time 25000ns (Clock Edge)
- Driver sets WDATA=0xa1d7ff82, WVALID=1
- **PROBLEM:** FSM is still in IDLE state
- WREADY = `(w_state_reg == WRITE_DATA) && s_axil_wvalid` = `(IDLE == WRITE_DATA) && 1` = **0**
- Driver waits indefinitely for WREADY

### Time 25000ns → ∞
- WVALID=1, WREADY=0 (stuck)
- FSM remains in IDLE state
- Simulation hangs waiting for WREADY

## Root Cause Analysis

### Primary Issue: FSM State Transition Timing
The Write FSM in `axi_lite_register_file_stub.sv` checks `if (s_axil_awvalid)` at clock edges, but the transition never occurs. Possible causes:

1. **Timing Issue:** AWVALID is set at 5000ns (non-blocking), but the FSM might not sample it correctly at the 10000ns clock edge
2. **State Machine Logic:** The FSM transition condition might not be met due to signal timing
3. **Non-blocking Assignment Delay:** The FSM might be checking AWVALID before the non-blocking assignment takes effect

### Secondary Issue: Driver Handshake Timing
The driver uses `do @(posedge vif.ACLK); while (vif.awready != 1'b1);` which waits for AWREADY at a clock edge. However, AWREADY is combinational and goes high immediately when AWVALID is set. This creates a timing mismatch where:
- AWREADY goes high immediately (combinational)
- Driver waits for next clock edge (15000ns)
- FSM should transition at 10000ns clock edge, but doesn't
- By 15000ns, driver clears AWVALID, but FSM never transitioned

## Diagnostic Evidence

### Signal States at Critical Times
```
Time 5000ns:
  AWVALID = 1 (set by driver)
  AWREADY = 1 (combinational, asserted immediately)
  w_state_reg = IDLE (0)

Time 10000ns (Clock Edge):
  AWVALID = 1 (still high)
  AWREADY = 1 (still high)
  w_state_reg = IDLE (0) ← SHOULD BE WRITE_DATA (2) BUT ISN'T

Time 15000ns (Clock Edge):
  AWVALID = 0 (cleared by driver)
  AWREADY = 0 (combinational, follows AWVALID)
  w_state_reg = IDLE (0) ← STILL IN IDLE!

Time 25000ns (Clock Edge):
  WVALID = 1 (set by driver)
  WREADY = 0 (combinational: IDLE != WRITE_DATA)
  w_state_reg = IDLE (0) ← STILL IN IDLE!
```

### FSM Diagnostic Output
```
[25000] STUB: Write FSM in IDLE: AWVALID=0, AWREADY=0, AWADDR=0x00000000
[35000] STUB: Write FSM in IDLE: AWVALID=0, AWREADY=0, AWADDR=0x00000000
[45000] STUB: Write FSM in IDLE: AWVALID=0, AWREADY=0, AWADDR=0x00000000
...
```
The FSM remains in IDLE state indefinitely, never transitioning to WRITE_DATA.

## Code Analysis

### Current FSM Logic (axi_lite_register_file_stub.sv)
```systemverilog
IDLE: begin
    if (s_axil_awvalid) begin
        $display("[%0t] STUB: Write FSM IDLE->WRITE_DATA: ...");
        current_w_addr <= s_axil_awaddr;
        w_state_reg <= WRITE_DATA;
    end
end
```

### Current AWREADY Assignment
```systemverilog
assign s_axil_awready = (w_state_reg == IDLE) && s_axil_awvalid;
```

### Current Driver Logic (axi_lite_driver.sv)
```systemverilog
@(posedge vif.ACLK);
vif.awaddr <= tr.addr;
vif.awvalid <= 1'b1;
do @(posedge vif.ACLK); while (vif.awready != 1'b1);
vif.awvalid <= 1'b0;
```

## Recommended Fixes

### Fix 1: Ensure FSM Transitions on AWVALID
The FSM should transition when AWVALID is high at a clock edge. The current code should work, but the transition isn't happening. Possible solutions:

1. **Add explicit clock edge synchronization in FSM:**
   ```systemverilog
   IDLE: begin
       if (s_axil_awvalid && s_axil_awready) begin  // Check both signals
           current_w_addr <= s_axil_awaddr;
           w_state_reg <= WRITE_DATA;
       end
   end
   ```

2. **Use edge detection:**
   ```systemverilog
   logic awvalid_prev;
   always @(posedge ACLK) begin
       awvalid_prev <= s_axil_awvalid;
       if (w_state_reg == IDLE && s_axil_awvalid && !awvalid_prev) begin
           // Transition on rising edge of AWVALID
           current_w_addr <= s_axil_awaddr;
           w_state_reg <= WRITE_DATA;
       end
   end
   ```

### Fix 2: Synchronize Driver Handshake
The driver should wait for the handshake to complete at a clock edge where both signals are stable:

```systemverilog
@(posedge vif.ACLK);
vif.awaddr <= tr.addr;
vif.awvalid <= 1'b1;
// Wait for handshake at clock edge
@(posedge vif.ACLK);
while (vif.awready != 1'b1) @(posedge vif.ACLK);
vif.awvalid <= 1'b0;
```

## Test Results

### Timeout Behavior
- Simulation runs indefinitely
- Timeout watchdog triggers at 10us (10000ns)
- At timeout, signal states show:
  - WVALID = 1
  - WREADY = 0
  - w_state_reg = IDLE (0)
  - FSM never progressed past IDLE

### Expected vs Actual Behavior
| Time | Expected FSM State | Actual FSM State | Issue |
|------|-------------------|------------------|-------|
| 5000ns | IDLE | IDLE | OK |
| 10000ns | WRITE_DATA | IDLE | **FAIL** |
| 15000ns | WRITE_DATA | IDLE | **FAIL** |
| 25000ns | WRITE_DATA | IDLE | **FAIL** |

## Conclusion

The simulation hang is caused by the Write FSM never transitioning from IDLE to WRITE_DATA state. This prevents WREADY from being asserted, causing the driver to wait indefinitely for the W channel handshake.

**Next Steps:**
1. Investigate why the FSM transition condition `if (s_axil_awvalid)` is not being met at clock edges
2. Add edge detection or explicit handshake checking in the FSM
3. Verify signal timing and non-blocking assignment behavior
4. Consider using synchronous handshake protocol (both VALID and READY checked at clock edge)

## Files Modified for Diagnosis
- `axi_lite_tb_top.sv`: Added timeout watchdog and signal monitoring
- `axi_lite_driver.sv`: Added timeout detection and detailed logging
- `axi_lite_register_file_stub.sv`: Added FSM state diagnostic logging
