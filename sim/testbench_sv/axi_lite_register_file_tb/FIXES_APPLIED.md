# Fixes Applied for Simulation Hang Issue

## Summary
Fixed the simulation hang by ensuring proper AXI-Lite handshake synchronization between the driver and FSM.

## Root Cause
The FSM was checking only `AWVALID` for state transitions, but the driver was clearing `AWVALID` immediately after detecting `AWREADY` (which is combinational). This created a race condition where the FSM never saw the handshake complete at a clock edge.

## Fixes Applied

### Fix 1: FSM State Transitions (axi_lite_register_file_stub.sv)

**Problem:** FSM checked only `AWVALID` for transitions, causing timing issues.

**Solution:** Changed FSM to check for **handshake completion** (both VALID and READY signals high) before transitioning states.

#### Write Address Channel (IDLE → WRITE_DATA)
```systemverilog
// BEFORE:
if (s_axil_awvalid) begin
    w_state_reg <= WRITE_DATA;
end

// AFTER:
if (s_axil_awvalid && s_axil_awready) begin
    w_state_reg <= WRITE_DATA;
end
```

#### Write Data Channel (WRITE_DATA → WRITE_RESP)
```systemverilog
// BEFORE:
if (s_axil_wvalid) begin
    w_state_reg <= WRITE_RESP;
end

// AFTER:
if (s_axil_wvalid && s_axil_wready) begin
    w_state_reg <= WRITE_RESP;
end
```

#### Write Response Channel (WRITE_RESP → IDLE)
```systemverilog
// BEFORE:
if (s_axil_bready) begin
    w_state_reg <= IDLE;
end

// AFTER:
if (s_axil_bvalid && s_axil_bready) begin
    w_state_reg <= IDLE;
end
```

**Why this works:** The FSM now only transitions when the handshake is actually complete at a clock edge, ensuring proper synchronization.

### Fix 2: Driver Handshake Waiting (axi_lite_driver.sv)

**Problem:** Driver used `do @(posedge vif.ACLK); while (signal != 1'b1);` which could exit immediately if the signal was already high.

**Solution:** Changed to explicitly wait for **both signals to be high at a clock edge**.

#### Before:
```systemverilog
do @(posedge vif.ACLK); while (vif.awready != 1'b1);
```

#### After:
```systemverilog
@(posedge vif.ACLK);
while (!(vif.awvalid && vif.awready)) begin
    @(posedge vif.ACLK);
end
```

**Why this works:** 
- Ensures we wait for the **next** clock edge after setting VALID
- Checks that **both** VALID and READY are high simultaneously
- Guarantees proper handshake completion before clearing signals

### Fix 3: Signal Clearing Timing

**Change:** Removed conditional checks after timeout forks. Signals are now cleared unconditionally after handshake detection, using non-blocking assignments that take effect at the end of the time step.

## Expected Behavior After Fixes

### Timeline:
1. **Time T:** Driver sets AWVALID=1, AWADDR=address
2. **Time T:** AWREADY goes high (combinational: `(IDLE && AWVALID)`)
3. **Time T+1 clock:** Both AWVALID and AWREADY are high → FSM transitions IDLE→WRITE_DATA
4. **Time T+1 clock:** Driver detects handshake complete, clears AWVALID
5. **Time T+2 clock:** Driver sets WVALID=1, WDATA=data
6. **Time T+2 clock:** WREADY goes high (combinational: `(WRITE_DATA && WVALID)`)
7. **Time T+3 clock:** Both WVALID and WREADY are high → FSM transitions WRITE_DATA→WRITE_RESP
8. **Time T+3 clock:** Driver detects handshake complete, clears WVALID
9. **Time T+3 clock:** BVALID goes high (combinational: `(WRITE_RESP)`)
10. **Time T+4 clock:** Driver sets BREADY=1
11. **Time T+4 clock:** Both BVALID and BREADY are high → FSM transitions WRITE_RESP→IDLE
12. **Time T+4 clock:** Driver detects handshake complete, clears BREADY

## Testing

Run the simulation:
```bash
cd sim/testbench_sv/axi_lite_register_file_tb
make clean
make simulate
```

Expected results:
- No simulation hang
- FSM transitions properly through all states
- All handshakes complete successfully
- Simulation terminates normally

## Files Modified

1. `axi_lite_register_file_stub.sv`
   - Changed FSM transition conditions to check handshake completion
   - Removed excessive diagnostic logging

2. `axi_lite_driver.sv`
   - Changed handshake waiting logic to explicitly check both signals
   - Improved timeout handling

## Key Principles Applied

1. **Handshake Completion:** Always check both VALID and READY signals together
2. **Clock Edge Synchronization:** Wait for clock edges where both signals are stable
3. **Non-blocking Assignments:** Use `<=` for signal assignments to ensure proper timing
4. **Consistent Protocol:** Apply same handshake pattern across all AXI channels

## Additional Notes

- The read channel FSM already used this pattern (`arvalid && arready`), so it was used as a reference
- These fixes ensure compliance with AXI-Lite protocol specification
- The timeout mechanisms remain in place for debugging future issues
