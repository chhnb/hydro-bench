**版本说明**：采用 cuda 原生 API 进行的二维计算模型重构版本

**核心计算流程**：
```c++
for (day = 0; day < total_days; day++) {
    for (step = 1; step < steps_per_day; step++) {

        // 4.1 计算边通量
        CalculateFlux(mesh_view, step, day);

        // 4.2 更新单元格状态
        UpdateCell(mesh_view);

    }
}
```

**计算效率**：

```shell
Day 1 / 2000 Done. Compute took 0.135690 seconds
Day 2 / 2000 Done. Compute took 0.133882 seconds
Day 3 / 2000 Done. Compute took 0.131494 seconds
Day 4 / 2000 Done. Compute took 0.124814 seconds
Day 5 / 2000 Done. Compute took 0.144162 seconds
Day 6 / 2000 Done. Compute took 0.125908 seconds
Day 7 / 2000 Done. Compute took 0.113513 seconds
Day 8 / 2000 Done. Compute took 0.113289 seconds
Day 9 / 2000 Done. Compute took 0.130279 seconds
Day 10 / 2000 Done. Compute took 0.116758 seconds
Day 11 / 2000 Done. Compute took 0.111293 seconds
Day 12 / 2000 Done. Compute took 0.115507 seconds
Day 13 / 2000 Done. Compute took 0.116197 seconds
Day 14 / 2000 Done. Compute took 0.114275 seconds
...
```

**原二维模型计算效率**
```shell
Day 1 / 2000 Done. Compute took 0.296617 seconds
Day 2 / 2000 Done. Compute took 0.261626 seconds
Day 3 / 2000 Done. Compute took 0.266733 seconds
Day 4 / 2000 Done. Compute took 0.296132 seconds
Day 5 / 2000 Done. Compute took 0.263661 seconds
Day 6 / 2000 Done. Compute took 0.263969 seconds
Day 7 / 2000 Done. Compute took 0.290154 seconds
Day 8 / 2000 Done. Compute took 0.287542 seconds
Day 9 / 2000 Done. Compute took 0.261186 seconds
Day 10 / 2000 Done. Compute took 0.260221 seconds
Day 11 / 2000 Done. Compute took 0.253590 seconds
Day 12 / 2000 Done. Compute took 0.260776 seconds
Day 13 / 2000 Done. Compute took 0.262641 seconds
Day 14 / 2000 Done. Compute took 0.258363 seconds
...
```

（两者都使用双精度浮点数）