"""One-shot worker: parse argv flags, init Taichi, run a*b - c kernel,
print result. Called from probe_taichi_fma_flags.py via subprocess.

Usage::

    python _fma_flag_worker.py [k=v ...]   # init kwargs, e.g. fast_math=False

Pre-set env vars in the parent control LLVM-side flags (TI_USE_LLVM_FMA, etc.).
"""
import os
import struct
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
    out = float(y[0])
    bits = int.from_bytes(struct.pack("<d", out), "little")
    print(f"RESULT={out!r}")
    print(f"HEX={bits:020X}")
    print(f"NO_FMA={'YES' if abs(out) < 1e-30 else 'no'}")


if __name__ == "__main__":
    main()
