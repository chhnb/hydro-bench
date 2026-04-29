---
created_at: 2026-04-29T05:39:49+00:00
created_at_open_count: 75
ttl_rounds: 20
---

Use profile_sass/ncu_dynamic/summary.md as the primary performance evidence. Taichi calculate_flux is faster mainly because native v42 executes ~1.56x more warp SASS instructions, ~1.66x more predicated-on FP64 thread instructions, ~1.77x more DADD/DMUL/DFMA thread instructions, ~1.41x more branch warp instructions, and has lower active_threads_per_inst (~11.9 vs ~16.0). DRAM bytes are close, so do not focus on bandwidth-only optimizations. Prioritize exact-alignment-preserving changes that reduce FP64 arithmetic, branch/predicate work, and redundant boundary/Osher helper work in CalculateFluxKernel.
