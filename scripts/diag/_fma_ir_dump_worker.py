"""Dump the LLVM IR + PTX for the `a*b - c` kernel under given init flags.

Run:
    python _fma_ir_dump_worker.py [k=v ...]
Look at /tmp/taichi_ptx_*.ptx and /tmp/taichi_opt_ir_*.ll for the kernel.
"""
import os
import sys

import taichi as ti


def parse_kwargs(argv):
    kwargs = {}
    for tok in argv[1:]:
        if "=" not in tok:
            continue
        k, v = tok.split("=", 1)
        if v in ("True", "False"):
            kwargs[k] = (v == "True")
        else:
            try:
                kwargs[k] = int(v)
            except ValueError:
                kwargs[k] = v
    return kwargs


def main():
    init_kwargs = parse_kwargs(sys.argv)
    init_kwargs.setdefault("default_fp", ti.f64)
    ti.init(arch=ti.cuda, **init_kwargs)

    a = ti.field(ti.f64, shape=1)
    b = ti.field(ti.f64, shape=1)
    c = ti.field(ti.f64, shape=1)
    y = ti.field(ti.f64, shape=1)

    @ti.kernel
    def k():
        y[0] = a[0] * b[0] - c[0]

    a[0] = 1e10
    b[0] = 1e-10
    c[0] = 1.0
    k()
    print(f"y = {float(y[0])!r}")
    # Surface where the artifacts landed
    import glob
    print("\nIR + PTX artifacts:")
    for f in sorted(glob.glob("/tmp/taichi_opt_ir_*.ll") + glob.glob("/tmp/taichi_ptx_*.ptx")):
        size = os.path.getsize(f)
        print(f"  {f}  ({size} bytes)")


if __name__ == "__main__":
    main()
