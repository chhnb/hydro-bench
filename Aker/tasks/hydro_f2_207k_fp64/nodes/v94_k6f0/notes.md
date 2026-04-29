# v94_k6f0

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and reuses freshly computed KLAS6 FLR0 values locally.

In the one-sided overtopping branches and the Z_pre <= ZC fully-wet branch of CalculataKlas6, the parent writes FLR(0) and immediately forms FLR(1) and/or FLR(2) by reading FLR(0) back through the macro-backed sides.FLUX0[idx] location. This node introduces a local Real flux0 for each existing FLR(0) product, stores FLR(0) from that local, and uses the same local for the dependent flux multiplications.

No KLAS6 branch predicates, side-geometry expressions, pow/copysign calls, flux store targets, CalculateFluxKernel dispatch, UpdateCellKernel code, launch wrapper, or floating-point operation order is otherwise changed.

## Correctness

Each local flux0 value is exactly the product the parent wrote to FLR(0), and no code writes sides.FLUX0[idx] between that store and the following dependent FLR(1)/FLR(2) expressions. Reading the local register therefore supplies the same bits as the immediate macro read-back.

The dependent products keep the same multiplication order after the cached prefix: flux0 times QL[1], QL[2], the projected normal velocity, fabs(UN), or VT exactly where the parent multiplied FLR(0) by those operands. This should preserve the frozen native CUDA baseline trajectory bit-exactly.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39920
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23736
