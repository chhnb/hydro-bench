# v64_revnorm

Parent: v42_rowoff

## Change

This node starts from v42_rowoff and cleans up the reverse internal-edge normal geometry setup in CalculateFluxKernel.

The parent declares COSJ1 and SINJ1 as 0.0, computes CL1, and then overwrites COSJ1 with -COSJ and SINJ1 with -SINJ before either value is read.

This node removes the two dead zero initializations and declares Real COSJ1 = -COSJ and Real SINJ1 = -SINJ at the existing assignment point. The reverse-edge projections, OSHER call, row-offset KLAS3 helper, update kernel, and launch wrappers are otherwise unchanged.

## Correctness

COSJ1 and SINJ1 have no observable use between their parent zero initialization and the immediate overwrite with the negated side-normal values. Their first consumers therefore receive the same -COSJ and -SINJ values as before.

No floating-point expression is reordered or removed from the flux calculations. The only removed operations are unreachable dead local stores, so the frozen native CUDA trajectory should remain bit-exact.

## Validation

Host-side broker validation is pending. meta.json intentionally sets attempt_status to FAIL and failure_reason to pending host validation until the Aker host writes report_acc.json and report_perf.json.

## Host validation
- test_acc: status=OK rc=0 queue_wait_ms=0 run_ms=39901
- test_perf: status=OK rc=0 queue_wait_ms=1 run_ms=23599
