# Alignment Validation Summary

**1 PASS / 11 FAIL of 12 entries.**

| case | step | precision | verdict | H max_abs | U max_abs | V max_abs | Z max_abs | mass rel | KE rel | momentum_x rel | klas1_inflow rel | reason |
|------|------|-----------|---------|-----------|-----------|-----------|-----------|----------|--------|----------------|------------------|--------|
| F1_207K_fp64 | 1 | fp64 | FAIL | 2.220e-16 | 1.067e-15 | 9.072e-16 | 0.000e+00 | 0.000e+00 | 5.706e-16 | 1.433e-12 | 0.000e+00 | conservation/momentum_x rel=1.433e-12 >= 1e-12 |
| F1_207K_fp64 | 100 | fp64 | FAIL | 2.860e-13 | 4.177e-13 | 7.390e-13 | 4.547e-13 | 0.000e+00 | 1.458e-15 | 6.844e-14 | 8.213e-11 | conservation/klas1_inflow rel=8.213e-11 >= 1e-12 |
| F1_207K_fp64 | 899 | fp64 | FAIL | 3.837e-13 | 1.845e-12 | 2.136e-12 | 4.547e-13 | 2.209e-16 | 2.700e-16 | 8.868e-15 | 8.371e-10 | conservation/klas1_inflow rel=8.371e-10 >= 1e-12 |
| F1_6.7K_fp64 | 1 | fp64 | FAIL | 0.000e+00 | 2.499e-16 | 2.290e-16 | 0.000e+00 | 0.000e+00 | 0.000e+00 | 4.844e-12 | 0.000e+00 | conservation/momentum_x rel=4.844e-12 >= 1e-12 |
| F1_6.7K_fp64 | 100 | fp64 | FAIL | 1.421e-14 | 8.692e-15 | 8.355e-15 | 2.842e-14 | 0.000e+00 | 1.854e-15 | 3.408e-12 | 0.000e+00 | conservation/momentum_x rel=3.408e-12 >= 1e-12 |
| F1_6.7K_fp64 | 899 | fp64 | FAIL | 1.421e-14 | 2.991e-14 | 3.143e-14 | 2.842e-14 | 2.183e-16 | 7.092e-15 | 8.001e-12 | 0.000e+00 | conservation/momentum_x rel=8.001e-12 >= 1e-12 |
| F2_207K_fp64 | 1 | fp64 | FAIL | 2.220e-16 | 1.067e-15 | 9.072e-16 | 0.000e+00 | 0.000e+00 | 5.706e-16 | 1.433e-12 | 0.000e+00 | conservation/momentum_x rel=1.433e-12 >= 1e-12 |
| F2_207K_fp64 | 100 | fp64 | FAIL | 2.860e-13 | 4.177e-13 | 7.390e-13 | 4.547e-13 | 0.000e+00 | 1.458e-15 | 6.844e-14 | 8.213e-11 | conservation/klas1_inflow rel=8.213e-11 >= 1e-12 |
| F2_207K_fp64 | 899 | fp64 | FAIL | 3.837e-13 | 1.845e-12 | 2.136e-12 | 4.547e-13 | 2.209e-16 | 2.700e-16 | 8.868e-15 | 8.371e-10 | conservation/klas1_inflow rel=8.371e-10 >= 1e-12 |
| F2_24K_fp64 | 1 | fp64 | PASS | 8.882e-16 | 2.776e-17 | 3.728e-16 | 8.882e-16 | 0.000e+00 | 2.623e-16 | 0.000e+00 | 3.152e-15 | fp64 thresholds met |
| F2_24K_fp64 | 100 | fp64 | FAIL | 7.105e-15 | 5.440e-15 | 6.891e-15 | 7.105e-15 | 0.000e+00 | 3.420e-16 | 5.193e-16 | 1.300e-12 | conservation/klas1_inflow rel=1.300e-12 >= 1e-12 |
| F2_24K_fp64 | 899 | fp64 | FAIL | 6.217e-15 | 1.242e-14 | 1.973e-14 | 6.217e-15 | 0.000e+00 | 2.824e-16 | 4.772e-15 | 1.817e-13 | OUTPUT/ZUV.OUT not byte-identical |
