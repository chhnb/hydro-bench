; ModuleID = 'kernel'
source_filename = "kernel"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.RuntimeContext.333 = type { i8*, %struct.LLVMRuntime.332*, i32, i64* }
%struct.LLVMRuntime.332 = type { %struct.PreallocatedMemoryChunk.327, %struct.PreallocatedMemoryChunk.327, i8* (i8*, i64, i64)*, void (i8*)*, void (i8*, ...)*, i32 (i8*, i64, i8*, %struct.__va_list_tag.328*)*, i8*, [512 x i8*], [512 x i64], i8*, void (i8*, i32, i32, i8*, void (i8*, i32, i32)*)*, [1024 x %struct.ListManager.329*], [1024 x %struct.NodeManager.330*], [1024 x i8*], i8*, %struct.RandState.331*, i8*, void (i8*, i8*)*, void (i8*)*, [2048 x i8], [32 x i64], i32, i64, i8*, i32, i32, i64 }
%struct.PreallocatedMemoryChunk.327 = type { i8*, i8*, i64 }
%struct.__va_list_tag.328 = type { i32, i32, i8*, i8* }
%struct.ListManager.329 = type { [131072 x i8*], i64, i64, i32, i32, i32, %struct.LLVMRuntime.332* }
%struct.NodeManager.330 = type <{ %struct.LLVMRuntime.332*, i32, i32, i32, i32, %struct.ListManager.329*, %struct.ListManager.329*, %struct.ListManager.329*, i32, [4 x i8] }>
%struct.RandState.331 = type { i32, i32, i32, i32, i32 }

; Function Attrs: nofree nounwind
define void @calculate_flux_c80_0_kernel_0_range_for(%struct.RuntimeContext.333* byval(%struct.RuntimeContext.333) %context) local_unnamed_addr #0 {
entry:
  %context1 = alloca %struct.RuntimeContext.333, align 8
  %0 = addrspacecast %struct.RuntimeContext.333* %context1 to %struct.RuntimeContext.333 addrspace(5)*
  %context2 = addrspacecast %struct.RuntimeContext.333* %context to %struct.RuntimeContext.333 addrspace(101)*
  %context3 = load %struct.RuntimeContext.333, %struct.RuntimeContext.333 addrspace(101)* %context2, align 8
  %context3.fca.0.extract = extractvalue %struct.RuntimeContext.333 %context3, 0
  %context3.fca.0.gep4 = bitcast %struct.RuntimeContext.333 addrspace(5)* %0 to i8* addrspace(5)*
  store i8* %context3.fca.0.extract, i8* addrspace(5)* %context3.fca.0.gep4, align 8
  %context3.fca.1.extract = extractvalue %struct.RuntimeContext.333 %context3, 1
  %context3.fca.1.gep = getelementptr inbounds %struct.RuntimeContext.333, %struct.RuntimeContext.333 addrspace(5)* %0, i32 0, i32 1
  store %struct.LLVMRuntime.332* %context3.fca.1.extract, %struct.LLVMRuntime.332* addrspace(5)* %context3.fca.1.gep, align 8
  %context3.fca.2.extract = extractvalue %struct.RuntimeContext.333 %context3, 2
  %context3.fca.2.gep = getelementptr inbounds %struct.RuntimeContext.333, %struct.RuntimeContext.333 addrspace(5)* %0, i32 0, i32 2
  store i32 %context3.fca.2.extract, i32 addrspace(5)* %context3.fca.2.gep, align 8
  %context3.fca.3.extract = extractvalue %struct.RuntimeContext.333 %context3, 3
  %context3.fca.3.gep = getelementptr inbounds %struct.RuntimeContext.333, %struct.RuntimeContext.333 addrspace(5)* %0, i32 0, i32 3
  store i64* %context3.fca.3.extract, i64* addrspace(5)* %context3.fca.3.gep, align 8
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !range !15
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !range !16
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !range !17
  %4 = mul nsw i32 %2, %3
  %5 = add nuw nsw i32 %4, %1
  %6 = icmp ult i32 %5, 828936
  br i1 %6, label %.lr.ph.i, label %gpu_parallel_range_for.exit

.lr.ph.i:                                         ; preds = %entry
  %7 = tail call i32 @llvm.nvvm.read.ptx.sreg.nctaid.x()
  %8 = mul nsw i32 %2, %7
  br label %9

9:                                                ; preds = %9, %.lr.ph.i
  %.01.i = phi i32 [ %5, %.lr.ph.i ], [ %10, %9 ]
  call fastcc void @function_body(%struct.RuntimeContext.333* noundef nonnull %context1, i8* poison, i32 noundef %.01.i) #5
  %10 = add i32 %.01.i, %8
  %11 = icmp ult i32 %10, 828936
  br i1 %11, label %9, label %gpu_parallel_range_for.exit, !llvm.loop !18

gpu_parallel_range_for.exit:                      ; preds = %9, %entry
  ret void
}

; Function Attrs: nofree nounwind
define internal fastcc void @function_body(%struct.RuntimeContext.333* %0, i8* nocapture readnone %1, i32 %2) unnamed_addr #0 {
allocs:
  %3 = sdiv i32 %2, 4
  %4 = icmp slt i32 %2, 0
  %5 = shl nsw i32 %3, 2
  %6 = icmp ne i32 %5, %2
  %7 = and i1 %4, %6
  %.neg = sext i1 %7 to i32
  %8 = add nsw i32 %3, %.neg
  %9 = getelementptr inbounds %struct.RuntimeContext.333, %struct.RuntimeContext.333* %0, i64 0, i32 1
  %10 = load %struct.LLVMRuntime.332*, %struct.LLVMRuntime.332** %9, align 8
  %11 = getelementptr inbounds %struct.LLVMRuntime.332, %struct.LLVMRuntime.332* %10, i64 0, i32 7, i64 0
  %12 = load i8*, i8** %11, align 8
  %getch.i2551 = getelementptr i8, i8* %12, i64 3315744
  %13 = sext i32 %2 to i64
  %14 = shl nsw i64 %13, 3
  %15 = getelementptr inbounds i8, i8* %getch.i2551, i64 %14
  %16 = bitcast i8* %15 to double*
  %17 = load double, double* %16, align 8
  %18 = fptosi double %17 to i32
  %19 = shl nsw i64 %13, 2
  %20 = getelementptr inbounds i8, i8* %12, i64 %19
  %21 = bitcast i8* %20 to i32*
  %22 = tail call i32 @llvm.nvvm.ldg.global.i.i32.p0i32(i32* %21, i32 32)
  %23 = add i32 %22, -1
  %getch.i2550 = getelementptr i8, i8* %12, i64 69630624
  %24 = sext i32 %8 to i64
  %25 = shl nsw i64 %24, 3
  %26 = getelementptr inbounds i8, i8* %getch.i2550, i64 %25
  %27 = bitcast i8* %26 to double*
  %28 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %27, i32 64)
  %getch.i2549 = getelementptr i8, i8* %12, i64 71288496
  %29 = getelementptr inbounds i8, i8* %getch.i2549, i64 %25
  %30 = bitcast i8* %29 to double*
  %31 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %30, i32 64)
  %getch.i2548 = getelementptr i8, i8* %12, i64 72946368
  %32 = getelementptr inbounds i8, i8* %getch.i2548, i64 %25
  %33 = bitcast i8* %32 to double*
  %34 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %33, i32 64)
  %getch.i2547 = getelementptr i8, i8* %12, i64 77919984
  %35 = getelementptr inbounds i8, i8* %getch.i2547, i64 %25
  %36 = bitcast i8* %35 to double*
  %37 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %36, i32 64)
  %getch.i2546 = getelementptr i8, i8* %12, i64 74604240
  %38 = getelementptr inbounds i8, i8* %getch.i2546, i64 %25
  %39 = bitcast i8* %38 to double*
  %40 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %39, i32 64)
  %getch.i2545 = getelementptr i8, i8* %12, i64 79577856
  %41 = getelementptr inbounds i8, i8* %getch.i2545, i64 %25
  %42 = bitcast i8* %41 to double*
  %43 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %42, i32 64)
  %44 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %40, double %43)
  %getch.i2544 = getelementptr i8, i8* %12, i64 16578720
  %45 = getelementptr inbounds i8, i8* %getch.i2544, i64 %14
  %46 = bitcast i8* %45 to double*
  %47 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %46, i32 64)
  %getch.i2543 = getelementptr i8, i8* %12, i64 23210208
  %48 = getelementptr inbounds i8, i8* %getch.i2543, i64 %14
  %49 = bitcast i8* %48 to double*
  %50 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %49, i32 64)
  %51 = fmul reassoc ninf nsz double %47, %31
  %52 = fmul reassoc ninf nsz double %50, %34
  %53 = fadd reassoc ninf nsz double %52, %51
  %54 = fmul reassoc ninf nsz double %47, %34
  %55 = fmul reassoc ninf nsz double %50, %31
  %56 = fsub reassoc ninf nsz double %54, %55
  %57 = fmul reassoc ninf nsz double %28, 9.810000e+00
  %58 = tail call double @llvm.sqrt.f64(double %57)
  %factor = fmul reassoc ninf nsz double %58, 2.000000e+00
  %59 = fadd reassoc ninf nsz double %53, %factor
  %.not = icmp eq i32 %22, 0
  br i1 %.not, label %after_if, label %true_block

true_block:                                       ; preds = %allocs
  %60 = sext i32 %23 to i64
  %61 = shl nsw i64 %60, 3
  %62 = getelementptr inbounds i8, i8* %getch.i2550, i64 %61
  %63 = bitcast i8* %62 to double*
  %64 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %63, i32 64)
  %65 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %64, double 1.000000e-03)
  %66 = getelementptr inbounds i8, i8* %getch.i2547, i64 %61
  %67 = bitcast i8* %66 to double*
  %68 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %67, i32 64)
  %69 = getelementptr inbounds i8, i8* %getch.i2546, i64 %61
  %70 = bitcast i8* %69 to double*
  %71 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %70, i32 64)
  %72 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %68, double %71)
  %73 = getelementptr inbounds i8, i8* %getch.i2549, i64 %61
  %74 = bitcast i8* %73 to double*
  %75 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %74, i32 64)
  %76 = getelementptr inbounds i8, i8* %getch.i2548, i64 %61
  %77 = bitcast i8* %76 to double*
  %78 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %77, i32 64)
  br label %after_if

after_if:                                         ; preds = %allocs, %true_block
  %.01384 = phi double [ %68, %true_block ], [ 0.000000e+00, %allocs ]
  %.01383 = phi double [ %72, %true_block ], [ 0.000000e+00, %allocs ]
  %.01382 = phi double [ %75, %true_block ], [ 0.000000e+00, %allocs ]
  %.01381 = phi double [ %78, %true_block ], [ 0.000000e+00, %allocs ]
  %.01168 = phi double [ %65, %true_block ], [ 0.000000e+00, %allocs ]
  %79 = add i32 %18, -1
  %80 = icmp ult i32 %79, 8
  %81 = icmp sgt i32 %18, 9
  %or.cond = or i1 %81, %80
  br i1 %or.cond, label %true_block7, label %false_block8

true_block7:                                      ; preds = %after_if
  %82 = fcmp reassoc ninf nsz ogt double %53, %58
  br i1 %82, label %true_block10, label %false_block11

false_block8:                                     ; preds = %after_if
  %83 = fcmp reassoc ninf nsz ole double %28, 1.000000e-03
  %84 = fcmp reassoc ninf nsz ole double %.01168, 1.000000e-03
  %.0743 = select i1 %83, i1 %84, i1 false
  br i1 %.0743, label %after_if9, label %false_block2519

after_if9:                                        ; preds = %false_block2503, %after_if2507, %true_block2464, %__nv_pow.exit2327, %__nv_pow.exit2297, %false_block2477, %__nv_pow.exit2237, %__nv_pow.exit2177, %false_block11, %after_if2590, %after_if2680, %true_block2536, %__nv_pow.exit, %true_block2530, %__nv_pow.exit2057, %__nv_pow.exit2087, %__nv_pow.exit2116, %false_block8, %true_block2455, %true_block2452, %after_while2446, %after_if2434, %after_while, %true_block10
  %.01380 = phi double [ %93, %true_block10 ], [ %124, %after_while ], [ %.0770, %after_if2434 ], [ %5867, %after_while2446 ], [ 0.000000e+00, %true_block2452 ], [ %5904, %true_block2455 ], [ 0.000000e+00, %false_block8 ], [ %7535, %__nv_pow.exit2116 ], [ %7730, %__nv_pow.exit2087 ], [ %7742, %true_block2530 ], [ %7938, %__nv_pow.exit2057 ], [ %7950, %true_block2536 ], [ %8142, %__nv_pow.exit ], [ %.0739, %after_if2590 ], [ %neg2723, %after_if2680 ], [ 0.000000e+00, %false_block11 ], [ 0.000000e+00, %true_block2464 ], [ %6106, %__nv_pow.exit2327 ], [ %6303, %__nv_pow.exit2297 ], [ %6714, %__nv_pow.exit2237 ], [ %7106, %__nv_pow.exit2177 ], [ 0.000000e+00, %false_block2477 ], [ %7327, %after_if2507 ], [ 0.000000e+00, %false_block2503 ]
  %.01379 = phi double [ %94, %true_block10 ], [ %.01369, %after_while ], [ %.0769, %after_if2434 ], [ %5868, %after_while2446 ], [ 0.000000e+00, %true_block2452 ], [ %5905, %true_block2455 ], [ 0.000000e+00, %false_block8 ], [ %7538, %__nv_pow.exit2116 ], [ %7733, %__nv_pow.exit2087 ], [ %7743, %true_block2530 ], [ 0.000000e+00, %__nv_pow.exit2057 ], [ %7951, %true_block2536 ], [ %8144, %__nv_pow.exit ], [ %8233, %after_if2590 ], [ %8527, %after_if2680 ], [ 0.000000e+00, %false_block11 ], [ 0.000000e+00, %true_block2464 ], [ %6107, %__nv_pow.exit2327 ], [ %6308, %__nv_pow.exit2297 ], [ %6716, %__nv_pow.exit2237 ], [ %7109, %__nv_pow.exit2177 ], [ 0.000000e+00, %false_block2477 ], [ %7333, %after_if2507 ], [ 0.000000e+00, %false_block2503 ]
  %.01378 = phi double [ %95, %true_block10 ], [ 0.000000e+00, %after_while ], [ %.01374, %after_if2434 ], [ %.01374, %after_while2446 ], [ 0.000000e+00, %true_block2452 ], [ %.01374, %true_block2455 ], [ 0.000000e+00, %false_block8 ], [ 0.000000e+00, %__nv_pow.exit2116 ], [ %7734, %__nv_pow.exit2087 ], [ %7747, %true_block2530 ], [ 0.000000e+00, %__nv_pow.exit2057 ], [ %7952, %true_block2536 ], [ 0.000000e+00, %__nv_pow.exit ], [ %.0737, %after_if2590 ], [ %.0724, %after_if2680 ], [ %.01374, %false_block11 ], [ 0.000000e+00, %true_block2464 ], [ %6108, %__nv_pow.exit2327 ], [ %6312, %__nv_pow.exit2297 ], [ %6717, %__nv_pow.exit2237 ], [ %7110, %__nv_pow.exit2177 ], [ 0.000000e+00, %false_block2477 ], [ 0.000000e+00, %after_if2507 ], [ 0.000000e+00, %false_block2503 ]
  %.01377 = phi double [ %97, %true_block10 ], [ %129, %after_while ], [ %.0768, %after_if2434 ], [ %5870, %after_while2446 ], [ %5902, %true_block2452 ], [ %5907, %true_block2455 ], [ 0.000000e+00, %false_block8 ], [ %7540, %__nv_pow.exit2116 ], [ 0.000000e+00, %__nv_pow.exit2087 ], [ %7749, %true_block2530 ], [ %7940, %__nv_pow.exit2057 ], [ %7954, %true_block2536 ], [ %8146, %__nv_pow.exit ], [ %.0736, %after_if2590 ], [ %8534, %after_if2680 ], [ 0.000000e+00, %false_block11 ], [ %5914, %true_block2464 ], [ %6111, %__nv_pow.exit2327 ], [ %6315, %__nv_pow.exit2297 ], [ %6720, %__nv_pow.exit2237 ], [ %7113, %__nv_pow.exit2177 ], [ 0.000000e+00, %false_block2477 ], [ 0.000000e+00, %after_if2507 ], [ %7127, %false_block2503 ]
  %getch.i2542 = getelementptr i8, i8* %12, i64 43104672
  %85 = getelementptr inbounds i8, i8* %getch.i2542, i64 %14
  %86 = bitcast i8* %85 to double*
  store double %.01380, double* %86, align 8
  %getch.i2541 = getelementptr i8, i8* %12, i64 49736160
  %87 = getelementptr inbounds i8, i8* %getch.i2541, i64 %14
  %88 = bitcast i8* %87 to double*
  store double %.01379, double* %88, align 8
  %getch.i2540 = getelementptr i8, i8* %12, i64 56367648
  %89 = getelementptr inbounds i8, i8* %getch.i2540, i64 %14
  %90 = bitcast i8* %89 to double*
  store double %.01378, double* %90, align 8
  %getch.i2539 = getelementptr i8, i8* %12, i64 62999136
  %91 = getelementptr inbounds i8, i8* %getch.i2539, i64 %14
  %92 = bitcast i8* %91 to double*
  store double %.01377, double* %92, align 8
  ret void

true_block10:                                     ; preds = %true_block7
  %93 = fmul reassoc ninf nsz double %53, %28
  %94 = fmul reassoc ninf nsz double %93, %53
  %95 = fmul reassoc ninf nsz double %93, %56
  %96 = fmul reassoc ninf nsz double %28, %28
  %97 = fmul reassoc ninf nsz double %96, 4.905000e+00
  br label %after_if9

false_block11:                                    ; preds = %true_block7
  %98 = fcmp reassoc ninf nsz ogt double %53, 0.000000e+00
  %99 = fmul reassoc ninf nsz double %53, %28
  %100 = fmul reassoc ninf nsz double %99, %56
  %.01374 = select i1 %98, double %100, double 0.000000e+00
  switch i32 %18, label %after_if9 [
    i32 10, label %true_block16
    i32 3, label %true_block26
    i32 1, label %true_block2442
    i32 4, label %true_block2452
    i32 5, label %true_block2455
    i32 6, label %true_block2458
    i32 7, label %true_block2496
  ]

true_block16:                                     ; preds = %false_block11
  %101 = trunc i64 %24 to i32
  %102 = bitcast %struct.RuntimeContext.333* %0 to { i32, i32 }**
  %103 = load { i32, i32 }*, { i32, i32 }** %102, align 8
  %104 = bitcast { i32, i32 }* %103 to i32*
  %105 = load i32, i32* %104, align 4
  %106 = getelementptr { i32, i32 }, { i32, i32 }* %103, i64 0, i32 1
  %107 = load i32, i32* %106, align 4
  %108 = mul i32 %107, 207234
  %109 = add i32 %108, %101
  %getch.i2538 = getelementptr i8, i8* %12, i64 252825480
  %110 = sext i32 %109 to i64
  %111 = shl nsw i64 %110, 3
  %112 = getelementptr inbounds i8, i8* %getch.i2538, i64 %111
  %113 = bitcast i8* %112 to double*
  %114 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %113, i32 64)
  %getch.i2537 = getelementptr i8, i8* %12, i64 335719080
  %115 = getelementptr inbounds i8, i8* %getch.i2537, i64 %111
  %116 = bitcast i8* %115 to double*
  %117 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %116, i32 64)
  %118 = sitofp i32 %105 to double
  %119 = fmul reassoc ninf nsz double %117, %118
  %120 = fadd reassoc ninf nsz double %119, %114
  %neg = fneg reassoc ninf nsz double %120
  %getch.i2536 = getelementptr i8, i8* %12, i64 9947232
  %121 = getelementptr inbounds i8, i8* %getch.i2536, i64 %14
  %122 = bitcast i8* %121 to double*
  %123 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %122, i32 64)
  %124 = fdiv reassoc ninf nsz double %neg, %123
  %125 = fmul reassoc ninf nsz double %124, %124
  br label %after_break

after_while:                                      ; preds = %after_if21.3, %after_if21.2, %after_if21.1, %after_if21, %after_break
  %.lcssa10974 = phi double [ %132, %after_break ], [ %142, %after_if21 ], [ %152, %after_if21.1 ], [ %162, %after_if21.2 ], [ %162, %after_if21.3 ]
  %.lcssa = phi double [ %133, %after_break ], [ %143, %after_if21 ], [ %153, %after_if21.1 ], [ %163, %after_if21.2 ], [ %163, %after_if21.3 ]
  %126 = fcmp reassoc ninf nsz ogt double %.lcssa, 1.000000e+00
  %127 = fdiv reassoc ninf nsz double %125, %.lcssa
  %.01369 = select i1 %126, double %127, double 0.000000e+00
  %128 = fmul reassoc ninf nsz double %.lcssa10974, 1.250000e-01
  %129 = fmul reassoc ninf nsz double %128, %.lcssa
  br label %after_if9

after_break:                                      ; preds = %after_if21.3, %true_block16
  %lsr.iv10981 = phi i32 [ %lsr.iv.next10982, %after_if21.3 ], [ -20, %true_block16 ]
  %.0137310968 = phi double [ %28, %true_block16 ], [ %169, %after_if21.3 ]
  %130 = fdiv reassoc ninf nsz double %124, %.0137310968
  %131 = fsub reassoc ninf nsz double %59, %130
  %132 = fmul reassoc ninf nsz double %131, %131
  %133 = fmul reassoc ninf nsz double %132, 0x3F9A1887B2C1A188
  %134 = fsub reassoc ninf nsz double %.0137310968, %133
  %135 = tail call double @llvm.fabs.f64(double %134)
  %136 = fcmp reassoc ninf nsz ugt double %135, 5.000000e-03
  br i1 %136, label %after_if21, label %after_while

after_if21:                                       ; preds = %after_break
  %137 = fmul reassoc ninf nsz double %.0137310968, 5.000000e-01
  %138 = fmul reassoc ninf nsz double %132, 0x3F8A1887B2C1A188
  %139 = fadd reassoc ninf nsz double %138, %137
  %140 = fdiv reassoc ninf nsz double %124, %139
  %141 = fsub reassoc ninf nsz double %59, %140
  %142 = fmul reassoc ninf nsz double %141, %141
  %143 = fmul reassoc ninf nsz double %142, 0x3F9A1887B2C1A188
  %144 = fsub reassoc ninf nsz double %139, %143
  %145 = tail call double @llvm.fabs.f64(double %144)
  %146 = fcmp reassoc ninf nsz ugt double %145, 5.000000e-03
  br i1 %146, label %after_if21.1, label %after_while

after_if21.1:                                     ; preds = %after_if21
  %147 = fmul reassoc ninf nsz double %139, 5.000000e-01
  %148 = fmul reassoc ninf nsz double %142, 0x3F8A1887B2C1A188
  %149 = fadd reassoc ninf nsz double %148, %147
  %150 = fdiv reassoc ninf nsz double %124, %149
  %151 = fsub reassoc ninf nsz double %59, %150
  %152 = fmul reassoc ninf nsz double %151, %151
  %153 = fmul reassoc ninf nsz double %152, 0x3F9A1887B2C1A188
  %154 = fsub reassoc ninf nsz double %149, %153
  %155 = tail call double @llvm.fabs.f64(double %154)
  %156 = fcmp reassoc ninf nsz ugt double %155, 5.000000e-03
  br i1 %156, label %after_if21.2, label %after_while

after_if21.2:                                     ; preds = %after_if21.1
  %157 = fmul reassoc ninf nsz double %149, 5.000000e-01
  %158 = fmul reassoc ninf nsz double %152, 0x3F8A1887B2C1A188
  %159 = fadd reassoc ninf nsz double %158, %157
  %160 = fdiv reassoc ninf nsz double %124, %159
  %161 = fsub reassoc ninf nsz double %59, %160
  %162 = fmul reassoc ninf nsz double %161, %161
  %163 = fmul reassoc ninf nsz double %162, 0x3F9A1887B2C1A188
  %164 = fsub reassoc ninf nsz double %159, %163
  %165 = tail call double @llvm.fabs.f64(double %164)
  %166 = fcmp reassoc ninf nsz ugt double %165, 5.000000e-03
  br i1 %166, label %after_if21.3, label %after_while

after_if21.3:                                     ; preds = %after_if21.2
  %167 = fmul reassoc ninf nsz double %159, 5.000000e-01
  %168 = fmul reassoc ninf nsz double %162, 0x3F8A1887B2C1A188
  %169 = fadd reassoc ninf nsz double %168, %167
  %lsr.iv.next10982 = add nsw i32 %lsr.iv10981, 4
  %exitcond.3 = icmp eq i32 %lsr.iv.next10982, 0
  br i1 %exitcond.3, label %after_while, label %after_break

true_block26:                                     ; preds = %false_block11
  %170 = trunc i64 %24 to i32
  %getch.i2535 = getelementptr i8, i8* %12, i64 9947232
  %171 = getelementptr inbounds i8, i8* %getch.i2535, i64 %14
  %172 = bitcast i8* %171 to double*
  %173 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %172, i32 64)
  %174 = fmul reassoc ninf nsz double %173, %99
  %175 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %174, double 0.000000e+00)
  %getch.i2534 = getelementptr i8, i8* %12, i64 86209344
  %176 = shl nsw i64 %24, 2
  %177 = getelementptr inbounds i8, i8* %getch.i2534, i64 %176
  %178 = bitcast i8* %177 to i32*
  %179 = tail call i32 @llvm.nvvm.ldg.global.i.i32.p0i32(i32* %178, i32 32)
  %180 = mul i32 %170, 200
  %181 = icmp sgt i32 %179, 0
  br i1 %181, label %true_block29, label %after_if31

true_block29:                                     ; preds = %true_block26
  %getch.i2533 = getelementptr i8, i8* %12, i64 750187080
  %182 = sext i32 %180 to i64
  %183 = shl nsw i64 %182, 3
  %184 = getelementptr inbounds i8, i8* %getch.i2533, i64 %183
  %185 = bitcast i8* %184 to double*
  %186 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %185, i32 64)
  %187 = fcmp reassoc ninf nsz olt double %175, %186
  br i1 %187, label %true_block32, label %false_block33

after_if31:                                       ; preds = %true_block2423, %true_block2417, %after_if2407, %true_block35, %true_block32, %true_block26
  %.01171 = phi double [ %200, %true_block32 ], [ %211, %true_block35 ], [ %5775, %true_block2423 ], [ %.198, %true_block2417 ], [ %.198, %after_if2407 ], [ 0.000000e+00, %true_block26 ]
  %188 = fsub reassoc ninf nsz double %.01171, %37
  %189 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %188, double 1.000000e-02)
  %190 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %53, double 0.000000e+00)
  %191 = or i32 %180, 1
  %getch.i2532 = getelementptr i8, i8* %12, i64 750187080
  %192 = sext i32 %191 to i64
  %193 = shl nsw i64 %192, 3
  %194 = getelementptr inbounds i8, i8* %getch.i2532, i64 %193
  %195 = bitcast i8* %194 to double*
  %196 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %195, i32 64)
  %197 = fcmp reassoc ninf nsz ugt double %175, %196
  br i1 %197, label %false_block2427, label %true_block2432

true_block32:                                     ; preds = %true_block29
  %getch.i2531 = getelementptr i8, i8* %12, i64 418612680
  %198 = getelementptr inbounds i8, i8* %getch.i2531, i64 %183
  %199 = bitcast i8* %198 to double*
  %200 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %199, i32 64)
  br label %after_if31

false_block33:                                    ; preds = %true_block29
  %201 = add nsw i32 %179, -1
  %202 = add i32 %201, %180
  %203 = sext i32 %202 to i64
  %204 = shl nsw i64 %203, 3
  %205 = getelementptr inbounds i8, i8* %getch.i2533, i64 %204
  %206 = bitcast i8* %205 to double*
  %207 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %206, i32 64)
  %208 = fcmp reassoc ninf nsz ogt double %175, %207
  br i1 %208, label %true_block35, label %false_block36

true_block35:                                     ; preds = %false_block33
  %getch.i2530 = getelementptr i8, i8* %12, i64 418612680
  %209 = getelementptr inbounds i8, i8* %getch.i2530, i64 %204
  %210 = bitcast i8* %209 to double*
  %211 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %210, i32 64)
  br label %after_if31

false_block36:                                    ; preds = %false_block33
  %.not10870 = icmp eq i32 %201, 0
  br i1 %.not10870, label %after_if43, label %true_block41

true_block41:                                     ; preds = %false_block36
  %212 = or i32 %180, 1
  %213 = sext i32 %212 to i64
  %214 = shl nsw i64 %213, 3
  %215 = getelementptr inbounds i8, i8* %getch.i2533, i64 %214
  %216 = bitcast i8* %215 to double*
  %217 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %216, i32 64)
  %218 = fcmp reassoc ninf nsz oge double %175, %186
  %219 = fcmp reassoc ninf nsz ole double %175, %217
  %.01167 = select i1 %218, i1 %219, i1 false
  br i1 %.01167, label %true_block47, label %after_if43

after_if43:                                       ; preds = %true_block47, %true_block41, %false_block36
  %.11172 = phi double [ %233, %true_block47 ], [ 0.000000e+00, %true_block41 ], [ 0.000000e+00, %false_block36 ]
  %.01169 = phi i1 [ true, %true_block47 ], [ false, %true_block41 ], [ false, %false_block36 ]
  %220 = icmp ult i32 %201, 2
  %221 = or i1 %220, %.01169
  br i1 %221, label %after_if55, label %true_block53

true_block47:                                     ; preds = %true_block41
  %getch.i2529 = getelementptr i8, i8* %12, i64 418612680
  %222 = getelementptr inbounds i8, i8* %getch.i2529, i64 %183
  %223 = bitcast i8* %222 to double*
  %224 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %223, i32 64)
  %225 = getelementptr inbounds i8, i8* %getch.i2529, i64 %214
  %226 = bitcast i8* %225 to double*
  %227 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %226, i32 64)
  %228 = fsub reassoc ninf nsz double %227, %224
  %229 = fsub reassoc ninf nsz double %217, %186
  %230 = fsub reassoc ninf nsz double %175, %186
  %231 = fmul reassoc ninf nsz double %228, %230
  %232 = fdiv reassoc ninf nsz double %231, %229
  %233 = fadd reassoc ninf nsz double %232, %224
  br label %after_if43

true_block53:                                     ; preds = %after_if43
  %234 = or i32 %180, 1
  %235 = sext i32 %234 to i64
  %236 = shl nsw i64 %235, 3
  %237 = getelementptr inbounds i8, i8* %getch.i2533, i64 %236
  %238 = bitcast i8* %237 to double*
  %239 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %238, i32 64)
  %240 = or i32 %180, 2
  %241 = sext i32 %240 to i64
  %242 = shl nsw i64 %241, 3
  %243 = getelementptr inbounds i8, i8* %getch.i2533, i64 %242
  %244 = bitcast i8* %243 to double*
  %245 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %244, i32 64)
  %246 = fcmp reassoc ninf nsz oge double %175, %239
  %247 = fcmp reassoc ninf nsz ole double %175, %245
  %.01165 = select i1 %246, i1 %247, i1 false
  br i1 %.01165, label %true_block59, label %after_if55

after_if55:                                       ; preds = %true_block59, %true_block53, %after_if43
  %.21173 = phi double [ %261, %true_block59 ], [ %.11172, %true_block53 ], [ %.11172, %after_if43 ]
  %.11170 = phi i1 [ true, %true_block59 ], [ false, %true_block53 ], [ %.01169, %after_if43 ]
  %248 = icmp ult i32 %201, 3
  %249 = or i1 %248, %.11170
  br i1 %249, label %after_if67, label %true_block65

true_block59:                                     ; preds = %true_block53
  %getch.i2528 = getelementptr i8, i8* %12, i64 418612680
  %250 = getelementptr inbounds i8, i8* %getch.i2528, i64 %236
  %251 = bitcast i8* %250 to double*
  %252 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %251, i32 64)
  %253 = getelementptr inbounds i8, i8* %getch.i2528, i64 %242
  %254 = bitcast i8* %253 to double*
  %255 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %254, i32 64)
  %256 = fsub reassoc ninf nsz double %255, %252
  %257 = fsub reassoc ninf nsz double %245, %239
  %258 = fsub reassoc ninf nsz double %175, %239
  %259 = fmul reassoc ninf nsz double %256, %258
  %260 = fdiv reassoc ninf nsz double %259, %257
  %261 = fadd reassoc ninf nsz double %260, %252
  br label %after_if55

true_block65:                                     ; preds = %after_if55
  %262 = or i32 %180, 2
  %263 = sext i32 %262 to i64
  %264 = shl nsw i64 %263, 3
  %265 = getelementptr inbounds i8, i8* %getch.i2533, i64 %264
  %266 = bitcast i8* %265 to double*
  %267 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %266, i32 64)
  %268 = or i32 %180, 3
  %269 = sext i32 %268 to i64
  %270 = shl nsw i64 %269, 3
  %271 = getelementptr inbounds i8, i8* %getch.i2533, i64 %270
  %272 = bitcast i8* %271 to double*
  %273 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %272, i32 64)
  %274 = fcmp reassoc ninf nsz oge double %175, %267
  %275 = fcmp reassoc ninf nsz ole double %175, %273
  %.01163 = select i1 %274, i1 %275, i1 false
  br i1 %.01163, label %true_block71, label %after_if67

after_if67:                                       ; preds = %true_block71, %true_block65, %after_if55
  %.31174 = phi double [ %289, %true_block71 ], [ %.21173, %true_block65 ], [ %.21173, %after_if55 ]
  %.2 = phi i1 [ true, %true_block71 ], [ false, %true_block65 ], [ %.11170, %after_if55 ]
  %276 = icmp ult i32 %201, 4
  %277 = or i1 %276, %.2
  br i1 %277, label %after_if79, label %true_block77

true_block71:                                     ; preds = %true_block65
  %getch.i2527 = getelementptr i8, i8* %12, i64 418612680
  %278 = getelementptr inbounds i8, i8* %getch.i2527, i64 %264
  %279 = bitcast i8* %278 to double*
  %280 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %279, i32 64)
  %281 = getelementptr inbounds i8, i8* %getch.i2527, i64 %270
  %282 = bitcast i8* %281 to double*
  %283 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %282, i32 64)
  %284 = fsub reassoc ninf nsz double %283, %280
  %285 = fsub reassoc ninf nsz double %273, %267
  %286 = fsub reassoc ninf nsz double %175, %267
  %287 = fmul reassoc ninf nsz double %284, %286
  %288 = fdiv reassoc ninf nsz double %287, %285
  %289 = fadd reassoc ninf nsz double %288, %280
  br label %after_if67

true_block77:                                     ; preds = %after_if67
  %290 = or i32 %180, 3
  %291 = sext i32 %290 to i64
  %292 = shl nsw i64 %291, 3
  %293 = getelementptr inbounds i8, i8* %getch.i2533, i64 %292
  %294 = bitcast i8* %293 to double*
  %295 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %294, i32 64)
  %296 = or i32 %180, 4
  %297 = sext i32 %296 to i64
  %298 = shl nsw i64 %297, 3
  %299 = getelementptr inbounds i8, i8* %getch.i2533, i64 %298
  %300 = bitcast i8* %299 to double*
  %301 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %300, i32 64)
  %302 = fcmp reassoc ninf nsz oge double %175, %295
  %303 = fcmp reassoc ninf nsz ole double %175, %301
  %.01161 = select i1 %302, i1 %303, i1 false
  br i1 %.01161, label %true_block83, label %after_if79

after_if79:                                       ; preds = %true_block83, %true_block77, %after_if67
  %.41175 = phi double [ %317, %true_block83 ], [ %.31174, %true_block77 ], [ %.31174, %after_if67 ]
  %.3 = phi i1 [ true, %true_block83 ], [ false, %true_block77 ], [ %.2, %after_if67 ]
  %304 = icmp ult i32 %201, 5
  %305 = or i1 %304, %.3
  br i1 %305, label %after_if91, label %true_block89

true_block83:                                     ; preds = %true_block77
  %getch.i2526 = getelementptr i8, i8* %12, i64 418612680
  %306 = getelementptr inbounds i8, i8* %getch.i2526, i64 %292
  %307 = bitcast i8* %306 to double*
  %308 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %307, i32 64)
  %309 = getelementptr inbounds i8, i8* %getch.i2526, i64 %298
  %310 = bitcast i8* %309 to double*
  %311 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %310, i32 64)
  %312 = fsub reassoc ninf nsz double %311, %308
  %313 = fsub reassoc ninf nsz double %301, %295
  %314 = fsub reassoc ninf nsz double %175, %295
  %315 = fmul reassoc ninf nsz double %312, %314
  %316 = fdiv reassoc ninf nsz double %315, %313
  %317 = fadd reassoc ninf nsz double %316, %308
  br label %after_if79

true_block89:                                     ; preds = %after_if79
  %318 = or i32 %180, 4
  %319 = sext i32 %318 to i64
  %320 = shl nsw i64 %319, 3
  %321 = getelementptr inbounds i8, i8* %getch.i2533, i64 %320
  %322 = bitcast i8* %321 to double*
  %323 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %322, i32 64)
  %324 = or i32 %180, 5
  %325 = sext i32 %324 to i64
  %326 = shl nsw i64 %325, 3
  %327 = getelementptr inbounds i8, i8* %getch.i2533, i64 %326
  %328 = bitcast i8* %327 to double*
  %329 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %328, i32 64)
  %330 = fcmp reassoc ninf nsz oge double %175, %323
  %331 = fcmp reassoc ninf nsz ole double %175, %329
  %.01159 = select i1 %330, i1 %331, i1 false
  br i1 %.01159, label %true_block95, label %after_if91

after_if91:                                       ; preds = %true_block95, %true_block89, %after_if79
  %.51176 = phi double [ %345, %true_block95 ], [ %.41175, %true_block89 ], [ %.41175, %after_if79 ]
  %.4 = phi i1 [ true, %true_block95 ], [ false, %true_block89 ], [ %.3, %after_if79 ]
  %332 = icmp ult i32 %201, 6
  %333 = or i1 %332, %.4
  br i1 %333, label %after_if103, label %true_block101

true_block95:                                     ; preds = %true_block89
  %getch.i2525 = getelementptr i8, i8* %12, i64 418612680
  %334 = getelementptr inbounds i8, i8* %getch.i2525, i64 %320
  %335 = bitcast i8* %334 to double*
  %336 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %335, i32 64)
  %337 = getelementptr inbounds i8, i8* %getch.i2525, i64 %326
  %338 = bitcast i8* %337 to double*
  %339 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %338, i32 64)
  %340 = fsub reassoc ninf nsz double %339, %336
  %341 = fsub reassoc ninf nsz double %329, %323
  %342 = fsub reassoc ninf nsz double %175, %323
  %343 = fmul reassoc ninf nsz double %340, %342
  %344 = fdiv reassoc ninf nsz double %343, %341
  %345 = fadd reassoc ninf nsz double %344, %336
  br label %after_if91

true_block101:                                    ; preds = %after_if91
  %346 = or i32 %180, 5
  %347 = sext i32 %346 to i64
  %348 = shl nsw i64 %347, 3
  %349 = getelementptr inbounds i8, i8* %getch.i2533, i64 %348
  %350 = bitcast i8* %349 to double*
  %351 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %350, i32 64)
  %352 = or i32 %180, 6
  %353 = sext i32 %352 to i64
  %354 = shl nsw i64 %353, 3
  %355 = getelementptr inbounds i8, i8* %getch.i2533, i64 %354
  %356 = bitcast i8* %355 to double*
  %357 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %356, i32 64)
  %358 = fcmp reassoc ninf nsz oge double %175, %351
  %359 = fcmp reassoc ninf nsz ole double %175, %357
  %.01157 = select i1 %358, i1 %359, i1 false
  br i1 %.01157, label %true_block107, label %after_if103

after_if103:                                      ; preds = %true_block107, %true_block101, %after_if91
  %.61177 = phi double [ %373, %true_block107 ], [ %.51176, %true_block101 ], [ %.51176, %after_if91 ]
  %.5 = phi i1 [ true, %true_block107 ], [ false, %true_block101 ], [ %.4, %after_if91 ]
  %360 = icmp ult i32 %201, 7
  %361 = or i1 %360, %.5
  br i1 %361, label %after_if115, label %true_block113

true_block107:                                    ; preds = %true_block101
  %getch.i2524 = getelementptr i8, i8* %12, i64 418612680
  %362 = getelementptr inbounds i8, i8* %getch.i2524, i64 %348
  %363 = bitcast i8* %362 to double*
  %364 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %363, i32 64)
  %365 = getelementptr inbounds i8, i8* %getch.i2524, i64 %354
  %366 = bitcast i8* %365 to double*
  %367 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %366, i32 64)
  %368 = fsub reassoc ninf nsz double %367, %364
  %369 = fsub reassoc ninf nsz double %357, %351
  %370 = fsub reassoc ninf nsz double %175, %351
  %371 = fmul reassoc ninf nsz double %368, %370
  %372 = fdiv reassoc ninf nsz double %371, %369
  %373 = fadd reassoc ninf nsz double %372, %364
  br label %after_if103

true_block113:                                    ; preds = %after_if103
  %374 = or i32 %180, 6
  %375 = sext i32 %374 to i64
  %376 = shl nsw i64 %375, 3
  %377 = getelementptr inbounds i8, i8* %getch.i2533, i64 %376
  %378 = bitcast i8* %377 to double*
  %379 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %378, i32 64)
  %380 = or i32 %180, 7
  %381 = sext i32 %380 to i64
  %382 = shl nsw i64 %381, 3
  %383 = getelementptr inbounds i8, i8* %getch.i2533, i64 %382
  %384 = bitcast i8* %383 to double*
  %385 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %384, i32 64)
  %386 = fcmp reassoc ninf nsz oge double %175, %379
  %387 = fcmp reassoc ninf nsz ole double %175, %385
  %.01155 = select i1 %386, i1 %387, i1 false
  br i1 %.01155, label %true_block119, label %after_if115

after_if115:                                      ; preds = %true_block119, %true_block113, %after_if103
  %.71178 = phi double [ %401, %true_block119 ], [ %.61177, %true_block113 ], [ %.61177, %after_if103 ]
  %.6 = phi i1 [ true, %true_block119 ], [ false, %true_block113 ], [ %.5, %after_if103 ]
  %388 = icmp ugt i32 %201, 7
  %389 = xor i1 %.6, true
  %spec.select1833 = select i1 %388, i1 %389, i1 false
  br i1 %spec.select1833, label %true_block125, label %after_if127

true_block119:                                    ; preds = %true_block113
  %getch.i2523 = getelementptr i8, i8* %12, i64 418612680
  %390 = getelementptr inbounds i8, i8* %getch.i2523, i64 %376
  %391 = bitcast i8* %390 to double*
  %392 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %391, i32 64)
  %393 = getelementptr inbounds i8, i8* %getch.i2523, i64 %382
  %394 = bitcast i8* %393 to double*
  %395 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %394, i32 64)
  %396 = fsub reassoc ninf nsz double %395, %392
  %397 = fsub reassoc ninf nsz double %385, %379
  %398 = fsub reassoc ninf nsz double %175, %379
  %399 = fmul reassoc ninf nsz double %396, %398
  %400 = fdiv reassoc ninf nsz double %399, %397
  %401 = fadd reassoc ninf nsz double %400, %392
  br label %after_if115

true_block125:                                    ; preds = %after_if115
  %402 = or i32 %180, 7
  %403 = sext i32 %402 to i64
  %404 = shl nsw i64 %403, 3
  %405 = getelementptr inbounds i8, i8* %getch.i2533, i64 %404
  %406 = bitcast i8* %405 to double*
  %407 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %406, i32 64)
  %408 = add i32 %180, 8
  %409 = sext i32 %408 to i64
  %410 = shl nsw i64 %409, 3
  %411 = getelementptr inbounds i8, i8* %getch.i2533, i64 %410
  %412 = bitcast i8* %411 to double*
  %413 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %412, i32 64)
  %414 = fcmp reassoc ninf nsz oge double %175, %407
  %415 = fcmp reassoc ninf nsz ole double %175, %413
  %.01153 = select i1 %414, i1 %415, i1 false
  br i1 %.01153, label %true_block131, label %after_if127

after_if127:                                      ; preds = %true_block131, %true_block125, %after_if115
  %.81179 = phi double [ %429, %true_block131 ], [ %.71178, %true_block125 ], [ %.71178, %after_if115 ]
  %.7 = phi i1 [ true, %true_block131 ], [ %.6, %true_block125 ], [ %.6, %after_if115 ]
  %416 = icmp ugt i32 %201, 8
  %417 = xor i1 %.7, true
  %spec.select1834 = select i1 %416, i1 %417, i1 false
  br i1 %spec.select1834, label %true_block137, label %after_if139

true_block131:                                    ; preds = %true_block125
  %getch.i2522 = getelementptr i8, i8* %12, i64 418612680
  %418 = getelementptr inbounds i8, i8* %getch.i2522, i64 %404
  %419 = bitcast i8* %418 to double*
  %420 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %419, i32 64)
  %421 = getelementptr inbounds i8, i8* %getch.i2522, i64 %410
  %422 = bitcast i8* %421 to double*
  %423 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %422, i32 64)
  %424 = fsub reassoc ninf nsz double %423, %420
  %425 = fsub reassoc ninf nsz double %413, %407
  %426 = fsub reassoc ninf nsz double %175, %407
  %427 = fmul reassoc ninf nsz double %424, %426
  %428 = fdiv reassoc ninf nsz double %427, %425
  %429 = fadd reassoc ninf nsz double %428, %420
  br label %after_if127

true_block137:                                    ; preds = %after_if127
  %430 = add i32 %180, 8
  %431 = sext i32 %430 to i64
  %432 = shl nsw i64 %431, 3
  %433 = getelementptr inbounds i8, i8* %getch.i2533, i64 %432
  %434 = bitcast i8* %433 to double*
  %435 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %434, i32 64)
  %436 = add i32 %180, 9
  %437 = sext i32 %436 to i64
  %438 = shl nsw i64 %437, 3
  %439 = getelementptr inbounds i8, i8* %getch.i2533, i64 %438
  %440 = bitcast i8* %439 to double*
  %441 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %440, i32 64)
  %442 = fcmp reassoc ninf nsz oge double %175, %435
  %443 = fcmp reassoc ninf nsz ole double %175, %441
  %.01151 = select i1 %442, i1 %443, i1 false
  br i1 %.01151, label %true_block143, label %after_if139

after_if139:                                      ; preds = %true_block143, %true_block137, %after_if127
  %.91180 = phi double [ %457, %true_block143 ], [ %.81179, %true_block137 ], [ %.81179, %after_if127 ]
  %.8 = phi i1 [ true, %true_block143 ], [ %.7, %true_block137 ], [ %.7, %after_if127 ]
  %444 = icmp ugt i32 %201, 9
  %445 = xor i1 %.8, true
  %spec.select1835 = select i1 %444, i1 %445, i1 false
  br i1 %spec.select1835, label %true_block149, label %after_if151

true_block143:                                    ; preds = %true_block137
  %getch.i2521 = getelementptr i8, i8* %12, i64 418612680
  %446 = getelementptr inbounds i8, i8* %getch.i2521, i64 %432
  %447 = bitcast i8* %446 to double*
  %448 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %447, i32 64)
  %449 = getelementptr inbounds i8, i8* %getch.i2521, i64 %438
  %450 = bitcast i8* %449 to double*
  %451 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %450, i32 64)
  %452 = fsub reassoc ninf nsz double %451, %448
  %453 = fsub reassoc ninf nsz double %441, %435
  %454 = fsub reassoc ninf nsz double %175, %435
  %455 = fmul reassoc ninf nsz double %452, %454
  %456 = fdiv reassoc ninf nsz double %455, %453
  %457 = fadd reassoc ninf nsz double %456, %448
  br label %after_if139

true_block149:                                    ; preds = %after_if139
  %458 = add i32 %180, 9
  %459 = sext i32 %458 to i64
  %460 = shl nsw i64 %459, 3
  %461 = getelementptr inbounds i8, i8* %getch.i2533, i64 %460
  %462 = bitcast i8* %461 to double*
  %463 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %462, i32 64)
  %464 = add i32 %180, 10
  %465 = sext i32 %464 to i64
  %466 = shl nsw i64 %465, 3
  %467 = getelementptr inbounds i8, i8* %getch.i2533, i64 %466
  %468 = bitcast i8* %467 to double*
  %469 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %468, i32 64)
  %470 = fcmp reassoc ninf nsz oge double %175, %463
  %471 = fcmp reassoc ninf nsz ole double %175, %469
  %.01149 = select i1 %470, i1 %471, i1 false
  br i1 %.01149, label %true_block155, label %after_if151

after_if151:                                      ; preds = %true_block155, %true_block149, %after_if139
  %.101181 = phi double [ %485, %true_block155 ], [ %.91180, %true_block149 ], [ %.91180, %after_if139 ]
  %.9 = phi i1 [ true, %true_block155 ], [ %.8, %true_block149 ], [ %.8, %after_if139 ]
  %472 = icmp ugt i32 %201, 10
  %473 = xor i1 %.9, true
  %spec.select1836 = select i1 %472, i1 %473, i1 false
  br i1 %spec.select1836, label %true_block161, label %after_if163

true_block155:                                    ; preds = %true_block149
  %getch.i2520 = getelementptr i8, i8* %12, i64 418612680
  %474 = getelementptr inbounds i8, i8* %getch.i2520, i64 %460
  %475 = bitcast i8* %474 to double*
  %476 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %475, i32 64)
  %477 = getelementptr inbounds i8, i8* %getch.i2520, i64 %466
  %478 = bitcast i8* %477 to double*
  %479 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %478, i32 64)
  %480 = fsub reassoc ninf nsz double %479, %476
  %481 = fsub reassoc ninf nsz double %469, %463
  %482 = fsub reassoc ninf nsz double %175, %463
  %483 = fmul reassoc ninf nsz double %480, %482
  %484 = fdiv reassoc ninf nsz double %483, %481
  %485 = fadd reassoc ninf nsz double %484, %476
  br label %after_if151

true_block161:                                    ; preds = %after_if151
  %486 = add i32 %180, 10
  %487 = sext i32 %486 to i64
  %488 = shl nsw i64 %487, 3
  %489 = getelementptr inbounds i8, i8* %getch.i2533, i64 %488
  %490 = bitcast i8* %489 to double*
  %491 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %490, i32 64)
  %492 = add i32 %180, 11
  %493 = sext i32 %492 to i64
  %494 = shl nsw i64 %493, 3
  %495 = getelementptr inbounds i8, i8* %getch.i2533, i64 %494
  %496 = bitcast i8* %495 to double*
  %497 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %496, i32 64)
  %498 = fcmp reassoc ninf nsz oge double %175, %491
  %499 = fcmp reassoc ninf nsz ole double %175, %497
  %.01147 = select i1 %498, i1 %499, i1 false
  br i1 %.01147, label %true_block167, label %after_if163

after_if163:                                      ; preds = %true_block167, %true_block161, %after_if151
  %.111182 = phi double [ %513, %true_block167 ], [ %.101181, %true_block161 ], [ %.101181, %after_if151 ]
  %.10 = phi i1 [ true, %true_block167 ], [ %.9, %true_block161 ], [ %.9, %after_if151 ]
  %500 = icmp ugt i32 %201, 11
  %501 = xor i1 %.10, true
  %spec.select1837 = select i1 %500, i1 %501, i1 false
  br i1 %spec.select1837, label %true_block173, label %after_if175

true_block167:                                    ; preds = %true_block161
  %getch.i2519 = getelementptr i8, i8* %12, i64 418612680
  %502 = getelementptr inbounds i8, i8* %getch.i2519, i64 %488
  %503 = bitcast i8* %502 to double*
  %504 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %503, i32 64)
  %505 = getelementptr inbounds i8, i8* %getch.i2519, i64 %494
  %506 = bitcast i8* %505 to double*
  %507 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %506, i32 64)
  %508 = fsub reassoc ninf nsz double %507, %504
  %509 = fsub reassoc ninf nsz double %497, %491
  %510 = fsub reassoc ninf nsz double %175, %491
  %511 = fmul reassoc ninf nsz double %508, %510
  %512 = fdiv reassoc ninf nsz double %511, %509
  %513 = fadd reassoc ninf nsz double %512, %504
  br label %after_if163

true_block173:                                    ; preds = %after_if163
  %514 = add i32 %180, 11
  %515 = sext i32 %514 to i64
  %516 = shl nsw i64 %515, 3
  %517 = getelementptr inbounds i8, i8* %getch.i2533, i64 %516
  %518 = bitcast i8* %517 to double*
  %519 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %518, i32 64)
  %520 = add i32 %180, 12
  %521 = sext i32 %520 to i64
  %522 = shl nsw i64 %521, 3
  %523 = getelementptr inbounds i8, i8* %getch.i2533, i64 %522
  %524 = bitcast i8* %523 to double*
  %525 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %524, i32 64)
  %526 = fcmp reassoc ninf nsz oge double %175, %519
  %527 = fcmp reassoc ninf nsz ole double %175, %525
  %.01145 = select i1 %526, i1 %527, i1 false
  br i1 %.01145, label %true_block179, label %after_if175

after_if175:                                      ; preds = %true_block179, %true_block173, %after_if163
  %.121183 = phi double [ %541, %true_block179 ], [ %.111182, %true_block173 ], [ %.111182, %after_if163 ]
  %.11 = phi i1 [ true, %true_block179 ], [ %.10, %true_block173 ], [ %.10, %after_if163 ]
  %528 = icmp ugt i32 %201, 12
  %529 = xor i1 %.11, true
  %spec.select1838 = select i1 %528, i1 %529, i1 false
  br i1 %spec.select1838, label %true_block185, label %after_if187

true_block179:                                    ; preds = %true_block173
  %getch.i2518 = getelementptr i8, i8* %12, i64 418612680
  %530 = getelementptr inbounds i8, i8* %getch.i2518, i64 %516
  %531 = bitcast i8* %530 to double*
  %532 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %531, i32 64)
  %533 = getelementptr inbounds i8, i8* %getch.i2518, i64 %522
  %534 = bitcast i8* %533 to double*
  %535 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %534, i32 64)
  %536 = fsub reassoc ninf nsz double %535, %532
  %537 = fsub reassoc ninf nsz double %525, %519
  %538 = fsub reassoc ninf nsz double %175, %519
  %539 = fmul reassoc ninf nsz double %536, %538
  %540 = fdiv reassoc ninf nsz double %539, %537
  %541 = fadd reassoc ninf nsz double %540, %532
  br label %after_if175

true_block185:                                    ; preds = %after_if175
  %542 = add i32 %180, 12
  %543 = sext i32 %542 to i64
  %544 = shl nsw i64 %543, 3
  %545 = getelementptr inbounds i8, i8* %getch.i2533, i64 %544
  %546 = bitcast i8* %545 to double*
  %547 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %546, i32 64)
  %548 = add i32 %180, 13
  %549 = sext i32 %548 to i64
  %550 = shl nsw i64 %549, 3
  %551 = getelementptr inbounds i8, i8* %getch.i2533, i64 %550
  %552 = bitcast i8* %551 to double*
  %553 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %552, i32 64)
  %554 = fcmp reassoc ninf nsz oge double %175, %547
  %555 = fcmp reassoc ninf nsz ole double %175, %553
  %.01143 = select i1 %554, i1 %555, i1 false
  br i1 %.01143, label %true_block191, label %after_if187

after_if187:                                      ; preds = %true_block191, %true_block185, %after_if175
  %.131184 = phi double [ %569, %true_block191 ], [ %.121183, %true_block185 ], [ %.121183, %after_if175 ]
  %.12 = phi i1 [ true, %true_block191 ], [ %.11, %true_block185 ], [ %.11, %after_if175 ]
  %556 = icmp ugt i32 %201, 13
  %557 = xor i1 %.12, true
  %spec.select1839 = select i1 %556, i1 %557, i1 false
  br i1 %spec.select1839, label %true_block197, label %after_if199

true_block191:                                    ; preds = %true_block185
  %getch.i2517 = getelementptr i8, i8* %12, i64 418612680
  %558 = getelementptr inbounds i8, i8* %getch.i2517, i64 %544
  %559 = bitcast i8* %558 to double*
  %560 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %559, i32 64)
  %561 = getelementptr inbounds i8, i8* %getch.i2517, i64 %550
  %562 = bitcast i8* %561 to double*
  %563 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %562, i32 64)
  %564 = fsub reassoc ninf nsz double %563, %560
  %565 = fsub reassoc ninf nsz double %553, %547
  %566 = fsub reassoc ninf nsz double %175, %547
  %567 = fmul reassoc ninf nsz double %564, %566
  %568 = fdiv reassoc ninf nsz double %567, %565
  %569 = fadd reassoc ninf nsz double %568, %560
  br label %after_if187

true_block197:                                    ; preds = %after_if187
  %570 = add i32 %180, 13
  %571 = sext i32 %570 to i64
  %572 = shl nsw i64 %571, 3
  %573 = getelementptr inbounds i8, i8* %getch.i2533, i64 %572
  %574 = bitcast i8* %573 to double*
  %575 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %574, i32 64)
  %576 = add i32 %180, 14
  %577 = sext i32 %576 to i64
  %578 = shl nsw i64 %577, 3
  %579 = getelementptr inbounds i8, i8* %getch.i2533, i64 %578
  %580 = bitcast i8* %579 to double*
  %581 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %580, i32 64)
  %582 = fcmp reassoc ninf nsz oge double %175, %575
  %583 = fcmp reassoc ninf nsz ole double %175, %581
  %.01141 = select i1 %582, i1 %583, i1 false
  br i1 %.01141, label %true_block203, label %after_if199

after_if199:                                      ; preds = %true_block203, %true_block197, %after_if187
  %.141185 = phi double [ %597, %true_block203 ], [ %.131184, %true_block197 ], [ %.131184, %after_if187 ]
  %.13 = phi i1 [ true, %true_block203 ], [ %.12, %true_block197 ], [ %.12, %after_if187 ]
  %584 = icmp ugt i32 %201, 14
  %585 = xor i1 %.13, true
  %spec.select1840 = select i1 %584, i1 %585, i1 false
  br i1 %spec.select1840, label %true_block209, label %after_if211

true_block203:                                    ; preds = %true_block197
  %getch.i2516 = getelementptr i8, i8* %12, i64 418612680
  %586 = getelementptr inbounds i8, i8* %getch.i2516, i64 %572
  %587 = bitcast i8* %586 to double*
  %588 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %587, i32 64)
  %589 = getelementptr inbounds i8, i8* %getch.i2516, i64 %578
  %590 = bitcast i8* %589 to double*
  %591 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %590, i32 64)
  %592 = fsub reassoc ninf nsz double %591, %588
  %593 = fsub reassoc ninf nsz double %581, %575
  %594 = fsub reassoc ninf nsz double %175, %575
  %595 = fmul reassoc ninf nsz double %592, %594
  %596 = fdiv reassoc ninf nsz double %595, %593
  %597 = fadd reassoc ninf nsz double %596, %588
  br label %after_if199

true_block209:                                    ; preds = %after_if199
  %598 = add i32 %180, 14
  %599 = sext i32 %598 to i64
  %600 = shl nsw i64 %599, 3
  %601 = getelementptr inbounds i8, i8* %getch.i2533, i64 %600
  %602 = bitcast i8* %601 to double*
  %603 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %602, i32 64)
  %604 = add i32 %180, 15
  %605 = sext i32 %604 to i64
  %606 = shl nsw i64 %605, 3
  %607 = getelementptr inbounds i8, i8* %getch.i2533, i64 %606
  %608 = bitcast i8* %607 to double*
  %609 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %608, i32 64)
  %610 = fcmp reassoc ninf nsz oge double %175, %603
  %611 = fcmp reassoc ninf nsz ole double %175, %609
  %.01139 = select i1 %610, i1 %611, i1 false
  br i1 %.01139, label %true_block215, label %after_if211

after_if211:                                      ; preds = %true_block215, %true_block209, %after_if199
  %.151186 = phi double [ %625, %true_block215 ], [ %.141185, %true_block209 ], [ %.141185, %after_if199 ]
  %.14 = phi i1 [ true, %true_block215 ], [ %.13, %true_block209 ], [ %.13, %after_if199 ]
  %612 = icmp ugt i32 %201, 15
  %613 = xor i1 %.14, true
  %spec.select1841 = select i1 %612, i1 %613, i1 false
  br i1 %spec.select1841, label %true_block221, label %after_if223

true_block215:                                    ; preds = %true_block209
  %getch.i2515 = getelementptr i8, i8* %12, i64 418612680
  %614 = getelementptr inbounds i8, i8* %getch.i2515, i64 %600
  %615 = bitcast i8* %614 to double*
  %616 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %615, i32 64)
  %617 = getelementptr inbounds i8, i8* %getch.i2515, i64 %606
  %618 = bitcast i8* %617 to double*
  %619 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %618, i32 64)
  %620 = fsub reassoc ninf nsz double %619, %616
  %621 = fsub reassoc ninf nsz double %609, %603
  %622 = fsub reassoc ninf nsz double %175, %603
  %623 = fmul reassoc ninf nsz double %620, %622
  %624 = fdiv reassoc ninf nsz double %623, %621
  %625 = fadd reassoc ninf nsz double %624, %616
  br label %after_if211

true_block221:                                    ; preds = %after_if211
  %626 = add i32 %180, 15
  %627 = sext i32 %626 to i64
  %628 = shl nsw i64 %627, 3
  %629 = getelementptr inbounds i8, i8* %getch.i2533, i64 %628
  %630 = bitcast i8* %629 to double*
  %631 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %630, i32 64)
  %632 = add i32 %180, 16
  %633 = sext i32 %632 to i64
  %634 = shl nsw i64 %633, 3
  %635 = getelementptr inbounds i8, i8* %getch.i2533, i64 %634
  %636 = bitcast i8* %635 to double*
  %637 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %636, i32 64)
  %638 = fcmp reassoc ninf nsz oge double %175, %631
  %639 = fcmp reassoc ninf nsz ole double %175, %637
  %.01137 = select i1 %638, i1 %639, i1 false
  br i1 %.01137, label %true_block227, label %after_if223

after_if223:                                      ; preds = %true_block227, %true_block221, %after_if211
  %.161187 = phi double [ %653, %true_block227 ], [ %.151186, %true_block221 ], [ %.151186, %after_if211 ]
  %.15 = phi i1 [ true, %true_block227 ], [ %.14, %true_block221 ], [ %.14, %after_if211 ]
  %640 = icmp ugt i32 %201, 16
  %641 = xor i1 %.15, true
  %spec.select1842 = select i1 %640, i1 %641, i1 false
  br i1 %spec.select1842, label %true_block233, label %after_if235

true_block227:                                    ; preds = %true_block221
  %getch.i2514 = getelementptr i8, i8* %12, i64 418612680
  %642 = getelementptr inbounds i8, i8* %getch.i2514, i64 %628
  %643 = bitcast i8* %642 to double*
  %644 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %643, i32 64)
  %645 = getelementptr inbounds i8, i8* %getch.i2514, i64 %634
  %646 = bitcast i8* %645 to double*
  %647 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %646, i32 64)
  %648 = fsub reassoc ninf nsz double %647, %644
  %649 = fsub reassoc ninf nsz double %637, %631
  %650 = fsub reassoc ninf nsz double %175, %631
  %651 = fmul reassoc ninf nsz double %648, %650
  %652 = fdiv reassoc ninf nsz double %651, %649
  %653 = fadd reassoc ninf nsz double %652, %644
  br label %after_if223

true_block233:                                    ; preds = %after_if223
  %654 = add i32 %180, 16
  %655 = sext i32 %654 to i64
  %656 = shl nsw i64 %655, 3
  %657 = getelementptr inbounds i8, i8* %getch.i2533, i64 %656
  %658 = bitcast i8* %657 to double*
  %659 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %658, i32 64)
  %660 = add i32 %180, 17
  %661 = sext i32 %660 to i64
  %662 = shl nsw i64 %661, 3
  %663 = getelementptr inbounds i8, i8* %getch.i2533, i64 %662
  %664 = bitcast i8* %663 to double*
  %665 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %664, i32 64)
  %666 = fcmp reassoc ninf nsz oge double %175, %659
  %667 = fcmp reassoc ninf nsz ole double %175, %665
  %.01135 = select i1 %666, i1 %667, i1 false
  br i1 %.01135, label %true_block239, label %after_if235

after_if235:                                      ; preds = %true_block239, %true_block233, %after_if223
  %.171188 = phi double [ %681, %true_block239 ], [ %.161187, %true_block233 ], [ %.161187, %after_if223 ]
  %.16 = phi i1 [ true, %true_block239 ], [ %.15, %true_block233 ], [ %.15, %after_if223 ]
  %668 = icmp ugt i32 %201, 17
  %669 = xor i1 %.16, true
  %spec.select1843 = select i1 %668, i1 %669, i1 false
  br i1 %spec.select1843, label %true_block245, label %after_if247

true_block239:                                    ; preds = %true_block233
  %getch.i2513 = getelementptr i8, i8* %12, i64 418612680
  %670 = getelementptr inbounds i8, i8* %getch.i2513, i64 %656
  %671 = bitcast i8* %670 to double*
  %672 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %671, i32 64)
  %673 = getelementptr inbounds i8, i8* %getch.i2513, i64 %662
  %674 = bitcast i8* %673 to double*
  %675 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %674, i32 64)
  %676 = fsub reassoc ninf nsz double %675, %672
  %677 = fsub reassoc ninf nsz double %665, %659
  %678 = fsub reassoc ninf nsz double %175, %659
  %679 = fmul reassoc ninf nsz double %676, %678
  %680 = fdiv reassoc ninf nsz double %679, %677
  %681 = fadd reassoc ninf nsz double %680, %672
  br label %after_if235

true_block245:                                    ; preds = %after_if235
  %682 = add i32 %180, 17
  %683 = sext i32 %682 to i64
  %684 = shl nsw i64 %683, 3
  %685 = getelementptr inbounds i8, i8* %getch.i2533, i64 %684
  %686 = bitcast i8* %685 to double*
  %687 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %686, i32 64)
  %688 = add i32 %180, 18
  %689 = sext i32 %688 to i64
  %690 = shl nsw i64 %689, 3
  %691 = getelementptr inbounds i8, i8* %getch.i2533, i64 %690
  %692 = bitcast i8* %691 to double*
  %693 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %692, i32 64)
  %694 = fcmp reassoc ninf nsz oge double %175, %687
  %695 = fcmp reassoc ninf nsz ole double %175, %693
  %.01133 = select i1 %694, i1 %695, i1 false
  br i1 %.01133, label %true_block251, label %after_if247

after_if247:                                      ; preds = %true_block251, %true_block245, %after_if235
  %.181189 = phi double [ %709, %true_block251 ], [ %.171188, %true_block245 ], [ %.171188, %after_if235 ]
  %.17 = phi i1 [ true, %true_block251 ], [ %.16, %true_block245 ], [ %.16, %after_if235 ]
  %696 = icmp ugt i32 %201, 18
  %697 = xor i1 %.17, true
  %spec.select1844 = select i1 %696, i1 %697, i1 false
  br i1 %spec.select1844, label %true_block257, label %after_if259

true_block251:                                    ; preds = %true_block245
  %getch.i2512 = getelementptr i8, i8* %12, i64 418612680
  %698 = getelementptr inbounds i8, i8* %getch.i2512, i64 %684
  %699 = bitcast i8* %698 to double*
  %700 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %699, i32 64)
  %701 = getelementptr inbounds i8, i8* %getch.i2512, i64 %690
  %702 = bitcast i8* %701 to double*
  %703 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %702, i32 64)
  %704 = fsub reassoc ninf nsz double %703, %700
  %705 = fsub reassoc ninf nsz double %693, %687
  %706 = fsub reassoc ninf nsz double %175, %687
  %707 = fmul reassoc ninf nsz double %704, %706
  %708 = fdiv reassoc ninf nsz double %707, %705
  %709 = fadd reassoc ninf nsz double %708, %700
  br label %after_if247

true_block257:                                    ; preds = %after_if247
  %710 = add i32 %180, 18
  %711 = sext i32 %710 to i64
  %712 = shl nsw i64 %711, 3
  %713 = getelementptr inbounds i8, i8* %getch.i2533, i64 %712
  %714 = bitcast i8* %713 to double*
  %715 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %714, i32 64)
  %716 = add i32 %180, 19
  %717 = sext i32 %716 to i64
  %718 = shl nsw i64 %717, 3
  %719 = getelementptr inbounds i8, i8* %getch.i2533, i64 %718
  %720 = bitcast i8* %719 to double*
  %721 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %720, i32 64)
  %722 = fcmp reassoc ninf nsz oge double %175, %715
  %723 = fcmp reassoc ninf nsz ole double %175, %721
  %.01131 = select i1 %722, i1 %723, i1 false
  br i1 %.01131, label %true_block263, label %after_if259

after_if259:                                      ; preds = %true_block263, %true_block257, %after_if247
  %.191190 = phi double [ %737, %true_block263 ], [ %.181189, %true_block257 ], [ %.181189, %after_if247 ]
  %.18 = phi i1 [ true, %true_block263 ], [ %.17, %true_block257 ], [ %.17, %after_if247 ]
  %724 = icmp ugt i32 %201, 19
  %725 = xor i1 %.18, true
  %spec.select1845 = select i1 %724, i1 %725, i1 false
  br i1 %spec.select1845, label %true_block269, label %after_if271

true_block263:                                    ; preds = %true_block257
  %getch.i2511 = getelementptr i8, i8* %12, i64 418612680
  %726 = getelementptr inbounds i8, i8* %getch.i2511, i64 %712
  %727 = bitcast i8* %726 to double*
  %728 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %727, i32 64)
  %729 = getelementptr inbounds i8, i8* %getch.i2511, i64 %718
  %730 = bitcast i8* %729 to double*
  %731 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %730, i32 64)
  %732 = fsub reassoc ninf nsz double %731, %728
  %733 = fsub reassoc ninf nsz double %721, %715
  %734 = fsub reassoc ninf nsz double %175, %715
  %735 = fmul reassoc ninf nsz double %732, %734
  %736 = fdiv reassoc ninf nsz double %735, %733
  %737 = fadd reassoc ninf nsz double %736, %728
  br label %after_if259

true_block269:                                    ; preds = %after_if259
  %738 = add i32 %180, 19
  %739 = sext i32 %738 to i64
  %740 = shl nsw i64 %739, 3
  %741 = getelementptr inbounds i8, i8* %getch.i2533, i64 %740
  %742 = bitcast i8* %741 to double*
  %743 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %742, i32 64)
  %744 = add i32 %180, 20
  %745 = sext i32 %744 to i64
  %746 = shl nsw i64 %745, 3
  %747 = getelementptr inbounds i8, i8* %getch.i2533, i64 %746
  %748 = bitcast i8* %747 to double*
  %749 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %748, i32 64)
  %750 = fcmp reassoc ninf nsz oge double %175, %743
  %751 = fcmp reassoc ninf nsz ole double %175, %749
  %.01129 = select i1 %750, i1 %751, i1 false
  br i1 %.01129, label %true_block275, label %after_if271

after_if271:                                      ; preds = %true_block275, %true_block269, %after_if259
  %.201191 = phi double [ %765, %true_block275 ], [ %.191190, %true_block269 ], [ %.191190, %after_if259 ]
  %.19 = phi i1 [ true, %true_block275 ], [ %.18, %true_block269 ], [ %.18, %after_if259 ]
  %752 = icmp ugt i32 %201, 20
  %753 = xor i1 %.19, true
  %spec.select1846 = select i1 %752, i1 %753, i1 false
  br i1 %spec.select1846, label %true_block281, label %after_if283

true_block275:                                    ; preds = %true_block269
  %getch.i2510 = getelementptr i8, i8* %12, i64 418612680
  %754 = getelementptr inbounds i8, i8* %getch.i2510, i64 %740
  %755 = bitcast i8* %754 to double*
  %756 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %755, i32 64)
  %757 = getelementptr inbounds i8, i8* %getch.i2510, i64 %746
  %758 = bitcast i8* %757 to double*
  %759 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %758, i32 64)
  %760 = fsub reassoc ninf nsz double %759, %756
  %761 = fsub reassoc ninf nsz double %749, %743
  %762 = fsub reassoc ninf nsz double %175, %743
  %763 = fmul reassoc ninf nsz double %760, %762
  %764 = fdiv reassoc ninf nsz double %763, %761
  %765 = fadd reassoc ninf nsz double %764, %756
  br label %after_if271

true_block281:                                    ; preds = %after_if271
  %766 = add i32 %180, 20
  %767 = sext i32 %766 to i64
  %768 = shl nsw i64 %767, 3
  %769 = getelementptr inbounds i8, i8* %getch.i2533, i64 %768
  %770 = bitcast i8* %769 to double*
  %771 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %770, i32 64)
  %772 = add i32 %180, 21
  %773 = sext i32 %772 to i64
  %774 = shl nsw i64 %773, 3
  %775 = getelementptr inbounds i8, i8* %getch.i2533, i64 %774
  %776 = bitcast i8* %775 to double*
  %777 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %776, i32 64)
  %778 = fcmp reassoc ninf nsz oge double %175, %771
  %779 = fcmp reassoc ninf nsz ole double %175, %777
  %.01127 = select i1 %778, i1 %779, i1 false
  br i1 %.01127, label %true_block287, label %after_if283

after_if283:                                      ; preds = %true_block287, %true_block281, %after_if271
  %.211192 = phi double [ %793, %true_block287 ], [ %.201191, %true_block281 ], [ %.201191, %after_if271 ]
  %.20 = phi i1 [ true, %true_block287 ], [ %.19, %true_block281 ], [ %.19, %after_if271 ]
  %780 = icmp ugt i32 %201, 21
  %781 = xor i1 %.20, true
  %spec.select1847 = select i1 %780, i1 %781, i1 false
  br i1 %spec.select1847, label %true_block293, label %after_if295

true_block287:                                    ; preds = %true_block281
  %getch.i2509 = getelementptr i8, i8* %12, i64 418612680
  %782 = getelementptr inbounds i8, i8* %getch.i2509, i64 %768
  %783 = bitcast i8* %782 to double*
  %784 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %783, i32 64)
  %785 = getelementptr inbounds i8, i8* %getch.i2509, i64 %774
  %786 = bitcast i8* %785 to double*
  %787 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %786, i32 64)
  %788 = fsub reassoc ninf nsz double %787, %784
  %789 = fsub reassoc ninf nsz double %777, %771
  %790 = fsub reassoc ninf nsz double %175, %771
  %791 = fmul reassoc ninf nsz double %788, %790
  %792 = fdiv reassoc ninf nsz double %791, %789
  %793 = fadd reassoc ninf nsz double %792, %784
  br label %after_if283

true_block293:                                    ; preds = %after_if283
  %794 = add i32 %180, 21
  %795 = sext i32 %794 to i64
  %796 = shl nsw i64 %795, 3
  %797 = getelementptr inbounds i8, i8* %getch.i2533, i64 %796
  %798 = bitcast i8* %797 to double*
  %799 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %798, i32 64)
  %800 = add i32 %180, 22
  %801 = sext i32 %800 to i64
  %802 = shl nsw i64 %801, 3
  %803 = getelementptr inbounds i8, i8* %getch.i2533, i64 %802
  %804 = bitcast i8* %803 to double*
  %805 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %804, i32 64)
  %806 = fcmp reassoc ninf nsz oge double %175, %799
  %807 = fcmp reassoc ninf nsz ole double %175, %805
  %.01125 = select i1 %806, i1 %807, i1 false
  br i1 %.01125, label %true_block299, label %after_if295

after_if295:                                      ; preds = %true_block299, %true_block293, %after_if283
  %.221193 = phi double [ %821, %true_block299 ], [ %.211192, %true_block293 ], [ %.211192, %after_if283 ]
  %.21 = phi i1 [ true, %true_block299 ], [ %.20, %true_block293 ], [ %.20, %after_if283 ]
  %808 = icmp ugt i32 %201, 22
  %809 = xor i1 %.21, true
  %spec.select1848 = select i1 %808, i1 %809, i1 false
  br i1 %spec.select1848, label %true_block305, label %after_if307

true_block299:                                    ; preds = %true_block293
  %getch.i2508 = getelementptr i8, i8* %12, i64 418612680
  %810 = getelementptr inbounds i8, i8* %getch.i2508, i64 %796
  %811 = bitcast i8* %810 to double*
  %812 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %811, i32 64)
  %813 = getelementptr inbounds i8, i8* %getch.i2508, i64 %802
  %814 = bitcast i8* %813 to double*
  %815 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %814, i32 64)
  %816 = fsub reassoc ninf nsz double %815, %812
  %817 = fsub reassoc ninf nsz double %805, %799
  %818 = fsub reassoc ninf nsz double %175, %799
  %819 = fmul reassoc ninf nsz double %816, %818
  %820 = fdiv reassoc ninf nsz double %819, %817
  %821 = fadd reassoc ninf nsz double %820, %812
  br label %after_if295

true_block305:                                    ; preds = %after_if295
  %822 = add i32 %180, 22
  %823 = sext i32 %822 to i64
  %824 = shl nsw i64 %823, 3
  %825 = getelementptr inbounds i8, i8* %getch.i2533, i64 %824
  %826 = bitcast i8* %825 to double*
  %827 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %826, i32 64)
  %828 = add i32 %180, 23
  %829 = sext i32 %828 to i64
  %830 = shl nsw i64 %829, 3
  %831 = getelementptr inbounds i8, i8* %getch.i2533, i64 %830
  %832 = bitcast i8* %831 to double*
  %833 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %832, i32 64)
  %834 = fcmp reassoc ninf nsz oge double %175, %827
  %835 = fcmp reassoc ninf nsz ole double %175, %833
  %.01123 = select i1 %834, i1 %835, i1 false
  br i1 %.01123, label %true_block311, label %after_if307

after_if307:                                      ; preds = %true_block311, %true_block305, %after_if295
  %.231194 = phi double [ %849, %true_block311 ], [ %.221193, %true_block305 ], [ %.221193, %after_if295 ]
  %.22 = phi i1 [ true, %true_block311 ], [ %.21, %true_block305 ], [ %.21, %after_if295 ]
  %836 = icmp ugt i32 %201, 23
  %837 = xor i1 %.22, true
  %spec.select1849 = select i1 %836, i1 %837, i1 false
  br i1 %spec.select1849, label %true_block317, label %after_if319

true_block311:                                    ; preds = %true_block305
  %getch.i2507 = getelementptr i8, i8* %12, i64 418612680
  %838 = getelementptr inbounds i8, i8* %getch.i2507, i64 %824
  %839 = bitcast i8* %838 to double*
  %840 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %839, i32 64)
  %841 = getelementptr inbounds i8, i8* %getch.i2507, i64 %830
  %842 = bitcast i8* %841 to double*
  %843 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %842, i32 64)
  %844 = fsub reassoc ninf nsz double %843, %840
  %845 = fsub reassoc ninf nsz double %833, %827
  %846 = fsub reassoc ninf nsz double %175, %827
  %847 = fmul reassoc ninf nsz double %844, %846
  %848 = fdiv reassoc ninf nsz double %847, %845
  %849 = fadd reassoc ninf nsz double %848, %840
  br label %after_if307

true_block317:                                    ; preds = %after_if307
  %850 = add i32 %180, 23
  %851 = sext i32 %850 to i64
  %852 = shl nsw i64 %851, 3
  %853 = getelementptr inbounds i8, i8* %getch.i2533, i64 %852
  %854 = bitcast i8* %853 to double*
  %855 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %854, i32 64)
  %856 = add i32 %180, 24
  %857 = sext i32 %856 to i64
  %858 = shl nsw i64 %857, 3
  %859 = getelementptr inbounds i8, i8* %getch.i2533, i64 %858
  %860 = bitcast i8* %859 to double*
  %861 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %860, i32 64)
  %862 = fcmp reassoc ninf nsz oge double %175, %855
  %863 = fcmp reassoc ninf nsz ole double %175, %861
  %.01121 = select i1 %862, i1 %863, i1 false
  br i1 %.01121, label %true_block323, label %after_if319

after_if319:                                      ; preds = %true_block323, %true_block317, %after_if307
  %.241195 = phi double [ %877, %true_block323 ], [ %.231194, %true_block317 ], [ %.231194, %after_if307 ]
  %.23 = phi i1 [ true, %true_block323 ], [ %.22, %true_block317 ], [ %.22, %after_if307 ]
  %864 = icmp ugt i32 %201, 24
  %865 = xor i1 %.23, true
  %spec.select1850 = select i1 %864, i1 %865, i1 false
  br i1 %spec.select1850, label %true_block329, label %after_if331

true_block323:                                    ; preds = %true_block317
  %getch.i2506 = getelementptr i8, i8* %12, i64 418612680
  %866 = getelementptr inbounds i8, i8* %getch.i2506, i64 %852
  %867 = bitcast i8* %866 to double*
  %868 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %867, i32 64)
  %869 = getelementptr inbounds i8, i8* %getch.i2506, i64 %858
  %870 = bitcast i8* %869 to double*
  %871 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %870, i32 64)
  %872 = fsub reassoc ninf nsz double %871, %868
  %873 = fsub reassoc ninf nsz double %861, %855
  %874 = fsub reassoc ninf nsz double %175, %855
  %875 = fmul reassoc ninf nsz double %872, %874
  %876 = fdiv reassoc ninf nsz double %875, %873
  %877 = fadd reassoc ninf nsz double %876, %868
  br label %after_if319

true_block329:                                    ; preds = %after_if319
  %878 = add i32 %180, 24
  %879 = sext i32 %878 to i64
  %880 = shl nsw i64 %879, 3
  %881 = getelementptr inbounds i8, i8* %getch.i2533, i64 %880
  %882 = bitcast i8* %881 to double*
  %883 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %882, i32 64)
  %884 = add i32 %180, 25
  %885 = sext i32 %884 to i64
  %886 = shl nsw i64 %885, 3
  %887 = getelementptr inbounds i8, i8* %getch.i2533, i64 %886
  %888 = bitcast i8* %887 to double*
  %889 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %888, i32 64)
  %890 = fcmp reassoc ninf nsz oge double %175, %883
  %891 = fcmp reassoc ninf nsz ole double %175, %889
  %.01119 = select i1 %890, i1 %891, i1 false
  br i1 %.01119, label %true_block335, label %after_if331

after_if331:                                      ; preds = %true_block335, %true_block329, %after_if319
  %.251196 = phi double [ %905, %true_block335 ], [ %.241195, %true_block329 ], [ %.241195, %after_if319 ]
  %.24 = phi i1 [ true, %true_block335 ], [ %.23, %true_block329 ], [ %.23, %after_if319 ]
  %892 = icmp ugt i32 %201, 25
  %893 = xor i1 %.24, true
  %spec.select1851 = select i1 %892, i1 %893, i1 false
  br i1 %spec.select1851, label %true_block341, label %after_if343

true_block335:                                    ; preds = %true_block329
  %getch.i2505 = getelementptr i8, i8* %12, i64 418612680
  %894 = getelementptr inbounds i8, i8* %getch.i2505, i64 %880
  %895 = bitcast i8* %894 to double*
  %896 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %895, i32 64)
  %897 = getelementptr inbounds i8, i8* %getch.i2505, i64 %886
  %898 = bitcast i8* %897 to double*
  %899 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %898, i32 64)
  %900 = fsub reassoc ninf nsz double %899, %896
  %901 = fsub reassoc ninf nsz double %889, %883
  %902 = fsub reassoc ninf nsz double %175, %883
  %903 = fmul reassoc ninf nsz double %900, %902
  %904 = fdiv reassoc ninf nsz double %903, %901
  %905 = fadd reassoc ninf nsz double %904, %896
  br label %after_if331

true_block341:                                    ; preds = %after_if331
  %906 = add i32 %180, 25
  %907 = sext i32 %906 to i64
  %908 = shl nsw i64 %907, 3
  %909 = getelementptr inbounds i8, i8* %getch.i2533, i64 %908
  %910 = bitcast i8* %909 to double*
  %911 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %910, i32 64)
  %912 = add i32 %180, 26
  %913 = sext i32 %912 to i64
  %914 = shl nsw i64 %913, 3
  %915 = getelementptr inbounds i8, i8* %getch.i2533, i64 %914
  %916 = bitcast i8* %915 to double*
  %917 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %916, i32 64)
  %918 = fcmp reassoc ninf nsz oge double %175, %911
  %919 = fcmp reassoc ninf nsz ole double %175, %917
  %.01117 = select i1 %918, i1 %919, i1 false
  br i1 %.01117, label %true_block347, label %after_if343

after_if343:                                      ; preds = %true_block347, %true_block341, %after_if331
  %.261197 = phi double [ %933, %true_block347 ], [ %.251196, %true_block341 ], [ %.251196, %after_if331 ]
  %.25 = phi i1 [ true, %true_block347 ], [ %.24, %true_block341 ], [ %.24, %after_if331 ]
  %920 = icmp ugt i32 %201, 26
  %921 = xor i1 %.25, true
  %spec.select1852 = select i1 %920, i1 %921, i1 false
  br i1 %spec.select1852, label %true_block353, label %after_if355

true_block347:                                    ; preds = %true_block341
  %getch.i2504 = getelementptr i8, i8* %12, i64 418612680
  %922 = getelementptr inbounds i8, i8* %getch.i2504, i64 %908
  %923 = bitcast i8* %922 to double*
  %924 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %923, i32 64)
  %925 = getelementptr inbounds i8, i8* %getch.i2504, i64 %914
  %926 = bitcast i8* %925 to double*
  %927 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %926, i32 64)
  %928 = fsub reassoc ninf nsz double %927, %924
  %929 = fsub reassoc ninf nsz double %917, %911
  %930 = fsub reassoc ninf nsz double %175, %911
  %931 = fmul reassoc ninf nsz double %928, %930
  %932 = fdiv reassoc ninf nsz double %931, %929
  %933 = fadd reassoc ninf nsz double %932, %924
  br label %after_if343

true_block353:                                    ; preds = %after_if343
  %934 = add i32 %180, 26
  %935 = sext i32 %934 to i64
  %936 = shl nsw i64 %935, 3
  %937 = getelementptr inbounds i8, i8* %getch.i2533, i64 %936
  %938 = bitcast i8* %937 to double*
  %939 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %938, i32 64)
  %940 = add i32 %180, 27
  %941 = sext i32 %940 to i64
  %942 = shl nsw i64 %941, 3
  %943 = getelementptr inbounds i8, i8* %getch.i2533, i64 %942
  %944 = bitcast i8* %943 to double*
  %945 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %944, i32 64)
  %946 = fcmp reassoc ninf nsz oge double %175, %939
  %947 = fcmp reassoc ninf nsz ole double %175, %945
  %.01115 = select i1 %946, i1 %947, i1 false
  br i1 %.01115, label %true_block359, label %after_if355

after_if355:                                      ; preds = %true_block359, %true_block353, %after_if343
  %.271198 = phi double [ %961, %true_block359 ], [ %.261197, %true_block353 ], [ %.261197, %after_if343 ]
  %.26 = phi i1 [ true, %true_block359 ], [ %.25, %true_block353 ], [ %.25, %after_if343 ]
  %948 = icmp ugt i32 %201, 27
  %949 = xor i1 %.26, true
  %spec.select1853 = select i1 %948, i1 %949, i1 false
  br i1 %spec.select1853, label %true_block365, label %after_if367

true_block359:                                    ; preds = %true_block353
  %getch.i2503 = getelementptr i8, i8* %12, i64 418612680
  %950 = getelementptr inbounds i8, i8* %getch.i2503, i64 %936
  %951 = bitcast i8* %950 to double*
  %952 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %951, i32 64)
  %953 = getelementptr inbounds i8, i8* %getch.i2503, i64 %942
  %954 = bitcast i8* %953 to double*
  %955 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %954, i32 64)
  %956 = fsub reassoc ninf nsz double %955, %952
  %957 = fsub reassoc ninf nsz double %945, %939
  %958 = fsub reassoc ninf nsz double %175, %939
  %959 = fmul reassoc ninf nsz double %956, %958
  %960 = fdiv reassoc ninf nsz double %959, %957
  %961 = fadd reassoc ninf nsz double %960, %952
  br label %after_if355

true_block365:                                    ; preds = %after_if355
  %962 = add i32 %180, 27
  %963 = sext i32 %962 to i64
  %964 = shl nsw i64 %963, 3
  %965 = getelementptr inbounds i8, i8* %getch.i2533, i64 %964
  %966 = bitcast i8* %965 to double*
  %967 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %966, i32 64)
  %968 = add i32 %180, 28
  %969 = sext i32 %968 to i64
  %970 = shl nsw i64 %969, 3
  %971 = getelementptr inbounds i8, i8* %getch.i2533, i64 %970
  %972 = bitcast i8* %971 to double*
  %973 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %972, i32 64)
  %974 = fcmp reassoc ninf nsz oge double %175, %967
  %975 = fcmp reassoc ninf nsz ole double %175, %973
  %.01113 = select i1 %974, i1 %975, i1 false
  br i1 %.01113, label %true_block371, label %after_if367

after_if367:                                      ; preds = %true_block371, %true_block365, %after_if355
  %.281199 = phi double [ %989, %true_block371 ], [ %.271198, %true_block365 ], [ %.271198, %after_if355 ]
  %.27 = phi i1 [ true, %true_block371 ], [ %.26, %true_block365 ], [ %.26, %after_if355 ]
  %976 = icmp ugt i32 %201, 28
  %977 = xor i1 %.27, true
  %spec.select1854 = select i1 %976, i1 %977, i1 false
  br i1 %spec.select1854, label %true_block377, label %after_if379

true_block371:                                    ; preds = %true_block365
  %getch.i2502 = getelementptr i8, i8* %12, i64 418612680
  %978 = getelementptr inbounds i8, i8* %getch.i2502, i64 %964
  %979 = bitcast i8* %978 to double*
  %980 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %979, i32 64)
  %981 = getelementptr inbounds i8, i8* %getch.i2502, i64 %970
  %982 = bitcast i8* %981 to double*
  %983 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %982, i32 64)
  %984 = fsub reassoc ninf nsz double %983, %980
  %985 = fsub reassoc ninf nsz double %973, %967
  %986 = fsub reassoc ninf nsz double %175, %967
  %987 = fmul reassoc ninf nsz double %984, %986
  %988 = fdiv reassoc ninf nsz double %987, %985
  %989 = fadd reassoc ninf nsz double %988, %980
  br label %after_if367

true_block377:                                    ; preds = %after_if367
  %990 = add i32 %180, 28
  %991 = sext i32 %990 to i64
  %992 = shl nsw i64 %991, 3
  %993 = getelementptr inbounds i8, i8* %getch.i2533, i64 %992
  %994 = bitcast i8* %993 to double*
  %995 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %994, i32 64)
  %996 = add i32 %180, 29
  %997 = sext i32 %996 to i64
  %998 = shl nsw i64 %997, 3
  %999 = getelementptr inbounds i8, i8* %getch.i2533, i64 %998
  %1000 = bitcast i8* %999 to double*
  %1001 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1000, i32 64)
  %1002 = fcmp reassoc ninf nsz oge double %175, %995
  %1003 = fcmp reassoc ninf nsz ole double %175, %1001
  %.01111 = select i1 %1002, i1 %1003, i1 false
  br i1 %.01111, label %true_block383, label %after_if379

after_if379:                                      ; preds = %true_block383, %true_block377, %after_if367
  %.291200 = phi double [ %1017, %true_block383 ], [ %.281199, %true_block377 ], [ %.281199, %after_if367 ]
  %.28 = phi i1 [ true, %true_block383 ], [ %.27, %true_block377 ], [ %.27, %after_if367 ]
  %1004 = icmp ugt i32 %201, 29
  %1005 = xor i1 %.28, true
  %spec.select1855 = select i1 %1004, i1 %1005, i1 false
  br i1 %spec.select1855, label %true_block389, label %after_if391

true_block383:                                    ; preds = %true_block377
  %getch.i2501 = getelementptr i8, i8* %12, i64 418612680
  %1006 = getelementptr inbounds i8, i8* %getch.i2501, i64 %992
  %1007 = bitcast i8* %1006 to double*
  %1008 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1007, i32 64)
  %1009 = getelementptr inbounds i8, i8* %getch.i2501, i64 %998
  %1010 = bitcast i8* %1009 to double*
  %1011 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1010, i32 64)
  %1012 = fsub reassoc ninf nsz double %1011, %1008
  %1013 = fsub reassoc ninf nsz double %1001, %995
  %1014 = fsub reassoc ninf nsz double %175, %995
  %1015 = fmul reassoc ninf nsz double %1012, %1014
  %1016 = fdiv reassoc ninf nsz double %1015, %1013
  %1017 = fadd reassoc ninf nsz double %1016, %1008
  br label %after_if379

true_block389:                                    ; preds = %after_if379
  %1018 = add i32 %180, 29
  %1019 = sext i32 %1018 to i64
  %1020 = shl nsw i64 %1019, 3
  %1021 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1020
  %1022 = bitcast i8* %1021 to double*
  %1023 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1022, i32 64)
  %1024 = add i32 %180, 30
  %1025 = sext i32 %1024 to i64
  %1026 = shl nsw i64 %1025, 3
  %1027 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1026
  %1028 = bitcast i8* %1027 to double*
  %1029 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1028, i32 64)
  %1030 = fcmp reassoc ninf nsz oge double %175, %1023
  %1031 = fcmp reassoc ninf nsz ole double %175, %1029
  %.01109 = select i1 %1030, i1 %1031, i1 false
  br i1 %.01109, label %true_block395, label %after_if391

after_if391:                                      ; preds = %true_block395, %true_block389, %after_if379
  %.301201 = phi double [ %1045, %true_block395 ], [ %.291200, %true_block389 ], [ %.291200, %after_if379 ]
  %.29 = phi i1 [ true, %true_block395 ], [ %.28, %true_block389 ], [ %.28, %after_if379 ]
  %1032 = icmp ugt i32 %201, 30
  %1033 = xor i1 %.29, true
  %spec.select1856 = select i1 %1032, i1 %1033, i1 false
  br i1 %spec.select1856, label %true_block401, label %after_if403

true_block395:                                    ; preds = %true_block389
  %getch.i2500 = getelementptr i8, i8* %12, i64 418612680
  %1034 = getelementptr inbounds i8, i8* %getch.i2500, i64 %1020
  %1035 = bitcast i8* %1034 to double*
  %1036 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1035, i32 64)
  %1037 = getelementptr inbounds i8, i8* %getch.i2500, i64 %1026
  %1038 = bitcast i8* %1037 to double*
  %1039 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1038, i32 64)
  %1040 = fsub reassoc ninf nsz double %1039, %1036
  %1041 = fsub reassoc ninf nsz double %1029, %1023
  %1042 = fsub reassoc ninf nsz double %175, %1023
  %1043 = fmul reassoc ninf nsz double %1040, %1042
  %1044 = fdiv reassoc ninf nsz double %1043, %1041
  %1045 = fadd reassoc ninf nsz double %1044, %1036
  br label %after_if391

true_block401:                                    ; preds = %after_if391
  %1046 = add i32 %180, 30
  %1047 = sext i32 %1046 to i64
  %1048 = shl nsw i64 %1047, 3
  %1049 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1048
  %1050 = bitcast i8* %1049 to double*
  %1051 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1050, i32 64)
  %1052 = add i32 %180, 31
  %1053 = sext i32 %1052 to i64
  %1054 = shl nsw i64 %1053, 3
  %1055 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1054
  %1056 = bitcast i8* %1055 to double*
  %1057 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1056, i32 64)
  %1058 = fcmp reassoc ninf nsz oge double %175, %1051
  %1059 = fcmp reassoc ninf nsz ole double %175, %1057
  %.01107 = select i1 %1058, i1 %1059, i1 false
  br i1 %.01107, label %true_block407, label %after_if403

after_if403:                                      ; preds = %true_block407, %true_block401, %after_if391
  %.311202 = phi double [ %1073, %true_block407 ], [ %.301201, %true_block401 ], [ %.301201, %after_if391 ]
  %.30 = phi i1 [ true, %true_block407 ], [ %.29, %true_block401 ], [ %.29, %after_if391 ]
  %1060 = icmp ugt i32 %201, 31
  %1061 = xor i1 %.30, true
  %spec.select1857 = select i1 %1060, i1 %1061, i1 false
  br i1 %spec.select1857, label %true_block413, label %after_if415

true_block407:                                    ; preds = %true_block401
  %getch.i2499 = getelementptr i8, i8* %12, i64 418612680
  %1062 = getelementptr inbounds i8, i8* %getch.i2499, i64 %1048
  %1063 = bitcast i8* %1062 to double*
  %1064 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1063, i32 64)
  %1065 = getelementptr inbounds i8, i8* %getch.i2499, i64 %1054
  %1066 = bitcast i8* %1065 to double*
  %1067 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1066, i32 64)
  %1068 = fsub reassoc ninf nsz double %1067, %1064
  %1069 = fsub reassoc ninf nsz double %1057, %1051
  %1070 = fsub reassoc ninf nsz double %175, %1051
  %1071 = fmul reassoc ninf nsz double %1068, %1070
  %1072 = fdiv reassoc ninf nsz double %1071, %1069
  %1073 = fadd reassoc ninf nsz double %1072, %1064
  br label %after_if403

true_block413:                                    ; preds = %after_if403
  %1074 = add i32 %180, 31
  %1075 = sext i32 %1074 to i64
  %1076 = shl nsw i64 %1075, 3
  %1077 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1076
  %1078 = bitcast i8* %1077 to double*
  %1079 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1078, i32 64)
  %1080 = add i32 %180, 32
  %1081 = sext i32 %1080 to i64
  %1082 = shl nsw i64 %1081, 3
  %1083 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1082
  %1084 = bitcast i8* %1083 to double*
  %1085 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1084, i32 64)
  %1086 = fcmp reassoc ninf nsz oge double %175, %1079
  %1087 = fcmp reassoc ninf nsz ole double %175, %1085
  %.01105 = select i1 %1086, i1 %1087, i1 false
  br i1 %.01105, label %true_block419, label %after_if415

after_if415:                                      ; preds = %true_block419, %true_block413, %after_if403
  %.321203 = phi double [ %1101, %true_block419 ], [ %.311202, %true_block413 ], [ %.311202, %after_if403 ]
  %.31 = phi i1 [ true, %true_block419 ], [ %.30, %true_block413 ], [ %.30, %after_if403 ]
  %1088 = icmp ugt i32 %201, 32
  %1089 = xor i1 %.31, true
  %spec.select1858 = select i1 %1088, i1 %1089, i1 false
  br i1 %spec.select1858, label %true_block425, label %after_if427

true_block419:                                    ; preds = %true_block413
  %getch.i2498 = getelementptr i8, i8* %12, i64 418612680
  %1090 = getelementptr inbounds i8, i8* %getch.i2498, i64 %1076
  %1091 = bitcast i8* %1090 to double*
  %1092 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1091, i32 64)
  %1093 = getelementptr inbounds i8, i8* %getch.i2498, i64 %1082
  %1094 = bitcast i8* %1093 to double*
  %1095 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1094, i32 64)
  %1096 = fsub reassoc ninf nsz double %1095, %1092
  %1097 = fsub reassoc ninf nsz double %1085, %1079
  %1098 = fsub reassoc ninf nsz double %175, %1079
  %1099 = fmul reassoc ninf nsz double %1096, %1098
  %1100 = fdiv reassoc ninf nsz double %1099, %1097
  %1101 = fadd reassoc ninf nsz double %1100, %1092
  br label %after_if415

true_block425:                                    ; preds = %after_if415
  %1102 = add i32 %180, 32
  %1103 = sext i32 %1102 to i64
  %1104 = shl nsw i64 %1103, 3
  %1105 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1104
  %1106 = bitcast i8* %1105 to double*
  %1107 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1106, i32 64)
  %1108 = add i32 %180, 33
  %1109 = sext i32 %1108 to i64
  %1110 = shl nsw i64 %1109, 3
  %1111 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1110
  %1112 = bitcast i8* %1111 to double*
  %1113 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1112, i32 64)
  %1114 = fcmp reassoc ninf nsz oge double %175, %1107
  %1115 = fcmp reassoc ninf nsz ole double %175, %1113
  %.01103 = select i1 %1114, i1 %1115, i1 false
  br i1 %.01103, label %true_block431, label %after_if427

after_if427:                                      ; preds = %true_block431, %true_block425, %after_if415
  %.331204 = phi double [ %1129, %true_block431 ], [ %.321203, %true_block425 ], [ %.321203, %after_if415 ]
  %.32 = phi i1 [ true, %true_block431 ], [ %.31, %true_block425 ], [ %.31, %after_if415 ]
  %1116 = icmp ugt i32 %201, 33
  %1117 = xor i1 %.32, true
  %spec.select1859 = select i1 %1116, i1 %1117, i1 false
  br i1 %spec.select1859, label %true_block437, label %after_if439

true_block431:                                    ; preds = %true_block425
  %getch.i2497 = getelementptr i8, i8* %12, i64 418612680
  %1118 = getelementptr inbounds i8, i8* %getch.i2497, i64 %1104
  %1119 = bitcast i8* %1118 to double*
  %1120 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1119, i32 64)
  %1121 = getelementptr inbounds i8, i8* %getch.i2497, i64 %1110
  %1122 = bitcast i8* %1121 to double*
  %1123 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1122, i32 64)
  %1124 = fsub reassoc ninf nsz double %1123, %1120
  %1125 = fsub reassoc ninf nsz double %1113, %1107
  %1126 = fsub reassoc ninf nsz double %175, %1107
  %1127 = fmul reassoc ninf nsz double %1124, %1126
  %1128 = fdiv reassoc ninf nsz double %1127, %1125
  %1129 = fadd reassoc ninf nsz double %1128, %1120
  br label %after_if427

true_block437:                                    ; preds = %after_if427
  %1130 = add i32 %180, 33
  %1131 = sext i32 %1130 to i64
  %1132 = shl nsw i64 %1131, 3
  %1133 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1132
  %1134 = bitcast i8* %1133 to double*
  %1135 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1134, i32 64)
  %1136 = add i32 %180, 34
  %1137 = sext i32 %1136 to i64
  %1138 = shl nsw i64 %1137, 3
  %1139 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1138
  %1140 = bitcast i8* %1139 to double*
  %1141 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1140, i32 64)
  %1142 = fcmp reassoc ninf nsz oge double %175, %1135
  %1143 = fcmp reassoc ninf nsz ole double %175, %1141
  %.01101 = select i1 %1142, i1 %1143, i1 false
  br i1 %.01101, label %true_block443, label %after_if439

after_if439:                                      ; preds = %true_block443, %true_block437, %after_if427
  %.341205 = phi double [ %1157, %true_block443 ], [ %.331204, %true_block437 ], [ %.331204, %after_if427 ]
  %.33 = phi i1 [ true, %true_block443 ], [ %.32, %true_block437 ], [ %.32, %after_if427 ]
  %1144 = icmp ugt i32 %201, 34
  %1145 = xor i1 %.33, true
  %spec.select1860 = select i1 %1144, i1 %1145, i1 false
  br i1 %spec.select1860, label %true_block449, label %after_if451

true_block443:                                    ; preds = %true_block437
  %getch.i2496 = getelementptr i8, i8* %12, i64 418612680
  %1146 = getelementptr inbounds i8, i8* %getch.i2496, i64 %1132
  %1147 = bitcast i8* %1146 to double*
  %1148 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1147, i32 64)
  %1149 = getelementptr inbounds i8, i8* %getch.i2496, i64 %1138
  %1150 = bitcast i8* %1149 to double*
  %1151 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1150, i32 64)
  %1152 = fsub reassoc ninf nsz double %1151, %1148
  %1153 = fsub reassoc ninf nsz double %1141, %1135
  %1154 = fsub reassoc ninf nsz double %175, %1135
  %1155 = fmul reassoc ninf nsz double %1152, %1154
  %1156 = fdiv reassoc ninf nsz double %1155, %1153
  %1157 = fadd reassoc ninf nsz double %1156, %1148
  br label %after_if439

true_block449:                                    ; preds = %after_if439
  %1158 = add i32 %180, 34
  %1159 = sext i32 %1158 to i64
  %1160 = shl nsw i64 %1159, 3
  %1161 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1160
  %1162 = bitcast i8* %1161 to double*
  %1163 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1162, i32 64)
  %1164 = add i32 %180, 35
  %1165 = sext i32 %1164 to i64
  %1166 = shl nsw i64 %1165, 3
  %1167 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1166
  %1168 = bitcast i8* %1167 to double*
  %1169 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1168, i32 64)
  %1170 = fcmp reassoc ninf nsz oge double %175, %1163
  %1171 = fcmp reassoc ninf nsz ole double %175, %1169
  %.01099 = select i1 %1170, i1 %1171, i1 false
  br i1 %.01099, label %true_block455, label %after_if451

after_if451:                                      ; preds = %true_block455, %true_block449, %after_if439
  %.351206 = phi double [ %1185, %true_block455 ], [ %.341205, %true_block449 ], [ %.341205, %after_if439 ]
  %.34 = phi i1 [ true, %true_block455 ], [ %.33, %true_block449 ], [ %.33, %after_if439 ]
  %1172 = icmp ugt i32 %201, 35
  %1173 = xor i1 %.34, true
  %spec.select1861 = select i1 %1172, i1 %1173, i1 false
  br i1 %spec.select1861, label %true_block461, label %after_if463

true_block455:                                    ; preds = %true_block449
  %getch.i2495 = getelementptr i8, i8* %12, i64 418612680
  %1174 = getelementptr inbounds i8, i8* %getch.i2495, i64 %1160
  %1175 = bitcast i8* %1174 to double*
  %1176 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1175, i32 64)
  %1177 = getelementptr inbounds i8, i8* %getch.i2495, i64 %1166
  %1178 = bitcast i8* %1177 to double*
  %1179 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1178, i32 64)
  %1180 = fsub reassoc ninf nsz double %1179, %1176
  %1181 = fsub reassoc ninf nsz double %1169, %1163
  %1182 = fsub reassoc ninf nsz double %175, %1163
  %1183 = fmul reassoc ninf nsz double %1180, %1182
  %1184 = fdiv reassoc ninf nsz double %1183, %1181
  %1185 = fadd reassoc ninf nsz double %1184, %1176
  br label %after_if451

true_block461:                                    ; preds = %after_if451
  %1186 = add i32 %180, 35
  %1187 = sext i32 %1186 to i64
  %1188 = shl nsw i64 %1187, 3
  %1189 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1188
  %1190 = bitcast i8* %1189 to double*
  %1191 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1190, i32 64)
  %1192 = add i32 %180, 36
  %1193 = sext i32 %1192 to i64
  %1194 = shl nsw i64 %1193, 3
  %1195 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1194
  %1196 = bitcast i8* %1195 to double*
  %1197 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1196, i32 64)
  %1198 = fcmp reassoc ninf nsz oge double %175, %1191
  %1199 = fcmp reassoc ninf nsz ole double %175, %1197
  %.01097 = select i1 %1198, i1 %1199, i1 false
  br i1 %.01097, label %true_block467, label %after_if463

after_if463:                                      ; preds = %true_block467, %true_block461, %after_if451
  %.361207 = phi double [ %1213, %true_block467 ], [ %.351206, %true_block461 ], [ %.351206, %after_if451 ]
  %.35 = phi i1 [ true, %true_block467 ], [ %.34, %true_block461 ], [ %.34, %after_if451 ]
  %1200 = icmp ugt i32 %201, 36
  %1201 = xor i1 %.35, true
  %spec.select1862 = select i1 %1200, i1 %1201, i1 false
  br i1 %spec.select1862, label %true_block473, label %after_if475

true_block467:                                    ; preds = %true_block461
  %getch.i2494 = getelementptr i8, i8* %12, i64 418612680
  %1202 = getelementptr inbounds i8, i8* %getch.i2494, i64 %1188
  %1203 = bitcast i8* %1202 to double*
  %1204 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1203, i32 64)
  %1205 = getelementptr inbounds i8, i8* %getch.i2494, i64 %1194
  %1206 = bitcast i8* %1205 to double*
  %1207 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1206, i32 64)
  %1208 = fsub reassoc ninf nsz double %1207, %1204
  %1209 = fsub reassoc ninf nsz double %1197, %1191
  %1210 = fsub reassoc ninf nsz double %175, %1191
  %1211 = fmul reassoc ninf nsz double %1208, %1210
  %1212 = fdiv reassoc ninf nsz double %1211, %1209
  %1213 = fadd reassoc ninf nsz double %1212, %1204
  br label %after_if463

true_block473:                                    ; preds = %after_if463
  %1214 = add i32 %180, 36
  %1215 = sext i32 %1214 to i64
  %1216 = shl nsw i64 %1215, 3
  %1217 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1216
  %1218 = bitcast i8* %1217 to double*
  %1219 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1218, i32 64)
  %1220 = add i32 %180, 37
  %1221 = sext i32 %1220 to i64
  %1222 = shl nsw i64 %1221, 3
  %1223 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1222
  %1224 = bitcast i8* %1223 to double*
  %1225 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1224, i32 64)
  %1226 = fcmp reassoc ninf nsz oge double %175, %1219
  %1227 = fcmp reassoc ninf nsz ole double %175, %1225
  %.01095 = select i1 %1226, i1 %1227, i1 false
  br i1 %.01095, label %true_block479, label %after_if475

after_if475:                                      ; preds = %true_block479, %true_block473, %after_if463
  %.371208 = phi double [ %1241, %true_block479 ], [ %.361207, %true_block473 ], [ %.361207, %after_if463 ]
  %.36 = phi i1 [ true, %true_block479 ], [ %.35, %true_block473 ], [ %.35, %after_if463 ]
  %1228 = icmp ugt i32 %201, 37
  %1229 = xor i1 %.36, true
  %spec.select1863 = select i1 %1228, i1 %1229, i1 false
  br i1 %spec.select1863, label %true_block485, label %after_if487

true_block479:                                    ; preds = %true_block473
  %getch.i2493 = getelementptr i8, i8* %12, i64 418612680
  %1230 = getelementptr inbounds i8, i8* %getch.i2493, i64 %1216
  %1231 = bitcast i8* %1230 to double*
  %1232 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1231, i32 64)
  %1233 = getelementptr inbounds i8, i8* %getch.i2493, i64 %1222
  %1234 = bitcast i8* %1233 to double*
  %1235 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1234, i32 64)
  %1236 = fsub reassoc ninf nsz double %1235, %1232
  %1237 = fsub reassoc ninf nsz double %1225, %1219
  %1238 = fsub reassoc ninf nsz double %175, %1219
  %1239 = fmul reassoc ninf nsz double %1236, %1238
  %1240 = fdiv reassoc ninf nsz double %1239, %1237
  %1241 = fadd reassoc ninf nsz double %1240, %1232
  br label %after_if475

true_block485:                                    ; preds = %after_if475
  %1242 = add i32 %180, 37
  %1243 = sext i32 %1242 to i64
  %1244 = shl nsw i64 %1243, 3
  %1245 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1244
  %1246 = bitcast i8* %1245 to double*
  %1247 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1246, i32 64)
  %1248 = add i32 %180, 38
  %1249 = sext i32 %1248 to i64
  %1250 = shl nsw i64 %1249, 3
  %1251 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1250
  %1252 = bitcast i8* %1251 to double*
  %1253 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1252, i32 64)
  %1254 = fcmp reassoc ninf nsz oge double %175, %1247
  %1255 = fcmp reassoc ninf nsz ole double %175, %1253
  %.01093 = select i1 %1254, i1 %1255, i1 false
  br i1 %.01093, label %true_block491, label %after_if487

after_if487:                                      ; preds = %true_block491, %true_block485, %after_if475
  %.381209 = phi double [ %1269, %true_block491 ], [ %.371208, %true_block485 ], [ %.371208, %after_if475 ]
  %.37 = phi i1 [ true, %true_block491 ], [ %.36, %true_block485 ], [ %.36, %after_if475 ]
  %1256 = icmp ugt i32 %201, 38
  %1257 = xor i1 %.37, true
  %spec.select1864 = select i1 %1256, i1 %1257, i1 false
  br i1 %spec.select1864, label %true_block497, label %after_if499

true_block491:                                    ; preds = %true_block485
  %getch.i2492 = getelementptr i8, i8* %12, i64 418612680
  %1258 = getelementptr inbounds i8, i8* %getch.i2492, i64 %1244
  %1259 = bitcast i8* %1258 to double*
  %1260 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1259, i32 64)
  %1261 = getelementptr inbounds i8, i8* %getch.i2492, i64 %1250
  %1262 = bitcast i8* %1261 to double*
  %1263 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1262, i32 64)
  %1264 = fsub reassoc ninf nsz double %1263, %1260
  %1265 = fsub reassoc ninf nsz double %1253, %1247
  %1266 = fsub reassoc ninf nsz double %175, %1247
  %1267 = fmul reassoc ninf nsz double %1264, %1266
  %1268 = fdiv reassoc ninf nsz double %1267, %1265
  %1269 = fadd reassoc ninf nsz double %1268, %1260
  br label %after_if487

true_block497:                                    ; preds = %after_if487
  %1270 = add i32 %180, 38
  %1271 = sext i32 %1270 to i64
  %1272 = shl nsw i64 %1271, 3
  %1273 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1272
  %1274 = bitcast i8* %1273 to double*
  %1275 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1274, i32 64)
  %1276 = add i32 %180, 39
  %1277 = sext i32 %1276 to i64
  %1278 = shl nsw i64 %1277, 3
  %1279 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1278
  %1280 = bitcast i8* %1279 to double*
  %1281 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1280, i32 64)
  %1282 = fcmp reassoc ninf nsz oge double %175, %1275
  %1283 = fcmp reassoc ninf nsz ole double %175, %1281
  %.01091 = select i1 %1282, i1 %1283, i1 false
  br i1 %.01091, label %true_block503, label %after_if499

after_if499:                                      ; preds = %true_block503, %true_block497, %after_if487
  %.391210 = phi double [ %1297, %true_block503 ], [ %.381209, %true_block497 ], [ %.381209, %after_if487 ]
  %.38 = phi i1 [ true, %true_block503 ], [ %.37, %true_block497 ], [ %.37, %after_if487 ]
  %1284 = icmp ugt i32 %201, 39
  %1285 = xor i1 %.38, true
  %spec.select1865 = select i1 %1284, i1 %1285, i1 false
  br i1 %spec.select1865, label %true_block509, label %after_if511

true_block503:                                    ; preds = %true_block497
  %getch.i2491 = getelementptr i8, i8* %12, i64 418612680
  %1286 = getelementptr inbounds i8, i8* %getch.i2491, i64 %1272
  %1287 = bitcast i8* %1286 to double*
  %1288 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1287, i32 64)
  %1289 = getelementptr inbounds i8, i8* %getch.i2491, i64 %1278
  %1290 = bitcast i8* %1289 to double*
  %1291 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1290, i32 64)
  %1292 = fsub reassoc ninf nsz double %1291, %1288
  %1293 = fsub reassoc ninf nsz double %1281, %1275
  %1294 = fsub reassoc ninf nsz double %175, %1275
  %1295 = fmul reassoc ninf nsz double %1292, %1294
  %1296 = fdiv reassoc ninf nsz double %1295, %1293
  %1297 = fadd reassoc ninf nsz double %1296, %1288
  br label %after_if499

true_block509:                                    ; preds = %after_if499
  %1298 = add i32 %180, 39
  %1299 = sext i32 %1298 to i64
  %1300 = shl nsw i64 %1299, 3
  %1301 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1300
  %1302 = bitcast i8* %1301 to double*
  %1303 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1302, i32 64)
  %1304 = add i32 %180, 40
  %1305 = sext i32 %1304 to i64
  %1306 = shl nsw i64 %1305, 3
  %1307 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1306
  %1308 = bitcast i8* %1307 to double*
  %1309 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1308, i32 64)
  %1310 = fcmp reassoc ninf nsz oge double %175, %1303
  %1311 = fcmp reassoc ninf nsz ole double %175, %1309
  %.01089 = select i1 %1310, i1 %1311, i1 false
  br i1 %.01089, label %true_block515, label %after_if511

after_if511:                                      ; preds = %true_block515, %true_block509, %after_if499
  %.401211 = phi double [ %1325, %true_block515 ], [ %.391210, %true_block509 ], [ %.391210, %after_if499 ]
  %.39 = phi i1 [ true, %true_block515 ], [ %.38, %true_block509 ], [ %.38, %after_if499 ]
  %1312 = icmp ugt i32 %201, 40
  %1313 = xor i1 %.39, true
  %spec.select1866 = select i1 %1312, i1 %1313, i1 false
  br i1 %spec.select1866, label %true_block521, label %after_if523

true_block515:                                    ; preds = %true_block509
  %getch.i2490 = getelementptr i8, i8* %12, i64 418612680
  %1314 = getelementptr inbounds i8, i8* %getch.i2490, i64 %1300
  %1315 = bitcast i8* %1314 to double*
  %1316 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1315, i32 64)
  %1317 = getelementptr inbounds i8, i8* %getch.i2490, i64 %1306
  %1318 = bitcast i8* %1317 to double*
  %1319 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1318, i32 64)
  %1320 = fsub reassoc ninf nsz double %1319, %1316
  %1321 = fsub reassoc ninf nsz double %1309, %1303
  %1322 = fsub reassoc ninf nsz double %175, %1303
  %1323 = fmul reassoc ninf nsz double %1320, %1322
  %1324 = fdiv reassoc ninf nsz double %1323, %1321
  %1325 = fadd reassoc ninf nsz double %1324, %1316
  br label %after_if511

true_block521:                                    ; preds = %after_if511
  %1326 = add i32 %180, 40
  %1327 = sext i32 %1326 to i64
  %1328 = shl nsw i64 %1327, 3
  %1329 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1328
  %1330 = bitcast i8* %1329 to double*
  %1331 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1330, i32 64)
  %1332 = add i32 %180, 41
  %1333 = sext i32 %1332 to i64
  %1334 = shl nsw i64 %1333, 3
  %1335 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1334
  %1336 = bitcast i8* %1335 to double*
  %1337 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1336, i32 64)
  %1338 = fcmp reassoc ninf nsz oge double %175, %1331
  %1339 = fcmp reassoc ninf nsz ole double %175, %1337
  %.01087 = select i1 %1338, i1 %1339, i1 false
  br i1 %.01087, label %true_block527, label %after_if523

after_if523:                                      ; preds = %true_block527, %true_block521, %after_if511
  %.411212 = phi double [ %1353, %true_block527 ], [ %.401211, %true_block521 ], [ %.401211, %after_if511 ]
  %.40 = phi i1 [ true, %true_block527 ], [ %.39, %true_block521 ], [ %.39, %after_if511 ]
  %1340 = icmp ugt i32 %201, 41
  %1341 = xor i1 %.40, true
  %spec.select1867 = select i1 %1340, i1 %1341, i1 false
  br i1 %spec.select1867, label %true_block533, label %after_if535

true_block527:                                    ; preds = %true_block521
  %getch.i2489 = getelementptr i8, i8* %12, i64 418612680
  %1342 = getelementptr inbounds i8, i8* %getch.i2489, i64 %1328
  %1343 = bitcast i8* %1342 to double*
  %1344 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1343, i32 64)
  %1345 = getelementptr inbounds i8, i8* %getch.i2489, i64 %1334
  %1346 = bitcast i8* %1345 to double*
  %1347 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1346, i32 64)
  %1348 = fsub reassoc ninf nsz double %1347, %1344
  %1349 = fsub reassoc ninf nsz double %1337, %1331
  %1350 = fsub reassoc ninf nsz double %175, %1331
  %1351 = fmul reassoc ninf nsz double %1348, %1350
  %1352 = fdiv reassoc ninf nsz double %1351, %1349
  %1353 = fadd reassoc ninf nsz double %1352, %1344
  br label %after_if523

true_block533:                                    ; preds = %after_if523
  %1354 = add i32 %180, 41
  %1355 = sext i32 %1354 to i64
  %1356 = shl nsw i64 %1355, 3
  %1357 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1356
  %1358 = bitcast i8* %1357 to double*
  %1359 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1358, i32 64)
  %1360 = add i32 %180, 42
  %1361 = sext i32 %1360 to i64
  %1362 = shl nsw i64 %1361, 3
  %1363 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1362
  %1364 = bitcast i8* %1363 to double*
  %1365 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1364, i32 64)
  %1366 = fcmp reassoc ninf nsz oge double %175, %1359
  %1367 = fcmp reassoc ninf nsz ole double %175, %1365
  %.01085 = select i1 %1366, i1 %1367, i1 false
  br i1 %.01085, label %true_block539, label %after_if535

after_if535:                                      ; preds = %true_block539, %true_block533, %after_if523
  %.421213 = phi double [ %1381, %true_block539 ], [ %.411212, %true_block533 ], [ %.411212, %after_if523 ]
  %.41 = phi i1 [ true, %true_block539 ], [ %.40, %true_block533 ], [ %.40, %after_if523 ]
  %1368 = icmp ugt i32 %201, 42
  %1369 = xor i1 %.41, true
  %spec.select1868 = select i1 %1368, i1 %1369, i1 false
  br i1 %spec.select1868, label %true_block545, label %after_if547

true_block539:                                    ; preds = %true_block533
  %getch.i2488 = getelementptr i8, i8* %12, i64 418612680
  %1370 = getelementptr inbounds i8, i8* %getch.i2488, i64 %1356
  %1371 = bitcast i8* %1370 to double*
  %1372 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1371, i32 64)
  %1373 = getelementptr inbounds i8, i8* %getch.i2488, i64 %1362
  %1374 = bitcast i8* %1373 to double*
  %1375 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1374, i32 64)
  %1376 = fsub reassoc ninf nsz double %1375, %1372
  %1377 = fsub reassoc ninf nsz double %1365, %1359
  %1378 = fsub reassoc ninf nsz double %175, %1359
  %1379 = fmul reassoc ninf nsz double %1376, %1378
  %1380 = fdiv reassoc ninf nsz double %1379, %1377
  %1381 = fadd reassoc ninf nsz double %1380, %1372
  br label %after_if535

true_block545:                                    ; preds = %after_if535
  %1382 = add i32 %180, 42
  %1383 = sext i32 %1382 to i64
  %1384 = shl nsw i64 %1383, 3
  %1385 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1384
  %1386 = bitcast i8* %1385 to double*
  %1387 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1386, i32 64)
  %1388 = add i32 %180, 43
  %1389 = sext i32 %1388 to i64
  %1390 = shl nsw i64 %1389, 3
  %1391 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1390
  %1392 = bitcast i8* %1391 to double*
  %1393 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1392, i32 64)
  %1394 = fcmp reassoc ninf nsz oge double %175, %1387
  %1395 = fcmp reassoc ninf nsz ole double %175, %1393
  %.01083 = select i1 %1394, i1 %1395, i1 false
  br i1 %.01083, label %true_block551, label %after_if547

after_if547:                                      ; preds = %true_block551, %true_block545, %after_if535
  %.431214 = phi double [ %1409, %true_block551 ], [ %.421213, %true_block545 ], [ %.421213, %after_if535 ]
  %.42 = phi i1 [ true, %true_block551 ], [ %.41, %true_block545 ], [ %.41, %after_if535 ]
  %1396 = icmp ugt i32 %201, 43
  %1397 = xor i1 %.42, true
  %spec.select1869 = select i1 %1396, i1 %1397, i1 false
  br i1 %spec.select1869, label %true_block557, label %after_if559

true_block551:                                    ; preds = %true_block545
  %getch.i2487 = getelementptr i8, i8* %12, i64 418612680
  %1398 = getelementptr inbounds i8, i8* %getch.i2487, i64 %1384
  %1399 = bitcast i8* %1398 to double*
  %1400 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1399, i32 64)
  %1401 = getelementptr inbounds i8, i8* %getch.i2487, i64 %1390
  %1402 = bitcast i8* %1401 to double*
  %1403 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1402, i32 64)
  %1404 = fsub reassoc ninf nsz double %1403, %1400
  %1405 = fsub reassoc ninf nsz double %1393, %1387
  %1406 = fsub reassoc ninf nsz double %175, %1387
  %1407 = fmul reassoc ninf nsz double %1404, %1406
  %1408 = fdiv reassoc ninf nsz double %1407, %1405
  %1409 = fadd reassoc ninf nsz double %1408, %1400
  br label %after_if547

true_block557:                                    ; preds = %after_if547
  %1410 = add i32 %180, 43
  %1411 = sext i32 %1410 to i64
  %1412 = shl nsw i64 %1411, 3
  %1413 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1412
  %1414 = bitcast i8* %1413 to double*
  %1415 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1414, i32 64)
  %1416 = add i32 %180, 44
  %1417 = sext i32 %1416 to i64
  %1418 = shl nsw i64 %1417, 3
  %1419 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1418
  %1420 = bitcast i8* %1419 to double*
  %1421 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1420, i32 64)
  %1422 = fcmp reassoc ninf nsz oge double %175, %1415
  %1423 = fcmp reassoc ninf nsz ole double %175, %1421
  %.01081 = select i1 %1422, i1 %1423, i1 false
  br i1 %.01081, label %true_block563, label %after_if559

after_if559:                                      ; preds = %true_block563, %true_block557, %after_if547
  %.441215 = phi double [ %1437, %true_block563 ], [ %.431214, %true_block557 ], [ %.431214, %after_if547 ]
  %.43 = phi i1 [ true, %true_block563 ], [ %.42, %true_block557 ], [ %.42, %after_if547 ]
  %1424 = icmp ugt i32 %201, 44
  %1425 = xor i1 %.43, true
  %spec.select1870 = select i1 %1424, i1 %1425, i1 false
  br i1 %spec.select1870, label %true_block569, label %after_if571

true_block563:                                    ; preds = %true_block557
  %getch.i2486 = getelementptr i8, i8* %12, i64 418612680
  %1426 = getelementptr inbounds i8, i8* %getch.i2486, i64 %1412
  %1427 = bitcast i8* %1426 to double*
  %1428 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1427, i32 64)
  %1429 = getelementptr inbounds i8, i8* %getch.i2486, i64 %1418
  %1430 = bitcast i8* %1429 to double*
  %1431 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1430, i32 64)
  %1432 = fsub reassoc ninf nsz double %1431, %1428
  %1433 = fsub reassoc ninf nsz double %1421, %1415
  %1434 = fsub reassoc ninf nsz double %175, %1415
  %1435 = fmul reassoc ninf nsz double %1432, %1434
  %1436 = fdiv reassoc ninf nsz double %1435, %1433
  %1437 = fadd reassoc ninf nsz double %1436, %1428
  br label %after_if559

true_block569:                                    ; preds = %after_if559
  %1438 = add i32 %180, 44
  %1439 = sext i32 %1438 to i64
  %1440 = shl nsw i64 %1439, 3
  %1441 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1440
  %1442 = bitcast i8* %1441 to double*
  %1443 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1442, i32 64)
  %1444 = add i32 %180, 45
  %1445 = sext i32 %1444 to i64
  %1446 = shl nsw i64 %1445, 3
  %1447 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1446
  %1448 = bitcast i8* %1447 to double*
  %1449 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1448, i32 64)
  %1450 = fcmp reassoc ninf nsz oge double %175, %1443
  %1451 = fcmp reassoc ninf nsz ole double %175, %1449
  %.01079 = select i1 %1450, i1 %1451, i1 false
  br i1 %.01079, label %true_block575, label %after_if571

after_if571:                                      ; preds = %true_block575, %true_block569, %after_if559
  %.451216 = phi double [ %1465, %true_block575 ], [ %.441215, %true_block569 ], [ %.441215, %after_if559 ]
  %.44 = phi i1 [ true, %true_block575 ], [ %.43, %true_block569 ], [ %.43, %after_if559 ]
  %1452 = icmp ugt i32 %201, 45
  %1453 = xor i1 %.44, true
  %spec.select1871 = select i1 %1452, i1 %1453, i1 false
  br i1 %spec.select1871, label %true_block581, label %after_if583

true_block575:                                    ; preds = %true_block569
  %getch.i2485 = getelementptr i8, i8* %12, i64 418612680
  %1454 = getelementptr inbounds i8, i8* %getch.i2485, i64 %1440
  %1455 = bitcast i8* %1454 to double*
  %1456 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1455, i32 64)
  %1457 = getelementptr inbounds i8, i8* %getch.i2485, i64 %1446
  %1458 = bitcast i8* %1457 to double*
  %1459 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1458, i32 64)
  %1460 = fsub reassoc ninf nsz double %1459, %1456
  %1461 = fsub reassoc ninf nsz double %1449, %1443
  %1462 = fsub reassoc ninf nsz double %175, %1443
  %1463 = fmul reassoc ninf nsz double %1460, %1462
  %1464 = fdiv reassoc ninf nsz double %1463, %1461
  %1465 = fadd reassoc ninf nsz double %1464, %1456
  br label %after_if571

true_block581:                                    ; preds = %after_if571
  %1466 = add i32 %180, 45
  %1467 = sext i32 %1466 to i64
  %1468 = shl nsw i64 %1467, 3
  %1469 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1468
  %1470 = bitcast i8* %1469 to double*
  %1471 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1470, i32 64)
  %1472 = add i32 %180, 46
  %1473 = sext i32 %1472 to i64
  %1474 = shl nsw i64 %1473, 3
  %1475 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1474
  %1476 = bitcast i8* %1475 to double*
  %1477 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1476, i32 64)
  %1478 = fcmp reassoc ninf nsz oge double %175, %1471
  %1479 = fcmp reassoc ninf nsz ole double %175, %1477
  %.01077 = select i1 %1478, i1 %1479, i1 false
  br i1 %.01077, label %true_block587, label %after_if583

after_if583:                                      ; preds = %true_block587, %true_block581, %after_if571
  %.461217 = phi double [ %1493, %true_block587 ], [ %.451216, %true_block581 ], [ %.451216, %after_if571 ]
  %.45 = phi i1 [ true, %true_block587 ], [ %.44, %true_block581 ], [ %.44, %after_if571 ]
  %1480 = icmp ugt i32 %201, 46
  %1481 = xor i1 %.45, true
  %spec.select1872 = select i1 %1480, i1 %1481, i1 false
  br i1 %spec.select1872, label %true_block593, label %after_if595

true_block587:                                    ; preds = %true_block581
  %getch.i2484 = getelementptr i8, i8* %12, i64 418612680
  %1482 = getelementptr inbounds i8, i8* %getch.i2484, i64 %1468
  %1483 = bitcast i8* %1482 to double*
  %1484 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1483, i32 64)
  %1485 = getelementptr inbounds i8, i8* %getch.i2484, i64 %1474
  %1486 = bitcast i8* %1485 to double*
  %1487 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1486, i32 64)
  %1488 = fsub reassoc ninf nsz double %1487, %1484
  %1489 = fsub reassoc ninf nsz double %1477, %1471
  %1490 = fsub reassoc ninf nsz double %175, %1471
  %1491 = fmul reassoc ninf nsz double %1488, %1490
  %1492 = fdiv reassoc ninf nsz double %1491, %1489
  %1493 = fadd reassoc ninf nsz double %1492, %1484
  br label %after_if583

true_block593:                                    ; preds = %after_if583
  %1494 = add i32 %180, 46
  %1495 = sext i32 %1494 to i64
  %1496 = shl nsw i64 %1495, 3
  %1497 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1496
  %1498 = bitcast i8* %1497 to double*
  %1499 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1498, i32 64)
  %1500 = add i32 %180, 47
  %1501 = sext i32 %1500 to i64
  %1502 = shl nsw i64 %1501, 3
  %1503 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1502
  %1504 = bitcast i8* %1503 to double*
  %1505 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1504, i32 64)
  %1506 = fcmp reassoc ninf nsz oge double %175, %1499
  %1507 = fcmp reassoc ninf nsz ole double %175, %1505
  %.01075 = select i1 %1506, i1 %1507, i1 false
  br i1 %.01075, label %true_block599, label %after_if595

after_if595:                                      ; preds = %true_block599, %true_block593, %after_if583
  %.471218 = phi double [ %1521, %true_block599 ], [ %.461217, %true_block593 ], [ %.461217, %after_if583 ]
  %.46 = phi i1 [ true, %true_block599 ], [ %.45, %true_block593 ], [ %.45, %after_if583 ]
  %1508 = icmp ugt i32 %201, 47
  %1509 = xor i1 %.46, true
  %spec.select1873 = select i1 %1508, i1 %1509, i1 false
  br i1 %spec.select1873, label %true_block605, label %after_if607

true_block599:                                    ; preds = %true_block593
  %getch.i2483 = getelementptr i8, i8* %12, i64 418612680
  %1510 = getelementptr inbounds i8, i8* %getch.i2483, i64 %1496
  %1511 = bitcast i8* %1510 to double*
  %1512 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1511, i32 64)
  %1513 = getelementptr inbounds i8, i8* %getch.i2483, i64 %1502
  %1514 = bitcast i8* %1513 to double*
  %1515 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1514, i32 64)
  %1516 = fsub reassoc ninf nsz double %1515, %1512
  %1517 = fsub reassoc ninf nsz double %1505, %1499
  %1518 = fsub reassoc ninf nsz double %175, %1499
  %1519 = fmul reassoc ninf nsz double %1516, %1518
  %1520 = fdiv reassoc ninf nsz double %1519, %1517
  %1521 = fadd reassoc ninf nsz double %1520, %1512
  br label %after_if595

true_block605:                                    ; preds = %after_if595
  %1522 = add i32 %180, 47
  %1523 = sext i32 %1522 to i64
  %1524 = shl nsw i64 %1523, 3
  %1525 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1524
  %1526 = bitcast i8* %1525 to double*
  %1527 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1526, i32 64)
  %1528 = add i32 %180, 48
  %1529 = sext i32 %1528 to i64
  %1530 = shl nsw i64 %1529, 3
  %1531 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1530
  %1532 = bitcast i8* %1531 to double*
  %1533 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1532, i32 64)
  %1534 = fcmp reassoc ninf nsz oge double %175, %1527
  %1535 = fcmp reassoc ninf nsz ole double %175, %1533
  %.01073 = select i1 %1534, i1 %1535, i1 false
  br i1 %.01073, label %true_block611, label %after_if607

after_if607:                                      ; preds = %true_block611, %true_block605, %after_if595
  %.481219 = phi double [ %1549, %true_block611 ], [ %.471218, %true_block605 ], [ %.471218, %after_if595 ]
  %.47 = phi i1 [ true, %true_block611 ], [ %.46, %true_block605 ], [ %.46, %after_if595 ]
  %1536 = icmp ugt i32 %201, 48
  %1537 = xor i1 %.47, true
  %spec.select1874 = select i1 %1536, i1 %1537, i1 false
  br i1 %spec.select1874, label %true_block617, label %after_if619

true_block611:                                    ; preds = %true_block605
  %getch.i2482 = getelementptr i8, i8* %12, i64 418612680
  %1538 = getelementptr inbounds i8, i8* %getch.i2482, i64 %1524
  %1539 = bitcast i8* %1538 to double*
  %1540 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1539, i32 64)
  %1541 = getelementptr inbounds i8, i8* %getch.i2482, i64 %1530
  %1542 = bitcast i8* %1541 to double*
  %1543 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1542, i32 64)
  %1544 = fsub reassoc ninf nsz double %1543, %1540
  %1545 = fsub reassoc ninf nsz double %1533, %1527
  %1546 = fsub reassoc ninf nsz double %175, %1527
  %1547 = fmul reassoc ninf nsz double %1544, %1546
  %1548 = fdiv reassoc ninf nsz double %1547, %1545
  %1549 = fadd reassoc ninf nsz double %1548, %1540
  br label %after_if607

true_block617:                                    ; preds = %after_if607
  %1550 = add i32 %180, 48
  %1551 = sext i32 %1550 to i64
  %1552 = shl nsw i64 %1551, 3
  %1553 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1552
  %1554 = bitcast i8* %1553 to double*
  %1555 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1554, i32 64)
  %1556 = add i32 %180, 49
  %1557 = sext i32 %1556 to i64
  %1558 = shl nsw i64 %1557, 3
  %1559 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1558
  %1560 = bitcast i8* %1559 to double*
  %1561 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1560, i32 64)
  %1562 = fcmp reassoc ninf nsz oge double %175, %1555
  %1563 = fcmp reassoc ninf nsz ole double %175, %1561
  %.01071 = select i1 %1562, i1 %1563, i1 false
  br i1 %.01071, label %true_block623, label %after_if619

after_if619:                                      ; preds = %true_block623, %true_block617, %after_if607
  %.491220 = phi double [ %1577, %true_block623 ], [ %.481219, %true_block617 ], [ %.481219, %after_if607 ]
  %.48 = phi i1 [ true, %true_block623 ], [ %.47, %true_block617 ], [ %.47, %after_if607 ]
  %1564 = icmp ugt i32 %201, 49
  %1565 = xor i1 %.48, true
  %spec.select1875 = select i1 %1564, i1 %1565, i1 false
  br i1 %spec.select1875, label %true_block629, label %after_if631

true_block623:                                    ; preds = %true_block617
  %getch.i2481 = getelementptr i8, i8* %12, i64 418612680
  %1566 = getelementptr inbounds i8, i8* %getch.i2481, i64 %1552
  %1567 = bitcast i8* %1566 to double*
  %1568 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1567, i32 64)
  %1569 = getelementptr inbounds i8, i8* %getch.i2481, i64 %1558
  %1570 = bitcast i8* %1569 to double*
  %1571 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1570, i32 64)
  %1572 = fsub reassoc ninf nsz double %1571, %1568
  %1573 = fsub reassoc ninf nsz double %1561, %1555
  %1574 = fsub reassoc ninf nsz double %175, %1555
  %1575 = fmul reassoc ninf nsz double %1572, %1574
  %1576 = fdiv reassoc ninf nsz double %1575, %1573
  %1577 = fadd reassoc ninf nsz double %1576, %1568
  br label %after_if619

true_block629:                                    ; preds = %after_if619
  %1578 = add i32 %180, 49
  %1579 = sext i32 %1578 to i64
  %1580 = shl nsw i64 %1579, 3
  %1581 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1580
  %1582 = bitcast i8* %1581 to double*
  %1583 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1582, i32 64)
  %1584 = add i32 %180, 50
  %1585 = sext i32 %1584 to i64
  %1586 = shl nsw i64 %1585, 3
  %1587 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1586
  %1588 = bitcast i8* %1587 to double*
  %1589 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1588, i32 64)
  %1590 = fcmp reassoc ninf nsz oge double %175, %1583
  %1591 = fcmp reassoc ninf nsz ole double %175, %1589
  %.01069 = select i1 %1590, i1 %1591, i1 false
  br i1 %.01069, label %true_block635, label %after_if631

after_if631:                                      ; preds = %true_block635, %true_block629, %after_if619
  %.501221 = phi double [ %1605, %true_block635 ], [ %.491220, %true_block629 ], [ %.491220, %after_if619 ]
  %.49 = phi i1 [ true, %true_block635 ], [ %.48, %true_block629 ], [ %.48, %after_if619 ]
  %1592 = icmp ugt i32 %201, 50
  %1593 = xor i1 %.49, true
  %spec.select1876 = select i1 %1592, i1 %1593, i1 false
  br i1 %spec.select1876, label %true_block641, label %after_if643

true_block635:                                    ; preds = %true_block629
  %getch.i2480 = getelementptr i8, i8* %12, i64 418612680
  %1594 = getelementptr inbounds i8, i8* %getch.i2480, i64 %1580
  %1595 = bitcast i8* %1594 to double*
  %1596 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1595, i32 64)
  %1597 = getelementptr inbounds i8, i8* %getch.i2480, i64 %1586
  %1598 = bitcast i8* %1597 to double*
  %1599 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1598, i32 64)
  %1600 = fsub reassoc ninf nsz double %1599, %1596
  %1601 = fsub reassoc ninf nsz double %1589, %1583
  %1602 = fsub reassoc ninf nsz double %175, %1583
  %1603 = fmul reassoc ninf nsz double %1600, %1602
  %1604 = fdiv reassoc ninf nsz double %1603, %1601
  %1605 = fadd reassoc ninf nsz double %1604, %1596
  br label %after_if631

true_block641:                                    ; preds = %after_if631
  %1606 = add i32 %180, 50
  %1607 = sext i32 %1606 to i64
  %1608 = shl nsw i64 %1607, 3
  %1609 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1608
  %1610 = bitcast i8* %1609 to double*
  %1611 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1610, i32 64)
  %1612 = add i32 %180, 51
  %1613 = sext i32 %1612 to i64
  %1614 = shl nsw i64 %1613, 3
  %1615 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1614
  %1616 = bitcast i8* %1615 to double*
  %1617 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1616, i32 64)
  %1618 = fcmp reassoc ninf nsz oge double %175, %1611
  %1619 = fcmp reassoc ninf nsz ole double %175, %1617
  %.01067 = select i1 %1618, i1 %1619, i1 false
  br i1 %.01067, label %true_block647, label %after_if643

after_if643:                                      ; preds = %true_block647, %true_block641, %after_if631
  %.511222 = phi double [ %1633, %true_block647 ], [ %.501221, %true_block641 ], [ %.501221, %after_if631 ]
  %.50 = phi i1 [ true, %true_block647 ], [ %.49, %true_block641 ], [ %.49, %after_if631 ]
  %1620 = icmp ugt i32 %201, 51
  %1621 = xor i1 %.50, true
  %spec.select1877 = select i1 %1620, i1 %1621, i1 false
  br i1 %spec.select1877, label %true_block653, label %after_if655

true_block647:                                    ; preds = %true_block641
  %getch.i2479 = getelementptr i8, i8* %12, i64 418612680
  %1622 = getelementptr inbounds i8, i8* %getch.i2479, i64 %1608
  %1623 = bitcast i8* %1622 to double*
  %1624 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1623, i32 64)
  %1625 = getelementptr inbounds i8, i8* %getch.i2479, i64 %1614
  %1626 = bitcast i8* %1625 to double*
  %1627 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1626, i32 64)
  %1628 = fsub reassoc ninf nsz double %1627, %1624
  %1629 = fsub reassoc ninf nsz double %1617, %1611
  %1630 = fsub reassoc ninf nsz double %175, %1611
  %1631 = fmul reassoc ninf nsz double %1628, %1630
  %1632 = fdiv reassoc ninf nsz double %1631, %1629
  %1633 = fadd reassoc ninf nsz double %1632, %1624
  br label %after_if643

true_block653:                                    ; preds = %after_if643
  %1634 = add i32 %180, 51
  %1635 = sext i32 %1634 to i64
  %1636 = shl nsw i64 %1635, 3
  %1637 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1636
  %1638 = bitcast i8* %1637 to double*
  %1639 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1638, i32 64)
  %1640 = add i32 %180, 52
  %1641 = sext i32 %1640 to i64
  %1642 = shl nsw i64 %1641, 3
  %1643 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1642
  %1644 = bitcast i8* %1643 to double*
  %1645 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1644, i32 64)
  %1646 = fcmp reassoc ninf nsz oge double %175, %1639
  %1647 = fcmp reassoc ninf nsz ole double %175, %1645
  %.01065 = select i1 %1646, i1 %1647, i1 false
  br i1 %.01065, label %true_block659, label %after_if655

after_if655:                                      ; preds = %true_block659, %true_block653, %after_if643
  %.521223 = phi double [ %1661, %true_block659 ], [ %.511222, %true_block653 ], [ %.511222, %after_if643 ]
  %.51 = phi i1 [ true, %true_block659 ], [ %.50, %true_block653 ], [ %.50, %after_if643 ]
  %1648 = icmp ugt i32 %201, 52
  %1649 = xor i1 %.51, true
  %spec.select1878 = select i1 %1648, i1 %1649, i1 false
  br i1 %spec.select1878, label %true_block665, label %after_if667

true_block659:                                    ; preds = %true_block653
  %getch.i2478 = getelementptr i8, i8* %12, i64 418612680
  %1650 = getelementptr inbounds i8, i8* %getch.i2478, i64 %1636
  %1651 = bitcast i8* %1650 to double*
  %1652 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1651, i32 64)
  %1653 = getelementptr inbounds i8, i8* %getch.i2478, i64 %1642
  %1654 = bitcast i8* %1653 to double*
  %1655 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1654, i32 64)
  %1656 = fsub reassoc ninf nsz double %1655, %1652
  %1657 = fsub reassoc ninf nsz double %1645, %1639
  %1658 = fsub reassoc ninf nsz double %175, %1639
  %1659 = fmul reassoc ninf nsz double %1656, %1658
  %1660 = fdiv reassoc ninf nsz double %1659, %1657
  %1661 = fadd reassoc ninf nsz double %1660, %1652
  br label %after_if655

true_block665:                                    ; preds = %after_if655
  %1662 = add i32 %180, 52
  %1663 = sext i32 %1662 to i64
  %1664 = shl nsw i64 %1663, 3
  %1665 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1664
  %1666 = bitcast i8* %1665 to double*
  %1667 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1666, i32 64)
  %1668 = add i32 %180, 53
  %1669 = sext i32 %1668 to i64
  %1670 = shl nsw i64 %1669, 3
  %1671 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1670
  %1672 = bitcast i8* %1671 to double*
  %1673 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1672, i32 64)
  %1674 = fcmp reassoc ninf nsz oge double %175, %1667
  %1675 = fcmp reassoc ninf nsz ole double %175, %1673
  %.01063 = select i1 %1674, i1 %1675, i1 false
  br i1 %.01063, label %true_block671, label %after_if667

after_if667:                                      ; preds = %true_block671, %true_block665, %after_if655
  %.531224 = phi double [ %1689, %true_block671 ], [ %.521223, %true_block665 ], [ %.521223, %after_if655 ]
  %.52 = phi i1 [ true, %true_block671 ], [ %.51, %true_block665 ], [ %.51, %after_if655 ]
  %1676 = icmp ugt i32 %201, 53
  %1677 = xor i1 %.52, true
  %spec.select1879 = select i1 %1676, i1 %1677, i1 false
  br i1 %spec.select1879, label %true_block677, label %after_if679

true_block671:                                    ; preds = %true_block665
  %getch.i2477 = getelementptr i8, i8* %12, i64 418612680
  %1678 = getelementptr inbounds i8, i8* %getch.i2477, i64 %1664
  %1679 = bitcast i8* %1678 to double*
  %1680 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1679, i32 64)
  %1681 = getelementptr inbounds i8, i8* %getch.i2477, i64 %1670
  %1682 = bitcast i8* %1681 to double*
  %1683 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1682, i32 64)
  %1684 = fsub reassoc ninf nsz double %1683, %1680
  %1685 = fsub reassoc ninf nsz double %1673, %1667
  %1686 = fsub reassoc ninf nsz double %175, %1667
  %1687 = fmul reassoc ninf nsz double %1684, %1686
  %1688 = fdiv reassoc ninf nsz double %1687, %1685
  %1689 = fadd reassoc ninf nsz double %1688, %1680
  br label %after_if667

true_block677:                                    ; preds = %after_if667
  %1690 = add i32 %180, 53
  %1691 = sext i32 %1690 to i64
  %1692 = shl nsw i64 %1691, 3
  %1693 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1692
  %1694 = bitcast i8* %1693 to double*
  %1695 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1694, i32 64)
  %1696 = add i32 %180, 54
  %1697 = sext i32 %1696 to i64
  %1698 = shl nsw i64 %1697, 3
  %1699 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1698
  %1700 = bitcast i8* %1699 to double*
  %1701 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1700, i32 64)
  %1702 = fcmp reassoc ninf nsz oge double %175, %1695
  %1703 = fcmp reassoc ninf nsz ole double %175, %1701
  %.01061 = select i1 %1702, i1 %1703, i1 false
  br i1 %.01061, label %true_block683, label %after_if679

after_if679:                                      ; preds = %true_block683, %true_block677, %after_if667
  %.541225 = phi double [ %1717, %true_block683 ], [ %.531224, %true_block677 ], [ %.531224, %after_if667 ]
  %.53 = phi i1 [ true, %true_block683 ], [ %.52, %true_block677 ], [ %.52, %after_if667 ]
  %1704 = icmp ugt i32 %201, 54
  %1705 = xor i1 %.53, true
  %spec.select1880 = select i1 %1704, i1 %1705, i1 false
  br i1 %spec.select1880, label %true_block689, label %after_if691

true_block683:                                    ; preds = %true_block677
  %getch.i2476 = getelementptr i8, i8* %12, i64 418612680
  %1706 = getelementptr inbounds i8, i8* %getch.i2476, i64 %1692
  %1707 = bitcast i8* %1706 to double*
  %1708 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1707, i32 64)
  %1709 = getelementptr inbounds i8, i8* %getch.i2476, i64 %1698
  %1710 = bitcast i8* %1709 to double*
  %1711 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1710, i32 64)
  %1712 = fsub reassoc ninf nsz double %1711, %1708
  %1713 = fsub reassoc ninf nsz double %1701, %1695
  %1714 = fsub reassoc ninf nsz double %175, %1695
  %1715 = fmul reassoc ninf nsz double %1712, %1714
  %1716 = fdiv reassoc ninf nsz double %1715, %1713
  %1717 = fadd reassoc ninf nsz double %1716, %1708
  br label %after_if679

true_block689:                                    ; preds = %after_if679
  %1718 = add i32 %180, 54
  %1719 = sext i32 %1718 to i64
  %1720 = shl nsw i64 %1719, 3
  %1721 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1720
  %1722 = bitcast i8* %1721 to double*
  %1723 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1722, i32 64)
  %1724 = add i32 %180, 55
  %1725 = sext i32 %1724 to i64
  %1726 = shl nsw i64 %1725, 3
  %1727 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1726
  %1728 = bitcast i8* %1727 to double*
  %1729 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1728, i32 64)
  %1730 = fcmp reassoc ninf nsz oge double %175, %1723
  %1731 = fcmp reassoc ninf nsz ole double %175, %1729
  %.01059 = select i1 %1730, i1 %1731, i1 false
  br i1 %.01059, label %true_block695, label %after_if691

after_if691:                                      ; preds = %true_block695, %true_block689, %after_if679
  %.551226 = phi double [ %1745, %true_block695 ], [ %.541225, %true_block689 ], [ %.541225, %after_if679 ]
  %.54 = phi i1 [ true, %true_block695 ], [ %.53, %true_block689 ], [ %.53, %after_if679 ]
  %1732 = icmp ugt i32 %201, 55
  %1733 = xor i1 %.54, true
  %spec.select1881 = select i1 %1732, i1 %1733, i1 false
  br i1 %spec.select1881, label %true_block701, label %after_if703

true_block695:                                    ; preds = %true_block689
  %getch.i2475 = getelementptr i8, i8* %12, i64 418612680
  %1734 = getelementptr inbounds i8, i8* %getch.i2475, i64 %1720
  %1735 = bitcast i8* %1734 to double*
  %1736 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1735, i32 64)
  %1737 = getelementptr inbounds i8, i8* %getch.i2475, i64 %1726
  %1738 = bitcast i8* %1737 to double*
  %1739 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1738, i32 64)
  %1740 = fsub reassoc ninf nsz double %1739, %1736
  %1741 = fsub reassoc ninf nsz double %1729, %1723
  %1742 = fsub reassoc ninf nsz double %175, %1723
  %1743 = fmul reassoc ninf nsz double %1740, %1742
  %1744 = fdiv reassoc ninf nsz double %1743, %1741
  %1745 = fadd reassoc ninf nsz double %1744, %1736
  br label %after_if691

true_block701:                                    ; preds = %after_if691
  %1746 = add i32 %180, 55
  %1747 = sext i32 %1746 to i64
  %1748 = shl nsw i64 %1747, 3
  %1749 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1748
  %1750 = bitcast i8* %1749 to double*
  %1751 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1750, i32 64)
  %1752 = add i32 %180, 56
  %1753 = sext i32 %1752 to i64
  %1754 = shl nsw i64 %1753, 3
  %1755 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1754
  %1756 = bitcast i8* %1755 to double*
  %1757 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1756, i32 64)
  %1758 = fcmp reassoc ninf nsz oge double %175, %1751
  %1759 = fcmp reassoc ninf nsz ole double %175, %1757
  %.01057 = select i1 %1758, i1 %1759, i1 false
  br i1 %.01057, label %true_block707, label %after_if703

after_if703:                                      ; preds = %true_block707, %true_block701, %after_if691
  %.561227 = phi double [ %1773, %true_block707 ], [ %.551226, %true_block701 ], [ %.551226, %after_if691 ]
  %.55 = phi i1 [ true, %true_block707 ], [ %.54, %true_block701 ], [ %.54, %after_if691 ]
  %1760 = icmp ugt i32 %201, 56
  %1761 = xor i1 %.55, true
  %spec.select1882 = select i1 %1760, i1 %1761, i1 false
  br i1 %spec.select1882, label %true_block713, label %after_if715

true_block707:                                    ; preds = %true_block701
  %getch.i2474 = getelementptr i8, i8* %12, i64 418612680
  %1762 = getelementptr inbounds i8, i8* %getch.i2474, i64 %1748
  %1763 = bitcast i8* %1762 to double*
  %1764 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1763, i32 64)
  %1765 = getelementptr inbounds i8, i8* %getch.i2474, i64 %1754
  %1766 = bitcast i8* %1765 to double*
  %1767 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1766, i32 64)
  %1768 = fsub reassoc ninf nsz double %1767, %1764
  %1769 = fsub reassoc ninf nsz double %1757, %1751
  %1770 = fsub reassoc ninf nsz double %175, %1751
  %1771 = fmul reassoc ninf nsz double %1768, %1770
  %1772 = fdiv reassoc ninf nsz double %1771, %1769
  %1773 = fadd reassoc ninf nsz double %1772, %1764
  br label %after_if703

true_block713:                                    ; preds = %after_if703
  %1774 = add i32 %180, 56
  %1775 = sext i32 %1774 to i64
  %1776 = shl nsw i64 %1775, 3
  %1777 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1776
  %1778 = bitcast i8* %1777 to double*
  %1779 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1778, i32 64)
  %1780 = add i32 %180, 57
  %1781 = sext i32 %1780 to i64
  %1782 = shl nsw i64 %1781, 3
  %1783 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1782
  %1784 = bitcast i8* %1783 to double*
  %1785 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1784, i32 64)
  %1786 = fcmp reassoc ninf nsz oge double %175, %1779
  %1787 = fcmp reassoc ninf nsz ole double %175, %1785
  %.01055 = select i1 %1786, i1 %1787, i1 false
  br i1 %.01055, label %true_block719, label %after_if715

after_if715:                                      ; preds = %true_block719, %true_block713, %after_if703
  %.571228 = phi double [ %1801, %true_block719 ], [ %.561227, %true_block713 ], [ %.561227, %after_if703 ]
  %.56 = phi i1 [ true, %true_block719 ], [ %.55, %true_block713 ], [ %.55, %after_if703 ]
  %1788 = icmp ugt i32 %201, 57
  %1789 = xor i1 %.56, true
  %spec.select1883 = select i1 %1788, i1 %1789, i1 false
  br i1 %spec.select1883, label %true_block725, label %after_if727

true_block719:                                    ; preds = %true_block713
  %getch.i2473 = getelementptr i8, i8* %12, i64 418612680
  %1790 = getelementptr inbounds i8, i8* %getch.i2473, i64 %1776
  %1791 = bitcast i8* %1790 to double*
  %1792 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1791, i32 64)
  %1793 = getelementptr inbounds i8, i8* %getch.i2473, i64 %1782
  %1794 = bitcast i8* %1793 to double*
  %1795 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1794, i32 64)
  %1796 = fsub reassoc ninf nsz double %1795, %1792
  %1797 = fsub reassoc ninf nsz double %1785, %1779
  %1798 = fsub reassoc ninf nsz double %175, %1779
  %1799 = fmul reassoc ninf nsz double %1796, %1798
  %1800 = fdiv reassoc ninf nsz double %1799, %1797
  %1801 = fadd reassoc ninf nsz double %1800, %1792
  br label %after_if715

true_block725:                                    ; preds = %after_if715
  %1802 = add i32 %180, 57
  %1803 = sext i32 %1802 to i64
  %1804 = shl nsw i64 %1803, 3
  %1805 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1804
  %1806 = bitcast i8* %1805 to double*
  %1807 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1806, i32 64)
  %1808 = add i32 %180, 58
  %1809 = sext i32 %1808 to i64
  %1810 = shl nsw i64 %1809, 3
  %1811 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1810
  %1812 = bitcast i8* %1811 to double*
  %1813 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1812, i32 64)
  %1814 = fcmp reassoc ninf nsz oge double %175, %1807
  %1815 = fcmp reassoc ninf nsz ole double %175, %1813
  %.01053 = select i1 %1814, i1 %1815, i1 false
  br i1 %.01053, label %true_block731, label %after_if727

after_if727:                                      ; preds = %true_block731, %true_block725, %after_if715
  %.581229 = phi double [ %1829, %true_block731 ], [ %.571228, %true_block725 ], [ %.571228, %after_if715 ]
  %.57 = phi i1 [ true, %true_block731 ], [ %.56, %true_block725 ], [ %.56, %after_if715 ]
  %1816 = icmp ugt i32 %201, 58
  %1817 = xor i1 %.57, true
  %spec.select1884 = select i1 %1816, i1 %1817, i1 false
  br i1 %spec.select1884, label %true_block737, label %after_if739

true_block731:                                    ; preds = %true_block725
  %getch.i2472 = getelementptr i8, i8* %12, i64 418612680
  %1818 = getelementptr inbounds i8, i8* %getch.i2472, i64 %1804
  %1819 = bitcast i8* %1818 to double*
  %1820 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1819, i32 64)
  %1821 = getelementptr inbounds i8, i8* %getch.i2472, i64 %1810
  %1822 = bitcast i8* %1821 to double*
  %1823 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1822, i32 64)
  %1824 = fsub reassoc ninf nsz double %1823, %1820
  %1825 = fsub reassoc ninf nsz double %1813, %1807
  %1826 = fsub reassoc ninf nsz double %175, %1807
  %1827 = fmul reassoc ninf nsz double %1824, %1826
  %1828 = fdiv reassoc ninf nsz double %1827, %1825
  %1829 = fadd reassoc ninf nsz double %1828, %1820
  br label %after_if727

true_block737:                                    ; preds = %after_if727
  %1830 = add i32 %180, 58
  %1831 = sext i32 %1830 to i64
  %1832 = shl nsw i64 %1831, 3
  %1833 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1832
  %1834 = bitcast i8* %1833 to double*
  %1835 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1834, i32 64)
  %1836 = add i32 %180, 59
  %1837 = sext i32 %1836 to i64
  %1838 = shl nsw i64 %1837, 3
  %1839 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1838
  %1840 = bitcast i8* %1839 to double*
  %1841 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1840, i32 64)
  %1842 = fcmp reassoc ninf nsz oge double %175, %1835
  %1843 = fcmp reassoc ninf nsz ole double %175, %1841
  %.01051 = select i1 %1842, i1 %1843, i1 false
  br i1 %.01051, label %true_block743, label %after_if739

after_if739:                                      ; preds = %true_block743, %true_block737, %after_if727
  %.591230 = phi double [ %1857, %true_block743 ], [ %.581229, %true_block737 ], [ %.581229, %after_if727 ]
  %.58 = phi i1 [ true, %true_block743 ], [ %.57, %true_block737 ], [ %.57, %after_if727 ]
  %1844 = icmp ugt i32 %201, 59
  %1845 = xor i1 %.58, true
  %spec.select1885 = select i1 %1844, i1 %1845, i1 false
  br i1 %spec.select1885, label %true_block749, label %after_if751

true_block743:                                    ; preds = %true_block737
  %getch.i2471 = getelementptr i8, i8* %12, i64 418612680
  %1846 = getelementptr inbounds i8, i8* %getch.i2471, i64 %1832
  %1847 = bitcast i8* %1846 to double*
  %1848 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1847, i32 64)
  %1849 = getelementptr inbounds i8, i8* %getch.i2471, i64 %1838
  %1850 = bitcast i8* %1849 to double*
  %1851 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1850, i32 64)
  %1852 = fsub reassoc ninf nsz double %1851, %1848
  %1853 = fsub reassoc ninf nsz double %1841, %1835
  %1854 = fsub reassoc ninf nsz double %175, %1835
  %1855 = fmul reassoc ninf nsz double %1852, %1854
  %1856 = fdiv reassoc ninf nsz double %1855, %1853
  %1857 = fadd reassoc ninf nsz double %1856, %1848
  br label %after_if739

true_block749:                                    ; preds = %after_if739
  %1858 = add i32 %180, 59
  %1859 = sext i32 %1858 to i64
  %1860 = shl nsw i64 %1859, 3
  %1861 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1860
  %1862 = bitcast i8* %1861 to double*
  %1863 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1862, i32 64)
  %1864 = add i32 %180, 60
  %1865 = sext i32 %1864 to i64
  %1866 = shl nsw i64 %1865, 3
  %1867 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1866
  %1868 = bitcast i8* %1867 to double*
  %1869 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1868, i32 64)
  %1870 = fcmp reassoc ninf nsz oge double %175, %1863
  %1871 = fcmp reassoc ninf nsz ole double %175, %1869
  %.01049 = select i1 %1870, i1 %1871, i1 false
  br i1 %.01049, label %true_block755, label %after_if751

after_if751:                                      ; preds = %true_block755, %true_block749, %after_if739
  %.601231 = phi double [ %1885, %true_block755 ], [ %.591230, %true_block749 ], [ %.591230, %after_if739 ]
  %.59 = phi i1 [ true, %true_block755 ], [ %.58, %true_block749 ], [ %.58, %after_if739 ]
  %1872 = icmp ugt i32 %201, 60
  %1873 = xor i1 %.59, true
  %spec.select1886 = select i1 %1872, i1 %1873, i1 false
  br i1 %spec.select1886, label %true_block761, label %after_if763

true_block755:                                    ; preds = %true_block749
  %getch.i2470 = getelementptr i8, i8* %12, i64 418612680
  %1874 = getelementptr inbounds i8, i8* %getch.i2470, i64 %1860
  %1875 = bitcast i8* %1874 to double*
  %1876 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1875, i32 64)
  %1877 = getelementptr inbounds i8, i8* %getch.i2470, i64 %1866
  %1878 = bitcast i8* %1877 to double*
  %1879 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1878, i32 64)
  %1880 = fsub reassoc ninf nsz double %1879, %1876
  %1881 = fsub reassoc ninf nsz double %1869, %1863
  %1882 = fsub reassoc ninf nsz double %175, %1863
  %1883 = fmul reassoc ninf nsz double %1880, %1882
  %1884 = fdiv reassoc ninf nsz double %1883, %1881
  %1885 = fadd reassoc ninf nsz double %1884, %1876
  br label %after_if751

true_block761:                                    ; preds = %after_if751
  %1886 = add i32 %180, 60
  %1887 = sext i32 %1886 to i64
  %1888 = shl nsw i64 %1887, 3
  %1889 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1888
  %1890 = bitcast i8* %1889 to double*
  %1891 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1890, i32 64)
  %1892 = add i32 %180, 61
  %1893 = sext i32 %1892 to i64
  %1894 = shl nsw i64 %1893, 3
  %1895 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1894
  %1896 = bitcast i8* %1895 to double*
  %1897 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1896, i32 64)
  %1898 = fcmp reassoc ninf nsz oge double %175, %1891
  %1899 = fcmp reassoc ninf nsz ole double %175, %1897
  %.01047 = select i1 %1898, i1 %1899, i1 false
  br i1 %.01047, label %true_block767, label %after_if763

after_if763:                                      ; preds = %true_block767, %true_block761, %after_if751
  %.611232 = phi double [ %1913, %true_block767 ], [ %.601231, %true_block761 ], [ %.601231, %after_if751 ]
  %.60 = phi i1 [ true, %true_block767 ], [ %.59, %true_block761 ], [ %.59, %after_if751 ]
  %1900 = icmp ugt i32 %201, 61
  %1901 = xor i1 %.60, true
  %spec.select1887 = select i1 %1900, i1 %1901, i1 false
  br i1 %spec.select1887, label %true_block773, label %after_if775

true_block767:                                    ; preds = %true_block761
  %getch.i2469 = getelementptr i8, i8* %12, i64 418612680
  %1902 = getelementptr inbounds i8, i8* %getch.i2469, i64 %1888
  %1903 = bitcast i8* %1902 to double*
  %1904 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1903, i32 64)
  %1905 = getelementptr inbounds i8, i8* %getch.i2469, i64 %1894
  %1906 = bitcast i8* %1905 to double*
  %1907 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1906, i32 64)
  %1908 = fsub reassoc ninf nsz double %1907, %1904
  %1909 = fsub reassoc ninf nsz double %1897, %1891
  %1910 = fsub reassoc ninf nsz double %175, %1891
  %1911 = fmul reassoc ninf nsz double %1908, %1910
  %1912 = fdiv reassoc ninf nsz double %1911, %1909
  %1913 = fadd reassoc ninf nsz double %1912, %1904
  br label %after_if763

true_block773:                                    ; preds = %after_if763
  %1914 = add i32 %180, 61
  %1915 = sext i32 %1914 to i64
  %1916 = shl nsw i64 %1915, 3
  %1917 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1916
  %1918 = bitcast i8* %1917 to double*
  %1919 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1918, i32 64)
  %1920 = add i32 %180, 62
  %1921 = sext i32 %1920 to i64
  %1922 = shl nsw i64 %1921, 3
  %1923 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1922
  %1924 = bitcast i8* %1923 to double*
  %1925 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1924, i32 64)
  %1926 = fcmp reassoc ninf nsz oge double %175, %1919
  %1927 = fcmp reassoc ninf nsz ole double %175, %1925
  %.01045 = select i1 %1926, i1 %1927, i1 false
  br i1 %.01045, label %true_block779, label %after_if775

after_if775:                                      ; preds = %true_block779, %true_block773, %after_if763
  %.621233 = phi double [ %1941, %true_block779 ], [ %.611232, %true_block773 ], [ %.611232, %after_if763 ]
  %.61 = phi i1 [ true, %true_block779 ], [ %.60, %true_block773 ], [ %.60, %after_if763 ]
  %1928 = icmp ugt i32 %201, 62
  %1929 = xor i1 %.61, true
  %spec.select1888 = select i1 %1928, i1 %1929, i1 false
  br i1 %spec.select1888, label %true_block785, label %after_if787

true_block779:                                    ; preds = %true_block773
  %getch.i2468 = getelementptr i8, i8* %12, i64 418612680
  %1930 = getelementptr inbounds i8, i8* %getch.i2468, i64 %1916
  %1931 = bitcast i8* %1930 to double*
  %1932 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1931, i32 64)
  %1933 = getelementptr inbounds i8, i8* %getch.i2468, i64 %1922
  %1934 = bitcast i8* %1933 to double*
  %1935 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1934, i32 64)
  %1936 = fsub reassoc ninf nsz double %1935, %1932
  %1937 = fsub reassoc ninf nsz double %1925, %1919
  %1938 = fsub reassoc ninf nsz double %175, %1919
  %1939 = fmul reassoc ninf nsz double %1936, %1938
  %1940 = fdiv reassoc ninf nsz double %1939, %1937
  %1941 = fadd reassoc ninf nsz double %1940, %1932
  br label %after_if775

true_block785:                                    ; preds = %after_if775
  %1942 = add i32 %180, 62
  %1943 = sext i32 %1942 to i64
  %1944 = shl nsw i64 %1943, 3
  %1945 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1944
  %1946 = bitcast i8* %1945 to double*
  %1947 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1946, i32 64)
  %1948 = add i32 %180, 63
  %1949 = sext i32 %1948 to i64
  %1950 = shl nsw i64 %1949, 3
  %1951 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1950
  %1952 = bitcast i8* %1951 to double*
  %1953 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1952, i32 64)
  %1954 = fcmp reassoc ninf nsz oge double %175, %1947
  %1955 = fcmp reassoc ninf nsz ole double %175, %1953
  %.01043 = select i1 %1954, i1 %1955, i1 false
  br i1 %.01043, label %true_block791, label %after_if787

after_if787:                                      ; preds = %true_block791, %true_block785, %after_if775
  %.631234 = phi double [ %1969, %true_block791 ], [ %.621233, %true_block785 ], [ %.621233, %after_if775 ]
  %.62 = phi i1 [ true, %true_block791 ], [ %.61, %true_block785 ], [ %.61, %after_if775 ]
  %1956 = icmp ugt i32 %201, 63
  %1957 = xor i1 %.62, true
  %spec.select1889 = select i1 %1956, i1 %1957, i1 false
  br i1 %spec.select1889, label %true_block797, label %after_if799

true_block791:                                    ; preds = %true_block785
  %getch.i2467 = getelementptr i8, i8* %12, i64 418612680
  %1958 = getelementptr inbounds i8, i8* %getch.i2467, i64 %1944
  %1959 = bitcast i8* %1958 to double*
  %1960 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1959, i32 64)
  %1961 = getelementptr inbounds i8, i8* %getch.i2467, i64 %1950
  %1962 = bitcast i8* %1961 to double*
  %1963 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1962, i32 64)
  %1964 = fsub reassoc ninf nsz double %1963, %1960
  %1965 = fsub reassoc ninf nsz double %1953, %1947
  %1966 = fsub reassoc ninf nsz double %175, %1947
  %1967 = fmul reassoc ninf nsz double %1964, %1966
  %1968 = fdiv reassoc ninf nsz double %1967, %1965
  %1969 = fadd reassoc ninf nsz double %1968, %1960
  br label %after_if787

true_block797:                                    ; preds = %after_if787
  %1970 = add i32 %180, 63
  %1971 = sext i32 %1970 to i64
  %1972 = shl nsw i64 %1971, 3
  %1973 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1972
  %1974 = bitcast i8* %1973 to double*
  %1975 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1974, i32 64)
  %1976 = add i32 %180, 64
  %1977 = sext i32 %1976 to i64
  %1978 = shl nsw i64 %1977, 3
  %1979 = getelementptr inbounds i8, i8* %getch.i2533, i64 %1978
  %1980 = bitcast i8* %1979 to double*
  %1981 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1980, i32 64)
  %1982 = fcmp reassoc ninf nsz oge double %175, %1975
  %1983 = fcmp reassoc ninf nsz ole double %175, %1981
  %.01041 = select i1 %1982, i1 %1983, i1 false
  br i1 %.01041, label %true_block803, label %after_if799

after_if799:                                      ; preds = %true_block803, %true_block797, %after_if787
  %.641235 = phi double [ %1997, %true_block803 ], [ %.631234, %true_block797 ], [ %.631234, %after_if787 ]
  %.63 = phi i1 [ true, %true_block803 ], [ %.62, %true_block797 ], [ %.62, %after_if787 ]
  %1984 = icmp ugt i32 %201, 64
  %1985 = xor i1 %.63, true
  %spec.select1890 = select i1 %1984, i1 %1985, i1 false
  br i1 %spec.select1890, label %true_block809, label %after_if811

true_block803:                                    ; preds = %true_block797
  %getch.i2466 = getelementptr i8, i8* %12, i64 418612680
  %1986 = getelementptr inbounds i8, i8* %getch.i2466, i64 %1972
  %1987 = bitcast i8* %1986 to double*
  %1988 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %1987, i32 64)
  %1989 = getelementptr inbounds i8, i8* %getch.i2466, i64 %1978
  %1990 = bitcast i8* %1989 to double*
  %1991 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %1990, i32 64)
  %1992 = fsub reassoc ninf nsz double %1991, %1988
  %1993 = fsub reassoc ninf nsz double %1981, %1975
  %1994 = fsub reassoc ninf nsz double %175, %1975
  %1995 = fmul reassoc ninf nsz double %1992, %1994
  %1996 = fdiv reassoc ninf nsz double %1995, %1993
  %1997 = fadd reassoc ninf nsz double %1996, %1988
  br label %after_if799

true_block809:                                    ; preds = %after_if799
  %1998 = add i32 %180, 64
  %1999 = sext i32 %1998 to i64
  %2000 = shl nsw i64 %1999, 3
  %2001 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2000
  %2002 = bitcast i8* %2001 to double*
  %2003 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2002, i32 64)
  %2004 = add i32 %180, 65
  %2005 = sext i32 %2004 to i64
  %2006 = shl nsw i64 %2005, 3
  %2007 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2006
  %2008 = bitcast i8* %2007 to double*
  %2009 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2008, i32 64)
  %2010 = fcmp reassoc ninf nsz oge double %175, %2003
  %2011 = fcmp reassoc ninf nsz ole double %175, %2009
  %.01039 = select i1 %2010, i1 %2011, i1 false
  br i1 %.01039, label %true_block815, label %after_if811

after_if811:                                      ; preds = %true_block815, %true_block809, %after_if799
  %.651236 = phi double [ %2025, %true_block815 ], [ %.641235, %true_block809 ], [ %.641235, %after_if799 ]
  %.64 = phi i1 [ true, %true_block815 ], [ %.63, %true_block809 ], [ %.63, %after_if799 ]
  %2012 = icmp ugt i32 %201, 65
  %2013 = xor i1 %.64, true
  %spec.select1891 = select i1 %2012, i1 %2013, i1 false
  br i1 %spec.select1891, label %true_block821, label %after_if823

true_block815:                                    ; preds = %true_block809
  %getch.i2465 = getelementptr i8, i8* %12, i64 418612680
  %2014 = getelementptr inbounds i8, i8* %getch.i2465, i64 %2000
  %2015 = bitcast i8* %2014 to double*
  %2016 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2015, i32 64)
  %2017 = getelementptr inbounds i8, i8* %getch.i2465, i64 %2006
  %2018 = bitcast i8* %2017 to double*
  %2019 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2018, i32 64)
  %2020 = fsub reassoc ninf nsz double %2019, %2016
  %2021 = fsub reassoc ninf nsz double %2009, %2003
  %2022 = fsub reassoc ninf nsz double %175, %2003
  %2023 = fmul reassoc ninf nsz double %2020, %2022
  %2024 = fdiv reassoc ninf nsz double %2023, %2021
  %2025 = fadd reassoc ninf nsz double %2024, %2016
  br label %after_if811

true_block821:                                    ; preds = %after_if811
  %2026 = add i32 %180, 65
  %2027 = sext i32 %2026 to i64
  %2028 = shl nsw i64 %2027, 3
  %2029 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2028
  %2030 = bitcast i8* %2029 to double*
  %2031 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2030, i32 64)
  %2032 = add i32 %180, 66
  %2033 = sext i32 %2032 to i64
  %2034 = shl nsw i64 %2033, 3
  %2035 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2034
  %2036 = bitcast i8* %2035 to double*
  %2037 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2036, i32 64)
  %2038 = fcmp reassoc ninf nsz oge double %175, %2031
  %2039 = fcmp reassoc ninf nsz ole double %175, %2037
  %.01037 = select i1 %2038, i1 %2039, i1 false
  br i1 %.01037, label %true_block827, label %after_if823

after_if823:                                      ; preds = %true_block827, %true_block821, %after_if811
  %.661237 = phi double [ %2053, %true_block827 ], [ %.651236, %true_block821 ], [ %.651236, %after_if811 ]
  %.65 = phi i1 [ true, %true_block827 ], [ %.64, %true_block821 ], [ %.64, %after_if811 ]
  %2040 = icmp ugt i32 %201, 66
  %2041 = xor i1 %.65, true
  %spec.select1892 = select i1 %2040, i1 %2041, i1 false
  br i1 %spec.select1892, label %true_block833, label %after_if835

true_block827:                                    ; preds = %true_block821
  %getch.i2464 = getelementptr i8, i8* %12, i64 418612680
  %2042 = getelementptr inbounds i8, i8* %getch.i2464, i64 %2028
  %2043 = bitcast i8* %2042 to double*
  %2044 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2043, i32 64)
  %2045 = getelementptr inbounds i8, i8* %getch.i2464, i64 %2034
  %2046 = bitcast i8* %2045 to double*
  %2047 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2046, i32 64)
  %2048 = fsub reassoc ninf nsz double %2047, %2044
  %2049 = fsub reassoc ninf nsz double %2037, %2031
  %2050 = fsub reassoc ninf nsz double %175, %2031
  %2051 = fmul reassoc ninf nsz double %2048, %2050
  %2052 = fdiv reassoc ninf nsz double %2051, %2049
  %2053 = fadd reassoc ninf nsz double %2052, %2044
  br label %after_if823

true_block833:                                    ; preds = %after_if823
  %2054 = add i32 %180, 66
  %2055 = sext i32 %2054 to i64
  %2056 = shl nsw i64 %2055, 3
  %2057 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2056
  %2058 = bitcast i8* %2057 to double*
  %2059 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2058, i32 64)
  %2060 = add i32 %180, 67
  %2061 = sext i32 %2060 to i64
  %2062 = shl nsw i64 %2061, 3
  %2063 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2062
  %2064 = bitcast i8* %2063 to double*
  %2065 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2064, i32 64)
  %2066 = fcmp reassoc ninf nsz oge double %175, %2059
  %2067 = fcmp reassoc ninf nsz ole double %175, %2065
  %.01035 = select i1 %2066, i1 %2067, i1 false
  br i1 %.01035, label %true_block839, label %after_if835

after_if835:                                      ; preds = %true_block839, %true_block833, %after_if823
  %.671238 = phi double [ %2081, %true_block839 ], [ %.661237, %true_block833 ], [ %.661237, %after_if823 ]
  %.66 = phi i1 [ true, %true_block839 ], [ %.65, %true_block833 ], [ %.65, %after_if823 ]
  %2068 = icmp ugt i32 %201, 67
  %2069 = xor i1 %.66, true
  %spec.select1893 = select i1 %2068, i1 %2069, i1 false
  br i1 %spec.select1893, label %true_block845, label %after_if847

true_block839:                                    ; preds = %true_block833
  %getch.i2463 = getelementptr i8, i8* %12, i64 418612680
  %2070 = getelementptr inbounds i8, i8* %getch.i2463, i64 %2056
  %2071 = bitcast i8* %2070 to double*
  %2072 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2071, i32 64)
  %2073 = getelementptr inbounds i8, i8* %getch.i2463, i64 %2062
  %2074 = bitcast i8* %2073 to double*
  %2075 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2074, i32 64)
  %2076 = fsub reassoc ninf nsz double %2075, %2072
  %2077 = fsub reassoc ninf nsz double %2065, %2059
  %2078 = fsub reassoc ninf nsz double %175, %2059
  %2079 = fmul reassoc ninf nsz double %2076, %2078
  %2080 = fdiv reassoc ninf nsz double %2079, %2077
  %2081 = fadd reassoc ninf nsz double %2080, %2072
  br label %after_if835

true_block845:                                    ; preds = %after_if835
  %2082 = add i32 %180, 67
  %2083 = sext i32 %2082 to i64
  %2084 = shl nsw i64 %2083, 3
  %2085 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2084
  %2086 = bitcast i8* %2085 to double*
  %2087 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2086, i32 64)
  %2088 = add i32 %180, 68
  %2089 = sext i32 %2088 to i64
  %2090 = shl nsw i64 %2089, 3
  %2091 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2090
  %2092 = bitcast i8* %2091 to double*
  %2093 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2092, i32 64)
  %2094 = fcmp reassoc ninf nsz oge double %175, %2087
  %2095 = fcmp reassoc ninf nsz ole double %175, %2093
  %.01033 = select i1 %2094, i1 %2095, i1 false
  br i1 %.01033, label %true_block851, label %after_if847

after_if847:                                      ; preds = %true_block851, %true_block845, %after_if835
  %.681239 = phi double [ %2109, %true_block851 ], [ %.671238, %true_block845 ], [ %.671238, %after_if835 ]
  %.67 = phi i1 [ true, %true_block851 ], [ %.66, %true_block845 ], [ %.66, %after_if835 ]
  %2096 = icmp ugt i32 %201, 68
  %2097 = xor i1 %.67, true
  %spec.select1894 = select i1 %2096, i1 %2097, i1 false
  br i1 %spec.select1894, label %true_block857, label %after_if859

true_block851:                                    ; preds = %true_block845
  %getch.i2462 = getelementptr i8, i8* %12, i64 418612680
  %2098 = getelementptr inbounds i8, i8* %getch.i2462, i64 %2084
  %2099 = bitcast i8* %2098 to double*
  %2100 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2099, i32 64)
  %2101 = getelementptr inbounds i8, i8* %getch.i2462, i64 %2090
  %2102 = bitcast i8* %2101 to double*
  %2103 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2102, i32 64)
  %2104 = fsub reassoc ninf nsz double %2103, %2100
  %2105 = fsub reassoc ninf nsz double %2093, %2087
  %2106 = fsub reassoc ninf nsz double %175, %2087
  %2107 = fmul reassoc ninf nsz double %2104, %2106
  %2108 = fdiv reassoc ninf nsz double %2107, %2105
  %2109 = fadd reassoc ninf nsz double %2108, %2100
  br label %after_if847

true_block857:                                    ; preds = %after_if847
  %2110 = add i32 %180, 68
  %2111 = sext i32 %2110 to i64
  %2112 = shl nsw i64 %2111, 3
  %2113 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2112
  %2114 = bitcast i8* %2113 to double*
  %2115 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2114, i32 64)
  %2116 = add i32 %180, 69
  %2117 = sext i32 %2116 to i64
  %2118 = shl nsw i64 %2117, 3
  %2119 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2118
  %2120 = bitcast i8* %2119 to double*
  %2121 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2120, i32 64)
  %2122 = fcmp reassoc ninf nsz oge double %175, %2115
  %2123 = fcmp reassoc ninf nsz ole double %175, %2121
  %.01031 = select i1 %2122, i1 %2123, i1 false
  br i1 %.01031, label %true_block863, label %after_if859

after_if859:                                      ; preds = %true_block863, %true_block857, %after_if847
  %.691240 = phi double [ %2137, %true_block863 ], [ %.681239, %true_block857 ], [ %.681239, %after_if847 ]
  %.68 = phi i1 [ true, %true_block863 ], [ %.67, %true_block857 ], [ %.67, %after_if847 ]
  %2124 = icmp ugt i32 %201, 69
  %2125 = xor i1 %.68, true
  %spec.select1895 = select i1 %2124, i1 %2125, i1 false
  br i1 %spec.select1895, label %true_block869, label %after_if871

true_block863:                                    ; preds = %true_block857
  %getch.i2461 = getelementptr i8, i8* %12, i64 418612680
  %2126 = getelementptr inbounds i8, i8* %getch.i2461, i64 %2112
  %2127 = bitcast i8* %2126 to double*
  %2128 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2127, i32 64)
  %2129 = getelementptr inbounds i8, i8* %getch.i2461, i64 %2118
  %2130 = bitcast i8* %2129 to double*
  %2131 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2130, i32 64)
  %2132 = fsub reassoc ninf nsz double %2131, %2128
  %2133 = fsub reassoc ninf nsz double %2121, %2115
  %2134 = fsub reassoc ninf nsz double %175, %2115
  %2135 = fmul reassoc ninf nsz double %2132, %2134
  %2136 = fdiv reassoc ninf nsz double %2135, %2133
  %2137 = fadd reassoc ninf nsz double %2136, %2128
  br label %after_if859

true_block869:                                    ; preds = %after_if859
  %2138 = add i32 %180, 69
  %2139 = sext i32 %2138 to i64
  %2140 = shl nsw i64 %2139, 3
  %2141 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2140
  %2142 = bitcast i8* %2141 to double*
  %2143 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2142, i32 64)
  %2144 = add i32 %180, 70
  %2145 = sext i32 %2144 to i64
  %2146 = shl nsw i64 %2145, 3
  %2147 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2146
  %2148 = bitcast i8* %2147 to double*
  %2149 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2148, i32 64)
  %2150 = fcmp reassoc ninf nsz oge double %175, %2143
  %2151 = fcmp reassoc ninf nsz ole double %175, %2149
  %.01029 = select i1 %2150, i1 %2151, i1 false
  br i1 %.01029, label %true_block875, label %after_if871

after_if871:                                      ; preds = %true_block875, %true_block869, %after_if859
  %.701241 = phi double [ %2165, %true_block875 ], [ %.691240, %true_block869 ], [ %.691240, %after_if859 ]
  %.69 = phi i1 [ true, %true_block875 ], [ %.68, %true_block869 ], [ %.68, %after_if859 ]
  %2152 = icmp ugt i32 %201, 70
  %2153 = xor i1 %.69, true
  %spec.select1896 = select i1 %2152, i1 %2153, i1 false
  br i1 %spec.select1896, label %true_block881, label %after_if883

true_block875:                                    ; preds = %true_block869
  %getch.i2460 = getelementptr i8, i8* %12, i64 418612680
  %2154 = getelementptr inbounds i8, i8* %getch.i2460, i64 %2140
  %2155 = bitcast i8* %2154 to double*
  %2156 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2155, i32 64)
  %2157 = getelementptr inbounds i8, i8* %getch.i2460, i64 %2146
  %2158 = bitcast i8* %2157 to double*
  %2159 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2158, i32 64)
  %2160 = fsub reassoc ninf nsz double %2159, %2156
  %2161 = fsub reassoc ninf nsz double %2149, %2143
  %2162 = fsub reassoc ninf nsz double %175, %2143
  %2163 = fmul reassoc ninf nsz double %2160, %2162
  %2164 = fdiv reassoc ninf nsz double %2163, %2161
  %2165 = fadd reassoc ninf nsz double %2164, %2156
  br label %after_if871

true_block881:                                    ; preds = %after_if871
  %2166 = add i32 %180, 70
  %2167 = sext i32 %2166 to i64
  %2168 = shl nsw i64 %2167, 3
  %2169 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2168
  %2170 = bitcast i8* %2169 to double*
  %2171 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2170, i32 64)
  %2172 = add i32 %180, 71
  %2173 = sext i32 %2172 to i64
  %2174 = shl nsw i64 %2173, 3
  %2175 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2174
  %2176 = bitcast i8* %2175 to double*
  %2177 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2176, i32 64)
  %2178 = fcmp reassoc ninf nsz oge double %175, %2171
  %2179 = fcmp reassoc ninf nsz ole double %175, %2177
  %.01027 = select i1 %2178, i1 %2179, i1 false
  br i1 %.01027, label %true_block887, label %after_if883

after_if883:                                      ; preds = %true_block887, %true_block881, %after_if871
  %.711242 = phi double [ %2193, %true_block887 ], [ %.701241, %true_block881 ], [ %.701241, %after_if871 ]
  %.70 = phi i1 [ true, %true_block887 ], [ %.69, %true_block881 ], [ %.69, %after_if871 ]
  %2180 = icmp ugt i32 %201, 71
  %2181 = xor i1 %.70, true
  %spec.select1897 = select i1 %2180, i1 %2181, i1 false
  br i1 %spec.select1897, label %true_block893, label %after_if895

true_block887:                                    ; preds = %true_block881
  %getch.i2459 = getelementptr i8, i8* %12, i64 418612680
  %2182 = getelementptr inbounds i8, i8* %getch.i2459, i64 %2168
  %2183 = bitcast i8* %2182 to double*
  %2184 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2183, i32 64)
  %2185 = getelementptr inbounds i8, i8* %getch.i2459, i64 %2174
  %2186 = bitcast i8* %2185 to double*
  %2187 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2186, i32 64)
  %2188 = fsub reassoc ninf nsz double %2187, %2184
  %2189 = fsub reassoc ninf nsz double %2177, %2171
  %2190 = fsub reassoc ninf nsz double %175, %2171
  %2191 = fmul reassoc ninf nsz double %2188, %2190
  %2192 = fdiv reassoc ninf nsz double %2191, %2189
  %2193 = fadd reassoc ninf nsz double %2192, %2184
  br label %after_if883

true_block893:                                    ; preds = %after_if883
  %2194 = add i32 %180, 71
  %2195 = sext i32 %2194 to i64
  %2196 = shl nsw i64 %2195, 3
  %2197 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2196
  %2198 = bitcast i8* %2197 to double*
  %2199 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2198, i32 64)
  %2200 = add i32 %180, 72
  %2201 = sext i32 %2200 to i64
  %2202 = shl nsw i64 %2201, 3
  %2203 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2202
  %2204 = bitcast i8* %2203 to double*
  %2205 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2204, i32 64)
  %2206 = fcmp reassoc ninf nsz oge double %175, %2199
  %2207 = fcmp reassoc ninf nsz ole double %175, %2205
  %.01025 = select i1 %2206, i1 %2207, i1 false
  br i1 %.01025, label %true_block899, label %after_if895

after_if895:                                      ; preds = %true_block899, %true_block893, %after_if883
  %.721243 = phi double [ %2221, %true_block899 ], [ %.711242, %true_block893 ], [ %.711242, %after_if883 ]
  %.71 = phi i1 [ true, %true_block899 ], [ %.70, %true_block893 ], [ %.70, %after_if883 ]
  %2208 = icmp ugt i32 %201, 72
  %2209 = xor i1 %.71, true
  %spec.select1898 = select i1 %2208, i1 %2209, i1 false
  br i1 %spec.select1898, label %true_block905, label %after_if907

true_block899:                                    ; preds = %true_block893
  %getch.i2458 = getelementptr i8, i8* %12, i64 418612680
  %2210 = getelementptr inbounds i8, i8* %getch.i2458, i64 %2196
  %2211 = bitcast i8* %2210 to double*
  %2212 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2211, i32 64)
  %2213 = getelementptr inbounds i8, i8* %getch.i2458, i64 %2202
  %2214 = bitcast i8* %2213 to double*
  %2215 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2214, i32 64)
  %2216 = fsub reassoc ninf nsz double %2215, %2212
  %2217 = fsub reassoc ninf nsz double %2205, %2199
  %2218 = fsub reassoc ninf nsz double %175, %2199
  %2219 = fmul reassoc ninf nsz double %2216, %2218
  %2220 = fdiv reassoc ninf nsz double %2219, %2217
  %2221 = fadd reassoc ninf nsz double %2220, %2212
  br label %after_if895

true_block905:                                    ; preds = %after_if895
  %2222 = add i32 %180, 72
  %2223 = sext i32 %2222 to i64
  %2224 = shl nsw i64 %2223, 3
  %2225 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2224
  %2226 = bitcast i8* %2225 to double*
  %2227 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2226, i32 64)
  %2228 = add i32 %180, 73
  %2229 = sext i32 %2228 to i64
  %2230 = shl nsw i64 %2229, 3
  %2231 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2230
  %2232 = bitcast i8* %2231 to double*
  %2233 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2232, i32 64)
  %2234 = fcmp reassoc ninf nsz oge double %175, %2227
  %2235 = fcmp reassoc ninf nsz ole double %175, %2233
  %.01023 = select i1 %2234, i1 %2235, i1 false
  br i1 %.01023, label %true_block911, label %after_if907

after_if907:                                      ; preds = %true_block911, %true_block905, %after_if895
  %.731244 = phi double [ %2249, %true_block911 ], [ %.721243, %true_block905 ], [ %.721243, %after_if895 ]
  %.72 = phi i1 [ true, %true_block911 ], [ %.71, %true_block905 ], [ %.71, %after_if895 ]
  %2236 = icmp ugt i32 %201, 73
  %2237 = xor i1 %.72, true
  %spec.select1899 = select i1 %2236, i1 %2237, i1 false
  br i1 %spec.select1899, label %true_block917, label %after_if919

true_block911:                                    ; preds = %true_block905
  %getch.i2457 = getelementptr i8, i8* %12, i64 418612680
  %2238 = getelementptr inbounds i8, i8* %getch.i2457, i64 %2224
  %2239 = bitcast i8* %2238 to double*
  %2240 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2239, i32 64)
  %2241 = getelementptr inbounds i8, i8* %getch.i2457, i64 %2230
  %2242 = bitcast i8* %2241 to double*
  %2243 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2242, i32 64)
  %2244 = fsub reassoc ninf nsz double %2243, %2240
  %2245 = fsub reassoc ninf nsz double %2233, %2227
  %2246 = fsub reassoc ninf nsz double %175, %2227
  %2247 = fmul reassoc ninf nsz double %2244, %2246
  %2248 = fdiv reassoc ninf nsz double %2247, %2245
  %2249 = fadd reassoc ninf nsz double %2248, %2240
  br label %after_if907

true_block917:                                    ; preds = %after_if907
  %2250 = add i32 %180, 73
  %2251 = sext i32 %2250 to i64
  %2252 = shl nsw i64 %2251, 3
  %2253 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2252
  %2254 = bitcast i8* %2253 to double*
  %2255 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2254, i32 64)
  %2256 = add i32 %180, 74
  %2257 = sext i32 %2256 to i64
  %2258 = shl nsw i64 %2257, 3
  %2259 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2258
  %2260 = bitcast i8* %2259 to double*
  %2261 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2260, i32 64)
  %2262 = fcmp reassoc ninf nsz oge double %175, %2255
  %2263 = fcmp reassoc ninf nsz ole double %175, %2261
  %.01021 = select i1 %2262, i1 %2263, i1 false
  br i1 %.01021, label %true_block923, label %after_if919

after_if919:                                      ; preds = %true_block923, %true_block917, %after_if907
  %.741245 = phi double [ %2277, %true_block923 ], [ %.731244, %true_block917 ], [ %.731244, %after_if907 ]
  %.73 = phi i1 [ true, %true_block923 ], [ %.72, %true_block917 ], [ %.72, %after_if907 ]
  %2264 = icmp ugt i32 %201, 74
  %2265 = xor i1 %.73, true
  %spec.select1900 = select i1 %2264, i1 %2265, i1 false
  br i1 %spec.select1900, label %true_block929, label %after_if931

true_block923:                                    ; preds = %true_block917
  %getch.i2456 = getelementptr i8, i8* %12, i64 418612680
  %2266 = getelementptr inbounds i8, i8* %getch.i2456, i64 %2252
  %2267 = bitcast i8* %2266 to double*
  %2268 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2267, i32 64)
  %2269 = getelementptr inbounds i8, i8* %getch.i2456, i64 %2258
  %2270 = bitcast i8* %2269 to double*
  %2271 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2270, i32 64)
  %2272 = fsub reassoc ninf nsz double %2271, %2268
  %2273 = fsub reassoc ninf nsz double %2261, %2255
  %2274 = fsub reassoc ninf nsz double %175, %2255
  %2275 = fmul reassoc ninf nsz double %2272, %2274
  %2276 = fdiv reassoc ninf nsz double %2275, %2273
  %2277 = fadd reassoc ninf nsz double %2276, %2268
  br label %after_if919

true_block929:                                    ; preds = %after_if919
  %2278 = add i32 %180, 74
  %2279 = sext i32 %2278 to i64
  %2280 = shl nsw i64 %2279, 3
  %2281 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2280
  %2282 = bitcast i8* %2281 to double*
  %2283 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2282, i32 64)
  %2284 = add i32 %180, 75
  %2285 = sext i32 %2284 to i64
  %2286 = shl nsw i64 %2285, 3
  %2287 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2286
  %2288 = bitcast i8* %2287 to double*
  %2289 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2288, i32 64)
  %2290 = fcmp reassoc ninf nsz oge double %175, %2283
  %2291 = fcmp reassoc ninf nsz ole double %175, %2289
  %.01019 = select i1 %2290, i1 %2291, i1 false
  br i1 %.01019, label %true_block935, label %after_if931

after_if931:                                      ; preds = %true_block935, %true_block929, %after_if919
  %.751246 = phi double [ %2305, %true_block935 ], [ %.741245, %true_block929 ], [ %.741245, %after_if919 ]
  %.74 = phi i1 [ true, %true_block935 ], [ %.73, %true_block929 ], [ %.73, %after_if919 ]
  %2292 = icmp ugt i32 %201, 75
  %2293 = xor i1 %.74, true
  %spec.select1901 = select i1 %2292, i1 %2293, i1 false
  br i1 %spec.select1901, label %true_block941, label %after_if943

true_block935:                                    ; preds = %true_block929
  %getch.i2455 = getelementptr i8, i8* %12, i64 418612680
  %2294 = getelementptr inbounds i8, i8* %getch.i2455, i64 %2280
  %2295 = bitcast i8* %2294 to double*
  %2296 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2295, i32 64)
  %2297 = getelementptr inbounds i8, i8* %getch.i2455, i64 %2286
  %2298 = bitcast i8* %2297 to double*
  %2299 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2298, i32 64)
  %2300 = fsub reassoc ninf nsz double %2299, %2296
  %2301 = fsub reassoc ninf nsz double %2289, %2283
  %2302 = fsub reassoc ninf nsz double %175, %2283
  %2303 = fmul reassoc ninf nsz double %2300, %2302
  %2304 = fdiv reassoc ninf nsz double %2303, %2301
  %2305 = fadd reassoc ninf nsz double %2304, %2296
  br label %after_if931

true_block941:                                    ; preds = %after_if931
  %2306 = add i32 %180, 75
  %2307 = sext i32 %2306 to i64
  %2308 = shl nsw i64 %2307, 3
  %2309 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2308
  %2310 = bitcast i8* %2309 to double*
  %2311 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2310, i32 64)
  %2312 = add i32 %180, 76
  %2313 = sext i32 %2312 to i64
  %2314 = shl nsw i64 %2313, 3
  %2315 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2314
  %2316 = bitcast i8* %2315 to double*
  %2317 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2316, i32 64)
  %2318 = fcmp reassoc ninf nsz oge double %175, %2311
  %2319 = fcmp reassoc ninf nsz ole double %175, %2317
  %.01017 = select i1 %2318, i1 %2319, i1 false
  br i1 %.01017, label %true_block947, label %after_if943

after_if943:                                      ; preds = %true_block947, %true_block941, %after_if931
  %.761247 = phi double [ %2333, %true_block947 ], [ %.751246, %true_block941 ], [ %.751246, %after_if931 ]
  %.75 = phi i1 [ true, %true_block947 ], [ %.74, %true_block941 ], [ %.74, %after_if931 ]
  %2320 = icmp ugt i32 %201, 76
  %2321 = xor i1 %.75, true
  %spec.select1902 = select i1 %2320, i1 %2321, i1 false
  br i1 %spec.select1902, label %true_block953, label %after_if955

true_block947:                                    ; preds = %true_block941
  %getch.i2454 = getelementptr i8, i8* %12, i64 418612680
  %2322 = getelementptr inbounds i8, i8* %getch.i2454, i64 %2308
  %2323 = bitcast i8* %2322 to double*
  %2324 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2323, i32 64)
  %2325 = getelementptr inbounds i8, i8* %getch.i2454, i64 %2314
  %2326 = bitcast i8* %2325 to double*
  %2327 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2326, i32 64)
  %2328 = fsub reassoc ninf nsz double %2327, %2324
  %2329 = fsub reassoc ninf nsz double %2317, %2311
  %2330 = fsub reassoc ninf nsz double %175, %2311
  %2331 = fmul reassoc ninf nsz double %2328, %2330
  %2332 = fdiv reassoc ninf nsz double %2331, %2329
  %2333 = fadd reassoc ninf nsz double %2332, %2324
  br label %after_if943

true_block953:                                    ; preds = %after_if943
  %2334 = add i32 %180, 76
  %2335 = sext i32 %2334 to i64
  %2336 = shl nsw i64 %2335, 3
  %2337 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2336
  %2338 = bitcast i8* %2337 to double*
  %2339 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2338, i32 64)
  %2340 = add i32 %180, 77
  %2341 = sext i32 %2340 to i64
  %2342 = shl nsw i64 %2341, 3
  %2343 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2342
  %2344 = bitcast i8* %2343 to double*
  %2345 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2344, i32 64)
  %2346 = fcmp reassoc ninf nsz oge double %175, %2339
  %2347 = fcmp reassoc ninf nsz ole double %175, %2345
  %.01015 = select i1 %2346, i1 %2347, i1 false
  br i1 %.01015, label %true_block959, label %after_if955

after_if955:                                      ; preds = %true_block959, %true_block953, %after_if943
  %.771248 = phi double [ %2361, %true_block959 ], [ %.761247, %true_block953 ], [ %.761247, %after_if943 ]
  %.76 = phi i1 [ true, %true_block959 ], [ %.75, %true_block953 ], [ %.75, %after_if943 ]
  %2348 = icmp ugt i32 %201, 77
  %2349 = xor i1 %.76, true
  %spec.select1903 = select i1 %2348, i1 %2349, i1 false
  br i1 %spec.select1903, label %true_block965, label %after_if967

true_block959:                                    ; preds = %true_block953
  %getch.i2453 = getelementptr i8, i8* %12, i64 418612680
  %2350 = getelementptr inbounds i8, i8* %getch.i2453, i64 %2336
  %2351 = bitcast i8* %2350 to double*
  %2352 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2351, i32 64)
  %2353 = getelementptr inbounds i8, i8* %getch.i2453, i64 %2342
  %2354 = bitcast i8* %2353 to double*
  %2355 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2354, i32 64)
  %2356 = fsub reassoc ninf nsz double %2355, %2352
  %2357 = fsub reassoc ninf nsz double %2345, %2339
  %2358 = fsub reassoc ninf nsz double %175, %2339
  %2359 = fmul reassoc ninf nsz double %2356, %2358
  %2360 = fdiv reassoc ninf nsz double %2359, %2357
  %2361 = fadd reassoc ninf nsz double %2360, %2352
  br label %after_if955

true_block965:                                    ; preds = %after_if955
  %2362 = add i32 %180, 77
  %2363 = sext i32 %2362 to i64
  %2364 = shl nsw i64 %2363, 3
  %2365 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2364
  %2366 = bitcast i8* %2365 to double*
  %2367 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2366, i32 64)
  %2368 = add i32 %180, 78
  %2369 = sext i32 %2368 to i64
  %2370 = shl nsw i64 %2369, 3
  %2371 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2370
  %2372 = bitcast i8* %2371 to double*
  %2373 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2372, i32 64)
  %2374 = fcmp reassoc ninf nsz oge double %175, %2367
  %2375 = fcmp reassoc ninf nsz ole double %175, %2373
  %.01013 = select i1 %2374, i1 %2375, i1 false
  br i1 %.01013, label %true_block971, label %after_if967

after_if967:                                      ; preds = %true_block971, %true_block965, %after_if955
  %.781249 = phi double [ %2389, %true_block971 ], [ %.771248, %true_block965 ], [ %.771248, %after_if955 ]
  %.77 = phi i1 [ true, %true_block971 ], [ %.76, %true_block965 ], [ %.76, %after_if955 ]
  %2376 = icmp ugt i32 %201, 78
  %2377 = xor i1 %.77, true
  %spec.select1904 = select i1 %2376, i1 %2377, i1 false
  br i1 %spec.select1904, label %true_block977, label %after_if979

true_block971:                                    ; preds = %true_block965
  %getch.i2452 = getelementptr i8, i8* %12, i64 418612680
  %2378 = getelementptr inbounds i8, i8* %getch.i2452, i64 %2364
  %2379 = bitcast i8* %2378 to double*
  %2380 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2379, i32 64)
  %2381 = getelementptr inbounds i8, i8* %getch.i2452, i64 %2370
  %2382 = bitcast i8* %2381 to double*
  %2383 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2382, i32 64)
  %2384 = fsub reassoc ninf nsz double %2383, %2380
  %2385 = fsub reassoc ninf nsz double %2373, %2367
  %2386 = fsub reassoc ninf nsz double %175, %2367
  %2387 = fmul reassoc ninf nsz double %2384, %2386
  %2388 = fdiv reassoc ninf nsz double %2387, %2385
  %2389 = fadd reassoc ninf nsz double %2388, %2380
  br label %after_if967

true_block977:                                    ; preds = %after_if967
  %2390 = add i32 %180, 78
  %2391 = sext i32 %2390 to i64
  %2392 = shl nsw i64 %2391, 3
  %2393 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2392
  %2394 = bitcast i8* %2393 to double*
  %2395 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2394, i32 64)
  %2396 = add i32 %180, 79
  %2397 = sext i32 %2396 to i64
  %2398 = shl nsw i64 %2397, 3
  %2399 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2398
  %2400 = bitcast i8* %2399 to double*
  %2401 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2400, i32 64)
  %2402 = fcmp reassoc ninf nsz oge double %175, %2395
  %2403 = fcmp reassoc ninf nsz ole double %175, %2401
  %.01011 = select i1 %2402, i1 %2403, i1 false
  br i1 %.01011, label %true_block983, label %after_if979

after_if979:                                      ; preds = %true_block983, %true_block977, %after_if967
  %.791250 = phi double [ %2417, %true_block983 ], [ %.781249, %true_block977 ], [ %.781249, %after_if967 ]
  %.78 = phi i1 [ true, %true_block983 ], [ %.77, %true_block977 ], [ %.77, %after_if967 ]
  %2404 = icmp ugt i32 %201, 79
  %2405 = xor i1 %.78, true
  %spec.select1905 = select i1 %2404, i1 %2405, i1 false
  br i1 %spec.select1905, label %true_block989, label %after_if991

true_block983:                                    ; preds = %true_block977
  %getch.i2451 = getelementptr i8, i8* %12, i64 418612680
  %2406 = getelementptr inbounds i8, i8* %getch.i2451, i64 %2392
  %2407 = bitcast i8* %2406 to double*
  %2408 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2407, i32 64)
  %2409 = getelementptr inbounds i8, i8* %getch.i2451, i64 %2398
  %2410 = bitcast i8* %2409 to double*
  %2411 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2410, i32 64)
  %2412 = fsub reassoc ninf nsz double %2411, %2408
  %2413 = fsub reassoc ninf nsz double %2401, %2395
  %2414 = fsub reassoc ninf nsz double %175, %2395
  %2415 = fmul reassoc ninf nsz double %2412, %2414
  %2416 = fdiv reassoc ninf nsz double %2415, %2413
  %2417 = fadd reassoc ninf nsz double %2416, %2408
  br label %after_if979

true_block989:                                    ; preds = %after_if979
  %2418 = add i32 %180, 79
  %2419 = sext i32 %2418 to i64
  %2420 = shl nsw i64 %2419, 3
  %2421 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2420
  %2422 = bitcast i8* %2421 to double*
  %2423 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2422, i32 64)
  %2424 = add i32 %180, 80
  %2425 = sext i32 %2424 to i64
  %2426 = shl nsw i64 %2425, 3
  %2427 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2426
  %2428 = bitcast i8* %2427 to double*
  %2429 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2428, i32 64)
  %2430 = fcmp reassoc ninf nsz oge double %175, %2423
  %2431 = fcmp reassoc ninf nsz ole double %175, %2429
  %.01009 = select i1 %2430, i1 %2431, i1 false
  br i1 %.01009, label %true_block995, label %after_if991

after_if991:                                      ; preds = %true_block995, %true_block989, %after_if979
  %.801251 = phi double [ %2445, %true_block995 ], [ %.791250, %true_block989 ], [ %.791250, %after_if979 ]
  %.79 = phi i1 [ true, %true_block995 ], [ %.78, %true_block989 ], [ %.78, %after_if979 ]
  %2432 = icmp ugt i32 %201, 80
  %2433 = xor i1 %.79, true
  %spec.select1906 = select i1 %2432, i1 %2433, i1 false
  br i1 %spec.select1906, label %true_block1001, label %after_if1003

true_block995:                                    ; preds = %true_block989
  %getch.i2450 = getelementptr i8, i8* %12, i64 418612680
  %2434 = getelementptr inbounds i8, i8* %getch.i2450, i64 %2420
  %2435 = bitcast i8* %2434 to double*
  %2436 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2435, i32 64)
  %2437 = getelementptr inbounds i8, i8* %getch.i2450, i64 %2426
  %2438 = bitcast i8* %2437 to double*
  %2439 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2438, i32 64)
  %2440 = fsub reassoc ninf nsz double %2439, %2436
  %2441 = fsub reassoc ninf nsz double %2429, %2423
  %2442 = fsub reassoc ninf nsz double %175, %2423
  %2443 = fmul reassoc ninf nsz double %2440, %2442
  %2444 = fdiv reassoc ninf nsz double %2443, %2441
  %2445 = fadd reassoc ninf nsz double %2444, %2436
  br label %after_if991

true_block1001:                                   ; preds = %after_if991
  %2446 = add i32 %180, 80
  %2447 = sext i32 %2446 to i64
  %2448 = shl nsw i64 %2447, 3
  %2449 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2448
  %2450 = bitcast i8* %2449 to double*
  %2451 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2450, i32 64)
  %2452 = add i32 %180, 81
  %2453 = sext i32 %2452 to i64
  %2454 = shl nsw i64 %2453, 3
  %2455 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2454
  %2456 = bitcast i8* %2455 to double*
  %2457 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2456, i32 64)
  %2458 = fcmp reassoc ninf nsz oge double %175, %2451
  %2459 = fcmp reassoc ninf nsz ole double %175, %2457
  %.01007 = select i1 %2458, i1 %2459, i1 false
  br i1 %.01007, label %true_block1007, label %after_if1003

after_if1003:                                     ; preds = %true_block1007, %true_block1001, %after_if991
  %.811252 = phi double [ %2473, %true_block1007 ], [ %.801251, %true_block1001 ], [ %.801251, %after_if991 ]
  %.80 = phi i1 [ true, %true_block1007 ], [ %.79, %true_block1001 ], [ %.79, %after_if991 ]
  %2460 = icmp ugt i32 %201, 81
  %2461 = xor i1 %.80, true
  %spec.select1907 = select i1 %2460, i1 %2461, i1 false
  br i1 %spec.select1907, label %true_block1013, label %after_if1015

true_block1007:                                   ; preds = %true_block1001
  %getch.i2449 = getelementptr i8, i8* %12, i64 418612680
  %2462 = getelementptr inbounds i8, i8* %getch.i2449, i64 %2448
  %2463 = bitcast i8* %2462 to double*
  %2464 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2463, i32 64)
  %2465 = getelementptr inbounds i8, i8* %getch.i2449, i64 %2454
  %2466 = bitcast i8* %2465 to double*
  %2467 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2466, i32 64)
  %2468 = fsub reassoc ninf nsz double %2467, %2464
  %2469 = fsub reassoc ninf nsz double %2457, %2451
  %2470 = fsub reassoc ninf nsz double %175, %2451
  %2471 = fmul reassoc ninf nsz double %2468, %2470
  %2472 = fdiv reassoc ninf nsz double %2471, %2469
  %2473 = fadd reassoc ninf nsz double %2472, %2464
  br label %after_if1003

true_block1013:                                   ; preds = %after_if1003
  %2474 = add i32 %180, 81
  %2475 = sext i32 %2474 to i64
  %2476 = shl nsw i64 %2475, 3
  %2477 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2476
  %2478 = bitcast i8* %2477 to double*
  %2479 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2478, i32 64)
  %2480 = add i32 %180, 82
  %2481 = sext i32 %2480 to i64
  %2482 = shl nsw i64 %2481, 3
  %2483 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2482
  %2484 = bitcast i8* %2483 to double*
  %2485 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2484, i32 64)
  %2486 = fcmp reassoc ninf nsz oge double %175, %2479
  %2487 = fcmp reassoc ninf nsz ole double %175, %2485
  %.01005 = select i1 %2486, i1 %2487, i1 false
  br i1 %.01005, label %true_block1019, label %after_if1015

after_if1015:                                     ; preds = %true_block1019, %true_block1013, %after_if1003
  %.821253 = phi double [ %2501, %true_block1019 ], [ %.811252, %true_block1013 ], [ %.811252, %after_if1003 ]
  %.81 = phi i1 [ true, %true_block1019 ], [ %.80, %true_block1013 ], [ %.80, %after_if1003 ]
  %2488 = icmp ugt i32 %201, 82
  %2489 = xor i1 %.81, true
  %spec.select1908 = select i1 %2488, i1 %2489, i1 false
  br i1 %spec.select1908, label %true_block1025, label %after_if1027

true_block1019:                                   ; preds = %true_block1013
  %getch.i2448 = getelementptr i8, i8* %12, i64 418612680
  %2490 = getelementptr inbounds i8, i8* %getch.i2448, i64 %2476
  %2491 = bitcast i8* %2490 to double*
  %2492 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2491, i32 64)
  %2493 = getelementptr inbounds i8, i8* %getch.i2448, i64 %2482
  %2494 = bitcast i8* %2493 to double*
  %2495 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2494, i32 64)
  %2496 = fsub reassoc ninf nsz double %2495, %2492
  %2497 = fsub reassoc ninf nsz double %2485, %2479
  %2498 = fsub reassoc ninf nsz double %175, %2479
  %2499 = fmul reassoc ninf nsz double %2496, %2498
  %2500 = fdiv reassoc ninf nsz double %2499, %2497
  %2501 = fadd reassoc ninf nsz double %2500, %2492
  br label %after_if1015

true_block1025:                                   ; preds = %after_if1015
  %2502 = add i32 %180, 82
  %2503 = sext i32 %2502 to i64
  %2504 = shl nsw i64 %2503, 3
  %2505 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2504
  %2506 = bitcast i8* %2505 to double*
  %2507 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2506, i32 64)
  %2508 = add i32 %180, 83
  %2509 = sext i32 %2508 to i64
  %2510 = shl nsw i64 %2509, 3
  %2511 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2510
  %2512 = bitcast i8* %2511 to double*
  %2513 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2512, i32 64)
  %2514 = fcmp reassoc ninf nsz oge double %175, %2507
  %2515 = fcmp reassoc ninf nsz ole double %175, %2513
  %.01003 = select i1 %2514, i1 %2515, i1 false
  br i1 %.01003, label %true_block1031, label %after_if1027

after_if1027:                                     ; preds = %true_block1031, %true_block1025, %after_if1015
  %.831254 = phi double [ %2529, %true_block1031 ], [ %.821253, %true_block1025 ], [ %.821253, %after_if1015 ]
  %.82 = phi i1 [ true, %true_block1031 ], [ %.81, %true_block1025 ], [ %.81, %after_if1015 ]
  %2516 = icmp ugt i32 %201, 83
  %2517 = xor i1 %.82, true
  %spec.select1909 = select i1 %2516, i1 %2517, i1 false
  br i1 %spec.select1909, label %true_block1037, label %after_if1039

true_block1031:                                   ; preds = %true_block1025
  %getch.i2447 = getelementptr i8, i8* %12, i64 418612680
  %2518 = getelementptr inbounds i8, i8* %getch.i2447, i64 %2504
  %2519 = bitcast i8* %2518 to double*
  %2520 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2519, i32 64)
  %2521 = getelementptr inbounds i8, i8* %getch.i2447, i64 %2510
  %2522 = bitcast i8* %2521 to double*
  %2523 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2522, i32 64)
  %2524 = fsub reassoc ninf nsz double %2523, %2520
  %2525 = fsub reassoc ninf nsz double %2513, %2507
  %2526 = fsub reassoc ninf nsz double %175, %2507
  %2527 = fmul reassoc ninf nsz double %2524, %2526
  %2528 = fdiv reassoc ninf nsz double %2527, %2525
  %2529 = fadd reassoc ninf nsz double %2528, %2520
  br label %after_if1027

true_block1037:                                   ; preds = %after_if1027
  %2530 = add i32 %180, 83
  %2531 = sext i32 %2530 to i64
  %2532 = shl nsw i64 %2531, 3
  %2533 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2532
  %2534 = bitcast i8* %2533 to double*
  %2535 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2534, i32 64)
  %2536 = add i32 %180, 84
  %2537 = sext i32 %2536 to i64
  %2538 = shl nsw i64 %2537, 3
  %2539 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2538
  %2540 = bitcast i8* %2539 to double*
  %2541 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2540, i32 64)
  %2542 = fcmp reassoc ninf nsz oge double %175, %2535
  %2543 = fcmp reassoc ninf nsz ole double %175, %2541
  %.01001 = select i1 %2542, i1 %2543, i1 false
  br i1 %.01001, label %true_block1043, label %after_if1039

after_if1039:                                     ; preds = %true_block1043, %true_block1037, %after_if1027
  %.841255 = phi double [ %2557, %true_block1043 ], [ %.831254, %true_block1037 ], [ %.831254, %after_if1027 ]
  %.83 = phi i1 [ true, %true_block1043 ], [ %.82, %true_block1037 ], [ %.82, %after_if1027 ]
  %2544 = icmp ugt i32 %201, 84
  %2545 = xor i1 %.83, true
  %spec.select1910 = select i1 %2544, i1 %2545, i1 false
  br i1 %spec.select1910, label %true_block1049, label %after_if1051

true_block1043:                                   ; preds = %true_block1037
  %getch.i2446 = getelementptr i8, i8* %12, i64 418612680
  %2546 = getelementptr inbounds i8, i8* %getch.i2446, i64 %2532
  %2547 = bitcast i8* %2546 to double*
  %2548 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2547, i32 64)
  %2549 = getelementptr inbounds i8, i8* %getch.i2446, i64 %2538
  %2550 = bitcast i8* %2549 to double*
  %2551 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2550, i32 64)
  %2552 = fsub reassoc ninf nsz double %2551, %2548
  %2553 = fsub reassoc ninf nsz double %2541, %2535
  %2554 = fsub reassoc ninf nsz double %175, %2535
  %2555 = fmul reassoc ninf nsz double %2552, %2554
  %2556 = fdiv reassoc ninf nsz double %2555, %2553
  %2557 = fadd reassoc ninf nsz double %2556, %2548
  br label %after_if1039

true_block1049:                                   ; preds = %after_if1039
  %2558 = add i32 %180, 84
  %2559 = sext i32 %2558 to i64
  %2560 = shl nsw i64 %2559, 3
  %2561 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2560
  %2562 = bitcast i8* %2561 to double*
  %2563 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2562, i32 64)
  %2564 = add i32 %180, 85
  %2565 = sext i32 %2564 to i64
  %2566 = shl nsw i64 %2565, 3
  %2567 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2566
  %2568 = bitcast i8* %2567 to double*
  %2569 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2568, i32 64)
  %2570 = fcmp reassoc ninf nsz oge double %175, %2563
  %2571 = fcmp reassoc ninf nsz ole double %175, %2569
  %.0999 = select i1 %2570, i1 %2571, i1 false
  br i1 %.0999, label %true_block1055, label %after_if1051

after_if1051:                                     ; preds = %true_block1055, %true_block1049, %after_if1039
  %.851256 = phi double [ %2585, %true_block1055 ], [ %.841255, %true_block1049 ], [ %.841255, %after_if1039 ]
  %.84 = phi i1 [ true, %true_block1055 ], [ %.83, %true_block1049 ], [ %.83, %after_if1039 ]
  %2572 = icmp ugt i32 %201, 85
  %2573 = xor i1 %.84, true
  %spec.select1911 = select i1 %2572, i1 %2573, i1 false
  br i1 %spec.select1911, label %true_block1061, label %after_if1063

true_block1055:                                   ; preds = %true_block1049
  %getch.i2445 = getelementptr i8, i8* %12, i64 418612680
  %2574 = getelementptr inbounds i8, i8* %getch.i2445, i64 %2560
  %2575 = bitcast i8* %2574 to double*
  %2576 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2575, i32 64)
  %2577 = getelementptr inbounds i8, i8* %getch.i2445, i64 %2566
  %2578 = bitcast i8* %2577 to double*
  %2579 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2578, i32 64)
  %2580 = fsub reassoc ninf nsz double %2579, %2576
  %2581 = fsub reassoc ninf nsz double %2569, %2563
  %2582 = fsub reassoc ninf nsz double %175, %2563
  %2583 = fmul reassoc ninf nsz double %2580, %2582
  %2584 = fdiv reassoc ninf nsz double %2583, %2581
  %2585 = fadd reassoc ninf nsz double %2584, %2576
  br label %after_if1051

true_block1061:                                   ; preds = %after_if1051
  %2586 = add i32 %180, 85
  %2587 = sext i32 %2586 to i64
  %2588 = shl nsw i64 %2587, 3
  %2589 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2588
  %2590 = bitcast i8* %2589 to double*
  %2591 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2590, i32 64)
  %2592 = add i32 %180, 86
  %2593 = sext i32 %2592 to i64
  %2594 = shl nsw i64 %2593, 3
  %2595 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2594
  %2596 = bitcast i8* %2595 to double*
  %2597 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2596, i32 64)
  %2598 = fcmp reassoc ninf nsz oge double %175, %2591
  %2599 = fcmp reassoc ninf nsz ole double %175, %2597
  %.0997 = select i1 %2598, i1 %2599, i1 false
  br i1 %.0997, label %true_block1067, label %after_if1063

after_if1063:                                     ; preds = %true_block1067, %true_block1061, %after_if1051
  %.861257 = phi double [ %2613, %true_block1067 ], [ %.851256, %true_block1061 ], [ %.851256, %after_if1051 ]
  %.85 = phi i1 [ true, %true_block1067 ], [ %.84, %true_block1061 ], [ %.84, %after_if1051 ]
  %2600 = icmp ugt i32 %201, 86
  %2601 = xor i1 %.85, true
  %spec.select1912 = select i1 %2600, i1 %2601, i1 false
  br i1 %spec.select1912, label %true_block1073, label %after_if1075

true_block1067:                                   ; preds = %true_block1061
  %getch.i2444 = getelementptr i8, i8* %12, i64 418612680
  %2602 = getelementptr inbounds i8, i8* %getch.i2444, i64 %2588
  %2603 = bitcast i8* %2602 to double*
  %2604 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2603, i32 64)
  %2605 = getelementptr inbounds i8, i8* %getch.i2444, i64 %2594
  %2606 = bitcast i8* %2605 to double*
  %2607 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2606, i32 64)
  %2608 = fsub reassoc ninf nsz double %2607, %2604
  %2609 = fsub reassoc ninf nsz double %2597, %2591
  %2610 = fsub reassoc ninf nsz double %175, %2591
  %2611 = fmul reassoc ninf nsz double %2608, %2610
  %2612 = fdiv reassoc ninf nsz double %2611, %2609
  %2613 = fadd reassoc ninf nsz double %2612, %2604
  br label %after_if1063

true_block1073:                                   ; preds = %after_if1063
  %2614 = add i32 %180, 86
  %2615 = sext i32 %2614 to i64
  %2616 = shl nsw i64 %2615, 3
  %2617 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2616
  %2618 = bitcast i8* %2617 to double*
  %2619 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2618, i32 64)
  %2620 = add i32 %180, 87
  %2621 = sext i32 %2620 to i64
  %2622 = shl nsw i64 %2621, 3
  %2623 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2622
  %2624 = bitcast i8* %2623 to double*
  %2625 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2624, i32 64)
  %2626 = fcmp reassoc ninf nsz oge double %175, %2619
  %2627 = fcmp reassoc ninf nsz ole double %175, %2625
  %.0995 = select i1 %2626, i1 %2627, i1 false
  br i1 %.0995, label %true_block1079, label %after_if1075

after_if1075:                                     ; preds = %true_block1079, %true_block1073, %after_if1063
  %.871258 = phi double [ %2641, %true_block1079 ], [ %.861257, %true_block1073 ], [ %.861257, %after_if1063 ]
  %.86 = phi i1 [ true, %true_block1079 ], [ %.85, %true_block1073 ], [ %.85, %after_if1063 ]
  %2628 = icmp ugt i32 %201, 87
  %2629 = xor i1 %.86, true
  %spec.select1913 = select i1 %2628, i1 %2629, i1 false
  br i1 %spec.select1913, label %true_block1085, label %after_if1087

true_block1079:                                   ; preds = %true_block1073
  %getch.i2443 = getelementptr i8, i8* %12, i64 418612680
  %2630 = getelementptr inbounds i8, i8* %getch.i2443, i64 %2616
  %2631 = bitcast i8* %2630 to double*
  %2632 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2631, i32 64)
  %2633 = getelementptr inbounds i8, i8* %getch.i2443, i64 %2622
  %2634 = bitcast i8* %2633 to double*
  %2635 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2634, i32 64)
  %2636 = fsub reassoc ninf nsz double %2635, %2632
  %2637 = fsub reassoc ninf nsz double %2625, %2619
  %2638 = fsub reassoc ninf nsz double %175, %2619
  %2639 = fmul reassoc ninf nsz double %2636, %2638
  %2640 = fdiv reassoc ninf nsz double %2639, %2637
  %2641 = fadd reassoc ninf nsz double %2640, %2632
  br label %after_if1075

true_block1085:                                   ; preds = %after_if1075
  %2642 = add i32 %180, 87
  %2643 = sext i32 %2642 to i64
  %2644 = shl nsw i64 %2643, 3
  %2645 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2644
  %2646 = bitcast i8* %2645 to double*
  %2647 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2646, i32 64)
  %2648 = add i32 %180, 88
  %2649 = sext i32 %2648 to i64
  %2650 = shl nsw i64 %2649, 3
  %2651 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2650
  %2652 = bitcast i8* %2651 to double*
  %2653 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2652, i32 64)
  %2654 = fcmp reassoc ninf nsz oge double %175, %2647
  %2655 = fcmp reassoc ninf nsz ole double %175, %2653
  %.0993 = select i1 %2654, i1 %2655, i1 false
  br i1 %.0993, label %true_block1091, label %after_if1087

after_if1087:                                     ; preds = %true_block1091, %true_block1085, %after_if1075
  %.881259 = phi double [ %2669, %true_block1091 ], [ %.871258, %true_block1085 ], [ %.871258, %after_if1075 ]
  %.87 = phi i1 [ true, %true_block1091 ], [ %.86, %true_block1085 ], [ %.86, %after_if1075 ]
  %2656 = icmp ugt i32 %201, 88
  %2657 = xor i1 %.87, true
  %spec.select1914 = select i1 %2656, i1 %2657, i1 false
  br i1 %spec.select1914, label %true_block1097, label %after_if1099

true_block1091:                                   ; preds = %true_block1085
  %getch.i2442 = getelementptr i8, i8* %12, i64 418612680
  %2658 = getelementptr inbounds i8, i8* %getch.i2442, i64 %2644
  %2659 = bitcast i8* %2658 to double*
  %2660 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2659, i32 64)
  %2661 = getelementptr inbounds i8, i8* %getch.i2442, i64 %2650
  %2662 = bitcast i8* %2661 to double*
  %2663 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2662, i32 64)
  %2664 = fsub reassoc ninf nsz double %2663, %2660
  %2665 = fsub reassoc ninf nsz double %2653, %2647
  %2666 = fsub reassoc ninf nsz double %175, %2647
  %2667 = fmul reassoc ninf nsz double %2664, %2666
  %2668 = fdiv reassoc ninf nsz double %2667, %2665
  %2669 = fadd reassoc ninf nsz double %2668, %2660
  br label %after_if1087

true_block1097:                                   ; preds = %after_if1087
  %2670 = add i32 %180, 88
  %2671 = sext i32 %2670 to i64
  %2672 = shl nsw i64 %2671, 3
  %2673 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2672
  %2674 = bitcast i8* %2673 to double*
  %2675 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2674, i32 64)
  %2676 = add i32 %180, 89
  %2677 = sext i32 %2676 to i64
  %2678 = shl nsw i64 %2677, 3
  %2679 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2678
  %2680 = bitcast i8* %2679 to double*
  %2681 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2680, i32 64)
  %2682 = fcmp reassoc ninf nsz oge double %175, %2675
  %2683 = fcmp reassoc ninf nsz ole double %175, %2681
  %.0991 = select i1 %2682, i1 %2683, i1 false
  br i1 %.0991, label %true_block1103, label %after_if1099

after_if1099:                                     ; preds = %true_block1103, %true_block1097, %after_if1087
  %.891260 = phi double [ %2697, %true_block1103 ], [ %.881259, %true_block1097 ], [ %.881259, %after_if1087 ]
  %.88 = phi i1 [ true, %true_block1103 ], [ %.87, %true_block1097 ], [ %.87, %after_if1087 ]
  %2684 = icmp ugt i32 %201, 89
  %2685 = xor i1 %.88, true
  %spec.select1915 = select i1 %2684, i1 %2685, i1 false
  br i1 %spec.select1915, label %true_block1109, label %after_if1111

true_block1103:                                   ; preds = %true_block1097
  %getch.i2441 = getelementptr i8, i8* %12, i64 418612680
  %2686 = getelementptr inbounds i8, i8* %getch.i2441, i64 %2672
  %2687 = bitcast i8* %2686 to double*
  %2688 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2687, i32 64)
  %2689 = getelementptr inbounds i8, i8* %getch.i2441, i64 %2678
  %2690 = bitcast i8* %2689 to double*
  %2691 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2690, i32 64)
  %2692 = fsub reassoc ninf nsz double %2691, %2688
  %2693 = fsub reassoc ninf nsz double %2681, %2675
  %2694 = fsub reassoc ninf nsz double %175, %2675
  %2695 = fmul reassoc ninf nsz double %2692, %2694
  %2696 = fdiv reassoc ninf nsz double %2695, %2693
  %2697 = fadd reassoc ninf nsz double %2696, %2688
  br label %after_if1099

true_block1109:                                   ; preds = %after_if1099
  %2698 = add i32 %180, 89
  %2699 = sext i32 %2698 to i64
  %2700 = shl nsw i64 %2699, 3
  %2701 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2700
  %2702 = bitcast i8* %2701 to double*
  %2703 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2702, i32 64)
  %2704 = add i32 %180, 90
  %2705 = sext i32 %2704 to i64
  %2706 = shl nsw i64 %2705, 3
  %2707 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2706
  %2708 = bitcast i8* %2707 to double*
  %2709 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2708, i32 64)
  %2710 = fcmp reassoc ninf nsz oge double %175, %2703
  %2711 = fcmp reassoc ninf nsz ole double %175, %2709
  %.0989 = select i1 %2710, i1 %2711, i1 false
  br i1 %.0989, label %true_block1115, label %after_if1111

after_if1111:                                     ; preds = %true_block1115, %true_block1109, %after_if1099
  %.901261 = phi double [ %2725, %true_block1115 ], [ %.891260, %true_block1109 ], [ %.891260, %after_if1099 ]
  %.89 = phi i1 [ true, %true_block1115 ], [ %.88, %true_block1109 ], [ %.88, %after_if1099 ]
  %2712 = icmp ugt i32 %201, 90
  %2713 = xor i1 %.89, true
  %spec.select1916 = select i1 %2712, i1 %2713, i1 false
  br i1 %spec.select1916, label %true_block1121, label %after_if1123

true_block1115:                                   ; preds = %true_block1109
  %getch.i2440 = getelementptr i8, i8* %12, i64 418612680
  %2714 = getelementptr inbounds i8, i8* %getch.i2440, i64 %2700
  %2715 = bitcast i8* %2714 to double*
  %2716 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2715, i32 64)
  %2717 = getelementptr inbounds i8, i8* %getch.i2440, i64 %2706
  %2718 = bitcast i8* %2717 to double*
  %2719 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2718, i32 64)
  %2720 = fsub reassoc ninf nsz double %2719, %2716
  %2721 = fsub reassoc ninf nsz double %2709, %2703
  %2722 = fsub reassoc ninf nsz double %175, %2703
  %2723 = fmul reassoc ninf nsz double %2720, %2722
  %2724 = fdiv reassoc ninf nsz double %2723, %2721
  %2725 = fadd reassoc ninf nsz double %2724, %2716
  br label %after_if1111

true_block1121:                                   ; preds = %after_if1111
  %2726 = add i32 %180, 90
  %2727 = sext i32 %2726 to i64
  %2728 = shl nsw i64 %2727, 3
  %2729 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2728
  %2730 = bitcast i8* %2729 to double*
  %2731 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2730, i32 64)
  %2732 = add i32 %180, 91
  %2733 = sext i32 %2732 to i64
  %2734 = shl nsw i64 %2733, 3
  %2735 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2734
  %2736 = bitcast i8* %2735 to double*
  %2737 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2736, i32 64)
  %2738 = fcmp reassoc ninf nsz oge double %175, %2731
  %2739 = fcmp reassoc ninf nsz ole double %175, %2737
  %.0987 = select i1 %2738, i1 %2739, i1 false
  br i1 %.0987, label %true_block1127, label %after_if1123

after_if1123:                                     ; preds = %true_block1127, %true_block1121, %after_if1111
  %.911262 = phi double [ %2753, %true_block1127 ], [ %.901261, %true_block1121 ], [ %.901261, %after_if1111 ]
  %.90 = phi i1 [ true, %true_block1127 ], [ %.89, %true_block1121 ], [ %.89, %after_if1111 ]
  %2740 = icmp ugt i32 %201, 91
  %2741 = xor i1 %.90, true
  %spec.select1917 = select i1 %2740, i1 %2741, i1 false
  br i1 %spec.select1917, label %true_block1133, label %after_if1135

true_block1127:                                   ; preds = %true_block1121
  %getch.i2439 = getelementptr i8, i8* %12, i64 418612680
  %2742 = getelementptr inbounds i8, i8* %getch.i2439, i64 %2728
  %2743 = bitcast i8* %2742 to double*
  %2744 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2743, i32 64)
  %2745 = getelementptr inbounds i8, i8* %getch.i2439, i64 %2734
  %2746 = bitcast i8* %2745 to double*
  %2747 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2746, i32 64)
  %2748 = fsub reassoc ninf nsz double %2747, %2744
  %2749 = fsub reassoc ninf nsz double %2737, %2731
  %2750 = fsub reassoc ninf nsz double %175, %2731
  %2751 = fmul reassoc ninf nsz double %2748, %2750
  %2752 = fdiv reassoc ninf nsz double %2751, %2749
  %2753 = fadd reassoc ninf nsz double %2752, %2744
  br label %after_if1123

true_block1133:                                   ; preds = %after_if1123
  %2754 = add i32 %180, 91
  %2755 = sext i32 %2754 to i64
  %2756 = shl nsw i64 %2755, 3
  %2757 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2756
  %2758 = bitcast i8* %2757 to double*
  %2759 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2758, i32 64)
  %2760 = add i32 %180, 92
  %2761 = sext i32 %2760 to i64
  %2762 = shl nsw i64 %2761, 3
  %2763 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2762
  %2764 = bitcast i8* %2763 to double*
  %2765 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2764, i32 64)
  %2766 = fcmp reassoc ninf nsz oge double %175, %2759
  %2767 = fcmp reassoc ninf nsz ole double %175, %2765
  %.0985 = select i1 %2766, i1 %2767, i1 false
  br i1 %.0985, label %true_block1139, label %after_if1135

after_if1135:                                     ; preds = %true_block1139, %true_block1133, %after_if1123
  %.921263 = phi double [ %2781, %true_block1139 ], [ %.911262, %true_block1133 ], [ %.911262, %after_if1123 ]
  %.91 = phi i1 [ true, %true_block1139 ], [ %.90, %true_block1133 ], [ %.90, %after_if1123 ]
  %2768 = icmp ugt i32 %201, 92
  %2769 = xor i1 %.91, true
  %spec.select1918 = select i1 %2768, i1 %2769, i1 false
  br i1 %spec.select1918, label %true_block1145, label %after_if1147

true_block1139:                                   ; preds = %true_block1133
  %getch.i2438 = getelementptr i8, i8* %12, i64 418612680
  %2770 = getelementptr inbounds i8, i8* %getch.i2438, i64 %2756
  %2771 = bitcast i8* %2770 to double*
  %2772 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2771, i32 64)
  %2773 = getelementptr inbounds i8, i8* %getch.i2438, i64 %2762
  %2774 = bitcast i8* %2773 to double*
  %2775 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2774, i32 64)
  %2776 = fsub reassoc ninf nsz double %2775, %2772
  %2777 = fsub reassoc ninf nsz double %2765, %2759
  %2778 = fsub reassoc ninf nsz double %175, %2759
  %2779 = fmul reassoc ninf nsz double %2776, %2778
  %2780 = fdiv reassoc ninf nsz double %2779, %2777
  %2781 = fadd reassoc ninf nsz double %2780, %2772
  br label %after_if1135

true_block1145:                                   ; preds = %after_if1135
  %2782 = add i32 %180, 92
  %2783 = sext i32 %2782 to i64
  %2784 = shl nsw i64 %2783, 3
  %2785 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2784
  %2786 = bitcast i8* %2785 to double*
  %2787 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2786, i32 64)
  %2788 = add i32 %180, 93
  %2789 = sext i32 %2788 to i64
  %2790 = shl nsw i64 %2789, 3
  %2791 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2790
  %2792 = bitcast i8* %2791 to double*
  %2793 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2792, i32 64)
  %2794 = fcmp reassoc ninf nsz oge double %175, %2787
  %2795 = fcmp reassoc ninf nsz ole double %175, %2793
  %.0983 = select i1 %2794, i1 %2795, i1 false
  br i1 %.0983, label %true_block1151, label %after_if1147

after_if1147:                                     ; preds = %true_block1151, %true_block1145, %after_if1135
  %.931264 = phi double [ %2809, %true_block1151 ], [ %.921263, %true_block1145 ], [ %.921263, %after_if1135 ]
  %.92 = phi i1 [ true, %true_block1151 ], [ %.91, %true_block1145 ], [ %.91, %after_if1135 ]
  %2796 = icmp ugt i32 %201, 93
  %2797 = xor i1 %.92, true
  %spec.select1919 = select i1 %2796, i1 %2797, i1 false
  br i1 %spec.select1919, label %true_block1157, label %after_if1159

true_block1151:                                   ; preds = %true_block1145
  %getch.i2437 = getelementptr i8, i8* %12, i64 418612680
  %2798 = getelementptr inbounds i8, i8* %getch.i2437, i64 %2784
  %2799 = bitcast i8* %2798 to double*
  %2800 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2799, i32 64)
  %2801 = getelementptr inbounds i8, i8* %getch.i2437, i64 %2790
  %2802 = bitcast i8* %2801 to double*
  %2803 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2802, i32 64)
  %2804 = fsub reassoc ninf nsz double %2803, %2800
  %2805 = fsub reassoc ninf nsz double %2793, %2787
  %2806 = fsub reassoc ninf nsz double %175, %2787
  %2807 = fmul reassoc ninf nsz double %2804, %2806
  %2808 = fdiv reassoc ninf nsz double %2807, %2805
  %2809 = fadd reassoc ninf nsz double %2808, %2800
  br label %after_if1147

true_block1157:                                   ; preds = %after_if1147
  %2810 = add i32 %180, 93
  %2811 = sext i32 %2810 to i64
  %2812 = shl nsw i64 %2811, 3
  %2813 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2812
  %2814 = bitcast i8* %2813 to double*
  %2815 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2814, i32 64)
  %2816 = add i32 %180, 94
  %2817 = sext i32 %2816 to i64
  %2818 = shl nsw i64 %2817, 3
  %2819 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2818
  %2820 = bitcast i8* %2819 to double*
  %2821 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2820, i32 64)
  %2822 = fcmp reassoc ninf nsz oge double %175, %2815
  %2823 = fcmp reassoc ninf nsz ole double %175, %2821
  %.0981 = select i1 %2822, i1 %2823, i1 false
  br i1 %.0981, label %true_block1163, label %after_if1159

after_if1159:                                     ; preds = %true_block1163, %true_block1157, %after_if1147
  %.941265 = phi double [ %2837, %true_block1163 ], [ %.931264, %true_block1157 ], [ %.931264, %after_if1147 ]
  %.93 = phi i1 [ true, %true_block1163 ], [ %.92, %true_block1157 ], [ %.92, %after_if1147 ]
  %2824 = icmp ugt i32 %201, 94
  %2825 = xor i1 %.93, true
  %spec.select1920 = select i1 %2824, i1 %2825, i1 false
  br i1 %spec.select1920, label %true_block1169, label %after_if1171

true_block1163:                                   ; preds = %true_block1157
  %getch.i2436 = getelementptr i8, i8* %12, i64 418612680
  %2826 = getelementptr inbounds i8, i8* %getch.i2436, i64 %2812
  %2827 = bitcast i8* %2826 to double*
  %2828 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2827, i32 64)
  %2829 = getelementptr inbounds i8, i8* %getch.i2436, i64 %2818
  %2830 = bitcast i8* %2829 to double*
  %2831 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2830, i32 64)
  %2832 = fsub reassoc ninf nsz double %2831, %2828
  %2833 = fsub reassoc ninf nsz double %2821, %2815
  %2834 = fsub reassoc ninf nsz double %175, %2815
  %2835 = fmul reassoc ninf nsz double %2832, %2834
  %2836 = fdiv reassoc ninf nsz double %2835, %2833
  %2837 = fadd reassoc ninf nsz double %2836, %2828
  br label %after_if1159

true_block1169:                                   ; preds = %after_if1159
  %2838 = add i32 %180, 94
  %2839 = sext i32 %2838 to i64
  %2840 = shl nsw i64 %2839, 3
  %2841 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2840
  %2842 = bitcast i8* %2841 to double*
  %2843 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2842, i32 64)
  %2844 = add i32 %180, 95
  %2845 = sext i32 %2844 to i64
  %2846 = shl nsw i64 %2845, 3
  %2847 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2846
  %2848 = bitcast i8* %2847 to double*
  %2849 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2848, i32 64)
  %2850 = fcmp reassoc ninf nsz oge double %175, %2843
  %2851 = fcmp reassoc ninf nsz ole double %175, %2849
  %.0979 = select i1 %2850, i1 %2851, i1 false
  br i1 %.0979, label %true_block1175, label %after_if1171

after_if1171:                                     ; preds = %true_block1175, %true_block1169, %after_if1159
  %.951266 = phi double [ %2865, %true_block1175 ], [ %.941265, %true_block1169 ], [ %.941265, %after_if1159 ]
  %.94 = phi i1 [ true, %true_block1175 ], [ %.93, %true_block1169 ], [ %.93, %after_if1159 ]
  %2852 = icmp ugt i32 %201, 95
  %2853 = xor i1 %.94, true
  %spec.select1921 = select i1 %2852, i1 %2853, i1 false
  br i1 %spec.select1921, label %true_block1181, label %after_if1183

true_block1175:                                   ; preds = %true_block1169
  %getch.i2435 = getelementptr i8, i8* %12, i64 418612680
  %2854 = getelementptr inbounds i8, i8* %getch.i2435, i64 %2840
  %2855 = bitcast i8* %2854 to double*
  %2856 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2855, i32 64)
  %2857 = getelementptr inbounds i8, i8* %getch.i2435, i64 %2846
  %2858 = bitcast i8* %2857 to double*
  %2859 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2858, i32 64)
  %2860 = fsub reassoc ninf nsz double %2859, %2856
  %2861 = fsub reassoc ninf nsz double %2849, %2843
  %2862 = fsub reassoc ninf nsz double %175, %2843
  %2863 = fmul reassoc ninf nsz double %2860, %2862
  %2864 = fdiv reassoc ninf nsz double %2863, %2861
  %2865 = fadd reassoc ninf nsz double %2864, %2856
  br label %after_if1171

true_block1181:                                   ; preds = %after_if1171
  %2866 = add i32 %180, 95
  %2867 = sext i32 %2866 to i64
  %2868 = shl nsw i64 %2867, 3
  %2869 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2868
  %2870 = bitcast i8* %2869 to double*
  %2871 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2870, i32 64)
  %2872 = add i32 %180, 96
  %2873 = sext i32 %2872 to i64
  %2874 = shl nsw i64 %2873, 3
  %2875 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2874
  %2876 = bitcast i8* %2875 to double*
  %2877 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2876, i32 64)
  %2878 = fcmp reassoc ninf nsz oge double %175, %2871
  %2879 = fcmp reassoc ninf nsz ole double %175, %2877
  %.0977 = select i1 %2878, i1 %2879, i1 false
  br i1 %.0977, label %true_block1187, label %after_if1183

after_if1183:                                     ; preds = %true_block1187, %true_block1181, %after_if1171
  %.961267 = phi double [ %2893, %true_block1187 ], [ %.951266, %true_block1181 ], [ %.951266, %after_if1171 ]
  %.95 = phi i1 [ true, %true_block1187 ], [ %.94, %true_block1181 ], [ %.94, %after_if1171 ]
  %2880 = icmp ugt i32 %201, 96
  %2881 = xor i1 %.95, true
  %spec.select1922 = select i1 %2880, i1 %2881, i1 false
  br i1 %spec.select1922, label %true_block1193, label %after_if1195

true_block1187:                                   ; preds = %true_block1181
  %getch.i2434 = getelementptr i8, i8* %12, i64 418612680
  %2882 = getelementptr inbounds i8, i8* %getch.i2434, i64 %2868
  %2883 = bitcast i8* %2882 to double*
  %2884 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2883, i32 64)
  %2885 = getelementptr inbounds i8, i8* %getch.i2434, i64 %2874
  %2886 = bitcast i8* %2885 to double*
  %2887 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2886, i32 64)
  %2888 = fsub reassoc ninf nsz double %2887, %2884
  %2889 = fsub reassoc ninf nsz double %2877, %2871
  %2890 = fsub reassoc ninf nsz double %175, %2871
  %2891 = fmul reassoc ninf nsz double %2888, %2890
  %2892 = fdiv reassoc ninf nsz double %2891, %2889
  %2893 = fadd reassoc ninf nsz double %2892, %2884
  br label %after_if1183

true_block1193:                                   ; preds = %after_if1183
  %2894 = add i32 %180, 96
  %2895 = sext i32 %2894 to i64
  %2896 = shl nsw i64 %2895, 3
  %2897 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2896
  %2898 = bitcast i8* %2897 to double*
  %2899 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2898, i32 64)
  %2900 = add i32 %180, 97
  %2901 = sext i32 %2900 to i64
  %2902 = shl nsw i64 %2901, 3
  %2903 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2902
  %2904 = bitcast i8* %2903 to double*
  %2905 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2904, i32 64)
  %2906 = fcmp reassoc ninf nsz oge double %175, %2899
  %2907 = fcmp reassoc ninf nsz ole double %175, %2905
  %.0975 = select i1 %2906, i1 %2907, i1 false
  br i1 %.0975, label %true_block1199, label %after_if1195

after_if1195:                                     ; preds = %true_block1199, %true_block1193, %after_if1183
  %.971268 = phi double [ %2921, %true_block1199 ], [ %.961267, %true_block1193 ], [ %.961267, %after_if1183 ]
  %.96 = phi i1 [ true, %true_block1199 ], [ %.95, %true_block1193 ], [ %.95, %after_if1183 ]
  %2908 = icmp ugt i32 %201, 97
  %2909 = xor i1 %.96, true
  %spec.select1923 = select i1 %2908, i1 %2909, i1 false
  br i1 %spec.select1923, label %true_block1205, label %after_if1207

true_block1199:                                   ; preds = %true_block1193
  %getch.i2433 = getelementptr i8, i8* %12, i64 418612680
  %2910 = getelementptr inbounds i8, i8* %getch.i2433, i64 %2896
  %2911 = bitcast i8* %2910 to double*
  %2912 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2911, i32 64)
  %2913 = getelementptr inbounds i8, i8* %getch.i2433, i64 %2902
  %2914 = bitcast i8* %2913 to double*
  %2915 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2914, i32 64)
  %2916 = fsub reassoc ninf nsz double %2915, %2912
  %2917 = fsub reassoc ninf nsz double %2905, %2899
  %2918 = fsub reassoc ninf nsz double %175, %2899
  %2919 = fmul reassoc ninf nsz double %2916, %2918
  %2920 = fdiv reassoc ninf nsz double %2919, %2917
  %2921 = fadd reassoc ninf nsz double %2920, %2912
  br label %after_if1195

true_block1205:                                   ; preds = %after_if1195
  %2922 = add i32 %180, 97
  %2923 = sext i32 %2922 to i64
  %2924 = shl nsw i64 %2923, 3
  %2925 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2924
  %2926 = bitcast i8* %2925 to double*
  %2927 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2926, i32 64)
  %2928 = add i32 %180, 98
  %2929 = sext i32 %2928 to i64
  %2930 = shl nsw i64 %2929, 3
  %2931 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2930
  %2932 = bitcast i8* %2931 to double*
  %2933 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2932, i32 64)
  %2934 = fcmp reassoc ninf nsz oge double %175, %2927
  %2935 = fcmp reassoc ninf nsz ole double %175, %2933
  %.0973 = select i1 %2934, i1 %2935, i1 false
  br i1 %.0973, label %true_block1211, label %after_if1207

after_if1207:                                     ; preds = %true_block1211, %true_block1205, %after_if1195
  %.981269 = phi double [ %2949, %true_block1211 ], [ %.971268, %true_block1205 ], [ %.971268, %after_if1195 ]
  %.97 = phi i1 [ true, %true_block1211 ], [ %.96, %true_block1205 ], [ %.96, %after_if1195 ]
  %2936 = icmp ugt i32 %201, 98
  %2937 = xor i1 %.97, true
  %spec.select1924 = select i1 %2936, i1 %2937, i1 false
  br i1 %spec.select1924, label %true_block1217, label %after_if1219

true_block1211:                                   ; preds = %true_block1205
  %getch.i2432 = getelementptr i8, i8* %12, i64 418612680
  %2938 = getelementptr inbounds i8, i8* %getch.i2432, i64 %2924
  %2939 = bitcast i8* %2938 to double*
  %2940 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2939, i32 64)
  %2941 = getelementptr inbounds i8, i8* %getch.i2432, i64 %2930
  %2942 = bitcast i8* %2941 to double*
  %2943 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2942, i32 64)
  %2944 = fsub reassoc ninf nsz double %2943, %2940
  %2945 = fsub reassoc ninf nsz double %2933, %2927
  %2946 = fsub reassoc ninf nsz double %175, %2927
  %2947 = fmul reassoc ninf nsz double %2944, %2946
  %2948 = fdiv reassoc ninf nsz double %2947, %2945
  %2949 = fadd reassoc ninf nsz double %2948, %2940
  br label %after_if1207

true_block1217:                                   ; preds = %after_if1207
  %2950 = add i32 %180, 98
  %2951 = sext i32 %2950 to i64
  %2952 = shl nsw i64 %2951, 3
  %2953 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2952
  %2954 = bitcast i8* %2953 to double*
  %2955 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2954, i32 64)
  %2956 = add i32 %180, 99
  %2957 = sext i32 %2956 to i64
  %2958 = shl nsw i64 %2957, 3
  %2959 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2958
  %2960 = bitcast i8* %2959 to double*
  %2961 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2960, i32 64)
  %2962 = fcmp reassoc ninf nsz oge double %175, %2955
  %2963 = fcmp reassoc ninf nsz ole double %175, %2961
  %.0971 = select i1 %2962, i1 %2963, i1 false
  br i1 %.0971, label %true_block1223, label %after_if1219

after_if1219:                                     ; preds = %true_block1223, %true_block1217, %after_if1207
  %.991270 = phi double [ %2977, %true_block1223 ], [ %.981269, %true_block1217 ], [ %.981269, %after_if1207 ]
  %.98 = phi i1 [ true, %true_block1223 ], [ %.97, %true_block1217 ], [ %.97, %after_if1207 ]
  %2964 = icmp ugt i32 %201, 99
  %2965 = xor i1 %.98, true
  %spec.select1925 = select i1 %2964, i1 %2965, i1 false
  br i1 %spec.select1925, label %true_block1229, label %after_if1231

true_block1223:                                   ; preds = %true_block1217
  %getch.i2431 = getelementptr i8, i8* %12, i64 418612680
  %2966 = getelementptr inbounds i8, i8* %getch.i2431, i64 %2952
  %2967 = bitcast i8* %2966 to double*
  %2968 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2967, i32 64)
  %2969 = getelementptr inbounds i8, i8* %getch.i2431, i64 %2958
  %2970 = bitcast i8* %2969 to double*
  %2971 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2970, i32 64)
  %2972 = fsub reassoc ninf nsz double %2971, %2968
  %2973 = fsub reassoc ninf nsz double %2961, %2955
  %2974 = fsub reassoc ninf nsz double %175, %2955
  %2975 = fmul reassoc ninf nsz double %2972, %2974
  %2976 = fdiv reassoc ninf nsz double %2975, %2973
  %2977 = fadd reassoc ninf nsz double %2976, %2968
  br label %after_if1219

true_block1229:                                   ; preds = %after_if1219
  %2978 = add i32 %180, 99
  %2979 = sext i32 %2978 to i64
  %2980 = shl nsw i64 %2979, 3
  %2981 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2980
  %2982 = bitcast i8* %2981 to double*
  %2983 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2982, i32 64)
  %2984 = add i32 %180, 100
  %2985 = sext i32 %2984 to i64
  %2986 = shl nsw i64 %2985, 3
  %2987 = getelementptr inbounds i8, i8* %getch.i2533, i64 %2986
  %2988 = bitcast i8* %2987 to double*
  %2989 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2988, i32 64)
  %2990 = fcmp reassoc ninf nsz oge double %175, %2983
  %2991 = fcmp reassoc ninf nsz ole double %175, %2989
  %.0969 = select i1 %2990, i1 %2991, i1 false
  br i1 %.0969, label %true_block1235, label %after_if1231

after_if1231:                                     ; preds = %true_block1235, %true_block1229, %after_if1219
  %.1001271 = phi double [ %3005, %true_block1235 ], [ %.991270, %true_block1229 ], [ %.991270, %after_if1219 ]
  %.99 = phi i1 [ true, %true_block1235 ], [ %.98, %true_block1229 ], [ %.98, %after_if1219 ]
  %2992 = icmp ugt i32 %201, 100
  %2993 = xor i1 %.99, true
  %spec.select1926 = select i1 %2992, i1 %2993, i1 false
  br i1 %spec.select1926, label %true_block1241, label %after_if1243

true_block1235:                                   ; preds = %true_block1229
  %getch.i2430 = getelementptr i8, i8* %12, i64 418612680
  %2994 = getelementptr inbounds i8, i8* %getch.i2430, i64 %2980
  %2995 = bitcast i8* %2994 to double*
  %2996 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %2995, i32 64)
  %2997 = getelementptr inbounds i8, i8* %getch.i2430, i64 %2986
  %2998 = bitcast i8* %2997 to double*
  %2999 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %2998, i32 64)
  %3000 = fsub reassoc ninf nsz double %2999, %2996
  %3001 = fsub reassoc ninf nsz double %2989, %2983
  %3002 = fsub reassoc ninf nsz double %175, %2983
  %3003 = fmul reassoc ninf nsz double %3000, %3002
  %3004 = fdiv reassoc ninf nsz double %3003, %3001
  %3005 = fadd reassoc ninf nsz double %3004, %2996
  br label %after_if1231

true_block1241:                                   ; preds = %after_if1231
  %3006 = add i32 %180, 100
  %3007 = sext i32 %3006 to i64
  %3008 = shl nsw i64 %3007, 3
  %3009 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3008
  %3010 = bitcast i8* %3009 to double*
  %3011 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3010, i32 64)
  %3012 = add i32 %180, 101
  %3013 = sext i32 %3012 to i64
  %3014 = shl nsw i64 %3013, 3
  %3015 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3014
  %3016 = bitcast i8* %3015 to double*
  %3017 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3016, i32 64)
  %3018 = fcmp reassoc ninf nsz oge double %175, %3011
  %3019 = fcmp reassoc ninf nsz ole double %175, %3017
  %.0967 = select i1 %3018, i1 %3019, i1 false
  br i1 %.0967, label %true_block1247, label %after_if1243

after_if1243:                                     ; preds = %true_block1247, %true_block1241, %after_if1231
  %.1011272 = phi double [ %3033, %true_block1247 ], [ %.1001271, %true_block1241 ], [ %.1001271, %after_if1231 ]
  %.100 = phi i1 [ true, %true_block1247 ], [ %.99, %true_block1241 ], [ %.99, %after_if1231 ]
  %3020 = icmp ugt i32 %201, 101
  %3021 = xor i1 %.100, true
  %spec.select1927 = select i1 %3020, i1 %3021, i1 false
  br i1 %spec.select1927, label %true_block1253, label %after_if1255

true_block1247:                                   ; preds = %true_block1241
  %getch.i2429 = getelementptr i8, i8* %12, i64 418612680
  %3022 = getelementptr inbounds i8, i8* %getch.i2429, i64 %3008
  %3023 = bitcast i8* %3022 to double*
  %3024 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3023, i32 64)
  %3025 = getelementptr inbounds i8, i8* %getch.i2429, i64 %3014
  %3026 = bitcast i8* %3025 to double*
  %3027 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3026, i32 64)
  %3028 = fsub reassoc ninf nsz double %3027, %3024
  %3029 = fsub reassoc ninf nsz double %3017, %3011
  %3030 = fsub reassoc ninf nsz double %175, %3011
  %3031 = fmul reassoc ninf nsz double %3028, %3030
  %3032 = fdiv reassoc ninf nsz double %3031, %3029
  %3033 = fadd reassoc ninf nsz double %3032, %3024
  br label %after_if1243

true_block1253:                                   ; preds = %after_if1243
  %3034 = add i32 %180, 101
  %3035 = sext i32 %3034 to i64
  %3036 = shl nsw i64 %3035, 3
  %3037 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3036
  %3038 = bitcast i8* %3037 to double*
  %3039 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3038, i32 64)
  %3040 = add i32 %180, 102
  %3041 = sext i32 %3040 to i64
  %3042 = shl nsw i64 %3041, 3
  %3043 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3042
  %3044 = bitcast i8* %3043 to double*
  %3045 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3044, i32 64)
  %3046 = fcmp reassoc ninf nsz oge double %175, %3039
  %3047 = fcmp reassoc ninf nsz ole double %175, %3045
  %.0965 = select i1 %3046, i1 %3047, i1 false
  br i1 %.0965, label %true_block1259, label %after_if1255

after_if1255:                                     ; preds = %true_block1259, %true_block1253, %after_if1243
  %.1021273 = phi double [ %3061, %true_block1259 ], [ %.1011272, %true_block1253 ], [ %.1011272, %after_if1243 ]
  %.101 = phi i1 [ true, %true_block1259 ], [ %.100, %true_block1253 ], [ %.100, %after_if1243 ]
  %3048 = icmp ugt i32 %201, 102
  %3049 = xor i1 %.101, true
  %spec.select1928 = select i1 %3048, i1 %3049, i1 false
  br i1 %spec.select1928, label %true_block1265, label %after_if1267

true_block1259:                                   ; preds = %true_block1253
  %getch.i2428 = getelementptr i8, i8* %12, i64 418612680
  %3050 = getelementptr inbounds i8, i8* %getch.i2428, i64 %3036
  %3051 = bitcast i8* %3050 to double*
  %3052 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3051, i32 64)
  %3053 = getelementptr inbounds i8, i8* %getch.i2428, i64 %3042
  %3054 = bitcast i8* %3053 to double*
  %3055 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3054, i32 64)
  %3056 = fsub reassoc ninf nsz double %3055, %3052
  %3057 = fsub reassoc ninf nsz double %3045, %3039
  %3058 = fsub reassoc ninf nsz double %175, %3039
  %3059 = fmul reassoc ninf nsz double %3056, %3058
  %3060 = fdiv reassoc ninf nsz double %3059, %3057
  %3061 = fadd reassoc ninf nsz double %3060, %3052
  br label %after_if1255

true_block1265:                                   ; preds = %after_if1255
  %3062 = add i32 %180, 102
  %3063 = sext i32 %3062 to i64
  %3064 = shl nsw i64 %3063, 3
  %3065 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3064
  %3066 = bitcast i8* %3065 to double*
  %3067 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3066, i32 64)
  %3068 = add i32 %180, 103
  %3069 = sext i32 %3068 to i64
  %3070 = shl nsw i64 %3069, 3
  %3071 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3070
  %3072 = bitcast i8* %3071 to double*
  %3073 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3072, i32 64)
  %3074 = fcmp reassoc ninf nsz oge double %175, %3067
  %3075 = fcmp reassoc ninf nsz ole double %175, %3073
  %.0963 = select i1 %3074, i1 %3075, i1 false
  br i1 %.0963, label %true_block1271, label %after_if1267

after_if1267:                                     ; preds = %true_block1271, %true_block1265, %after_if1255
  %.1031274 = phi double [ %3089, %true_block1271 ], [ %.1021273, %true_block1265 ], [ %.1021273, %after_if1255 ]
  %.102 = phi i1 [ true, %true_block1271 ], [ %.101, %true_block1265 ], [ %.101, %after_if1255 ]
  %3076 = icmp ugt i32 %201, 103
  %3077 = xor i1 %.102, true
  %spec.select1929 = select i1 %3076, i1 %3077, i1 false
  br i1 %spec.select1929, label %true_block1277, label %after_if1279

true_block1271:                                   ; preds = %true_block1265
  %getch.i2427 = getelementptr i8, i8* %12, i64 418612680
  %3078 = getelementptr inbounds i8, i8* %getch.i2427, i64 %3064
  %3079 = bitcast i8* %3078 to double*
  %3080 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3079, i32 64)
  %3081 = getelementptr inbounds i8, i8* %getch.i2427, i64 %3070
  %3082 = bitcast i8* %3081 to double*
  %3083 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3082, i32 64)
  %3084 = fsub reassoc ninf nsz double %3083, %3080
  %3085 = fsub reassoc ninf nsz double %3073, %3067
  %3086 = fsub reassoc ninf nsz double %175, %3067
  %3087 = fmul reassoc ninf nsz double %3084, %3086
  %3088 = fdiv reassoc ninf nsz double %3087, %3085
  %3089 = fadd reassoc ninf nsz double %3088, %3080
  br label %after_if1267

true_block1277:                                   ; preds = %after_if1267
  %3090 = add i32 %180, 103
  %3091 = sext i32 %3090 to i64
  %3092 = shl nsw i64 %3091, 3
  %3093 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3092
  %3094 = bitcast i8* %3093 to double*
  %3095 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3094, i32 64)
  %3096 = add i32 %180, 104
  %3097 = sext i32 %3096 to i64
  %3098 = shl nsw i64 %3097, 3
  %3099 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3098
  %3100 = bitcast i8* %3099 to double*
  %3101 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3100, i32 64)
  %3102 = fcmp reassoc ninf nsz oge double %175, %3095
  %3103 = fcmp reassoc ninf nsz ole double %175, %3101
  %.0961 = select i1 %3102, i1 %3103, i1 false
  br i1 %.0961, label %true_block1283, label %after_if1279

after_if1279:                                     ; preds = %true_block1283, %true_block1277, %after_if1267
  %.1041275 = phi double [ %3117, %true_block1283 ], [ %.1031274, %true_block1277 ], [ %.1031274, %after_if1267 ]
  %.103 = phi i1 [ true, %true_block1283 ], [ %.102, %true_block1277 ], [ %.102, %after_if1267 ]
  %3104 = icmp ugt i32 %201, 104
  %3105 = xor i1 %.103, true
  %spec.select1930 = select i1 %3104, i1 %3105, i1 false
  br i1 %spec.select1930, label %true_block1289, label %after_if1291

true_block1283:                                   ; preds = %true_block1277
  %getch.i2426 = getelementptr i8, i8* %12, i64 418612680
  %3106 = getelementptr inbounds i8, i8* %getch.i2426, i64 %3092
  %3107 = bitcast i8* %3106 to double*
  %3108 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3107, i32 64)
  %3109 = getelementptr inbounds i8, i8* %getch.i2426, i64 %3098
  %3110 = bitcast i8* %3109 to double*
  %3111 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3110, i32 64)
  %3112 = fsub reassoc ninf nsz double %3111, %3108
  %3113 = fsub reassoc ninf nsz double %3101, %3095
  %3114 = fsub reassoc ninf nsz double %175, %3095
  %3115 = fmul reassoc ninf nsz double %3112, %3114
  %3116 = fdiv reassoc ninf nsz double %3115, %3113
  %3117 = fadd reassoc ninf nsz double %3116, %3108
  br label %after_if1279

true_block1289:                                   ; preds = %after_if1279
  %3118 = add i32 %180, 104
  %3119 = sext i32 %3118 to i64
  %3120 = shl nsw i64 %3119, 3
  %3121 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3120
  %3122 = bitcast i8* %3121 to double*
  %3123 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3122, i32 64)
  %3124 = add i32 %180, 105
  %3125 = sext i32 %3124 to i64
  %3126 = shl nsw i64 %3125, 3
  %3127 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3126
  %3128 = bitcast i8* %3127 to double*
  %3129 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3128, i32 64)
  %3130 = fcmp reassoc ninf nsz oge double %175, %3123
  %3131 = fcmp reassoc ninf nsz ole double %175, %3129
  %.0959 = select i1 %3130, i1 %3131, i1 false
  br i1 %.0959, label %true_block1295, label %after_if1291

after_if1291:                                     ; preds = %true_block1295, %true_block1289, %after_if1279
  %.1051276 = phi double [ %3145, %true_block1295 ], [ %.1041275, %true_block1289 ], [ %.1041275, %after_if1279 ]
  %.104 = phi i1 [ true, %true_block1295 ], [ %.103, %true_block1289 ], [ %.103, %after_if1279 ]
  %3132 = icmp ugt i32 %201, 105
  %3133 = xor i1 %.104, true
  %spec.select1931 = select i1 %3132, i1 %3133, i1 false
  br i1 %spec.select1931, label %true_block1301, label %after_if1303

true_block1295:                                   ; preds = %true_block1289
  %getch.i2425 = getelementptr i8, i8* %12, i64 418612680
  %3134 = getelementptr inbounds i8, i8* %getch.i2425, i64 %3120
  %3135 = bitcast i8* %3134 to double*
  %3136 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3135, i32 64)
  %3137 = getelementptr inbounds i8, i8* %getch.i2425, i64 %3126
  %3138 = bitcast i8* %3137 to double*
  %3139 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3138, i32 64)
  %3140 = fsub reassoc ninf nsz double %3139, %3136
  %3141 = fsub reassoc ninf nsz double %3129, %3123
  %3142 = fsub reassoc ninf nsz double %175, %3123
  %3143 = fmul reassoc ninf nsz double %3140, %3142
  %3144 = fdiv reassoc ninf nsz double %3143, %3141
  %3145 = fadd reassoc ninf nsz double %3144, %3136
  br label %after_if1291

true_block1301:                                   ; preds = %after_if1291
  %3146 = add i32 %180, 105
  %3147 = sext i32 %3146 to i64
  %3148 = shl nsw i64 %3147, 3
  %3149 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3148
  %3150 = bitcast i8* %3149 to double*
  %3151 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3150, i32 64)
  %3152 = add i32 %180, 106
  %3153 = sext i32 %3152 to i64
  %3154 = shl nsw i64 %3153, 3
  %3155 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3154
  %3156 = bitcast i8* %3155 to double*
  %3157 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3156, i32 64)
  %3158 = fcmp reassoc ninf nsz oge double %175, %3151
  %3159 = fcmp reassoc ninf nsz ole double %175, %3157
  %.0957 = select i1 %3158, i1 %3159, i1 false
  br i1 %.0957, label %true_block1307, label %after_if1303

after_if1303:                                     ; preds = %true_block1307, %true_block1301, %after_if1291
  %.1061277 = phi double [ %3173, %true_block1307 ], [ %.1051276, %true_block1301 ], [ %.1051276, %after_if1291 ]
  %.105 = phi i1 [ true, %true_block1307 ], [ %.104, %true_block1301 ], [ %.104, %after_if1291 ]
  %3160 = icmp ugt i32 %201, 106
  %3161 = xor i1 %.105, true
  %spec.select1932 = select i1 %3160, i1 %3161, i1 false
  br i1 %spec.select1932, label %true_block1313, label %after_if1315

true_block1307:                                   ; preds = %true_block1301
  %getch.i2424 = getelementptr i8, i8* %12, i64 418612680
  %3162 = getelementptr inbounds i8, i8* %getch.i2424, i64 %3148
  %3163 = bitcast i8* %3162 to double*
  %3164 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3163, i32 64)
  %3165 = getelementptr inbounds i8, i8* %getch.i2424, i64 %3154
  %3166 = bitcast i8* %3165 to double*
  %3167 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3166, i32 64)
  %3168 = fsub reassoc ninf nsz double %3167, %3164
  %3169 = fsub reassoc ninf nsz double %3157, %3151
  %3170 = fsub reassoc ninf nsz double %175, %3151
  %3171 = fmul reassoc ninf nsz double %3168, %3170
  %3172 = fdiv reassoc ninf nsz double %3171, %3169
  %3173 = fadd reassoc ninf nsz double %3172, %3164
  br label %after_if1303

true_block1313:                                   ; preds = %after_if1303
  %3174 = add i32 %180, 106
  %3175 = sext i32 %3174 to i64
  %3176 = shl nsw i64 %3175, 3
  %3177 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3176
  %3178 = bitcast i8* %3177 to double*
  %3179 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3178, i32 64)
  %3180 = add i32 %180, 107
  %3181 = sext i32 %3180 to i64
  %3182 = shl nsw i64 %3181, 3
  %3183 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3182
  %3184 = bitcast i8* %3183 to double*
  %3185 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3184, i32 64)
  %3186 = fcmp reassoc ninf nsz oge double %175, %3179
  %3187 = fcmp reassoc ninf nsz ole double %175, %3185
  %.0955 = select i1 %3186, i1 %3187, i1 false
  br i1 %.0955, label %true_block1319, label %after_if1315

after_if1315:                                     ; preds = %true_block1319, %true_block1313, %after_if1303
  %.1071278 = phi double [ %3201, %true_block1319 ], [ %.1061277, %true_block1313 ], [ %.1061277, %after_if1303 ]
  %.106 = phi i1 [ true, %true_block1319 ], [ %.105, %true_block1313 ], [ %.105, %after_if1303 ]
  %3188 = icmp ugt i32 %201, 107
  %3189 = xor i1 %.106, true
  %spec.select1933 = select i1 %3188, i1 %3189, i1 false
  br i1 %spec.select1933, label %true_block1325, label %after_if1327

true_block1319:                                   ; preds = %true_block1313
  %getch.i2423 = getelementptr i8, i8* %12, i64 418612680
  %3190 = getelementptr inbounds i8, i8* %getch.i2423, i64 %3176
  %3191 = bitcast i8* %3190 to double*
  %3192 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3191, i32 64)
  %3193 = getelementptr inbounds i8, i8* %getch.i2423, i64 %3182
  %3194 = bitcast i8* %3193 to double*
  %3195 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3194, i32 64)
  %3196 = fsub reassoc ninf nsz double %3195, %3192
  %3197 = fsub reassoc ninf nsz double %3185, %3179
  %3198 = fsub reassoc ninf nsz double %175, %3179
  %3199 = fmul reassoc ninf nsz double %3196, %3198
  %3200 = fdiv reassoc ninf nsz double %3199, %3197
  %3201 = fadd reassoc ninf nsz double %3200, %3192
  br label %after_if1315

true_block1325:                                   ; preds = %after_if1315
  %3202 = add i32 %180, 107
  %3203 = sext i32 %3202 to i64
  %3204 = shl nsw i64 %3203, 3
  %3205 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3204
  %3206 = bitcast i8* %3205 to double*
  %3207 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3206, i32 64)
  %3208 = add i32 %180, 108
  %3209 = sext i32 %3208 to i64
  %3210 = shl nsw i64 %3209, 3
  %3211 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3210
  %3212 = bitcast i8* %3211 to double*
  %3213 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3212, i32 64)
  %3214 = fcmp reassoc ninf nsz oge double %175, %3207
  %3215 = fcmp reassoc ninf nsz ole double %175, %3213
  %.0953 = select i1 %3214, i1 %3215, i1 false
  br i1 %.0953, label %true_block1331, label %after_if1327

after_if1327:                                     ; preds = %true_block1331, %true_block1325, %after_if1315
  %.1081279 = phi double [ %3229, %true_block1331 ], [ %.1071278, %true_block1325 ], [ %.1071278, %after_if1315 ]
  %.107 = phi i1 [ true, %true_block1331 ], [ %.106, %true_block1325 ], [ %.106, %after_if1315 ]
  %3216 = icmp ugt i32 %201, 108
  %3217 = xor i1 %.107, true
  %spec.select1934 = select i1 %3216, i1 %3217, i1 false
  br i1 %spec.select1934, label %true_block1337, label %after_if1339

true_block1331:                                   ; preds = %true_block1325
  %getch.i2422 = getelementptr i8, i8* %12, i64 418612680
  %3218 = getelementptr inbounds i8, i8* %getch.i2422, i64 %3204
  %3219 = bitcast i8* %3218 to double*
  %3220 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3219, i32 64)
  %3221 = getelementptr inbounds i8, i8* %getch.i2422, i64 %3210
  %3222 = bitcast i8* %3221 to double*
  %3223 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3222, i32 64)
  %3224 = fsub reassoc ninf nsz double %3223, %3220
  %3225 = fsub reassoc ninf nsz double %3213, %3207
  %3226 = fsub reassoc ninf nsz double %175, %3207
  %3227 = fmul reassoc ninf nsz double %3224, %3226
  %3228 = fdiv reassoc ninf nsz double %3227, %3225
  %3229 = fadd reassoc ninf nsz double %3228, %3220
  br label %after_if1327

true_block1337:                                   ; preds = %after_if1327
  %3230 = add i32 %180, 108
  %3231 = sext i32 %3230 to i64
  %3232 = shl nsw i64 %3231, 3
  %3233 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3232
  %3234 = bitcast i8* %3233 to double*
  %3235 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3234, i32 64)
  %3236 = add i32 %180, 109
  %3237 = sext i32 %3236 to i64
  %3238 = shl nsw i64 %3237, 3
  %3239 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3238
  %3240 = bitcast i8* %3239 to double*
  %3241 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3240, i32 64)
  %3242 = fcmp reassoc ninf nsz oge double %175, %3235
  %3243 = fcmp reassoc ninf nsz ole double %175, %3241
  %.0951 = select i1 %3242, i1 %3243, i1 false
  br i1 %.0951, label %true_block1343, label %after_if1339

after_if1339:                                     ; preds = %true_block1343, %true_block1337, %after_if1327
  %.1091280 = phi double [ %3257, %true_block1343 ], [ %.1081279, %true_block1337 ], [ %.1081279, %after_if1327 ]
  %.108 = phi i1 [ true, %true_block1343 ], [ %.107, %true_block1337 ], [ %.107, %after_if1327 ]
  %3244 = icmp ugt i32 %201, 109
  %3245 = xor i1 %.108, true
  %spec.select1935 = select i1 %3244, i1 %3245, i1 false
  br i1 %spec.select1935, label %true_block1349, label %after_if1351

true_block1343:                                   ; preds = %true_block1337
  %getch.i2421 = getelementptr i8, i8* %12, i64 418612680
  %3246 = getelementptr inbounds i8, i8* %getch.i2421, i64 %3232
  %3247 = bitcast i8* %3246 to double*
  %3248 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3247, i32 64)
  %3249 = getelementptr inbounds i8, i8* %getch.i2421, i64 %3238
  %3250 = bitcast i8* %3249 to double*
  %3251 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3250, i32 64)
  %3252 = fsub reassoc ninf nsz double %3251, %3248
  %3253 = fsub reassoc ninf nsz double %3241, %3235
  %3254 = fsub reassoc ninf nsz double %175, %3235
  %3255 = fmul reassoc ninf nsz double %3252, %3254
  %3256 = fdiv reassoc ninf nsz double %3255, %3253
  %3257 = fadd reassoc ninf nsz double %3256, %3248
  br label %after_if1339

true_block1349:                                   ; preds = %after_if1339
  %3258 = add i32 %180, 109
  %3259 = sext i32 %3258 to i64
  %3260 = shl nsw i64 %3259, 3
  %3261 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3260
  %3262 = bitcast i8* %3261 to double*
  %3263 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3262, i32 64)
  %3264 = add i32 %180, 110
  %3265 = sext i32 %3264 to i64
  %3266 = shl nsw i64 %3265, 3
  %3267 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3266
  %3268 = bitcast i8* %3267 to double*
  %3269 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3268, i32 64)
  %3270 = fcmp reassoc ninf nsz oge double %175, %3263
  %3271 = fcmp reassoc ninf nsz ole double %175, %3269
  %.0949 = select i1 %3270, i1 %3271, i1 false
  br i1 %.0949, label %true_block1355, label %after_if1351

after_if1351:                                     ; preds = %true_block1355, %true_block1349, %after_if1339
  %.1101281 = phi double [ %3285, %true_block1355 ], [ %.1091280, %true_block1349 ], [ %.1091280, %after_if1339 ]
  %.109 = phi i1 [ true, %true_block1355 ], [ %.108, %true_block1349 ], [ %.108, %after_if1339 ]
  %3272 = icmp ugt i32 %201, 110
  %3273 = xor i1 %.109, true
  %spec.select1936 = select i1 %3272, i1 %3273, i1 false
  br i1 %spec.select1936, label %true_block1361, label %after_if1363

true_block1355:                                   ; preds = %true_block1349
  %getch.i2420 = getelementptr i8, i8* %12, i64 418612680
  %3274 = getelementptr inbounds i8, i8* %getch.i2420, i64 %3260
  %3275 = bitcast i8* %3274 to double*
  %3276 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3275, i32 64)
  %3277 = getelementptr inbounds i8, i8* %getch.i2420, i64 %3266
  %3278 = bitcast i8* %3277 to double*
  %3279 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3278, i32 64)
  %3280 = fsub reassoc ninf nsz double %3279, %3276
  %3281 = fsub reassoc ninf nsz double %3269, %3263
  %3282 = fsub reassoc ninf nsz double %175, %3263
  %3283 = fmul reassoc ninf nsz double %3280, %3282
  %3284 = fdiv reassoc ninf nsz double %3283, %3281
  %3285 = fadd reassoc ninf nsz double %3284, %3276
  br label %after_if1351

true_block1361:                                   ; preds = %after_if1351
  %3286 = add i32 %180, 110
  %3287 = sext i32 %3286 to i64
  %3288 = shl nsw i64 %3287, 3
  %3289 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3288
  %3290 = bitcast i8* %3289 to double*
  %3291 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3290, i32 64)
  %3292 = add i32 %180, 111
  %3293 = sext i32 %3292 to i64
  %3294 = shl nsw i64 %3293, 3
  %3295 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3294
  %3296 = bitcast i8* %3295 to double*
  %3297 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3296, i32 64)
  %3298 = fcmp reassoc ninf nsz oge double %175, %3291
  %3299 = fcmp reassoc ninf nsz ole double %175, %3297
  %.0947 = select i1 %3298, i1 %3299, i1 false
  br i1 %.0947, label %true_block1367, label %after_if1363

after_if1363:                                     ; preds = %true_block1367, %true_block1361, %after_if1351
  %.1111282 = phi double [ %3313, %true_block1367 ], [ %.1101281, %true_block1361 ], [ %.1101281, %after_if1351 ]
  %.110 = phi i1 [ true, %true_block1367 ], [ %.109, %true_block1361 ], [ %.109, %after_if1351 ]
  %3300 = icmp ugt i32 %201, 111
  %3301 = xor i1 %.110, true
  %spec.select1937 = select i1 %3300, i1 %3301, i1 false
  br i1 %spec.select1937, label %true_block1373, label %after_if1375

true_block1367:                                   ; preds = %true_block1361
  %getch.i2419 = getelementptr i8, i8* %12, i64 418612680
  %3302 = getelementptr inbounds i8, i8* %getch.i2419, i64 %3288
  %3303 = bitcast i8* %3302 to double*
  %3304 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3303, i32 64)
  %3305 = getelementptr inbounds i8, i8* %getch.i2419, i64 %3294
  %3306 = bitcast i8* %3305 to double*
  %3307 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3306, i32 64)
  %3308 = fsub reassoc ninf nsz double %3307, %3304
  %3309 = fsub reassoc ninf nsz double %3297, %3291
  %3310 = fsub reassoc ninf nsz double %175, %3291
  %3311 = fmul reassoc ninf nsz double %3308, %3310
  %3312 = fdiv reassoc ninf nsz double %3311, %3309
  %3313 = fadd reassoc ninf nsz double %3312, %3304
  br label %after_if1363

true_block1373:                                   ; preds = %after_if1363
  %3314 = add i32 %180, 111
  %3315 = sext i32 %3314 to i64
  %3316 = shl nsw i64 %3315, 3
  %3317 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3316
  %3318 = bitcast i8* %3317 to double*
  %3319 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3318, i32 64)
  %3320 = add i32 %180, 112
  %3321 = sext i32 %3320 to i64
  %3322 = shl nsw i64 %3321, 3
  %3323 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3322
  %3324 = bitcast i8* %3323 to double*
  %3325 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3324, i32 64)
  %3326 = fcmp reassoc ninf nsz oge double %175, %3319
  %3327 = fcmp reassoc ninf nsz ole double %175, %3325
  %.0945 = select i1 %3326, i1 %3327, i1 false
  br i1 %.0945, label %true_block1379, label %after_if1375

after_if1375:                                     ; preds = %true_block1379, %true_block1373, %after_if1363
  %.1121283 = phi double [ %3341, %true_block1379 ], [ %.1111282, %true_block1373 ], [ %.1111282, %after_if1363 ]
  %.111 = phi i1 [ true, %true_block1379 ], [ %.110, %true_block1373 ], [ %.110, %after_if1363 ]
  %3328 = icmp ugt i32 %201, 112
  %3329 = xor i1 %.111, true
  %spec.select1938 = select i1 %3328, i1 %3329, i1 false
  br i1 %spec.select1938, label %true_block1385, label %after_if1387

true_block1379:                                   ; preds = %true_block1373
  %getch.i2418 = getelementptr i8, i8* %12, i64 418612680
  %3330 = getelementptr inbounds i8, i8* %getch.i2418, i64 %3316
  %3331 = bitcast i8* %3330 to double*
  %3332 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3331, i32 64)
  %3333 = getelementptr inbounds i8, i8* %getch.i2418, i64 %3322
  %3334 = bitcast i8* %3333 to double*
  %3335 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3334, i32 64)
  %3336 = fsub reassoc ninf nsz double %3335, %3332
  %3337 = fsub reassoc ninf nsz double %3325, %3319
  %3338 = fsub reassoc ninf nsz double %175, %3319
  %3339 = fmul reassoc ninf nsz double %3336, %3338
  %3340 = fdiv reassoc ninf nsz double %3339, %3337
  %3341 = fadd reassoc ninf nsz double %3340, %3332
  br label %after_if1375

true_block1385:                                   ; preds = %after_if1375
  %3342 = add i32 %180, 112
  %3343 = sext i32 %3342 to i64
  %3344 = shl nsw i64 %3343, 3
  %3345 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3344
  %3346 = bitcast i8* %3345 to double*
  %3347 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3346, i32 64)
  %3348 = add i32 %180, 113
  %3349 = sext i32 %3348 to i64
  %3350 = shl nsw i64 %3349, 3
  %3351 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3350
  %3352 = bitcast i8* %3351 to double*
  %3353 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3352, i32 64)
  %3354 = fcmp reassoc ninf nsz oge double %175, %3347
  %3355 = fcmp reassoc ninf nsz ole double %175, %3353
  %.0943 = select i1 %3354, i1 %3355, i1 false
  br i1 %.0943, label %true_block1391, label %after_if1387

after_if1387:                                     ; preds = %true_block1391, %true_block1385, %after_if1375
  %.1131284 = phi double [ %3369, %true_block1391 ], [ %.1121283, %true_block1385 ], [ %.1121283, %after_if1375 ]
  %.112 = phi i1 [ true, %true_block1391 ], [ %.111, %true_block1385 ], [ %.111, %after_if1375 ]
  %3356 = icmp ugt i32 %201, 113
  %3357 = xor i1 %.112, true
  %spec.select1939 = select i1 %3356, i1 %3357, i1 false
  br i1 %spec.select1939, label %true_block1397, label %after_if1399

true_block1391:                                   ; preds = %true_block1385
  %getch.i2417 = getelementptr i8, i8* %12, i64 418612680
  %3358 = getelementptr inbounds i8, i8* %getch.i2417, i64 %3344
  %3359 = bitcast i8* %3358 to double*
  %3360 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3359, i32 64)
  %3361 = getelementptr inbounds i8, i8* %getch.i2417, i64 %3350
  %3362 = bitcast i8* %3361 to double*
  %3363 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3362, i32 64)
  %3364 = fsub reassoc ninf nsz double %3363, %3360
  %3365 = fsub reassoc ninf nsz double %3353, %3347
  %3366 = fsub reassoc ninf nsz double %175, %3347
  %3367 = fmul reassoc ninf nsz double %3364, %3366
  %3368 = fdiv reassoc ninf nsz double %3367, %3365
  %3369 = fadd reassoc ninf nsz double %3368, %3360
  br label %after_if1387

true_block1397:                                   ; preds = %after_if1387
  %3370 = add i32 %180, 113
  %3371 = sext i32 %3370 to i64
  %3372 = shl nsw i64 %3371, 3
  %3373 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3372
  %3374 = bitcast i8* %3373 to double*
  %3375 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3374, i32 64)
  %3376 = add i32 %180, 114
  %3377 = sext i32 %3376 to i64
  %3378 = shl nsw i64 %3377, 3
  %3379 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3378
  %3380 = bitcast i8* %3379 to double*
  %3381 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3380, i32 64)
  %3382 = fcmp reassoc ninf nsz oge double %175, %3375
  %3383 = fcmp reassoc ninf nsz ole double %175, %3381
  %.0941 = select i1 %3382, i1 %3383, i1 false
  br i1 %.0941, label %true_block1403, label %after_if1399

after_if1399:                                     ; preds = %true_block1403, %true_block1397, %after_if1387
  %.1141285 = phi double [ %3397, %true_block1403 ], [ %.1131284, %true_block1397 ], [ %.1131284, %after_if1387 ]
  %.113 = phi i1 [ true, %true_block1403 ], [ %.112, %true_block1397 ], [ %.112, %after_if1387 ]
  %3384 = icmp ugt i32 %201, 114
  %3385 = xor i1 %.113, true
  %spec.select1940 = select i1 %3384, i1 %3385, i1 false
  br i1 %spec.select1940, label %true_block1409, label %after_if1411

true_block1403:                                   ; preds = %true_block1397
  %getch.i2416 = getelementptr i8, i8* %12, i64 418612680
  %3386 = getelementptr inbounds i8, i8* %getch.i2416, i64 %3372
  %3387 = bitcast i8* %3386 to double*
  %3388 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3387, i32 64)
  %3389 = getelementptr inbounds i8, i8* %getch.i2416, i64 %3378
  %3390 = bitcast i8* %3389 to double*
  %3391 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3390, i32 64)
  %3392 = fsub reassoc ninf nsz double %3391, %3388
  %3393 = fsub reassoc ninf nsz double %3381, %3375
  %3394 = fsub reassoc ninf nsz double %175, %3375
  %3395 = fmul reassoc ninf nsz double %3392, %3394
  %3396 = fdiv reassoc ninf nsz double %3395, %3393
  %3397 = fadd reassoc ninf nsz double %3396, %3388
  br label %after_if1399

true_block1409:                                   ; preds = %after_if1399
  %3398 = add i32 %180, 114
  %3399 = sext i32 %3398 to i64
  %3400 = shl nsw i64 %3399, 3
  %3401 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3400
  %3402 = bitcast i8* %3401 to double*
  %3403 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3402, i32 64)
  %3404 = add i32 %180, 115
  %3405 = sext i32 %3404 to i64
  %3406 = shl nsw i64 %3405, 3
  %3407 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3406
  %3408 = bitcast i8* %3407 to double*
  %3409 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3408, i32 64)
  %3410 = fcmp reassoc ninf nsz oge double %175, %3403
  %3411 = fcmp reassoc ninf nsz ole double %175, %3409
  %.0939 = select i1 %3410, i1 %3411, i1 false
  br i1 %.0939, label %true_block1415, label %after_if1411

after_if1411:                                     ; preds = %true_block1415, %true_block1409, %after_if1399
  %.1151286 = phi double [ %3425, %true_block1415 ], [ %.1141285, %true_block1409 ], [ %.1141285, %after_if1399 ]
  %.114 = phi i1 [ true, %true_block1415 ], [ %.113, %true_block1409 ], [ %.113, %after_if1399 ]
  %3412 = icmp ugt i32 %201, 115
  %3413 = xor i1 %.114, true
  %spec.select1941 = select i1 %3412, i1 %3413, i1 false
  br i1 %spec.select1941, label %true_block1421, label %after_if1423

true_block1415:                                   ; preds = %true_block1409
  %getch.i2415 = getelementptr i8, i8* %12, i64 418612680
  %3414 = getelementptr inbounds i8, i8* %getch.i2415, i64 %3400
  %3415 = bitcast i8* %3414 to double*
  %3416 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3415, i32 64)
  %3417 = getelementptr inbounds i8, i8* %getch.i2415, i64 %3406
  %3418 = bitcast i8* %3417 to double*
  %3419 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3418, i32 64)
  %3420 = fsub reassoc ninf nsz double %3419, %3416
  %3421 = fsub reassoc ninf nsz double %3409, %3403
  %3422 = fsub reassoc ninf nsz double %175, %3403
  %3423 = fmul reassoc ninf nsz double %3420, %3422
  %3424 = fdiv reassoc ninf nsz double %3423, %3421
  %3425 = fadd reassoc ninf nsz double %3424, %3416
  br label %after_if1411

true_block1421:                                   ; preds = %after_if1411
  %3426 = add i32 %180, 115
  %3427 = sext i32 %3426 to i64
  %3428 = shl nsw i64 %3427, 3
  %3429 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3428
  %3430 = bitcast i8* %3429 to double*
  %3431 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3430, i32 64)
  %3432 = add i32 %180, 116
  %3433 = sext i32 %3432 to i64
  %3434 = shl nsw i64 %3433, 3
  %3435 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3434
  %3436 = bitcast i8* %3435 to double*
  %3437 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3436, i32 64)
  %3438 = fcmp reassoc ninf nsz oge double %175, %3431
  %3439 = fcmp reassoc ninf nsz ole double %175, %3437
  %.0937 = select i1 %3438, i1 %3439, i1 false
  br i1 %.0937, label %true_block1427, label %after_if1423

after_if1423:                                     ; preds = %true_block1427, %true_block1421, %after_if1411
  %.1161287 = phi double [ %3453, %true_block1427 ], [ %.1151286, %true_block1421 ], [ %.1151286, %after_if1411 ]
  %.115 = phi i1 [ true, %true_block1427 ], [ %.114, %true_block1421 ], [ %.114, %after_if1411 ]
  %3440 = icmp ugt i32 %201, 116
  %3441 = xor i1 %.115, true
  %spec.select1942 = select i1 %3440, i1 %3441, i1 false
  br i1 %spec.select1942, label %true_block1433, label %after_if1435

true_block1427:                                   ; preds = %true_block1421
  %getch.i2414 = getelementptr i8, i8* %12, i64 418612680
  %3442 = getelementptr inbounds i8, i8* %getch.i2414, i64 %3428
  %3443 = bitcast i8* %3442 to double*
  %3444 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3443, i32 64)
  %3445 = getelementptr inbounds i8, i8* %getch.i2414, i64 %3434
  %3446 = bitcast i8* %3445 to double*
  %3447 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3446, i32 64)
  %3448 = fsub reassoc ninf nsz double %3447, %3444
  %3449 = fsub reassoc ninf nsz double %3437, %3431
  %3450 = fsub reassoc ninf nsz double %175, %3431
  %3451 = fmul reassoc ninf nsz double %3448, %3450
  %3452 = fdiv reassoc ninf nsz double %3451, %3449
  %3453 = fadd reassoc ninf nsz double %3452, %3444
  br label %after_if1423

true_block1433:                                   ; preds = %after_if1423
  %3454 = add i32 %180, 116
  %3455 = sext i32 %3454 to i64
  %3456 = shl nsw i64 %3455, 3
  %3457 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3456
  %3458 = bitcast i8* %3457 to double*
  %3459 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3458, i32 64)
  %3460 = add i32 %180, 117
  %3461 = sext i32 %3460 to i64
  %3462 = shl nsw i64 %3461, 3
  %3463 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3462
  %3464 = bitcast i8* %3463 to double*
  %3465 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3464, i32 64)
  %3466 = fcmp reassoc ninf nsz oge double %175, %3459
  %3467 = fcmp reassoc ninf nsz ole double %175, %3465
  %.0935 = select i1 %3466, i1 %3467, i1 false
  br i1 %.0935, label %true_block1439, label %after_if1435

after_if1435:                                     ; preds = %true_block1439, %true_block1433, %after_if1423
  %.1171288 = phi double [ %3481, %true_block1439 ], [ %.1161287, %true_block1433 ], [ %.1161287, %after_if1423 ]
  %.116 = phi i1 [ true, %true_block1439 ], [ %.115, %true_block1433 ], [ %.115, %after_if1423 ]
  %3468 = icmp ugt i32 %201, 117
  %3469 = xor i1 %.116, true
  %spec.select1943 = select i1 %3468, i1 %3469, i1 false
  br i1 %spec.select1943, label %true_block1445, label %after_if1447

true_block1439:                                   ; preds = %true_block1433
  %getch.i2413 = getelementptr i8, i8* %12, i64 418612680
  %3470 = getelementptr inbounds i8, i8* %getch.i2413, i64 %3456
  %3471 = bitcast i8* %3470 to double*
  %3472 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3471, i32 64)
  %3473 = getelementptr inbounds i8, i8* %getch.i2413, i64 %3462
  %3474 = bitcast i8* %3473 to double*
  %3475 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3474, i32 64)
  %3476 = fsub reassoc ninf nsz double %3475, %3472
  %3477 = fsub reassoc ninf nsz double %3465, %3459
  %3478 = fsub reassoc ninf nsz double %175, %3459
  %3479 = fmul reassoc ninf nsz double %3476, %3478
  %3480 = fdiv reassoc ninf nsz double %3479, %3477
  %3481 = fadd reassoc ninf nsz double %3480, %3472
  br label %after_if1435

true_block1445:                                   ; preds = %after_if1435
  %3482 = add i32 %180, 117
  %3483 = sext i32 %3482 to i64
  %3484 = shl nsw i64 %3483, 3
  %3485 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3484
  %3486 = bitcast i8* %3485 to double*
  %3487 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3486, i32 64)
  %3488 = add i32 %180, 118
  %3489 = sext i32 %3488 to i64
  %3490 = shl nsw i64 %3489, 3
  %3491 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3490
  %3492 = bitcast i8* %3491 to double*
  %3493 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3492, i32 64)
  %3494 = fcmp reassoc ninf nsz oge double %175, %3487
  %3495 = fcmp reassoc ninf nsz ole double %175, %3493
  %.0933 = select i1 %3494, i1 %3495, i1 false
  br i1 %.0933, label %true_block1451, label %after_if1447

after_if1447:                                     ; preds = %true_block1451, %true_block1445, %after_if1435
  %.1181289 = phi double [ %3509, %true_block1451 ], [ %.1171288, %true_block1445 ], [ %.1171288, %after_if1435 ]
  %.117 = phi i1 [ true, %true_block1451 ], [ %.116, %true_block1445 ], [ %.116, %after_if1435 ]
  %3496 = icmp ugt i32 %201, 118
  %3497 = xor i1 %.117, true
  %spec.select1944 = select i1 %3496, i1 %3497, i1 false
  br i1 %spec.select1944, label %true_block1457, label %after_if1459

true_block1451:                                   ; preds = %true_block1445
  %getch.i2412 = getelementptr i8, i8* %12, i64 418612680
  %3498 = getelementptr inbounds i8, i8* %getch.i2412, i64 %3484
  %3499 = bitcast i8* %3498 to double*
  %3500 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3499, i32 64)
  %3501 = getelementptr inbounds i8, i8* %getch.i2412, i64 %3490
  %3502 = bitcast i8* %3501 to double*
  %3503 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3502, i32 64)
  %3504 = fsub reassoc ninf nsz double %3503, %3500
  %3505 = fsub reassoc ninf nsz double %3493, %3487
  %3506 = fsub reassoc ninf nsz double %175, %3487
  %3507 = fmul reassoc ninf nsz double %3504, %3506
  %3508 = fdiv reassoc ninf nsz double %3507, %3505
  %3509 = fadd reassoc ninf nsz double %3508, %3500
  br label %after_if1447

true_block1457:                                   ; preds = %after_if1447
  %3510 = add i32 %180, 118
  %3511 = sext i32 %3510 to i64
  %3512 = shl nsw i64 %3511, 3
  %3513 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3512
  %3514 = bitcast i8* %3513 to double*
  %3515 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3514, i32 64)
  %3516 = add i32 %180, 119
  %3517 = sext i32 %3516 to i64
  %3518 = shl nsw i64 %3517, 3
  %3519 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3518
  %3520 = bitcast i8* %3519 to double*
  %3521 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3520, i32 64)
  %3522 = fcmp reassoc ninf nsz oge double %175, %3515
  %3523 = fcmp reassoc ninf nsz ole double %175, %3521
  %.0931 = select i1 %3522, i1 %3523, i1 false
  br i1 %.0931, label %true_block1463, label %after_if1459

after_if1459:                                     ; preds = %true_block1463, %true_block1457, %after_if1447
  %.1191290 = phi double [ %3537, %true_block1463 ], [ %.1181289, %true_block1457 ], [ %.1181289, %after_if1447 ]
  %.118 = phi i1 [ true, %true_block1463 ], [ %.117, %true_block1457 ], [ %.117, %after_if1447 ]
  %3524 = icmp ugt i32 %201, 119
  %3525 = xor i1 %.118, true
  %spec.select1945 = select i1 %3524, i1 %3525, i1 false
  br i1 %spec.select1945, label %true_block1469, label %after_if1471

true_block1463:                                   ; preds = %true_block1457
  %getch.i2411 = getelementptr i8, i8* %12, i64 418612680
  %3526 = getelementptr inbounds i8, i8* %getch.i2411, i64 %3512
  %3527 = bitcast i8* %3526 to double*
  %3528 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3527, i32 64)
  %3529 = getelementptr inbounds i8, i8* %getch.i2411, i64 %3518
  %3530 = bitcast i8* %3529 to double*
  %3531 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3530, i32 64)
  %3532 = fsub reassoc ninf nsz double %3531, %3528
  %3533 = fsub reassoc ninf nsz double %3521, %3515
  %3534 = fsub reassoc ninf nsz double %175, %3515
  %3535 = fmul reassoc ninf nsz double %3532, %3534
  %3536 = fdiv reassoc ninf nsz double %3535, %3533
  %3537 = fadd reassoc ninf nsz double %3536, %3528
  br label %after_if1459

true_block1469:                                   ; preds = %after_if1459
  %3538 = add i32 %180, 119
  %3539 = sext i32 %3538 to i64
  %3540 = shl nsw i64 %3539, 3
  %3541 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3540
  %3542 = bitcast i8* %3541 to double*
  %3543 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3542, i32 64)
  %3544 = add i32 %180, 120
  %3545 = sext i32 %3544 to i64
  %3546 = shl nsw i64 %3545, 3
  %3547 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3546
  %3548 = bitcast i8* %3547 to double*
  %3549 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3548, i32 64)
  %3550 = fcmp reassoc ninf nsz oge double %175, %3543
  %3551 = fcmp reassoc ninf nsz ole double %175, %3549
  %.0929 = select i1 %3550, i1 %3551, i1 false
  br i1 %.0929, label %true_block1475, label %after_if1471

after_if1471:                                     ; preds = %true_block1475, %true_block1469, %after_if1459
  %.1201291 = phi double [ %3565, %true_block1475 ], [ %.1191290, %true_block1469 ], [ %.1191290, %after_if1459 ]
  %.119 = phi i1 [ true, %true_block1475 ], [ %.118, %true_block1469 ], [ %.118, %after_if1459 ]
  %3552 = icmp ugt i32 %201, 120
  %3553 = xor i1 %.119, true
  %spec.select1946 = select i1 %3552, i1 %3553, i1 false
  br i1 %spec.select1946, label %true_block1481, label %after_if1483

true_block1475:                                   ; preds = %true_block1469
  %getch.i2410 = getelementptr i8, i8* %12, i64 418612680
  %3554 = getelementptr inbounds i8, i8* %getch.i2410, i64 %3540
  %3555 = bitcast i8* %3554 to double*
  %3556 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3555, i32 64)
  %3557 = getelementptr inbounds i8, i8* %getch.i2410, i64 %3546
  %3558 = bitcast i8* %3557 to double*
  %3559 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3558, i32 64)
  %3560 = fsub reassoc ninf nsz double %3559, %3556
  %3561 = fsub reassoc ninf nsz double %3549, %3543
  %3562 = fsub reassoc ninf nsz double %175, %3543
  %3563 = fmul reassoc ninf nsz double %3560, %3562
  %3564 = fdiv reassoc ninf nsz double %3563, %3561
  %3565 = fadd reassoc ninf nsz double %3564, %3556
  br label %after_if1471

true_block1481:                                   ; preds = %after_if1471
  %3566 = add i32 %180, 120
  %3567 = sext i32 %3566 to i64
  %3568 = shl nsw i64 %3567, 3
  %3569 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3568
  %3570 = bitcast i8* %3569 to double*
  %3571 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3570, i32 64)
  %3572 = add i32 %180, 121
  %3573 = sext i32 %3572 to i64
  %3574 = shl nsw i64 %3573, 3
  %3575 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3574
  %3576 = bitcast i8* %3575 to double*
  %3577 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3576, i32 64)
  %3578 = fcmp reassoc ninf nsz oge double %175, %3571
  %3579 = fcmp reassoc ninf nsz ole double %175, %3577
  %.0927 = select i1 %3578, i1 %3579, i1 false
  br i1 %.0927, label %true_block1487, label %after_if1483

after_if1483:                                     ; preds = %true_block1487, %true_block1481, %after_if1471
  %.1211292 = phi double [ %3593, %true_block1487 ], [ %.1201291, %true_block1481 ], [ %.1201291, %after_if1471 ]
  %.120 = phi i1 [ true, %true_block1487 ], [ %.119, %true_block1481 ], [ %.119, %after_if1471 ]
  %3580 = icmp ugt i32 %201, 121
  %3581 = xor i1 %.120, true
  %spec.select1947 = select i1 %3580, i1 %3581, i1 false
  br i1 %spec.select1947, label %true_block1493, label %after_if1495

true_block1487:                                   ; preds = %true_block1481
  %getch.i2409 = getelementptr i8, i8* %12, i64 418612680
  %3582 = getelementptr inbounds i8, i8* %getch.i2409, i64 %3568
  %3583 = bitcast i8* %3582 to double*
  %3584 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3583, i32 64)
  %3585 = getelementptr inbounds i8, i8* %getch.i2409, i64 %3574
  %3586 = bitcast i8* %3585 to double*
  %3587 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3586, i32 64)
  %3588 = fsub reassoc ninf nsz double %3587, %3584
  %3589 = fsub reassoc ninf nsz double %3577, %3571
  %3590 = fsub reassoc ninf nsz double %175, %3571
  %3591 = fmul reassoc ninf nsz double %3588, %3590
  %3592 = fdiv reassoc ninf nsz double %3591, %3589
  %3593 = fadd reassoc ninf nsz double %3592, %3584
  br label %after_if1483

true_block1493:                                   ; preds = %after_if1483
  %3594 = add i32 %180, 121
  %3595 = sext i32 %3594 to i64
  %3596 = shl nsw i64 %3595, 3
  %3597 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3596
  %3598 = bitcast i8* %3597 to double*
  %3599 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3598, i32 64)
  %3600 = add i32 %180, 122
  %3601 = sext i32 %3600 to i64
  %3602 = shl nsw i64 %3601, 3
  %3603 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3602
  %3604 = bitcast i8* %3603 to double*
  %3605 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3604, i32 64)
  %3606 = fcmp reassoc ninf nsz oge double %175, %3599
  %3607 = fcmp reassoc ninf nsz ole double %175, %3605
  %.0925 = select i1 %3606, i1 %3607, i1 false
  br i1 %.0925, label %true_block1499, label %after_if1495

after_if1495:                                     ; preds = %true_block1499, %true_block1493, %after_if1483
  %.1221293 = phi double [ %3621, %true_block1499 ], [ %.1211292, %true_block1493 ], [ %.1211292, %after_if1483 ]
  %.121 = phi i1 [ true, %true_block1499 ], [ %.120, %true_block1493 ], [ %.120, %after_if1483 ]
  %3608 = icmp ugt i32 %201, 122
  %3609 = xor i1 %.121, true
  %spec.select1948 = select i1 %3608, i1 %3609, i1 false
  br i1 %spec.select1948, label %true_block1505, label %after_if1507

true_block1499:                                   ; preds = %true_block1493
  %getch.i2408 = getelementptr i8, i8* %12, i64 418612680
  %3610 = getelementptr inbounds i8, i8* %getch.i2408, i64 %3596
  %3611 = bitcast i8* %3610 to double*
  %3612 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3611, i32 64)
  %3613 = getelementptr inbounds i8, i8* %getch.i2408, i64 %3602
  %3614 = bitcast i8* %3613 to double*
  %3615 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3614, i32 64)
  %3616 = fsub reassoc ninf nsz double %3615, %3612
  %3617 = fsub reassoc ninf nsz double %3605, %3599
  %3618 = fsub reassoc ninf nsz double %175, %3599
  %3619 = fmul reassoc ninf nsz double %3616, %3618
  %3620 = fdiv reassoc ninf nsz double %3619, %3617
  %3621 = fadd reassoc ninf nsz double %3620, %3612
  br label %after_if1495

true_block1505:                                   ; preds = %after_if1495
  %3622 = add i32 %180, 122
  %3623 = sext i32 %3622 to i64
  %3624 = shl nsw i64 %3623, 3
  %3625 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3624
  %3626 = bitcast i8* %3625 to double*
  %3627 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3626, i32 64)
  %3628 = add i32 %180, 123
  %3629 = sext i32 %3628 to i64
  %3630 = shl nsw i64 %3629, 3
  %3631 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3630
  %3632 = bitcast i8* %3631 to double*
  %3633 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3632, i32 64)
  %3634 = fcmp reassoc ninf nsz oge double %175, %3627
  %3635 = fcmp reassoc ninf nsz ole double %175, %3633
  %.0923 = select i1 %3634, i1 %3635, i1 false
  br i1 %.0923, label %true_block1511, label %after_if1507

after_if1507:                                     ; preds = %true_block1511, %true_block1505, %after_if1495
  %.1231294 = phi double [ %3649, %true_block1511 ], [ %.1221293, %true_block1505 ], [ %.1221293, %after_if1495 ]
  %.122 = phi i1 [ true, %true_block1511 ], [ %.121, %true_block1505 ], [ %.121, %after_if1495 ]
  %3636 = icmp ugt i32 %201, 123
  %3637 = xor i1 %.122, true
  %spec.select1949 = select i1 %3636, i1 %3637, i1 false
  br i1 %spec.select1949, label %true_block1517, label %after_if1519

true_block1511:                                   ; preds = %true_block1505
  %getch.i2407 = getelementptr i8, i8* %12, i64 418612680
  %3638 = getelementptr inbounds i8, i8* %getch.i2407, i64 %3624
  %3639 = bitcast i8* %3638 to double*
  %3640 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3639, i32 64)
  %3641 = getelementptr inbounds i8, i8* %getch.i2407, i64 %3630
  %3642 = bitcast i8* %3641 to double*
  %3643 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3642, i32 64)
  %3644 = fsub reassoc ninf nsz double %3643, %3640
  %3645 = fsub reassoc ninf nsz double %3633, %3627
  %3646 = fsub reassoc ninf nsz double %175, %3627
  %3647 = fmul reassoc ninf nsz double %3644, %3646
  %3648 = fdiv reassoc ninf nsz double %3647, %3645
  %3649 = fadd reassoc ninf nsz double %3648, %3640
  br label %after_if1507

true_block1517:                                   ; preds = %after_if1507
  %3650 = add i32 %180, 123
  %3651 = sext i32 %3650 to i64
  %3652 = shl nsw i64 %3651, 3
  %3653 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3652
  %3654 = bitcast i8* %3653 to double*
  %3655 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3654, i32 64)
  %3656 = add i32 %180, 124
  %3657 = sext i32 %3656 to i64
  %3658 = shl nsw i64 %3657, 3
  %3659 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3658
  %3660 = bitcast i8* %3659 to double*
  %3661 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3660, i32 64)
  %3662 = fcmp reassoc ninf nsz oge double %175, %3655
  %3663 = fcmp reassoc ninf nsz ole double %175, %3661
  %.0921 = select i1 %3662, i1 %3663, i1 false
  br i1 %.0921, label %true_block1523, label %after_if1519

after_if1519:                                     ; preds = %true_block1523, %true_block1517, %after_if1507
  %.1241295 = phi double [ %3677, %true_block1523 ], [ %.1231294, %true_block1517 ], [ %.1231294, %after_if1507 ]
  %.123 = phi i1 [ true, %true_block1523 ], [ %.122, %true_block1517 ], [ %.122, %after_if1507 ]
  %3664 = icmp ugt i32 %201, 124
  %3665 = xor i1 %.123, true
  %spec.select1950 = select i1 %3664, i1 %3665, i1 false
  br i1 %spec.select1950, label %true_block1529, label %after_if1531

true_block1523:                                   ; preds = %true_block1517
  %getch.i2406 = getelementptr i8, i8* %12, i64 418612680
  %3666 = getelementptr inbounds i8, i8* %getch.i2406, i64 %3652
  %3667 = bitcast i8* %3666 to double*
  %3668 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3667, i32 64)
  %3669 = getelementptr inbounds i8, i8* %getch.i2406, i64 %3658
  %3670 = bitcast i8* %3669 to double*
  %3671 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3670, i32 64)
  %3672 = fsub reassoc ninf nsz double %3671, %3668
  %3673 = fsub reassoc ninf nsz double %3661, %3655
  %3674 = fsub reassoc ninf nsz double %175, %3655
  %3675 = fmul reassoc ninf nsz double %3672, %3674
  %3676 = fdiv reassoc ninf nsz double %3675, %3673
  %3677 = fadd reassoc ninf nsz double %3676, %3668
  br label %after_if1519

true_block1529:                                   ; preds = %after_if1519
  %3678 = add i32 %180, 124
  %3679 = sext i32 %3678 to i64
  %3680 = shl nsw i64 %3679, 3
  %3681 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3680
  %3682 = bitcast i8* %3681 to double*
  %3683 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3682, i32 64)
  %3684 = add i32 %180, 125
  %3685 = sext i32 %3684 to i64
  %3686 = shl nsw i64 %3685, 3
  %3687 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3686
  %3688 = bitcast i8* %3687 to double*
  %3689 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3688, i32 64)
  %3690 = fcmp reassoc ninf nsz oge double %175, %3683
  %3691 = fcmp reassoc ninf nsz ole double %175, %3689
  %.0919 = select i1 %3690, i1 %3691, i1 false
  br i1 %.0919, label %true_block1535, label %after_if1531

after_if1531:                                     ; preds = %true_block1535, %true_block1529, %after_if1519
  %.1251296 = phi double [ %3705, %true_block1535 ], [ %.1241295, %true_block1529 ], [ %.1241295, %after_if1519 ]
  %.124 = phi i1 [ true, %true_block1535 ], [ %.123, %true_block1529 ], [ %.123, %after_if1519 ]
  %3692 = icmp ugt i32 %201, 125
  %3693 = xor i1 %.124, true
  %spec.select1951 = select i1 %3692, i1 %3693, i1 false
  br i1 %spec.select1951, label %true_block1541, label %after_if1543

true_block1535:                                   ; preds = %true_block1529
  %getch.i2405 = getelementptr i8, i8* %12, i64 418612680
  %3694 = getelementptr inbounds i8, i8* %getch.i2405, i64 %3680
  %3695 = bitcast i8* %3694 to double*
  %3696 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3695, i32 64)
  %3697 = getelementptr inbounds i8, i8* %getch.i2405, i64 %3686
  %3698 = bitcast i8* %3697 to double*
  %3699 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3698, i32 64)
  %3700 = fsub reassoc ninf nsz double %3699, %3696
  %3701 = fsub reassoc ninf nsz double %3689, %3683
  %3702 = fsub reassoc ninf nsz double %175, %3683
  %3703 = fmul reassoc ninf nsz double %3700, %3702
  %3704 = fdiv reassoc ninf nsz double %3703, %3701
  %3705 = fadd reassoc ninf nsz double %3704, %3696
  br label %after_if1531

true_block1541:                                   ; preds = %after_if1531
  %3706 = add i32 %180, 125
  %3707 = sext i32 %3706 to i64
  %3708 = shl nsw i64 %3707, 3
  %3709 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3708
  %3710 = bitcast i8* %3709 to double*
  %3711 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3710, i32 64)
  %3712 = add i32 %180, 126
  %3713 = sext i32 %3712 to i64
  %3714 = shl nsw i64 %3713, 3
  %3715 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3714
  %3716 = bitcast i8* %3715 to double*
  %3717 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3716, i32 64)
  %3718 = fcmp reassoc ninf nsz oge double %175, %3711
  %3719 = fcmp reassoc ninf nsz ole double %175, %3717
  %.0917 = select i1 %3718, i1 %3719, i1 false
  br i1 %.0917, label %true_block1547, label %after_if1543

after_if1543:                                     ; preds = %true_block1547, %true_block1541, %after_if1531
  %.1261297 = phi double [ %3733, %true_block1547 ], [ %.1251296, %true_block1541 ], [ %.1251296, %after_if1531 ]
  %.125 = phi i1 [ true, %true_block1547 ], [ %.124, %true_block1541 ], [ %.124, %after_if1531 ]
  %3720 = icmp ugt i32 %201, 126
  %3721 = xor i1 %.125, true
  %spec.select1952 = select i1 %3720, i1 %3721, i1 false
  br i1 %spec.select1952, label %true_block1553, label %after_if1555

true_block1547:                                   ; preds = %true_block1541
  %getch.i2404 = getelementptr i8, i8* %12, i64 418612680
  %3722 = getelementptr inbounds i8, i8* %getch.i2404, i64 %3708
  %3723 = bitcast i8* %3722 to double*
  %3724 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3723, i32 64)
  %3725 = getelementptr inbounds i8, i8* %getch.i2404, i64 %3714
  %3726 = bitcast i8* %3725 to double*
  %3727 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3726, i32 64)
  %3728 = fsub reassoc ninf nsz double %3727, %3724
  %3729 = fsub reassoc ninf nsz double %3717, %3711
  %3730 = fsub reassoc ninf nsz double %175, %3711
  %3731 = fmul reassoc ninf nsz double %3728, %3730
  %3732 = fdiv reassoc ninf nsz double %3731, %3729
  %3733 = fadd reassoc ninf nsz double %3732, %3724
  br label %after_if1543

true_block1553:                                   ; preds = %after_if1543
  %3734 = add i32 %180, 126
  %3735 = sext i32 %3734 to i64
  %3736 = shl nsw i64 %3735, 3
  %3737 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3736
  %3738 = bitcast i8* %3737 to double*
  %3739 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3738, i32 64)
  %3740 = add i32 %180, 127
  %3741 = sext i32 %3740 to i64
  %3742 = shl nsw i64 %3741, 3
  %3743 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3742
  %3744 = bitcast i8* %3743 to double*
  %3745 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3744, i32 64)
  %3746 = fcmp reassoc ninf nsz oge double %175, %3739
  %3747 = fcmp reassoc ninf nsz ole double %175, %3745
  %.0915 = select i1 %3746, i1 %3747, i1 false
  br i1 %.0915, label %true_block1559, label %after_if1555

after_if1555:                                     ; preds = %true_block1559, %true_block1553, %after_if1543
  %.1271298 = phi double [ %3761, %true_block1559 ], [ %.1261297, %true_block1553 ], [ %.1261297, %after_if1543 ]
  %.126 = phi i1 [ true, %true_block1559 ], [ %.125, %true_block1553 ], [ %.125, %after_if1543 ]
  %3748 = icmp ugt i32 %201, 127
  %3749 = xor i1 %.126, true
  %spec.select1953 = select i1 %3748, i1 %3749, i1 false
  br i1 %spec.select1953, label %true_block1565, label %after_if1567

true_block1559:                                   ; preds = %true_block1553
  %getch.i2403 = getelementptr i8, i8* %12, i64 418612680
  %3750 = getelementptr inbounds i8, i8* %getch.i2403, i64 %3736
  %3751 = bitcast i8* %3750 to double*
  %3752 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3751, i32 64)
  %3753 = getelementptr inbounds i8, i8* %getch.i2403, i64 %3742
  %3754 = bitcast i8* %3753 to double*
  %3755 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3754, i32 64)
  %3756 = fsub reassoc ninf nsz double %3755, %3752
  %3757 = fsub reassoc ninf nsz double %3745, %3739
  %3758 = fsub reassoc ninf nsz double %175, %3739
  %3759 = fmul reassoc ninf nsz double %3756, %3758
  %3760 = fdiv reassoc ninf nsz double %3759, %3757
  %3761 = fadd reassoc ninf nsz double %3760, %3752
  br label %after_if1555

true_block1565:                                   ; preds = %after_if1555
  %3762 = add i32 %180, 127
  %3763 = sext i32 %3762 to i64
  %3764 = shl nsw i64 %3763, 3
  %3765 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3764
  %3766 = bitcast i8* %3765 to double*
  %3767 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3766, i32 64)
  %3768 = add i32 %180, 128
  %3769 = sext i32 %3768 to i64
  %3770 = shl nsw i64 %3769, 3
  %3771 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3770
  %3772 = bitcast i8* %3771 to double*
  %3773 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3772, i32 64)
  %3774 = fcmp reassoc ninf nsz oge double %175, %3767
  %3775 = fcmp reassoc ninf nsz ole double %175, %3773
  %.0913 = select i1 %3774, i1 %3775, i1 false
  br i1 %.0913, label %true_block1571, label %after_if1567

after_if1567:                                     ; preds = %true_block1571, %true_block1565, %after_if1555
  %.1281299 = phi double [ %3789, %true_block1571 ], [ %.1271298, %true_block1565 ], [ %.1271298, %after_if1555 ]
  %.127 = phi i1 [ true, %true_block1571 ], [ %.126, %true_block1565 ], [ %.126, %after_if1555 ]
  %3776 = icmp ugt i32 %201, 128
  %3777 = xor i1 %.127, true
  %spec.select1954 = select i1 %3776, i1 %3777, i1 false
  br i1 %spec.select1954, label %true_block1577, label %after_if1579

true_block1571:                                   ; preds = %true_block1565
  %getch.i2402 = getelementptr i8, i8* %12, i64 418612680
  %3778 = getelementptr inbounds i8, i8* %getch.i2402, i64 %3764
  %3779 = bitcast i8* %3778 to double*
  %3780 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3779, i32 64)
  %3781 = getelementptr inbounds i8, i8* %getch.i2402, i64 %3770
  %3782 = bitcast i8* %3781 to double*
  %3783 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3782, i32 64)
  %3784 = fsub reassoc ninf nsz double %3783, %3780
  %3785 = fsub reassoc ninf nsz double %3773, %3767
  %3786 = fsub reassoc ninf nsz double %175, %3767
  %3787 = fmul reassoc ninf nsz double %3784, %3786
  %3788 = fdiv reassoc ninf nsz double %3787, %3785
  %3789 = fadd reassoc ninf nsz double %3788, %3780
  br label %after_if1567

true_block1577:                                   ; preds = %after_if1567
  %3790 = add i32 %180, 128
  %3791 = sext i32 %3790 to i64
  %3792 = shl nsw i64 %3791, 3
  %3793 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3792
  %3794 = bitcast i8* %3793 to double*
  %3795 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3794, i32 64)
  %3796 = add i32 %180, 129
  %3797 = sext i32 %3796 to i64
  %3798 = shl nsw i64 %3797, 3
  %3799 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3798
  %3800 = bitcast i8* %3799 to double*
  %3801 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3800, i32 64)
  %3802 = fcmp reassoc ninf nsz oge double %175, %3795
  %3803 = fcmp reassoc ninf nsz ole double %175, %3801
  %.0911 = select i1 %3802, i1 %3803, i1 false
  br i1 %.0911, label %true_block1583, label %after_if1579

after_if1579:                                     ; preds = %true_block1583, %true_block1577, %after_if1567
  %.1291300 = phi double [ %3817, %true_block1583 ], [ %.1281299, %true_block1577 ], [ %.1281299, %after_if1567 ]
  %.128 = phi i1 [ true, %true_block1583 ], [ %.127, %true_block1577 ], [ %.127, %after_if1567 ]
  %3804 = icmp ugt i32 %201, 129
  %3805 = xor i1 %.128, true
  %spec.select1955 = select i1 %3804, i1 %3805, i1 false
  br i1 %spec.select1955, label %true_block1589, label %after_if1591

true_block1583:                                   ; preds = %true_block1577
  %getch.i2401 = getelementptr i8, i8* %12, i64 418612680
  %3806 = getelementptr inbounds i8, i8* %getch.i2401, i64 %3792
  %3807 = bitcast i8* %3806 to double*
  %3808 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3807, i32 64)
  %3809 = getelementptr inbounds i8, i8* %getch.i2401, i64 %3798
  %3810 = bitcast i8* %3809 to double*
  %3811 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3810, i32 64)
  %3812 = fsub reassoc ninf nsz double %3811, %3808
  %3813 = fsub reassoc ninf nsz double %3801, %3795
  %3814 = fsub reassoc ninf nsz double %175, %3795
  %3815 = fmul reassoc ninf nsz double %3812, %3814
  %3816 = fdiv reassoc ninf nsz double %3815, %3813
  %3817 = fadd reassoc ninf nsz double %3816, %3808
  br label %after_if1579

true_block1589:                                   ; preds = %after_if1579
  %3818 = add i32 %180, 129
  %3819 = sext i32 %3818 to i64
  %3820 = shl nsw i64 %3819, 3
  %3821 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3820
  %3822 = bitcast i8* %3821 to double*
  %3823 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3822, i32 64)
  %3824 = add i32 %180, 130
  %3825 = sext i32 %3824 to i64
  %3826 = shl nsw i64 %3825, 3
  %3827 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3826
  %3828 = bitcast i8* %3827 to double*
  %3829 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3828, i32 64)
  %3830 = fcmp reassoc ninf nsz oge double %175, %3823
  %3831 = fcmp reassoc ninf nsz ole double %175, %3829
  %.0909 = select i1 %3830, i1 %3831, i1 false
  br i1 %.0909, label %true_block1595, label %after_if1591

after_if1591:                                     ; preds = %true_block1595, %true_block1589, %after_if1579
  %.1301301 = phi double [ %3845, %true_block1595 ], [ %.1291300, %true_block1589 ], [ %.1291300, %after_if1579 ]
  %.129 = phi i1 [ true, %true_block1595 ], [ %.128, %true_block1589 ], [ %.128, %after_if1579 ]
  %3832 = icmp ugt i32 %201, 130
  %3833 = xor i1 %.129, true
  %spec.select1956 = select i1 %3832, i1 %3833, i1 false
  br i1 %spec.select1956, label %true_block1601, label %after_if1603

true_block1595:                                   ; preds = %true_block1589
  %getch.i2400 = getelementptr i8, i8* %12, i64 418612680
  %3834 = getelementptr inbounds i8, i8* %getch.i2400, i64 %3820
  %3835 = bitcast i8* %3834 to double*
  %3836 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3835, i32 64)
  %3837 = getelementptr inbounds i8, i8* %getch.i2400, i64 %3826
  %3838 = bitcast i8* %3837 to double*
  %3839 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3838, i32 64)
  %3840 = fsub reassoc ninf nsz double %3839, %3836
  %3841 = fsub reassoc ninf nsz double %3829, %3823
  %3842 = fsub reassoc ninf nsz double %175, %3823
  %3843 = fmul reassoc ninf nsz double %3840, %3842
  %3844 = fdiv reassoc ninf nsz double %3843, %3841
  %3845 = fadd reassoc ninf nsz double %3844, %3836
  br label %after_if1591

true_block1601:                                   ; preds = %after_if1591
  %3846 = add i32 %180, 130
  %3847 = sext i32 %3846 to i64
  %3848 = shl nsw i64 %3847, 3
  %3849 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3848
  %3850 = bitcast i8* %3849 to double*
  %3851 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3850, i32 64)
  %3852 = add i32 %180, 131
  %3853 = sext i32 %3852 to i64
  %3854 = shl nsw i64 %3853, 3
  %3855 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3854
  %3856 = bitcast i8* %3855 to double*
  %3857 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3856, i32 64)
  %3858 = fcmp reassoc ninf nsz oge double %175, %3851
  %3859 = fcmp reassoc ninf nsz ole double %175, %3857
  %.0907 = select i1 %3858, i1 %3859, i1 false
  br i1 %.0907, label %true_block1607, label %after_if1603

after_if1603:                                     ; preds = %true_block1607, %true_block1601, %after_if1591
  %.1311302 = phi double [ %3873, %true_block1607 ], [ %.1301301, %true_block1601 ], [ %.1301301, %after_if1591 ]
  %.130 = phi i1 [ true, %true_block1607 ], [ %.129, %true_block1601 ], [ %.129, %after_if1591 ]
  %3860 = icmp ugt i32 %201, 131
  %3861 = xor i1 %.130, true
  %spec.select1957 = select i1 %3860, i1 %3861, i1 false
  br i1 %spec.select1957, label %true_block1613, label %after_if1615

true_block1607:                                   ; preds = %true_block1601
  %getch.i2399 = getelementptr i8, i8* %12, i64 418612680
  %3862 = getelementptr inbounds i8, i8* %getch.i2399, i64 %3848
  %3863 = bitcast i8* %3862 to double*
  %3864 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3863, i32 64)
  %3865 = getelementptr inbounds i8, i8* %getch.i2399, i64 %3854
  %3866 = bitcast i8* %3865 to double*
  %3867 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3866, i32 64)
  %3868 = fsub reassoc ninf nsz double %3867, %3864
  %3869 = fsub reassoc ninf nsz double %3857, %3851
  %3870 = fsub reassoc ninf nsz double %175, %3851
  %3871 = fmul reassoc ninf nsz double %3868, %3870
  %3872 = fdiv reassoc ninf nsz double %3871, %3869
  %3873 = fadd reassoc ninf nsz double %3872, %3864
  br label %after_if1603

true_block1613:                                   ; preds = %after_if1603
  %3874 = add i32 %180, 131
  %3875 = sext i32 %3874 to i64
  %3876 = shl nsw i64 %3875, 3
  %3877 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3876
  %3878 = bitcast i8* %3877 to double*
  %3879 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3878, i32 64)
  %3880 = add i32 %180, 132
  %3881 = sext i32 %3880 to i64
  %3882 = shl nsw i64 %3881, 3
  %3883 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3882
  %3884 = bitcast i8* %3883 to double*
  %3885 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3884, i32 64)
  %3886 = fcmp reassoc ninf nsz oge double %175, %3879
  %3887 = fcmp reassoc ninf nsz ole double %175, %3885
  %.0905 = select i1 %3886, i1 %3887, i1 false
  br i1 %.0905, label %true_block1619, label %after_if1615

after_if1615:                                     ; preds = %true_block1619, %true_block1613, %after_if1603
  %.1321303 = phi double [ %3901, %true_block1619 ], [ %.1311302, %true_block1613 ], [ %.1311302, %after_if1603 ]
  %.131 = phi i1 [ true, %true_block1619 ], [ %.130, %true_block1613 ], [ %.130, %after_if1603 ]
  %3888 = icmp ugt i32 %201, 132
  %3889 = xor i1 %.131, true
  %spec.select1958 = select i1 %3888, i1 %3889, i1 false
  br i1 %spec.select1958, label %true_block1625, label %after_if1627

true_block1619:                                   ; preds = %true_block1613
  %getch.i2398 = getelementptr i8, i8* %12, i64 418612680
  %3890 = getelementptr inbounds i8, i8* %getch.i2398, i64 %3876
  %3891 = bitcast i8* %3890 to double*
  %3892 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3891, i32 64)
  %3893 = getelementptr inbounds i8, i8* %getch.i2398, i64 %3882
  %3894 = bitcast i8* %3893 to double*
  %3895 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3894, i32 64)
  %3896 = fsub reassoc ninf nsz double %3895, %3892
  %3897 = fsub reassoc ninf nsz double %3885, %3879
  %3898 = fsub reassoc ninf nsz double %175, %3879
  %3899 = fmul reassoc ninf nsz double %3896, %3898
  %3900 = fdiv reassoc ninf nsz double %3899, %3897
  %3901 = fadd reassoc ninf nsz double %3900, %3892
  br label %after_if1615

true_block1625:                                   ; preds = %after_if1615
  %3902 = add i32 %180, 132
  %3903 = sext i32 %3902 to i64
  %3904 = shl nsw i64 %3903, 3
  %3905 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3904
  %3906 = bitcast i8* %3905 to double*
  %3907 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3906, i32 64)
  %3908 = add i32 %180, 133
  %3909 = sext i32 %3908 to i64
  %3910 = shl nsw i64 %3909, 3
  %3911 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3910
  %3912 = bitcast i8* %3911 to double*
  %3913 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3912, i32 64)
  %3914 = fcmp reassoc ninf nsz oge double %175, %3907
  %3915 = fcmp reassoc ninf nsz ole double %175, %3913
  %.0903 = select i1 %3914, i1 %3915, i1 false
  br i1 %.0903, label %true_block1631, label %after_if1627

after_if1627:                                     ; preds = %true_block1631, %true_block1625, %after_if1615
  %.1331304 = phi double [ %3929, %true_block1631 ], [ %.1321303, %true_block1625 ], [ %.1321303, %after_if1615 ]
  %.132 = phi i1 [ true, %true_block1631 ], [ %.131, %true_block1625 ], [ %.131, %after_if1615 ]
  %3916 = icmp ugt i32 %201, 133
  %3917 = xor i1 %.132, true
  %spec.select1959 = select i1 %3916, i1 %3917, i1 false
  br i1 %spec.select1959, label %true_block1637, label %after_if1639

true_block1631:                                   ; preds = %true_block1625
  %getch.i2397 = getelementptr i8, i8* %12, i64 418612680
  %3918 = getelementptr inbounds i8, i8* %getch.i2397, i64 %3904
  %3919 = bitcast i8* %3918 to double*
  %3920 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3919, i32 64)
  %3921 = getelementptr inbounds i8, i8* %getch.i2397, i64 %3910
  %3922 = bitcast i8* %3921 to double*
  %3923 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3922, i32 64)
  %3924 = fsub reassoc ninf nsz double %3923, %3920
  %3925 = fsub reassoc ninf nsz double %3913, %3907
  %3926 = fsub reassoc ninf nsz double %175, %3907
  %3927 = fmul reassoc ninf nsz double %3924, %3926
  %3928 = fdiv reassoc ninf nsz double %3927, %3925
  %3929 = fadd reassoc ninf nsz double %3928, %3920
  br label %after_if1627

true_block1637:                                   ; preds = %after_if1627
  %3930 = add i32 %180, 133
  %3931 = sext i32 %3930 to i64
  %3932 = shl nsw i64 %3931, 3
  %3933 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3932
  %3934 = bitcast i8* %3933 to double*
  %3935 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3934, i32 64)
  %3936 = add i32 %180, 134
  %3937 = sext i32 %3936 to i64
  %3938 = shl nsw i64 %3937, 3
  %3939 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3938
  %3940 = bitcast i8* %3939 to double*
  %3941 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3940, i32 64)
  %3942 = fcmp reassoc ninf nsz oge double %175, %3935
  %3943 = fcmp reassoc ninf nsz ole double %175, %3941
  %.0901 = select i1 %3942, i1 %3943, i1 false
  br i1 %.0901, label %true_block1643, label %after_if1639

after_if1639:                                     ; preds = %true_block1643, %true_block1637, %after_if1627
  %.1341305 = phi double [ %3957, %true_block1643 ], [ %.1331304, %true_block1637 ], [ %.1331304, %after_if1627 ]
  %.133 = phi i1 [ true, %true_block1643 ], [ %.132, %true_block1637 ], [ %.132, %after_if1627 ]
  %3944 = icmp ugt i32 %201, 134
  %3945 = xor i1 %.133, true
  %spec.select1960 = select i1 %3944, i1 %3945, i1 false
  br i1 %spec.select1960, label %true_block1649, label %after_if1651

true_block1643:                                   ; preds = %true_block1637
  %getch.i2396 = getelementptr i8, i8* %12, i64 418612680
  %3946 = getelementptr inbounds i8, i8* %getch.i2396, i64 %3932
  %3947 = bitcast i8* %3946 to double*
  %3948 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3947, i32 64)
  %3949 = getelementptr inbounds i8, i8* %getch.i2396, i64 %3938
  %3950 = bitcast i8* %3949 to double*
  %3951 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3950, i32 64)
  %3952 = fsub reassoc ninf nsz double %3951, %3948
  %3953 = fsub reassoc ninf nsz double %3941, %3935
  %3954 = fsub reassoc ninf nsz double %175, %3935
  %3955 = fmul reassoc ninf nsz double %3952, %3954
  %3956 = fdiv reassoc ninf nsz double %3955, %3953
  %3957 = fadd reassoc ninf nsz double %3956, %3948
  br label %after_if1639

true_block1649:                                   ; preds = %after_if1639
  %3958 = add i32 %180, 134
  %3959 = sext i32 %3958 to i64
  %3960 = shl nsw i64 %3959, 3
  %3961 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3960
  %3962 = bitcast i8* %3961 to double*
  %3963 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3962, i32 64)
  %3964 = add i32 %180, 135
  %3965 = sext i32 %3964 to i64
  %3966 = shl nsw i64 %3965, 3
  %3967 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3966
  %3968 = bitcast i8* %3967 to double*
  %3969 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3968, i32 64)
  %3970 = fcmp reassoc ninf nsz oge double %175, %3963
  %3971 = fcmp reassoc ninf nsz ole double %175, %3969
  %.0899 = select i1 %3970, i1 %3971, i1 false
  br i1 %.0899, label %true_block1655, label %after_if1651

after_if1651:                                     ; preds = %true_block1655, %true_block1649, %after_if1639
  %.1351306 = phi double [ %3985, %true_block1655 ], [ %.1341305, %true_block1649 ], [ %.1341305, %after_if1639 ]
  %.134 = phi i1 [ true, %true_block1655 ], [ %.133, %true_block1649 ], [ %.133, %after_if1639 ]
  %3972 = icmp ugt i32 %201, 135
  %3973 = xor i1 %.134, true
  %spec.select1961 = select i1 %3972, i1 %3973, i1 false
  br i1 %spec.select1961, label %true_block1661, label %after_if1663

true_block1655:                                   ; preds = %true_block1649
  %getch.i2395 = getelementptr i8, i8* %12, i64 418612680
  %3974 = getelementptr inbounds i8, i8* %getch.i2395, i64 %3960
  %3975 = bitcast i8* %3974 to double*
  %3976 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3975, i32 64)
  %3977 = getelementptr inbounds i8, i8* %getch.i2395, i64 %3966
  %3978 = bitcast i8* %3977 to double*
  %3979 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3978, i32 64)
  %3980 = fsub reassoc ninf nsz double %3979, %3976
  %3981 = fsub reassoc ninf nsz double %3969, %3963
  %3982 = fsub reassoc ninf nsz double %175, %3963
  %3983 = fmul reassoc ninf nsz double %3980, %3982
  %3984 = fdiv reassoc ninf nsz double %3983, %3981
  %3985 = fadd reassoc ninf nsz double %3984, %3976
  br label %after_if1651

true_block1661:                                   ; preds = %after_if1651
  %3986 = add i32 %180, 135
  %3987 = sext i32 %3986 to i64
  %3988 = shl nsw i64 %3987, 3
  %3989 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3988
  %3990 = bitcast i8* %3989 to double*
  %3991 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %3990, i32 64)
  %3992 = add i32 %180, 136
  %3993 = sext i32 %3992 to i64
  %3994 = shl nsw i64 %3993, 3
  %3995 = getelementptr inbounds i8, i8* %getch.i2533, i64 %3994
  %3996 = bitcast i8* %3995 to double*
  %3997 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %3996, i32 64)
  %3998 = fcmp reassoc ninf nsz oge double %175, %3991
  %3999 = fcmp reassoc ninf nsz ole double %175, %3997
  %.0897 = select i1 %3998, i1 %3999, i1 false
  br i1 %.0897, label %true_block1667, label %after_if1663

after_if1663:                                     ; preds = %true_block1667, %true_block1661, %after_if1651
  %.1361307 = phi double [ %4013, %true_block1667 ], [ %.1351306, %true_block1661 ], [ %.1351306, %after_if1651 ]
  %.135 = phi i1 [ true, %true_block1667 ], [ %.134, %true_block1661 ], [ %.134, %after_if1651 ]
  %4000 = icmp ugt i32 %201, 136
  %4001 = xor i1 %.135, true
  %spec.select1962 = select i1 %4000, i1 %4001, i1 false
  br i1 %spec.select1962, label %true_block1673, label %after_if1675

true_block1667:                                   ; preds = %true_block1661
  %getch.i2394 = getelementptr i8, i8* %12, i64 418612680
  %4002 = getelementptr inbounds i8, i8* %getch.i2394, i64 %3988
  %4003 = bitcast i8* %4002 to double*
  %4004 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4003, i32 64)
  %4005 = getelementptr inbounds i8, i8* %getch.i2394, i64 %3994
  %4006 = bitcast i8* %4005 to double*
  %4007 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4006, i32 64)
  %4008 = fsub reassoc ninf nsz double %4007, %4004
  %4009 = fsub reassoc ninf nsz double %3997, %3991
  %4010 = fsub reassoc ninf nsz double %175, %3991
  %4011 = fmul reassoc ninf nsz double %4008, %4010
  %4012 = fdiv reassoc ninf nsz double %4011, %4009
  %4013 = fadd reassoc ninf nsz double %4012, %4004
  br label %after_if1663

true_block1673:                                   ; preds = %after_if1663
  %4014 = add i32 %180, 136
  %4015 = sext i32 %4014 to i64
  %4016 = shl nsw i64 %4015, 3
  %4017 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4016
  %4018 = bitcast i8* %4017 to double*
  %4019 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4018, i32 64)
  %4020 = add i32 %180, 137
  %4021 = sext i32 %4020 to i64
  %4022 = shl nsw i64 %4021, 3
  %4023 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4022
  %4024 = bitcast i8* %4023 to double*
  %4025 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4024, i32 64)
  %4026 = fcmp reassoc ninf nsz oge double %175, %4019
  %4027 = fcmp reassoc ninf nsz ole double %175, %4025
  %.0895 = select i1 %4026, i1 %4027, i1 false
  br i1 %.0895, label %true_block1679, label %after_if1675

after_if1675:                                     ; preds = %true_block1679, %true_block1673, %after_if1663
  %.1371308 = phi double [ %4041, %true_block1679 ], [ %.1361307, %true_block1673 ], [ %.1361307, %after_if1663 ]
  %.136 = phi i1 [ true, %true_block1679 ], [ %.135, %true_block1673 ], [ %.135, %after_if1663 ]
  %4028 = icmp ugt i32 %201, 137
  %4029 = xor i1 %.136, true
  %spec.select1963 = select i1 %4028, i1 %4029, i1 false
  br i1 %spec.select1963, label %true_block1685, label %after_if1687

true_block1679:                                   ; preds = %true_block1673
  %getch.i2393 = getelementptr i8, i8* %12, i64 418612680
  %4030 = getelementptr inbounds i8, i8* %getch.i2393, i64 %4016
  %4031 = bitcast i8* %4030 to double*
  %4032 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4031, i32 64)
  %4033 = getelementptr inbounds i8, i8* %getch.i2393, i64 %4022
  %4034 = bitcast i8* %4033 to double*
  %4035 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4034, i32 64)
  %4036 = fsub reassoc ninf nsz double %4035, %4032
  %4037 = fsub reassoc ninf nsz double %4025, %4019
  %4038 = fsub reassoc ninf nsz double %175, %4019
  %4039 = fmul reassoc ninf nsz double %4036, %4038
  %4040 = fdiv reassoc ninf nsz double %4039, %4037
  %4041 = fadd reassoc ninf nsz double %4040, %4032
  br label %after_if1675

true_block1685:                                   ; preds = %after_if1675
  %4042 = add i32 %180, 137
  %4043 = sext i32 %4042 to i64
  %4044 = shl nsw i64 %4043, 3
  %4045 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4044
  %4046 = bitcast i8* %4045 to double*
  %4047 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4046, i32 64)
  %4048 = add i32 %180, 138
  %4049 = sext i32 %4048 to i64
  %4050 = shl nsw i64 %4049, 3
  %4051 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4050
  %4052 = bitcast i8* %4051 to double*
  %4053 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4052, i32 64)
  %4054 = fcmp reassoc ninf nsz oge double %175, %4047
  %4055 = fcmp reassoc ninf nsz ole double %175, %4053
  %.0893 = select i1 %4054, i1 %4055, i1 false
  br i1 %.0893, label %true_block1691, label %after_if1687

after_if1687:                                     ; preds = %true_block1691, %true_block1685, %after_if1675
  %.1381309 = phi double [ %4069, %true_block1691 ], [ %.1371308, %true_block1685 ], [ %.1371308, %after_if1675 ]
  %.137 = phi i1 [ true, %true_block1691 ], [ %.136, %true_block1685 ], [ %.136, %after_if1675 ]
  %4056 = icmp ugt i32 %201, 138
  %4057 = xor i1 %.137, true
  %spec.select1964 = select i1 %4056, i1 %4057, i1 false
  br i1 %spec.select1964, label %true_block1697, label %after_if1699

true_block1691:                                   ; preds = %true_block1685
  %getch.i2392 = getelementptr i8, i8* %12, i64 418612680
  %4058 = getelementptr inbounds i8, i8* %getch.i2392, i64 %4044
  %4059 = bitcast i8* %4058 to double*
  %4060 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4059, i32 64)
  %4061 = getelementptr inbounds i8, i8* %getch.i2392, i64 %4050
  %4062 = bitcast i8* %4061 to double*
  %4063 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4062, i32 64)
  %4064 = fsub reassoc ninf nsz double %4063, %4060
  %4065 = fsub reassoc ninf nsz double %4053, %4047
  %4066 = fsub reassoc ninf nsz double %175, %4047
  %4067 = fmul reassoc ninf nsz double %4064, %4066
  %4068 = fdiv reassoc ninf nsz double %4067, %4065
  %4069 = fadd reassoc ninf nsz double %4068, %4060
  br label %after_if1687

true_block1697:                                   ; preds = %after_if1687
  %4070 = add i32 %180, 138
  %4071 = sext i32 %4070 to i64
  %4072 = shl nsw i64 %4071, 3
  %4073 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4072
  %4074 = bitcast i8* %4073 to double*
  %4075 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4074, i32 64)
  %4076 = add i32 %180, 139
  %4077 = sext i32 %4076 to i64
  %4078 = shl nsw i64 %4077, 3
  %4079 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4078
  %4080 = bitcast i8* %4079 to double*
  %4081 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4080, i32 64)
  %4082 = fcmp reassoc ninf nsz oge double %175, %4075
  %4083 = fcmp reassoc ninf nsz ole double %175, %4081
  %.0891 = select i1 %4082, i1 %4083, i1 false
  br i1 %.0891, label %true_block1703, label %after_if1699

after_if1699:                                     ; preds = %true_block1703, %true_block1697, %after_if1687
  %.1391310 = phi double [ %4097, %true_block1703 ], [ %.1381309, %true_block1697 ], [ %.1381309, %after_if1687 ]
  %.138 = phi i1 [ true, %true_block1703 ], [ %.137, %true_block1697 ], [ %.137, %after_if1687 ]
  %4084 = icmp ugt i32 %201, 139
  %4085 = xor i1 %.138, true
  %spec.select1965 = select i1 %4084, i1 %4085, i1 false
  br i1 %spec.select1965, label %true_block1709, label %after_if1711

true_block1703:                                   ; preds = %true_block1697
  %getch.i2391 = getelementptr i8, i8* %12, i64 418612680
  %4086 = getelementptr inbounds i8, i8* %getch.i2391, i64 %4072
  %4087 = bitcast i8* %4086 to double*
  %4088 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4087, i32 64)
  %4089 = getelementptr inbounds i8, i8* %getch.i2391, i64 %4078
  %4090 = bitcast i8* %4089 to double*
  %4091 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4090, i32 64)
  %4092 = fsub reassoc ninf nsz double %4091, %4088
  %4093 = fsub reassoc ninf nsz double %4081, %4075
  %4094 = fsub reassoc ninf nsz double %175, %4075
  %4095 = fmul reassoc ninf nsz double %4092, %4094
  %4096 = fdiv reassoc ninf nsz double %4095, %4093
  %4097 = fadd reassoc ninf nsz double %4096, %4088
  br label %after_if1699

true_block1709:                                   ; preds = %after_if1699
  %4098 = add i32 %180, 139
  %4099 = sext i32 %4098 to i64
  %4100 = shl nsw i64 %4099, 3
  %4101 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4100
  %4102 = bitcast i8* %4101 to double*
  %4103 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4102, i32 64)
  %4104 = add i32 %180, 140
  %4105 = sext i32 %4104 to i64
  %4106 = shl nsw i64 %4105, 3
  %4107 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4106
  %4108 = bitcast i8* %4107 to double*
  %4109 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4108, i32 64)
  %4110 = fcmp reassoc ninf nsz oge double %175, %4103
  %4111 = fcmp reassoc ninf nsz ole double %175, %4109
  %.0889 = select i1 %4110, i1 %4111, i1 false
  br i1 %.0889, label %true_block1715, label %after_if1711

after_if1711:                                     ; preds = %true_block1715, %true_block1709, %after_if1699
  %.1401311 = phi double [ %4125, %true_block1715 ], [ %.1391310, %true_block1709 ], [ %.1391310, %after_if1699 ]
  %.139 = phi i1 [ true, %true_block1715 ], [ %.138, %true_block1709 ], [ %.138, %after_if1699 ]
  %4112 = icmp ugt i32 %201, 140
  %4113 = xor i1 %.139, true
  %spec.select1966 = select i1 %4112, i1 %4113, i1 false
  br i1 %spec.select1966, label %true_block1721, label %after_if1723

true_block1715:                                   ; preds = %true_block1709
  %getch.i2390 = getelementptr i8, i8* %12, i64 418612680
  %4114 = getelementptr inbounds i8, i8* %getch.i2390, i64 %4100
  %4115 = bitcast i8* %4114 to double*
  %4116 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4115, i32 64)
  %4117 = getelementptr inbounds i8, i8* %getch.i2390, i64 %4106
  %4118 = bitcast i8* %4117 to double*
  %4119 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4118, i32 64)
  %4120 = fsub reassoc ninf nsz double %4119, %4116
  %4121 = fsub reassoc ninf nsz double %4109, %4103
  %4122 = fsub reassoc ninf nsz double %175, %4103
  %4123 = fmul reassoc ninf nsz double %4120, %4122
  %4124 = fdiv reassoc ninf nsz double %4123, %4121
  %4125 = fadd reassoc ninf nsz double %4124, %4116
  br label %after_if1711

true_block1721:                                   ; preds = %after_if1711
  %4126 = add i32 %180, 140
  %4127 = sext i32 %4126 to i64
  %4128 = shl nsw i64 %4127, 3
  %4129 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4128
  %4130 = bitcast i8* %4129 to double*
  %4131 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4130, i32 64)
  %4132 = add i32 %180, 141
  %4133 = sext i32 %4132 to i64
  %4134 = shl nsw i64 %4133, 3
  %4135 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4134
  %4136 = bitcast i8* %4135 to double*
  %4137 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4136, i32 64)
  %4138 = fcmp reassoc ninf nsz oge double %175, %4131
  %4139 = fcmp reassoc ninf nsz ole double %175, %4137
  %.0887 = select i1 %4138, i1 %4139, i1 false
  br i1 %.0887, label %true_block1727, label %after_if1723

after_if1723:                                     ; preds = %true_block1727, %true_block1721, %after_if1711
  %.1411312 = phi double [ %4153, %true_block1727 ], [ %.1401311, %true_block1721 ], [ %.1401311, %after_if1711 ]
  %.140 = phi i1 [ true, %true_block1727 ], [ %.139, %true_block1721 ], [ %.139, %after_if1711 ]
  %4140 = icmp ugt i32 %201, 141
  %4141 = xor i1 %.140, true
  %spec.select1967 = select i1 %4140, i1 %4141, i1 false
  br i1 %spec.select1967, label %true_block1733, label %after_if1735

true_block1727:                                   ; preds = %true_block1721
  %getch.i2389 = getelementptr i8, i8* %12, i64 418612680
  %4142 = getelementptr inbounds i8, i8* %getch.i2389, i64 %4128
  %4143 = bitcast i8* %4142 to double*
  %4144 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4143, i32 64)
  %4145 = getelementptr inbounds i8, i8* %getch.i2389, i64 %4134
  %4146 = bitcast i8* %4145 to double*
  %4147 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4146, i32 64)
  %4148 = fsub reassoc ninf nsz double %4147, %4144
  %4149 = fsub reassoc ninf nsz double %4137, %4131
  %4150 = fsub reassoc ninf nsz double %175, %4131
  %4151 = fmul reassoc ninf nsz double %4148, %4150
  %4152 = fdiv reassoc ninf nsz double %4151, %4149
  %4153 = fadd reassoc ninf nsz double %4152, %4144
  br label %after_if1723

true_block1733:                                   ; preds = %after_if1723
  %4154 = add i32 %180, 141
  %4155 = sext i32 %4154 to i64
  %4156 = shl nsw i64 %4155, 3
  %4157 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4156
  %4158 = bitcast i8* %4157 to double*
  %4159 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4158, i32 64)
  %4160 = add i32 %180, 142
  %4161 = sext i32 %4160 to i64
  %4162 = shl nsw i64 %4161, 3
  %4163 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4162
  %4164 = bitcast i8* %4163 to double*
  %4165 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4164, i32 64)
  %4166 = fcmp reassoc ninf nsz oge double %175, %4159
  %4167 = fcmp reassoc ninf nsz ole double %175, %4165
  %.0885 = select i1 %4166, i1 %4167, i1 false
  br i1 %.0885, label %true_block1739, label %after_if1735

after_if1735:                                     ; preds = %true_block1739, %true_block1733, %after_if1723
  %.1421313 = phi double [ %4181, %true_block1739 ], [ %.1411312, %true_block1733 ], [ %.1411312, %after_if1723 ]
  %.141 = phi i1 [ true, %true_block1739 ], [ %.140, %true_block1733 ], [ %.140, %after_if1723 ]
  %4168 = icmp ugt i32 %201, 142
  %4169 = xor i1 %.141, true
  %spec.select1968 = select i1 %4168, i1 %4169, i1 false
  br i1 %spec.select1968, label %true_block1745, label %after_if1747

true_block1739:                                   ; preds = %true_block1733
  %getch.i2388 = getelementptr i8, i8* %12, i64 418612680
  %4170 = getelementptr inbounds i8, i8* %getch.i2388, i64 %4156
  %4171 = bitcast i8* %4170 to double*
  %4172 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4171, i32 64)
  %4173 = getelementptr inbounds i8, i8* %getch.i2388, i64 %4162
  %4174 = bitcast i8* %4173 to double*
  %4175 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4174, i32 64)
  %4176 = fsub reassoc ninf nsz double %4175, %4172
  %4177 = fsub reassoc ninf nsz double %4165, %4159
  %4178 = fsub reassoc ninf nsz double %175, %4159
  %4179 = fmul reassoc ninf nsz double %4176, %4178
  %4180 = fdiv reassoc ninf nsz double %4179, %4177
  %4181 = fadd reassoc ninf nsz double %4180, %4172
  br label %after_if1735

true_block1745:                                   ; preds = %after_if1735
  %4182 = add i32 %180, 142
  %4183 = sext i32 %4182 to i64
  %4184 = shl nsw i64 %4183, 3
  %4185 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4184
  %4186 = bitcast i8* %4185 to double*
  %4187 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4186, i32 64)
  %4188 = add i32 %180, 143
  %4189 = sext i32 %4188 to i64
  %4190 = shl nsw i64 %4189, 3
  %4191 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4190
  %4192 = bitcast i8* %4191 to double*
  %4193 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4192, i32 64)
  %4194 = fcmp reassoc ninf nsz oge double %175, %4187
  %4195 = fcmp reassoc ninf nsz ole double %175, %4193
  %.0883 = select i1 %4194, i1 %4195, i1 false
  br i1 %.0883, label %true_block1751, label %after_if1747

after_if1747:                                     ; preds = %true_block1751, %true_block1745, %after_if1735
  %.1431314 = phi double [ %4209, %true_block1751 ], [ %.1421313, %true_block1745 ], [ %.1421313, %after_if1735 ]
  %.142 = phi i1 [ true, %true_block1751 ], [ %.141, %true_block1745 ], [ %.141, %after_if1735 ]
  %4196 = icmp ugt i32 %201, 143
  %4197 = xor i1 %.142, true
  %spec.select1969 = select i1 %4196, i1 %4197, i1 false
  br i1 %spec.select1969, label %true_block1757, label %after_if1759

true_block1751:                                   ; preds = %true_block1745
  %getch.i2387 = getelementptr i8, i8* %12, i64 418612680
  %4198 = getelementptr inbounds i8, i8* %getch.i2387, i64 %4184
  %4199 = bitcast i8* %4198 to double*
  %4200 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4199, i32 64)
  %4201 = getelementptr inbounds i8, i8* %getch.i2387, i64 %4190
  %4202 = bitcast i8* %4201 to double*
  %4203 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4202, i32 64)
  %4204 = fsub reassoc ninf nsz double %4203, %4200
  %4205 = fsub reassoc ninf nsz double %4193, %4187
  %4206 = fsub reassoc ninf nsz double %175, %4187
  %4207 = fmul reassoc ninf nsz double %4204, %4206
  %4208 = fdiv reassoc ninf nsz double %4207, %4205
  %4209 = fadd reassoc ninf nsz double %4208, %4200
  br label %after_if1747

true_block1757:                                   ; preds = %after_if1747
  %4210 = add i32 %180, 143
  %4211 = sext i32 %4210 to i64
  %4212 = shl nsw i64 %4211, 3
  %4213 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4212
  %4214 = bitcast i8* %4213 to double*
  %4215 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4214, i32 64)
  %4216 = add i32 %180, 144
  %4217 = sext i32 %4216 to i64
  %4218 = shl nsw i64 %4217, 3
  %4219 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4218
  %4220 = bitcast i8* %4219 to double*
  %4221 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4220, i32 64)
  %4222 = fcmp reassoc ninf nsz oge double %175, %4215
  %4223 = fcmp reassoc ninf nsz ole double %175, %4221
  %.0881 = select i1 %4222, i1 %4223, i1 false
  br i1 %.0881, label %true_block1763, label %after_if1759

after_if1759:                                     ; preds = %true_block1763, %true_block1757, %after_if1747
  %.1441315 = phi double [ %4237, %true_block1763 ], [ %.1431314, %true_block1757 ], [ %.1431314, %after_if1747 ]
  %.143 = phi i1 [ true, %true_block1763 ], [ %.142, %true_block1757 ], [ %.142, %after_if1747 ]
  %4224 = icmp ugt i32 %201, 144
  %4225 = xor i1 %.143, true
  %spec.select1970 = select i1 %4224, i1 %4225, i1 false
  br i1 %spec.select1970, label %true_block1769, label %after_if1771

true_block1763:                                   ; preds = %true_block1757
  %getch.i2386 = getelementptr i8, i8* %12, i64 418612680
  %4226 = getelementptr inbounds i8, i8* %getch.i2386, i64 %4212
  %4227 = bitcast i8* %4226 to double*
  %4228 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4227, i32 64)
  %4229 = getelementptr inbounds i8, i8* %getch.i2386, i64 %4218
  %4230 = bitcast i8* %4229 to double*
  %4231 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4230, i32 64)
  %4232 = fsub reassoc ninf nsz double %4231, %4228
  %4233 = fsub reassoc ninf nsz double %4221, %4215
  %4234 = fsub reassoc ninf nsz double %175, %4215
  %4235 = fmul reassoc ninf nsz double %4232, %4234
  %4236 = fdiv reassoc ninf nsz double %4235, %4233
  %4237 = fadd reassoc ninf nsz double %4236, %4228
  br label %after_if1759

true_block1769:                                   ; preds = %after_if1759
  %4238 = add i32 %180, 144
  %4239 = sext i32 %4238 to i64
  %4240 = shl nsw i64 %4239, 3
  %4241 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4240
  %4242 = bitcast i8* %4241 to double*
  %4243 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4242, i32 64)
  %4244 = add i32 %180, 145
  %4245 = sext i32 %4244 to i64
  %4246 = shl nsw i64 %4245, 3
  %4247 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4246
  %4248 = bitcast i8* %4247 to double*
  %4249 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4248, i32 64)
  %4250 = fcmp reassoc ninf nsz oge double %175, %4243
  %4251 = fcmp reassoc ninf nsz ole double %175, %4249
  %.0879 = select i1 %4250, i1 %4251, i1 false
  br i1 %.0879, label %true_block1775, label %after_if1771

after_if1771:                                     ; preds = %true_block1775, %true_block1769, %after_if1759
  %.1451316 = phi double [ %4265, %true_block1775 ], [ %.1441315, %true_block1769 ], [ %.1441315, %after_if1759 ]
  %.144 = phi i1 [ true, %true_block1775 ], [ %.143, %true_block1769 ], [ %.143, %after_if1759 ]
  %4252 = icmp ugt i32 %201, 145
  %4253 = xor i1 %.144, true
  %spec.select1971 = select i1 %4252, i1 %4253, i1 false
  br i1 %spec.select1971, label %true_block1781, label %after_if1783

true_block1775:                                   ; preds = %true_block1769
  %getch.i2385 = getelementptr i8, i8* %12, i64 418612680
  %4254 = getelementptr inbounds i8, i8* %getch.i2385, i64 %4240
  %4255 = bitcast i8* %4254 to double*
  %4256 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4255, i32 64)
  %4257 = getelementptr inbounds i8, i8* %getch.i2385, i64 %4246
  %4258 = bitcast i8* %4257 to double*
  %4259 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4258, i32 64)
  %4260 = fsub reassoc ninf nsz double %4259, %4256
  %4261 = fsub reassoc ninf nsz double %4249, %4243
  %4262 = fsub reassoc ninf nsz double %175, %4243
  %4263 = fmul reassoc ninf nsz double %4260, %4262
  %4264 = fdiv reassoc ninf nsz double %4263, %4261
  %4265 = fadd reassoc ninf nsz double %4264, %4256
  br label %after_if1771

true_block1781:                                   ; preds = %after_if1771
  %4266 = add i32 %180, 145
  %4267 = sext i32 %4266 to i64
  %4268 = shl nsw i64 %4267, 3
  %4269 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4268
  %4270 = bitcast i8* %4269 to double*
  %4271 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4270, i32 64)
  %4272 = add i32 %180, 146
  %4273 = sext i32 %4272 to i64
  %4274 = shl nsw i64 %4273, 3
  %4275 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4274
  %4276 = bitcast i8* %4275 to double*
  %4277 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4276, i32 64)
  %4278 = fcmp reassoc ninf nsz oge double %175, %4271
  %4279 = fcmp reassoc ninf nsz ole double %175, %4277
  %.0877 = select i1 %4278, i1 %4279, i1 false
  br i1 %.0877, label %true_block1787, label %after_if1783

after_if1783:                                     ; preds = %true_block1787, %true_block1781, %after_if1771
  %.1461317 = phi double [ %4293, %true_block1787 ], [ %.1451316, %true_block1781 ], [ %.1451316, %after_if1771 ]
  %.145 = phi i1 [ true, %true_block1787 ], [ %.144, %true_block1781 ], [ %.144, %after_if1771 ]
  %4280 = icmp ugt i32 %201, 146
  %4281 = xor i1 %.145, true
  %spec.select1972 = select i1 %4280, i1 %4281, i1 false
  br i1 %spec.select1972, label %true_block1793, label %after_if1795

true_block1787:                                   ; preds = %true_block1781
  %getch.i2384 = getelementptr i8, i8* %12, i64 418612680
  %4282 = getelementptr inbounds i8, i8* %getch.i2384, i64 %4268
  %4283 = bitcast i8* %4282 to double*
  %4284 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4283, i32 64)
  %4285 = getelementptr inbounds i8, i8* %getch.i2384, i64 %4274
  %4286 = bitcast i8* %4285 to double*
  %4287 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4286, i32 64)
  %4288 = fsub reassoc ninf nsz double %4287, %4284
  %4289 = fsub reassoc ninf nsz double %4277, %4271
  %4290 = fsub reassoc ninf nsz double %175, %4271
  %4291 = fmul reassoc ninf nsz double %4288, %4290
  %4292 = fdiv reassoc ninf nsz double %4291, %4289
  %4293 = fadd reassoc ninf nsz double %4292, %4284
  br label %after_if1783

true_block1793:                                   ; preds = %after_if1783
  %4294 = add i32 %180, 146
  %4295 = sext i32 %4294 to i64
  %4296 = shl nsw i64 %4295, 3
  %4297 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4296
  %4298 = bitcast i8* %4297 to double*
  %4299 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4298, i32 64)
  %4300 = add i32 %180, 147
  %4301 = sext i32 %4300 to i64
  %4302 = shl nsw i64 %4301, 3
  %4303 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4302
  %4304 = bitcast i8* %4303 to double*
  %4305 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4304, i32 64)
  %4306 = fcmp reassoc ninf nsz oge double %175, %4299
  %4307 = fcmp reassoc ninf nsz ole double %175, %4305
  %.0875 = select i1 %4306, i1 %4307, i1 false
  br i1 %.0875, label %true_block1799, label %after_if1795

after_if1795:                                     ; preds = %true_block1799, %true_block1793, %after_if1783
  %.1471318 = phi double [ %4321, %true_block1799 ], [ %.1461317, %true_block1793 ], [ %.1461317, %after_if1783 ]
  %.146 = phi i1 [ true, %true_block1799 ], [ %.145, %true_block1793 ], [ %.145, %after_if1783 ]
  %4308 = icmp ugt i32 %201, 147
  %4309 = xor i1 %.146, true
  %spec.select1973 = select i1 %4308, i1 %4309, i1 false
  br i1 %spec.select1973, label %true_block1805, label %after_if1807

true_block1799:                                   ; preds = %true_block1793
  %getch.i2383 = getelementptr i8, i8* %12, i64 418612680
  %4310 = getelementptr inbounds i8, i8* %getch.i2383, i64 %4296
  %4311 = bitcast i8* %4310 to double*
  %4312 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4311, i32 64)
  %4313 = getelementptr inbounds i8, i8* %getch.i2383, i64 %4302
  %4314 = bitcast i8* %4313 to double*
  %4315 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4314, i32 64)
  %4316 = fsub reassoc ninf nsz double %4315, %4312
  %4317 = fsub reassoc ninf nsz double %4305, %4299
  %4318 = fsub reassoc ninf nsz double %175, %4299
  %4319 = fmul reassoc ninf nsz double %4316, %4318
  %4320 = fdiv reassoc ninf nsz double %4319, %4317
  %4321 = fadd reassoc ninf nsz double %4320, %4312
  br label %after_if1795

true_block1805:                                   ; preds = %after_if1795
  %4322 = add i32 %180, 147
  %4323 = sext i32 %4322 to i64
  %4324 = shl nsw i64 %4323, 3
  %4325 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4324
  %4326 = bitcast i8* %4325 to double*
  %4327 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4326, i32 64)
  %4328 = add i32 %180, 148
  %4329 = sext i32 %4328 to i64
  %4330 = shl nsw i64 %4329, 3
  %4331 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4330
  %4332 = bitcast i8* %4331 to double*
  %4333 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4332, i32 64)
  %4334 = fcmp reassoc ninf nsz oge double %175, %4327
  %4335 = fcmp reassoc ninf nsz ole double %175, %4333
  %.0873 = select i1 %4334, i1 %4335, i1 false
  br i1 %.0873, label %true_block1811, label %after_if1807

after_if1807:                                     ; preds = %true_block1811, %true_block1805, %after_if1795
  %.1481319 = phi double [ %4349, %true_block1811 ], [ %.1471318, %true_block1805 ], [ %.1471318, %after_if1795 ]
  %.147 = phi i1 [ true, %true_block1811 ], [ %.146, %true_block1805 ], [ %.146, %after_if1795 ]
  %4336 = icmp ugt i32 %201, 148
  %4337 = xor i1 %.147, true
  %spec.select1974 = select i1 %4336, i1 %4337, i1 false
  br i1 %spec.select1974, label %true_block1817, label %after_if1819

true_block1811:                                   ; preds = %true_block1805
  %getch.i2382 = getelementptr i8, i8* %12, i64 418612680
  %4338 = getelementptr inbounds i8, i8* %getch.i2382, i64 %4324
  %4339 = bitcast i8* %4338 to double*
  %4340 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4339, i32 64)
  %4341 = getelementptr inbounds i8, i8* %getch.i2382, i64 %4330
  %4342 = bitcast i8* %4341 to double*
  %4343 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4342, i32 64)
  %4344 = fsub reassoc ninf nsz double %4343, %4340
  %4345 = fsub reassoc ninf nsz double %4333, %4327
  %4346 = fsub reassoc ninf nsz double %175, %4327
  %4347 = fmul reassoc ninf nsz double %4344, %4346
  %4348 = fdiv reassoc ninf nsz double %4347, %4345
  %4349 = fadd reassoc ninf nsz double %4348, %4340
  br label %after_if1807

true_block1817:                                   ; preds = %after_if1807
  %4350 = add i32 %180, 148
  %4351 = sext i32 %4350 to i64
  %4352 = shl nsw i64 %4351, 3
  %4353 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4352
  %4354 = bitcast i8* %4353 to double*
  %4355 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4354, i32 64)
  %4356 = add i32 %180, 149
  %4357 = sext i32 %4356 to i64
  %4358 = shl nsw i64 %4357, 3
  %4359 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4358
  %4360 = bitcast i8* %4359 to double*
  %4361 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4360, i32 64)
  %4362 = fcmp reassoc ninf nsz oge double %175, %4355
  %4363 = fcmp reassoc ninf nsz ole double %175, %4361
  %.0871 = select i1 %4362, i1 %4363, i1 false
  br i1 %.0871, label %true_block1823, label %after_if1819

after_if1819:                                     ; preds = %true_block1823, %true_block1817, %after_if1807
  %.1491320 = phi double [ %4377, %true_block1823 ], [ %.1481319, %true_block1817 ], [ %.1481319, %after_if1807 ]
  %.148 = phi i1 [ true, %true_block1823 ], [ %.147, %true_block1817 ], [ %.147, %after_if1807 ]
  %4364 = icmp ugt i32 %201, 149
  %4365 = xor i1 %.148, true
  %spec.select1975 = select i1 %4364, i1 %4365, i1 false
  br i1 %spec.select1975, label %true_block1829, label %after_if1831

true_block1823:                                   ; preds = %true_block1817
  %getch.i2381 = getelementptr i8, i8* %12, i64 418612680
  %4366 = getelementptr inbounds i8, i8* %getch.i2381, i64 %4352
  %4367 = bitcast i8* %4366 to double*
  %4368 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4367, i32 64)
  %4369 = getelementptr inbounds i8, i8* %getch.i2381, i64 %4358
  %4370 = bitcast i8* %4369 to double*
  %4371 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4370, i32 64)
  %4372 = fsub reassoc ninf nsz double %4371, %4368
  %4373 = fsub reassoc ninf nsz double %4361, %4355
  %4374 = fsub reassoc ninf nsz double %175, %4355
  %4375 = fmul reassoc ninf nsz double %4372, %4374
  %4376 = fdiv reassoc ninf nsz double %4375, %4373
  %4377 = fadd reassoc ninf nsz double %4376, %4368
  br label %after_if1819

true_block1829:                                   ; preds = %after_if1819
  %4378 = add i32 %180, 149
  %4379 = sext i32 %4378 to i64
  %4380 = shl nsw i64 %4379, 3
  %4381 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4380
  %4382 = bitcast i8* %4381 to double*
  %4383 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4382, i32 64)
  %4384 = add i32 %180, 150
  %4385 = sext i32 %4384 to i64
  %4386 = shl nsw i64 %4385, 3
  %4387 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4386
  %4388 = bitcast i8* %4387 to double*
  %4389 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4388, i32 64)
  %4390 = fcmp reassoc ninf nsz oge double %175, %4383
  %4391 = fcmp reassoc ninf nsz ole double %175, %4389
  %.0869 = select i1 %4390, i1 %4391, i1 false
  br i1 %.0869, label %true_block1835, label %after_if1831

after_if1831:                                     ; preds = %true_block1835, %true_block1829, %after_if1819
  %.1501321 = phi double [ %4405, %true_block1835 ], [ %.1491320, %true_block1829 ], [ %.1491320, %after_if1819 ]
  %.149 = phi i1 [ true, %true_block1835 ], [ %.148, %true_block1829 ], [ %.148, %after_if1819 ]
  %4392 = icmp ugt i32 %201, 150
  %4393 = xor i1 %.149, true
  %spec.select1976 = select i1 %4392, i1 %4393, i1 false
  br i1 %spec.select1976, label %true_block1841, label %after_if1843

true_block1835:                                   ; preds = %true_block1829
  %getch.i2380 = getelementptr i8, i8* %12, i64 418612680
  %4394 = getelementptr inbounds i8, i8* %getch.i2380, i64 %4380
  %4395 = bitcast i8* %4394 to double*
  %4396 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4395, i32 64)
  %4397 = getelementptr inbounds i8, i8* %getch.i2380, i64 %4386
  %4398 = bitcast i8* %4397 to double*
  %4399 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4398, i32 64)
  %4400 = fsub reassoc ninf nsz double %4399, %4396
  %4401 = fsub reassoc ninf nsz double %4389, %4383
  %4402 = fsub reassoc ninf nsz double %175, %4383
  %4403 = fmul reassoc ninf nsz double %4400, %4402
  %4404 = fdiv reassoc ninf nsz double %4403, %4401
  %4405 = fadd reassoc ninf nsz double %4404, %4396
  br label %after_if1831

true_block1841:                                   ; preds = %after_if1831
  %4406 = add i32 %180, 150
  %4407 = sext i32 %4406 to i64
  %4408 = shl nsw i64 %4407, 3
  %4409 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4408
  %4410 = bitcast i8* %4409 to double*
  %4411 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4410, i32 64)
  %4412 = add i32 %180, 151
  %4413 = sext i32 %4412 to i64
  %4414 = shl nsw i64 %4413, 3
  %4415 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4414
  %4416 = bitcast i8* %4415 to double*
  %4417 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4416, i32 64)
  %4418 = fcmp reassoc ninf nsz oge double %175, %4411
  %4419 = fcmp reassoc ninf nsz ole double %175, %4417
  %.0867 = select i1 %4418, i1 %4419, i1 false
  br i1 %.0867, label %true_block1847, label %after_if1843

after_if1843:                                     ; preds = %true_block1847, %true_block1841, %after_if1831
  %.1511322 = phi double [ %4433, %true_block1847 ], [ %.1501321, %true_block1841 ], [ %.1501321, %after_if1831 ]
  %.150 = phi i1 [ true, %true_block1847 ], [ %.149, %true_block1841 ], [ %.149, %after_if1831 ]
  %4420 = icmp ugt i32 %201, 151
  %4421 = xor i1 %.150, true
  %spec.select1977 = select i1 %4420, i1 %4421, i1 false
  br i1 %spec.select1977, label %true_block1853, label %after_if1855

true_block1847:                                   ; preds = %true_block1841
  %getch.i2379 = getelementptr i8, i8* %12, i64 418612680
  %4422 = getelementptr inbounds i8, i8* %getch.i2379, i64 %4408
  %4423 = bitcast i8* %4422 to double*
  %4424 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4423, i32 64)
  %4425 = getelementptr inbounds i8, i8* %getch.i2379, i64 %4414
  %4426 = bitcast i8* %4425 to double*
  %4427 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4426, i32 64)
  %4428 = fsub reassoc ninf nsz double %4427, %4424
  %4429 = fsub reassoc ninf nsz double %4417, %4411
  %4430 = fsub reassoc ninf nsz double %175, %4411
  %4431 = fmul reassoc ninf nsz double %4428, %4430
  %4432 = fdiv reassoc ninf nsz double %4431, %4429
  %4433 = fadd reassoc ninf nsz double %4432, %4424
  br label %after_if1843

true_block1853:                                   ; preds = %after_if1843
  %4434 = add i32 %180, 151
  %4435 = sext i32 %4434 to i64
  %4436 = shl nsw i64 %4435, 3
  %4437 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4436
  %4438 = bitcast i8* %4437 to double*
  %4439 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4438, i32 64)
  %4440 = add i32 %180, 152
  %4441 = sext i32 %4440 to i64
  %4442 = shl nsw i64 %4441, 3
  %4443 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4442
  %4444 = bitcast i8* %4443 to double*
  %4445 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4444, i32 64)
  %4446 = fcmp reassoc ninf nsz oge double %175, %4439
  %4447 = fcmp reassoc ninf nsz ole double %175, %4445
  %.0865 = select i1 %4446, i1 %4447, i1 false
  br i1 %.0865, label %true_block1859, label %after_if1855

after_if1855:                                     ; preds = %true_block1859, %true_block1853, %after_if1843
  %.1521323 = phi double [ %4461, %true_block1859 ], [ %.1511322, %true_block1853 ], [ %.1511322, %after_if1843 ]
  %.151 = phi i1 [ true, %true_block1859 ], [ %.150, %true_block1853 ], [ %.150, %after_if1843 ]
  %4448 = icmp ugt i32 %201, 152
  %4449 = xor i1 %.151, true
  %spec.select1978 = select i1 %4448, i1 %4449, i1 false
  br i1 %spec.select1978, label %true_block1865, label %after_if1867

true_block1859:                                   ; preds = %true_block1853
  %getch.i2378 = getelementptr i8, i8* %12, i64 418612680
  %4450 = getelementptr inbounds i8, i8* %getch.i2378, i64 %4436
  %4451 = bitcast i8* %4450 to double*
  %4452 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4451, i32 64)
  %4453 = getelementptr inbounds i8, i8* %getch.i2378, i64 %4442
  %4454 = bitcast i8* %4453 to double*
  %4455 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4454, i32 64)
  %4456 = fsub reassoc ninf nsz double %4455, %4452
  %4457 = fsub reassoc ninf nsz double %4445, %4439
  %4458 = fsub reassoc ninf nsz double %175, %4439
  %4459 = fmul reassoc ninf nsz double %4456, %4458
  %4460 = fdiv reassoc ninf nsz double %4459, %4457
  %4461 = fadd reassoc ninf nsz double %4460, %4452
  br label %after_if1855

true_block1865:                                   ; preds = %after_if1855
  %4462 = add i32 %180, 152
  %4463 = sext i32 %4462 to i64
  %4464 = shl nsw i64 %4463, 3
  %4465 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4464
  %4466 = bitcast i8* %4465 to double*
  %4467 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4466, i32 64)
  %4468 = add i32 %180, 153
  %4469 = sext i32 %4468 to i64
  %4470 = shl nsw i64 %4469, 3
  %4471 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4470
  %4472 = bitcast i8* %4471 to double*
  %4473 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4472, i32 64)
  %4474 = fcmp reassoc ninf nsz oge double %175, %4467
  %4475 = fcmp reassoc ninf nsz ole double %175, %4473
  %.0863 = select i1 %4474, i1 %4475, i1 false
  br i1 %.0863, label %true_block1871, label %after_if1867

after_if1867:                                     ; preds = %true_block1871, %true_block1865, %after_if1855
  %.1531324 = phi double [ %4489, %true_block1871 ], [ %.1521323, %true_block1865 ], [ %.1521323, %after_if1855 ]
  %.152 = phi i1 [ true, %true_block1871 ], [ %.151, %true_block1865 ], [ %.151, %after_if1855 ]
  %4476 = icmp ugt i32 %201, 153
  %4477 = xor i1 %.152, true
  %spec.select1979 = select i1 %4476, i1 %4477, i1 false
  br i1 %spec.select1979, label %true_block1877, label %after_if1879

true_block1871:                                   ; preds = %true_block1865
  %getch.i2377 = getelementptr i8, i8* %12, i64 418612680
  %4478 = getelementptr inbounds i8, i8* %getch.i2377, i64 %4464
  %4479 = bitcast i8* %4478 to double*
  %4480 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4479, i32 64)
  %4481 = getelementptr inbounds i8, i8* %getch.i2377, i64 %4470
  %4482 = bitcast i8* %4481 to double*
  %4483 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4482, i32 64)
  %4484 = fsub reassoc ninf nsz double %4483, %4480
  %4485 = fsub reassoc ninf nsz double %4473, %4467
  %4486 = fsub reassoc ninf nsz double %175, %4467
  %4487 = fmul reassoc ninf nsz double %4484, %4486
  %4488 = fdiv reassoc ninf nsz double %4487, %4485
  %4489 = fadd reassoc ninf nsz double %4488, %4480
  br label %after_if1867

true_block1877:                                   ; preds = %after_if1867
  %4490 = add i32 %180, 153
  %4491 = sext i32 %4490 to i64
  %4492 = shl nsw i64 %4491, 3
  %4493 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4492
  %4494 = bitcast i8* %4493 to double*
  %4495 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4494, i32 64)
  %4496 = add i32 %180, 154
  %4497 = sext i32 %4496 to i64
  %4498 = shl nsw i64 %4497, 3
  %4499 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4498
  %4500 = bitcast i8* %4499 to double*
  %4501 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4500, i32 64)
  %4502 = fcmp reassoc ninf nsz oge double %175, %4495
  %4503 = fcmp reassoc ninf nsz ole double %175, %4501
  %.0861 = select i1 %4502, i1 %4503, i1 false
  br i1 %.0861, label %true_block1883, label %after_if1879

after_if1879:                                     ; preds = %true_block1883, %true_block1877, %after_if1867
  %.1541325 = phi double [ %4517, %true_block1883 ], [ %.1531324, %true_block1877 ], [ %.1531324, %after_if1867 ]
  %.153 = phi i1 [ true, %true_block1883 ], [ %.152, %true_block1877 ], [ %.152, %after_if1867 ]
  %4504 = icmp ugt i32 %201, 154
  %4505 = xor i1 %.153, true
  %spec.select1980 = select i1 %4504, i1 %4505, i1 false
  br i1 %spec.select1980, label %true_block1889, label %after_if1891

true_block1883:                                   ; preds = %true_block1877
  %getch.i2376 = getelementptr i8, i8* %12, i64 418612680
  %4506 = getelementptr inbounds i8, i8* %getch.i2376, i64 %4492
  %4507 = bitcast i8* %4506 to double*
  %4508 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4507, i32 64)
  %4509 = getelementptr inbounds i8, i8* %getch.i2376, i64 %4498
  %4510 = bitcast i8* %4509 to double*
  %4511 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4510, i32 64)
  %4512 = fsub reassoc ninf nsz double %4511, %4508
  %4513 = fsub reassoc ninf nsz double %4501, %4495
  %4514 = fsub reassoc ninf nsz double %175, %4495
  %4515 = fmul reassoc ninf nsz double %4512, %4514
  %4516 = fdiv reassoc ninf nsz double %4515, %4513
  %4517 = fadd reassoc ninf nsz double %4516, %4508
  br label %after_if1879

true_block1889:                                   ; preds = %after_if1879
  %4518 = add i32 %180, 154
  %4519 = sext i32 %4518 to i64
  %4520 = shl nsw i64 %4519, 3
  %4521 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4520
  %4522 = bitcast i8* %4521 to double*
  %4523 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4522, i32 64)
  %4524 = add i32 %180, 155
  %4525 = sext i32 %4524 to i64
  %4526 = shl nsw i64 %4525, 3
  %4527 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4526
  %4528 = bitcast i8* %4527 to double*
  %4529 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4528, i32 64)
  %4530 = fcmp reassoc ninf nsz oge double %175, %4523
  %4531 = fcmp reassoc ninf nsz ole double %175, %4529
  %.0859 = select i1 %4530, i1 %4531, i1 false
  br i1 %.0859, label %true_block1895, label %after_if1891

after_if1891:                                     ; preds = %true_block1895, %true_block1889, %after_if1879
  %.1551326 = phi double [ %4545, %true_block1895 ], [ %.1541325, %true_block1889 ], [ %.1541325, %after_if1879 ]
  %.154 = phi i1 [ true, %true_block1895 ], [ %.153, %true_block1889 ], [ %.153, %after_if1879 ]
  %4532 = icmp ugt i32 %201, 155
  %4533 = xor i1 %.154, true
  %spec.select1981 = select i1 %4532, i1 %4533, i1 false
  br i1 %spec.select1981, label %true_block1901, label %after_if1903

true_block1895:                                   ; preds = %true_block1889
  %getch.i2375 = getelementptr i8, i8* %12, i64 418612680
  %4534 = getelementptr inbounds i8, i8* %getch.i2375, i64 %4520
  %4535 = bitcast i8* %4534 to double*
  %4536 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4535, i32 64)
  %4537 = getelementptr inbounds i8, i8* %getch.i2375, i64 %4526
  %4538 = bitcast i8* %4537 to double*
  %4539 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4538, i32 64)
  %4540 = fsub reassoc ninf nsz double %4539, %4536
  %4541 = fsub reassoc ninf nsz double %4529, %4523
  %4542 = fsub reassoc ninf nsz double %175, %4523
  %4543 = fmul reassoc ninf nsz double %4540, %4542
  %4544 = fdiv reassoc ninf nsz double %4543, %4541
  %4545 = fadd reassoc ninf nsz double %4544, %4536
  br label %after_if1891

true_block1901:                                   ; preds = %after_if1891
  %4546 = add i32 %180, 155
  %4547 = sext i32 %4546 to i64
  %4548 = shl nsw i64 %4547, 3
  %4549 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4548
  %4550 = bitcast i8* %4549 to double*
  %4551 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4550, i32 64)
  %4552 = add i32 %180, 156
  %4553 = sext i32 %4552 to i64
  %4554 = shl nsw i64 %4553, 3
  %4555 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4554
  %4556 = bitcast i8* %4555 to double*
  %4557 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4556, i32 64)
  %4558 = fcmp reassoc ninf nsz oge double %175, %4551
  %4559 = fcmp reassoc ninf nsz ole double %175, %4557
  %.0857 = select i1 %4558, i1 %4559, i1 false
  br i1 %.0857, label %true_block1907, label %after_if1903

after_if1903:                                     ; preds = %true_block1907, %true_block1901, %after_if1891
  %.1561327 = phi double [ %4573, %true_block1907 ], [ %.1551326, %true_block1901 ], [ %.1551326, %after_if1891 ]
  %.155 = phi i1 [ true, %true_block1907 ], [ %.154, %true_block1901 ], [ %.154, %after_if1891 ]
  %4560 = icmp ugt i32 %201, 156
  %4561 = xor i1 %.155, true
  %spec.select1982 = select i1 %4560, i1 %4561, i1 false
  br i1 %spec.select1982, label %true_block1913, label %after_if1915

true_block1907:                                   ; preds = %true_block1901
  %getch.i2374 = getelementptr i8, i8* %12, i64 418612680
  %4562 = getelementptr inbounds i8, i8* %getch.i2374, i64 %4548
  %4563 = bitcast i8* %4562 to double*
  %4564 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4563, i32 64)
  %4565 = getelementptr inbounds i8, i8* %getch.i2374, i64 %4554
  %4566 = bitcast i8* %4565 to double*
  %4567 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4566, i32 64)
  %4568 = fsub reassoc ninf nsz double %4567, %4564
  %4569 = fsub reassoc ninf nsz double %4557, %4551
  %4570 = fsub reassoc ninf nsz double %175, %4551
  %4571 = fmul reassoc ninf nsz double %4568, %4570
  %4572 = fdiv reassoc ninf nsz double %4571, %4569
  %4573 = fadd reassoc ninf nsz double %4572, %4564
  br label %after_if1903

true_block1913:                                   ; preds = %after_if1903
  %4574 = add i32 %180, 156
  %4575 = sext i32 %4574 to i64
  %4576 = shl nsw i64 %4575, 3
  %4577 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4576
  %4578 = bitcast i8* %4577 to double*
  %4579 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4578, i32 64)
  %4580 = add i32 %180, 157
  %4581 = sext i32 %4580 to i64
  %4582 = shl nsw i64 %4581, 3
  %4583 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4582
  %4584 = bitcast i8* %4583 to double*
  %4585 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4584, i32 64)
  %4586 = fcmp reassoc ninf nsz oge double %175, %4579
  %4587 = fcmp reassoc ninf nsz ole double %175, %4585
  %.0855 = select i1 %4586, i1 %4587, i1 false
  br i1 %.0855, label %true_block1919, label %after_if1915

after_if1915:                                     ; preds = %true_block1919, %true_block1913, %after_if1903
  %.1571328 = phi double [ %4601, %true_block1919 ], [ %.1561327, %true_block1913 ], [ %.1561327, %after_if1903 ]
  %.156 = phi i1 [ true, %true_block1919 ], [ %.155, %true_block1913 ], [ %.155, %after_if1903 ]
  %4588 = icmp ugt i32 %201, 157
  %4589 = xor i1 %.156, true
  %spec.select1983 = select i1 %4588, i1 %4589, i1 false
  br i1 %spec.select1983, label %true_block1925, label %after_if1927

true_block1919:                                   ; preds = %true_block1913
  %getch.i2373 = getelementptr i8, i8* %12, i64 418612680
  %4590 = getelementptr inbounds i8, i8* %getch.i2373, i64 %4576
  %4591 = bitcast i8* %4590 to double*
  %4592 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4591, i32 64)
  %4593 = getelementptr inbounds i8, i8* %getch.i2373, i64 %4582
  %4594 = bitcast i8* %4593 to double*
  %4595 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4594, i32 64)
  %4596 = fsub reassoc ninf nsz double %4595, %4592
  %4597 = fsub reassoc ninf nsz double %4585, %4579
  %4598 = fsub reassoc ninf nsz double %175, %4579
  %4599 = fmul reassoc ninf nsz double %4596, %4598
  %4600 = fdiv reassoc ninf nsz double %4599, %4597
  %4601 = fadd reassoc ninf nsz double %4600, %4592
  br label %after_if1915

true_block1925:                                   ; preds = %after_if1915
  %4602 = add i32 %180, 157
  %4603 = sext i32 %4602 to i64
  %4604 = shl nsw i64 %4603, 3
  %4605 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4604
  %4606 = bitcast i8* %4605 to double*
  %4607 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4606, i32 64)
  %4608 = add i32 %180, 158
  %4609 = sext i32 %4608 to i64
  %4610 = shl nsw i64 %4609, 3
  %4611 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4610
  %4612 = bitcast i8* %4611 to double*
  %4613 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4612, i32 64)
  %4614 = fcmp reassoc ninf nsz oge double %175, %4607
  %4615 = fcmp reassoc ninf nsz ole double %175, %4613
  %.0853 = select i1 %4614, i1 %4615, i1 false
  br i1 %.0853, label %true_block1931, label %after_if1927

after_if1927:                                     ; preds = %true_block1931, %true_block1925, %after_if1915
  %.1581329 = phi double [ %4629, %true_block1931 ], [ %.1571328, %true_block1925 ], [ %.1571328, %after_if1915 ]
  %.157 = phi i1 [ true, %true_block1931 ], [ %.156, %true_block1925 ], [ %.156, %after_if1915 ]
  %4616 = icmp ugt i32 %201, 158
  %4617 = xor i1 %.157, true
  %spec.select1984 = select i1 %4616, i1 %4617, i1 false
  br i1 %spec.select1984, label %true_block1937, label %after_if1939

true_block1931:                                   ; preds = %true_block1925
  %getch.i2372 = getelementptr i8, i8* %12, i64 418612680
  %4618 = getelementptr inbounds i8, i8* %getch.i2372, i64 %4604
  %4619 = bitcast i8* %4618 to double*
  %4620 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4619, i32 64)
  %4621 = getelementptr inbounds i8, i8* %getch.i2372, i64 %4610
  %4622 = bitcast i8* %4621 to double*
  %4623 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4622, i32 64)
  %4624 = fsub reassoc ninf nsz double %4623, %4620
  %4625 = fsub reassoc ninf nsz double %4613, %4607
  %4626 = fsub reassoc ninf nsz double %175, %4607
  %4627 = fmul reassoc ninf nsz double %4624, %4626
  %4628 = fdiv reassoc ninf nsz double %4627, %4625
  %4629 = fadd reassoc ninf nsz double %4628, %4620
  br label %after_if1927

true_block1937:                                   ; preds = %after_if1927
  %4630 = add i32 %180, 158
  %4631 = sext i32 %4630 to i64
  %4632 = shl nsw i64 %4631, 3
  %4633 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4632
  %4634 = bitcast i8* %4633 to double*
  %4635 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4634, i32 64)
  %4636 = add i32 %180, 159
  %4637 = sext i32 %4636 to i64
  %4638 = shl nsw i64 %4637, 3
  %4639 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4638
  %4640 = bitcast i8* %4639 to double*
  %4641 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4640, i32 64)
  %4642 = fcmp reassoc ninf nsz oge double %175, %4635
  %4643 = fcmp reassoc ninf nsz ole double %175, %4641
  %.0851 = select i1 %4642, i1 %4643, i1 false
  br i1 %.0851, label %true_block1943, label %after_if1939

after_if1939:                                     ; preds = %true_block1943, %true_block1937, %after_if1927
  %.1591330 = phi double [ %4657, %true_block1943 ], [ %.1581329, %true_block1937 ], [ %.1581329, %after_if1927 ]
  %.158 = phi i1 [ true, %true_block1943 ], [ %.157, %true_block1937 ], [ %.157, %after_if1927 ]
  %4644 = icmp ugt i32 %201, 159
  %4645 = xor i1 %.158, true
  %spec.select1985 = select i1 %4644, i1 %4645, i1 false
  br i1 %spec.select1985, label %true_block1949, label %after_if1951

true_block1943:                                   ; preds = %true_block1937
  %getch.i2371 = getelementptr i8, i8* %12, i64 418612680
  %4646 = getelementptr inbounds i8, i8* %getch.i2371, i64 %4632
  %4647 = bitcast i8* %4646 to double*
  %4648 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4647, i32 64)
  %4649 = getelementptr inbounds i8, i8* %getch.i2371, i64 %4638
  %4650 = bitcast i8* %4649 to double*
  %4651 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4650, i32 64)
  %4652 = fsub reassoc ninf nsz double %4651, %4648
  %4653 = fsub reassoc ninf nsz double %4641, %4635
  %4654 = fsub reassoc ninf nsz double %175, %4635
  %4655 = fmul reassoc ninf nsz double %4652, %4654
  %4656 = fdiv reassoc ninf nsz double %4655, %4653
  %4657 = fadd reassoc ninf nsz double %4656, %4648
  br label %after_if1939

true_block1949:                                   ; preds = %after_if1939
  %4658 = add i32 %180, 159
  %4659 = sext i32 %4658 to i64
  %4660 = shl nsw i64 %4659, 3
  %4661 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4660
  %4662 = bitcast i8* %4661 to double*
  %4663 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4662, i32 64)
  %4664 = add i32 %180, 160
  %4665 = sext i32 %4664 to i64
  %4666 = shl nsw i64 %4665, 3
  %4667 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4666
  %4668 = bitcast i8* %4667 to double*
  %4669 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4668, i32 64)
  %4670 = fcmp reassoc ninf nsz oge double %175, %4663
  %4671 = fcmp reassoc ninf nsz ole double %175, %4669
  %.0849 = select i1 %4670, i1 %4671, i1 false
  br i1 %.0849, label %true_block1955, label %after_if1951

after_if1951:                                     ; preds = %true_block1955, %true_block1949, %after_if1939
  %.1601331 = phi double [ %4685, %true_block1955 ], [ %.1591330, %true_block1949 ], [ %.1591330, %after_if1939 ]
  %.159 = phi i1 [ true, %true_block1955 ], [ %.158, %true_block1949 ], [ %.158, %after_if1939 ]
  %4672 = icmp ugt i32 %201, 160
  %4673 = xor i1 %.159, true
  %spec.select1986 = select i1 %4672, i1 %4673, i1 false
  br i1 %spec.select1986, label %true_block1961, label %after_if1963

true_block1955:                                   ; preds = %true_block1949
  %getch.i2370 = getelementptr i8, i8* %12, i64 418612680
  %4674 = getelementptr inbounds i8, i8* %getch.i2370, i64 %4660
  %4675 = bitcast i8* %4674 to double*
  %4676 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4675, i32 64)
  %4677 = getelementptr inbounds i8, i8* %getch.i2370, i64 %4666
  %4678 = bitcast i8* %4677 to double*
  %4679 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4678, i32 64)
  %4680 = fsub reassoc ninf nsz double %4679, %4676
  %4681 = fsub reassoc ninf nsz double %4669, %4663
  %4682 = fsub reassoc ninf nsz double %175, %4663
  %4683 = fmul reassoc ninf nsz double %4680, %4682
  %4684 = fdiv reassoc ninf nsz double %4683, %4681
  %4685 = fadd reassoc ninf nsz double %4684, %4676
  br label %after_if1951

true_block1961:                                   ; preds = %after_if1951
  %4686 = add i32 %180, 160
  %4687 = sext i32 %4686 to i64
  %4688 = shl nsw i64 %4687, 3
  %4689 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4688
  %4690 = bitcast i8* %4689 to double*
  %4691 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4690, i32 64)
  %4692 = add i32 %180, 161
  %4693 = sext i32 %4692 to i64
  %4694 = shl nsw i64 %4693, 3
  %4695 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4694
  %4696 = bitcast i8* %4695 to double*
  %4697 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4696, i32 64)
  %4698 = fcmp reassoc ninf nsz oge double %175, %4691
  %4699 = fcmp reassoc ninf nsz ole double %175, %4697
  %.0847 = select i1 %4698, i1 %4699, i1 false
  br i1 %.0847, label %true_block1967, label %after_if1963

after_if1963:                                     ; preds = %true_block1967, %true_block1961, %after_if1951
  %.1611332 = phi double [ %4713, %true_block1967 ], [ %.1601331, %true_block1961 ], [ %.1601331, %after_if1951 ]
  %.160 = phi i1 [ true, %true_block1967 ], [ %.159, %true_block1961 ], [ %.159, %after_if1951 ]
  %4700 = icmp ugt i32 %201, 161
  %4701 = xor i1 %.160, true
  %spec.select1987 = select i1 %4700, i1 %4701, i1 false
  br i1 %spec.select1987, label %true_block1973, label %after_if1975

true_block1967:                                   ; preds = %true_block1961
  %getch.i2369 = getelementptr i8, i8* %12, i64 418612680
  %4702 = getelementptr inbounds i8, i8* %getch.i2369, i64 %4688
  %4703 = bitcast i8* %4702 to double*
  %4704 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4703, i32 64)
  %4705 = getelementptr inbounds i8, i8* %getch.i2369, i64 %4694
  %4706 = bitcast i8* %4705 to double*
  %4707 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4706, i32 64)
  %4708 = fsub reassoc ninf nsz double %4707, %4704
  %4709 = fsub reassoc ninf nsz double %4697, %4691
  %4710 = fsub reassoc ninf nsz double %175, %4691
  %4711 = fmul reassoc ninf nsz double %4708, %4710
  %4712 = fdiv reassoc ninf nsz double %4711, %4709
  %4713 = fadd reassoc ninf nsz double %4712, %4704
  br label %after_if1963

true_block1973:                                   ; preds = %after_if1963
  %4714 = add i32 %180, 161
  %4715 = sext i32 %4714 to i64
  %4716 = shl nsw i64 %4715, 3
  %4717 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4716
  %4718 = bitcast i8* %4717 to double*
  %4719 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4718, i32 64)
  %4720 = add i32 %180, 162
  %4721 = sext i32 %4720 to i64
  %4722 = shl nsw i64 %4721, 3
  %4723 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4722
  %4724 = bitcast i8* %4723 to double*
  %4725 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4724, i32 64)
  %4726 = fcmp reassoc ninf nsz oge double %175, %4719
  %4727 = fcmp reassoc ninf nsz ole double %175, %4725
  %.0845 = select i1 %4726, i1 %4727, i1 false
  br i1 %.0845, label %true_block1979, label %after_if1975

after_if1975:                                     ; preds = %true_block1979, %true_block1973, %after_if1963
  %.1621333 = phi double [ %4741, %true_block1979 ], [ %.1611332, %true_block1973 ], [ %.1611332, %after_if1963 ]
  %.161 = phi i1 [ true, %true_block1979 ], [ %.160, %true_block1973 ], [ %.160, %after_if1963 ]
  %4728 = icmp ugt i32 %201, 162
  %4729 = xor i1 %.161, true
  %spec.select1988 = select i1 %4728, i1 %4729, i1 false
  br i1 %spec.select1988, label %true_block1985, label %after_if1987

true_block1979:                                   ; preds = %true_block1973
  %getch.i2368 = getelementptr i8, i8* %12, i64 418612680
  %4730 = getelementptr inbounds i8, i8* %getch.i2368, i64 %4716
  %4731 = bitcast i8* %4730 to double*
  %4732 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4731, i32 64)
  %4733 = getelementptr inbounds i8, i8* %getch.i2368, i64 %4722
  %4734 = bitcast i8* %4733 to double*
  %4735 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4734, i32 64)
  %4736 = fsub reassoc ninf nsz double %4735, %4732
  %4737 = fsub reassoc ninf nsz double %4725, %4719
  %4738 = fsub reassoc ninf nsz double %175, %4719
  %4739 = fmul reassoc ninf nsz double %4736, %4738
  %4740 = fdiv reassoc ninf nsz double %4739, %4737
  %4741 = fadd reassoc ninf nsz double %4740, %4732
  br label %after_if1975

true_block1985:                                   ; preds = %after_if1975
  %4742 = add i32 %180, 162
  %4743 = sext i32 %4742 to i64
  %4744 = shl nsw i64 %4743, 3
  %4745 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4744
  %4746 = bitcast i8* %4745 to double*
  %4747 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4746, i32 64)
  %4748 = add i32 %180, 163
  %4749 = sext i32 %4748 to i64
  %4750 = shl nsw i64 %4749, 3
  %4751 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4750
  %4752 = bitcast i8* %4751 to double*
  %4753 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4752, i32 64)
  %4754 = fcmp reassoc ninf nsz oge double %175, %4747
  %4755 = fcmp reassoc ninf nsz ole double %175, %4753
  %.0843 = select i1 %4754, i1 %4755, i1 false
  br i1 %.0843, label %true_block1991, label %after_if1987

after_if1987:                                     ; preds = %true_block1991, %true_block1985, %after_if1975
  %.1631334 = phi double [ %4769, %true_block1991 ], [ %.1621333, %true_block1985 ], [ %.1621333, %after_if1975 ]
  %.162 = phi i1 [ true, %true_block1991 ], [ %.161, %true_block1985 ], [ %.161, %after_if1975 ]
  %4756 = icmp ugt i32 %201, 163
  %4757 = xor i1 %.162, true
  %spec.select1989 = select i1 %4756, i1 %4757, i1 false
  br i1 %spec.select1989, label %true_block1997, label %after_if1999

true_block1991:                                   ; preds = %true_block1985
  %getch.i2367 = getelementptr i8, i8* %12, i64 418612680
  %4758 = getelementptr inbounds i8, i8* %getch.i2367, i64 %4744
  %4759 = bitcast i8* %4758 to double*
  %4760 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4759, i32 64)
  %4761 = getelementptr inbounds i8, i8* %getch.i2367, i64 %4750
  %4762 = bitcast i8* %4761 to double*
  %4763 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4762, i32 64)
  %4764 = fsub reassoc ninf nsz double %4763, %4760
  %4765 = fsub reassoc ninf nsz double %4753, %4747
  %4766 = fsub reassoc ninf nsz double %175, %4747
  %4767 = fmul reassoc ninf nsz double %4764, %4766
  %4768 = fdiv reassoc ninf nsz double %4767, %4765
  %4769 = fadd reassoc ninf nsz double %4768, %4760
  br label %after_if1987

true_block1997:                                   ; preds = %after_if1987
  %4770 = add i32 %180, 163
  %4771 = sext i32 %4770 to i64
  %4772 = shl nsw i64 %4771, 3
  %4773 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4772
  %4774 = bitcast i8* %4773 to double*
  %4775 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4774, i32 64)
  %4776 = add i32 %180, 164
  %4777 = sext i32 %4776 to i64
  %4778 = shl nsw i64 %4777, 3
  %4779 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4778
  %4780 = bitcast i8* %4779 to double*
  %4781 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4780, i32 64)
  %4782 = fcmp reassoc ninf nsz oge double %175, %4775
  %4783 = fcmp reassoc ninf nsz ole double %175, %4781
  %.0841 = select i1 %4782, i1 %4783, i1 false
  br i1 %.0841, label %true_block2003, label %after_if1999

after_if1999:                                     ; preds = %true_block2003, %true_block1997, %after_if1987
  %.1641335 = phi double [ %4797, %true_block2003 ], [ %.1631334, %true_block1997 ], [ %.1631334, %after_if1987 ]
  %.163 = phi i1 [ true, %true_block2003 ], [ %.162, %true_block1997 ], [ %.162, %after_if1987 ]
  %4784 = icmp ugt i32 %201, 164
  %4785 = xor i1 %.163, true
  %spec.select1990 = select i1 %4784, i1 %4785, i1 false
  br i1 %spec.select1990, label %true_block2009, label %after_if2011

true_block2003:                                   ; preds = %true_block1997
  %getch.i2366 = getelementptr i8, i8* %12, i64 418612680
  %4786 = getelementptr inbounds i8, i8* %getch.i2366, i64 %4772
  %4787 = bitcast i8* %4786 to double*
  %4788 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4787, i32 64)
  %4789 = getelementptr inbounds i8, i8* %getch.i2366, i64 %4778
  %4790 = bitcast i8* %4789 to double*
  %4791 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4790, i32 64)
  %4792 = fsub reassoc ninf nsz double %4791, %4788
  %4793 = fsub reassoc ninf nsz double %4781, %4775
  %4794 = fsub reassoc ninf nsz double %175, %4775
  %4795 = fmul reassoc ninf nsz double %4792, %4794
  %4796 = fdiv reassoc ninf nsz double %4795, %4793
  %4797 = fadd reassoc ninf nsz double %4796, %4788
  br label %after_if1999

true_block2009:                                   ; preds = %after_if1999
  %4798 = add i32 %180, 164
  %4799 = sext i32 %4798 to i64
  %4800 = shl nsw i64 %4799, 3
  %4801 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4800
  %4802 = bitcast i8* %4801 to double*
  %4803 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4802, i32 64)
  %4804 = add i32 %180, 165
  %4805 = sext i32 %4804 to i64
  %4806 = shl nsw i64 %4805, 3
  %4807 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4806
  %4808 = bitcast i8* %4807 to double*
  %4809 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4808, i32 64)
  %4810 = fcmp reassoc ninf nsz oge double %175, %4803
  %4811 = fcmp reassoc ninf nsz ole double %175, %4809
  %.0839 = select i1 %4810, i1 %4811, i1 false
  br i1 %.0839, label %true_block2015, label %after_if2011

after_if2011:                                     ; preds = %true_block2015, %true_block2009, %after_if1999
  %.1651336 = phi double [ %4825, %true_block2015 ], [ %.1641335, %true_block2009 ], [ %.1641335, %after_if1999 ]
  %.164 = phi i1 [ true, %true_block2015 ], [ %.163, %true_block2009 ], [ %.163, %after_if1999 ]
  %4812 = icmp ugt i32 %201, 165
  %4813 = xor i1 %.164, true
  %spec.select1991 = select i1 %4812, i1 %4813, i1 false
  br i1 %spec.select1991, label %true_block2021, label %after_if2023

true_block2015:                                   ; preds = %true_block2009
  %getch.i2365 = getelementptr i8, i8* %12, i64 418612680
  %4814 = getelementptr inbounds i8, i8* %getch.i2365, i64 %4800
  %4815 = bitcast i8* %4814 to double*
  %4816 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4815, i32 64)
  %4817 = getelementptr inbounds i8, i8* %getch.i2365, i64 %4806
  %4818 = bitcast i8* %4817 to double*
  %4819 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4818, i32 64)
  %4820 = fsub reassoc ninf nsz double %4819, %4816
  %4821 = fsub reassoc ninf nsz double %4809, %4803
  %4822 = fsub reassoc ninf nsz double %175, %4803
  %4823 = fmul reassoc ninf nsz double %4820, %4822
  %4824 = fdiv reassoc ninf nsz double %4823, %4821
  %4825 = fadd reassoc ninf nsz double %4824, %4816
  br label %after_if2011

true_block2021:                                   ; preds = %after_if2011
  %4826 = add i32 %180, 165
  %4827 = sext i32 %4826 to i64
  %4828 = shl nsw i64 %4827, 3
  %4829 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4828
  %4830 = bitcast i8* %4829 to double*
  %4831 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4830, i32 64)
  %4832 = add i32 %180, 166
  %4833 = sext i32 %4832 to i64
  %4834 = shl nsw i64 %4833, 3
  %4835 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4834
  %4836 = bitcast i8* %4835 to double*
  %4837 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4836, i32 64)
  %4838 = fcmp reassoc ninf nsz oge double %175, %4831
  %4839 = fcmp reassoc ninf nsz ole double %175, %4837
  %.0837 = select i1 %4838, i1 %4839, i1 false
  br i1 %.0837, label %true_block2027, label %after_if2023

after_if2023:                                     ; preds = %true_block2027, %true_block2021, %after_if2011
  %.1661337 = phi double [ %4853, %true_block2027 ], [ %.1651336, %true_block2021 ], [ %.1651336, %after_if2011 ]
  %.165 = phi i1 [ true, %true_block2027 ], [ %.164, %true_block2021 ], [ %.164, %after_if2011 ]
  %4840 = icmp ugt i32 %201, 166
  %4841 = xor i1 %.165, true
  %spec.select1992 = select i1 %4840, i1 %4841, i1 false
  br i1 %spec.select1992, label %true_block2033, label %after_if2035

true_block2027:                                   ; preds = %true_block2021
  %getch.i2364 = getelementptr i8, i8* %12, i64 418612680
  %4842 = getelementptr inbounds i8, i8* %getch.i2364, i64 %4828
  %4843 = bitcast i8* %4842 to double*
  %4844 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4843, i32 64)
  %4845 = getelementptr inbounds i8, i8* %getch.i2364, i64 %4834
  %4846 = bitcast i8* %4845 to double*
  %4847 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4846, i32 64)
  %4848 = fsub reassoc ninf nsz double %4847, %4844
  %4849 = fsub reassoc ninf nsz double %4837, %4831
  %4850 = fsub reassoc ninf nsz double %175, %4831
  %4851 = fmul reassoc ninf nsz double %4848, %4850
  %4852 = fdiv reassoc ninf nsz double %4851, %4849
  %4853 = fadd reassoc ninf nsz double %4852, %4844
  br label %after_if2023

true_block2033:                                   ; preds = %after_if2023
  %4854 = add i32 %180, 166
  %4855 = sext i32 %4854 to i64
  %4856 = shl nsw i64 %4855, 3
  %4857 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4856
  %4858 = bitcast i8* %4857 to double*
  %4859 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4858, i32 64)
  %4860 = add i32 %180, 167
  %4861 = sext i32 %4860 to i64
  %4862 = shl nsw i64 %4861, 3
  %4863 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4862
  %4864 = bitcast i8* %4863 to double*
  %4865 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4864, i32 64)
  %4866 = fcmp reassoc ninf nsz oge double %175, %4859
  %4867 = fcmp reassoc ninf nsz ole double %175, %4865
  %.0835 = select i1 %4866, i1 %4867, i1 false
  br i1 %.0835, label %true_block2039, label %after_if2035

after_if2035:                                     ; preds = %true_block2039, %true_block2033, %after_if2023
  %.1671338 = phi double [ %4881, %true_block2039 ], [ %.1661337, %true_block2033 ], [ %.1661337, %after_if2023 ]
  %.166 = phi i1 [ true, %true_block2039 ], [ %.165, %true_block2033 ], [ %.165, %after_if2023 ]
  %4868 = icmp ugt i32 %201, 167
  %4869 = xor i1 %.166, true
  %spec.select1993 = select i1 %4868, i1 %4869, i1 false
  br i1 %spec.select1993, label %true_block2045, label %after_if2047

true_block2039:                                   ; preds = %true_block2033
  %getch.i2363 = getelementptr i8, i8* %12, i64 418612680
  %4870 = getelementptr inbounds i8, i8* %getch.i2363, i64 %4856
  %4871 = bitcast i8* %4870 to double*
  %4872 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4871, i32 64)
  %4873 = getelementptr inbounds i8, i8* %getch.i2363, i64 %4862
  %4874 = bitcast i8* %4873 to double*
  %4875 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4874, i32 64)
  %4876 = fsub reassoc ninf nsz double %4875, %4872
  %4877 = fsub reassoc ninf nsz double %4865, %4859
  %4878 = fsub reassoc ninf nsz double %175, %4859
  %4879 = fmul reassoc ninf nsz double %4876, %4878
  %4880 = fdiv reassoc ninf nsz double %4879, %4877
  %4881 = fadd reassoc ninf nsz double %4880, %4872
  br label %after_if2035

true_block2045:                                   ; preds = %after_if2035
  %4882 = add i32 %180, 167
  %4883 = sext i32 %4882 to i64
  %4884 = shl nsw i64 %4883, 3
  %4885 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4884
  %4886 = bitcast i8* %4885 to double*
  %4887 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4886, i32 64)
  %4888 = add i32 %180, 168
  %4889 = sext i32 %4888 to i64
  %4890 = shl nsw i64 %4889, 3
  %4891 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4890
  %4892 = bitcast i8* %4891 to double*
  %4893 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4892, i32 64)
  %4894 = fcmp reassoc ninf nsz oge double %175, %4887
  %4895 = fcmp reassoc ninf nsz ole double %175, %4893
  %.0833 = select i1 %4894, i1 %4895, i1 false
  br i1 %.0833, label %true_block2051, label %after_if2047

after_if2047:                                     ; preds = %true_block2051, %true_block2045, %after_if2035
  %.1681339 = phi double [ %4909, %true_block2051 ], [ %.1671338, %true_block2045 ], [ %.1671338, %after_if2035 ]
  %.167 = phi i1 [ true, %true_block2051 ], [ %.166, %true_block2045 ], [ %.166, %after_if2035 ]
  %4896 = icmp ugt i32 %201, 168
  %4897 = xor i1 %.167, true
  %spec.select1994 = select i1 %4896, i1 %4897, i1 false
  br i1 %spec.select1994, label %true_block2057, label %after_if2059

true_block2051:                                   ; preds = %true_block2045
  %getch.i2362 = getelementptr i8, i8* %12, i64 418612680
  %4898 = getelementptr inbounds i8, i8* %getch.i2362, i64 %4884
  %4899 = bitcast i8* %4898 to double*
  %4900 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4899, i32 64)
  %4901 = getelementptr inbounds i8, i8* %getch.i2362, i64 %4890
  %4902 = bitcast i8* %4901 to double*
  %4903 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4902, i32 64)
  %4904 = fsub reassoc ninf nsz double %4903, %4900
  %4905 = fsub reassoc ninf nsz double %4893, %4887
  %4906 = fsub reassoc ninf nsz double %175, %4887
  %4907 = fmul reassoc ninf nsz double %4904, %4906
  %4908 = fdiv reassoc ninf nsz double %4907, %4905
  %4909 = fadd reassoc ninf nsz double %4908, %4900
  br label %after_if2047

true_block2057:                                   ; preds = %after_if2047
  %4910 = add i32 %180, 168
  %4911 = sext i32 %4910 to i64
  %4912 = shl nsw i64 %4911, 3
  %4913 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4912
  %4914 = bitcast i8* %4913 to double*
  %4915 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4914, i32 64)
  %4916 = add i32 %180, 169
  %4917 = sext i32 %4916 to i64
  %4918 = shl nsw i64 %4917, 3
  %4919 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4918
  %4920 = bitcast i8* %4919 to double*
  %4921 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4920, i32 64)
  %4922 = fcmp reassoc ninf nsz oge double %175, %4915
  %4923 = fcmp reassoc ninf nsz ole double %175, %4921
  %.0831 = select i1 %4922, i1 %4923, i1 false
  br i1 %.0831, label %true_block2063, label %after_if2059

after_if2059:                                     ; preds = %true_block2063, %true_block2057, %after_if2047
  %.1691340 = phi double [ %4937, %true_block2063 ], [ %.1681339, %true_block2057 ], [ %.1681339, %after_if2047 ]
  %.168 = phi i1 [ true, %true_block2063 ], [ %.167, %true_block2057 ], [ %.167, %after_if2047 ]
  %4924 = icmp ugt i32 %201, 169
  %4925 = xor i1 %.168, true
  %spec.select1995 = select i1 %4924, i1 %4925, i1 false
  br i1 %spec.select1995, label %true_block2069, label %after_if2071

true_block2063:                                   ; preds = %true_block2057
  %getch.i2361 = getelementptr i8, i8* %12, i64 418612680
  %4926 = getelementptr inbounds i8, i8* %getch.i2361, i64 %4912
  %4927 = bitcast i8* %4926 to double*
  %4928 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4927, i32 64)
  %4929 = getelementptr inbounds i8, i8* %getch.i2361, i64 %4918
  %4930 = bitcast i8* %4929 to double*
  %4931 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4930, i32 64)
  %4932 = fsub reassoc ninf nsz double %4931, %4928
  %4933 = fsub reassoc ninf nsz double %4921, %4915
  %4934 = fsub reassoc ninf nsz double %175, %4915
  %4935 = fmul reassoc ninf nsz double %4932, %4934
  %4936 = fdiv reassoc ninf nsz double %4935, %4933
  %4937 = fadd reassoc ninf nsz double %4936, %4928
  br label %after_if2059

true_block2069:                                   ; preds = %after_if2059
  %4938 = add i32 %180, 169
  %4939 = sext i32 %4938 to i64
  %4940 = shl nsw i64 %4939, 3
  %4941 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4940
  %4942 = bitcast i8* %4941 to double*
  %4943 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4942, i32 64)
  %4944 = add i32 %180, 170
  %4945 = sext i32 %4944 to i64
  %4946 = shl nsw i64 %4945, 3
  %4947 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4946
  %4948 = bitcast i8* %4947 to double*
  %4949 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4948, i32 64)
  %4950 = fcmp reassoc ninf nsz oge double %175, %4943
  %4951 = fcmp reassoc ninf nsz ole double %175, %4949
  %.0829 = select i1 %4950, i1 %4951, i1 false
  br i1 %.0829, label %true_block2075, label %after_if2071

after_if2071:                                     ; preds = %true_block2075, %true_block2069, %after_if2059
  %.1701341 = phi double [ %4965, %true_block2075 ], [ %.1691340, %true_block2069 ], [ %.1691340, %after_if2059 ]
  %.169 = phi i1 [ true, %true_block2075 ], [ %.168, %true_block2069 ], [ %.168, %after_if2059 ]
  %4952 = icmp ugt i32 %201, 170
  %4953 = xor i1 %.169, true
  %spec.select1996 = select i1 %4952, i1 %4953, i1 false
  br i1 %spec.select1996, label %true_block2081, label %after_if2083

true_block2075:                                   ; preds = %true_block2069
  %getch.i2360 = getelementptr i8, i8* %12, i64 418612680
  %4954 = getelementptr inbounds i8, i8* %getch.i2360, i64 %4940
  %4955 = bitcast i8* %4954 to double*
  %4956 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4955, i32 64)
  %4957 = getelementptr inbounds i8, i8* %getch.i2360, i64 %4946
  %4958 = bitcast i8* %4957 to double*
  %4959 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4958, i32 64)
  %4960 = fsub reassoc ninf nsz double %4959, %4956
  %4961 = fsub reassoc ninf nsz double %4949, %4943
  %4962 = fsub reassoc ninf nsz double %175, %4943
  %4963 = fmul reassoc ninf nsz double %4960, %4962
  %4964 = fdiv reassoc ninf nsz double %4963, %4961
  %4965 = fadd reassoc ninf nsz double %4964, %4956
  br label %after_if2071

true_block2081:                                   ; preds = %after_if2071
  %4966 = add i32 %180, 170
  %4967 = sext i32 %4966 to i64
  %4968 = shl nsw i64 %4967, 3
  %4969 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4968
  %4970 = bitcast i8* %4969 to double*
  %4971 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4970, i32 64)
  %4972 = add i32 %180, 171
  %4973 = sext i32 %4972 to i64
  %4974 = shl nsw i64 %4973, 3
  %4975 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4974
  %4976 = bitcast i8* %4975 to double*
  %4977 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4976, i32 64)
  %4978 = fcmp reassoc ninf nsz oge double %175, %4971
  %4979 = fcmp reassoc ninf nsz ole double %175, %4977
  %.0827 = select i1 %4978, i1 %4979, i1 false
  br i1 %.0827, label %true_block2087, label %after_if2083

after_if2083:                                     ; preds = %true_block2087, %true_block2081, %after_if2071
  %.1711342 = phi double [ %4993, %true_block2087 ], [ %.1701341, %true_block2081 ], [ %.1701341, %after_if2071 ]
  %.170 = phi i1 [ true, %true_block2087 ], [ %.169, %true_block2081 ], [ %.169, %after_if2071 ]
  %4980 = icmp ugt i32 %201, 171
  %4981 = xor i1 %.170, true
  %spec.select1997 = select i1 %4980, i1 %4981, i1 false
  br i1 %spec.select1997, label %true_block2093, label %after_if2095

true_block2087:                                   ; preds = %true_block2081
  %getch.i2359 = getelementptr i8, i8* %12, i64 418612680
  %4982 = getelementptr inbounds i8, i8* %getch.i2359, i64 %4968
  %4983 = bitcast i8* %4982 to double*
  %4984 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %4983, i32 64)
  %4985 = getelementptr inbounds i8, i8* %getch.i2359, i64 %4974
  %4986 = bitcast i8* %4985 to double*
  %4987 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4986, i32 64)
  %4988 = fsub reassoc ninf nsz double %4987, %4984
  %4989 = fsub reassoc ninf nsz double %4977, %4971
  %4990 = fsub reassoc ninf nsz double %175, %4971
  %4991 = fmul reassoc ninf nsz double %4988, %4990
  %4992 = fdiv reassoc ninf nsz double %4991, %4989
  %4993 = fadd reassoc ninf nsz double %4992, %4984
  br label %after_if2083

true_block2093:                                   ; preds = %after_if2083
  %4994 = add i32 %180, 171
  %4995 = sext i32 %4994 to i64
  %4996 = shl nsw i64 %4995, 3
  %4997 = getelementptr inbounds i8, i8* %getch.i2533, i64 %4996
  %4998 = bitcast i8* %4997 to double*
  %4999 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %4998, i32 64)
  %5000 = add i32 %180, 172
  %5001 = sext i32 %5000 to i64
  %5002 = shl nsw i64 %5001, 3
  %5003 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5002
  %5004 = bitcast i8* %5003 to double*
  %5005 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5004, i32 64)
  %5006 = fcmp reassoc ninf nsz oge double %175, %4999
  %5007 = fcmp reassoc ninf nsz ole double %175, %5005
  %.0825 = select i1 %5006, i1 %5007, i1 false
  br i1 %.0825, label %true_block2099, label %after_if2095

after_if2095:                                     ; preds = %true_block2099, %true_block2093, %after_if2083
  %.1721343 = phi double [ %5021, %true_block2099 ], [ %.1711342, %true_block2093 ], [ %.1711342, %after_if2083 ]
  %.171 = phi i1 [ true, %true_block2099 ], [ %.170, %true_block2093 ], [ %.170, %after_if2083 ]
  %5008 = icmp ugt i32 %201, 172
  %5009 = xor i1 %.171, true
  %spec.select1998 = select i1 %5008, i1 %5009, i1 false
  br i1 %spec.select1998, label %true_block2105, label %after_if2107

true_block2099:                                   ; preds = %true_block2093
  %getch.i2358 = getelementptr i8, i8* %12, i64 418612680
  %5010 = getelementptr inbounds i8, i8* %getch.i2358, i64 %4996
  %5011 = bitcast i8* %5010 to double*
  %5012 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5011, i32 64)
  %5013 = getelementptr inbounds i8, i8* %getch.i2358, i64 %5002
  %5014 = bitcast i8* %5013 to double*
  %5015 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5014, i32 64)
  %5016 = fsub reassoc ninf nsz double %5015, %5012
  %5017 = fsub reassoc ninf nsz double %5005, %4999
  %5018 = fsub reassoc ninf nsz double %175, %4999
  %5019 = fmul reassoc ninf nsz double %5016, %5018
  %5020 = fdiv reassoc ninf nsz double %5019, %5017
  %5021 = fadd reassoc ninf nsz double %5020, %5012
  br label %after_if2095

true_block2105:                                   ; preds = %after_if2095
  %5022 = add i32 %180, 172
  %5023 = sext i32 %5022 to i64
  %5024 = shl nsw i64 %5023, 3
  %5025 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5024
  %5026 = bitcast i8* %5025 to double*
  %5027 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5026, i32 64)
  %5028 = add i32 %180, 173
  %5029 = sext i32 %5028 to i64
  %5030 = shl nsw i64 %5029, 3
  %5031 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5030
  %5032 = bitcast i8* %5031 to double*
  %5033 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5032, i32 64)
  %5034 = fcmp reassoc ninf nsz oge double %175, %5027
  %5035 = fcmp reassoc ninf nsz ole double %175, %5033
  %.0823 = select i1 %5034, i1 %5035, i1 false
  br i1 %.0823, label %true_block2111, label %after_if2107

after_if2107:                                     ; preds = %true_block2111, %true_block2105, %after_if2095
  %.1731344 = phi double [ %5049, %true_block2111 ], [ %.1721343, %true_block2105 ], [ %.1721343, %after_if2095 ]
  %.172 = phi i1 [ true, %true_block2111 ], [ %.171, %true_block2105 ], [ %.171, %after_if2095 ]
  %5036 = icmp ugt i32 %201, 173
  %5037 = xor i1 %.172, true
  %spec.select1999 = select i1 %5036, i1 %5037, i1 false
  br i1 %spec.select1999, label %true_block2117, label %after_if2119

true_block2111:                                   ; preds = %true_block2105
  %getch.i2357 = getelementptr i8, i8* %12, i64 418612680
  %5038 = getelementptr inbounds i8, i8* %getch.i2357, i64 %5024
  %5039 = bitcast i8* %5038 to double*
  %5040 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5039, i32 64)
  %5041 = getelementptr inbounds i8, i8* %getch.i2357, i64 %5030
  %5042 = bitcast i8* %5041 to double*
  %5043 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5042, i32 64)
  %5044 = fsub reassoc ninf nsz double %5043, %5040
  %5045 = fsub reassoc ninf nsz double %5033, %5027
  %5046 = fsub reassoc ninf nsz double %175, %5027
  %5047 = fmul reassoc ninf nsz double %5044, %5046
  %5048 = fdiv reassoc ninf nsz double %5047, %5045
  %5049 = fadd reassoc ninf nsz double %5048, %5040
  br label %after_if2107

true_block2117:                                   ; preds = %after_if2107
  %5050 = add i32 %180, 173
  %5051 = sext i32 %5050 to i64
  %5052 = shl nsw i64 %5051, 3
  %5053 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5052
  %5054 = bitcast i8* %5053 to double*
  %5055 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5054, i32 64)
  %5056 = add i32 %180, 174
  %5057 = sext i32 %5056 to i64
  %5058 = shl nsw i64 %5057, 3
  %5059 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5058
  %5060 = bitcast i8* %5059 to double*
  %5061 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5060, i32 64)
  %5062 = fcmp reassoc ninf nsz oge double %175, %5055
  %5063 = fcmp reassoc ninf nsz ole double %175, %5061
  %.0821 = select i1 %5062, i1 %5063, i1 false
  br i1 %.0821, label %true_block2123, label %after_if2119

after_if2119:                                     ; preds = %true_block2123, %true_block2117, %after_if2107
  %.1741345 = phi double [ %5077, %true_block2123 ], [ %.1731344, %true_block2117 ], [ %.1731344, %after_if2107 ]
  %.173 = phi i1 [ true, %true_block2123 ], [ %.172, %true_block2117 ], [ %.172, %after_if2107 ]
  %5064 = icmp ugt i32 %201, 174
  %5065 = xor i1 %.173, true
  %spec.select2000 = select i1 %5064, i1 %5065, i1 false
  br i1 %spec.select2000, label %true_block2129, label %after_if2131

true_block2123:                                   ; preds = %true_block2117
  %getch.i2356 = getelementptr i8, i8* %12, i64 418612680
  %5066 = getelementptr inbounds i8, i8* %getch.i2356, i64 %5052
  %5067 = bitcast i8* %5066 to double*
  %5068 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5067, i32 64)
  %5069 = getelementptr inbounds i8, i8* %getch.i2356, i64 %5058
  %5070 = bitcast i8* %5069 to double*
  %5071 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5070, i32 64)
  %5072 = fsub reassoc ninf nsz double %5071, %5068
  %5073 = fsub reassoc ninf nsz double %5061, %5055
  %5074 = fsub reassoc ninf nsz double %175, %5055
  %5075 = fmul reassoc ninf nsz double %5072, %5074
  %5076 = fdiv reassoc ninf nsz double %5075, %5073
  %5077 = fadd reassoc ninf nsz double %5076, %5068
  br label %after_if2119

true_block2129:                                   ; preds = %after_if2119
  %5078 = add i32 %180, 174
  %5079 = sext i32 %5078 to i64
  %5080 = shl nsw i64 %5079, 3
  %5081 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5080
  %5082 = bitcast i8* %5081 to double*
  %5083 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5082, i32 64)
  %5084 = add i32 %180, 175
  %5085 = sext i32 %5084 to i64
  %5086 = shl nsw i64 %5085, 3
  %5087 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5086
  %5088 = bitcast i8* %5087 to double*
  %5089 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5088, i32 64)
  %5090 = fcmp reassoc ninf nsz oge double %175, %5083
  %5091 = fcmp reassoc ninf nsz ole double %175, %5089
  %.0819 = select i1 %5090, i1 %5091, i1 false
  br i1 %.0819, label %true_block2135, label %after_if2131

after_if2131:                                     ; preds = %true_block2135, %true_block2129, %after_if2119
  %.1751346 = phi double [ %5105, %true_block2135 ], [ %.1741345, %true_block2129 ], [ %.1741345, %after_if2119 ]
  %.174 = phi i1 [ true, %true_block2135 ], [ %.173, %true_block2129 ], [ %.173, %after_if2119 ]
  %5092 = icmp ugt i32 %201, 175
  %5093 = xor i1 %.174, true
  %spec.select2001 = select i1 %5092, i1 %5093, i1 false
  br i1 %spec.select2001, label %true_block2141, label %after_if2143

true_block2135:                                   ; preds = %true_block2129
  %getch.i2355 = getelementptr i8, i8* %12, i64 418612680
  %5094 = getelementptr inbounds i8, i8* %getch.i2355, i64 %5080
  %5095 = bitcast i8* %5094 to double*
  %5096 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5095, i32 64)
  %5097 = getelementptr inbounds i8, i8* %getch.i2355, i64 %5086
  %5098 = bitcast i8* %5097 to double*
  %5099 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5098, i32 64)
  %5100 = fsub reassoc ninf nsz double %5099, %5096
  %5101 = fsub reassoc ninf nsz double %5089, %5083
  %5102 = fsub reassoc ninf nsz double %175, %5083
  %5103 = fmul reassoc ninf nsz double %5100, %5102
  %5104 = fdiv reassoc ninf nsz double %5103, %5101
  %5105 = fadd reassoc ninf nsz double %5104, %5096
  br label %after_if2131

true_block2141:                                   ; preds = %after_if2131
  %5106 = add i32 %180, 175
  %5107 = sext i32 %5106 to i64
  %5108 = shl nsw i64 %5107, 3
  %5109 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5108
  %5110 = bitcast i8* %5109 to double*
  %5111 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5110, i32 64)
  %5112 = add i32 %180, 176
  %5113 = sext i32 %5112 to i64
  %5114 = shl nsw i64 %5113, 3
  %5115 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5114
  %5116 = bitcast i8* %5115 to double*
  %5117 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5116, i32 64)
  %5118 = fcmp reassoc ninf nsz oge double %175, %5111
  %5119 = fcmp reassoc ninf nsz ole double %175, %5117
  %.0817 = select i1 %5118, i1 %5119, i1 false
  br i1 %.0817, label %true_block2147, label %after_if2143

after_if2143:                                     ; preds = %true_block2147, %true_block2141, %after_if2131
  %.1761347 = phi double [ %5133, %true_block2147 ], [ %.1751346, %true_block2141 ], [ %.1751346, %after_if2131 ]
  %.175 = phi i1 [ true, %true_block2147 ], [ %.174, %true_block2141 ], [ %.174, %after_if2131 ]
  %5120 = icmp ugt i32 %201, 176
  %5121 = xor i1 %.175, true
  %spec.select2002 = select i1 %5120, i1 %5121, i1 false
  br i1 %spec.select2002, label %true_block2153, label %after_if2155

true_block2147:                                   ; preds = %true_block2141
  %getch.i2354 = getelementptr i8, i8* %12, i64 418612680
  %5122 = getelementptr inbounds i8, i8* %getch.i2354, i64 %5108
  %5123 = bitcast i8* %5122 to double*
  %5124 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5123, i32 64)
  %5125 = getelementptr inbounds i8, i8* %getch.i2354, i64 %5114
  %5126 = bitcast i8* %5125 to double*
  %5127 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5126, i32 64)
  %5128 = fsub reassoc ninf nsz double %5127, %5124
  %5129 = fsub reassoc ninf nsz double %5117, %5111
  %5130 = fsub reassoc ninf nsz double %175, %5111
  %5131 = fmul reassoc ninf nsz double %5128, %5130
  %5132 = fdiv reassoc ninf nsz double %5131, %5129
  %5133 = fadd reassoc ninf nsz double %5132, %5124
  br label %after_if2143

true_block2153:                                   ; preds = %after_if2143
  %5134 = add i32 %180, 176
  %5135 = sext i32 %5134 to i64
  %5136 = shl nsw i64 %5135, 3
  %5137 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5136
  %5138 = bitcast i8* %5137 to double*
  %5139 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5138, i32 64)
  %5140 = add i32 %180, 177
  %5141 = sext i32 %5140 to i64
  %5142 = shl nsw i64 %5141, 3
  %5143 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5142
  %5144 = bitcast i8* %5143 to double*
  %5145 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5144, i32 64)
  %5146 = fcmp reassoc ninf nsz oge double %175, %5139
  %5147 = fcmp reassoc ninf nsz ole double %175, %5145
  %.0815 = select i1 %5146, i1 %5147, i1 false
  br i1 %.0815, label %true_block2159, label %after_if2155

after_if2155:                                     ; preds = %true_block2159, %true_block2153, %after_if2143
  %.1771348 = phi double [ %5161, %true_block2159 ], [ %.1761347, %true_block2153 ], [ %.1761347, %after_if2143 ]
  %.176 = phi i1 [ true, %true_block2159 ], [ %.175, %true_block2153 ], [ %.175, %after_if2143 ]
  %5148 = icmp ugt i32 %201, 177
  %5149 = xor i1 %.176, true
  %spec.select2003 = select i1 %5148, i1 %5149, i1 false
  br i1 %spec.select2003, label %true_block2165, label %after_if2167

true_block2159:                                   ; preds = %true_block2153
  %getch.i2353 = getelementptr i8, i8* %12, i64 418612680
  %5150 = getelementptr inbounds i8, i8* %getch.i2353, i64 %5136
  %5151 = bitcast i8* %5150 to double*
  %5152 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5151, i32 64)
  %5153 = getelementptr inbounds i8, i8* %getch.i2353, i64 %5142
  %5154 = bitcast i8* %5153 to double*
  %5155 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5154, i32 64)
  %5156 = fsub reassoc ninf nsz double %5155, %5152
  %5157 = fsub reassoc ninf nsz double %5145, %5139
  %5158 = fsub reassoc ninf nsz double %175, %5139
  %5159 = fmul reassoc ninf nsz double %5156, %5158
  %5160 = fdiv reassoc ninf nsz double %5159, %5157
  %5161 = fadd reassoc ninf nsz double %5160, %5152
  br label %after_if2155

true_block2165:                                   ; preds = %after_if2155
  %5162 = add i32 %180, 177
  %5163 = sext i32 %5162 to i64
  %5164 = shl nsw i64 %5163, 3
  %5165 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5164
  %5166 = bitcast i8* %5165 to double*
  %5167 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5166, i32 64)
  %5168 = add i32 %180, 178
  %5169 = sext i32 %5168 to i64
  %5170 = shl nsw i64 %5169, 3
  %5171 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5170
  %5172 = bitcast i8* %5171 to double*
  %5173 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5172, i32 64)
  %5174 = fcmp reassoc ninf nsz oge double %175, %5167
  %5175 = fcmp reassoc ninf nsz ole double %175, %5173
  %.0813 = select i1 %5174, i1 %5175, i1 false
  br i1 %.0813, label %true_block2171, label %after_if2167

after_if2167:                                     ; preds = %true_block2171, %true_block2165, %after_if2155
  %.1781349 = phi double [ %5189, %true_block2171 ], [ %.1771348, %true_block2165 ], [ %.1771348, %after_if2155 ]
  %.177 = phi i1 [ true, %true_block2171 ], [ %.176, %true_block2165 ], [ %.176, %after_if2155 ]
  %5176 = icmp ugt i32 %201, 178
  %5177 = xor i1 %.177, true
  %spec.select2004 = select i1 %5176, i1 %5177, i1 false
  br i1 %spec.select2004, label %true_block2177, label %after_if2179

true_block2171:                                   ; preds = %true_block2165
  %getch.i2352 = getelementptr i8, i8* %12, i64 418612680
  %5178 = getelementptr inbounds i8, i8* %getch.i2352, i64 %5164
  %5179 = bitcast i8* %5178 to double*
  %5180 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5179, i32 64)
  %5181 = getelementptr inbounds i8, i8* %getch.i2352, i64 %5170
  %5182 = bitcast i8* %5181 to double*
  %5183 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5182, i32 64)
  %5184 = fsub reassoc ninf nsz double %5183, %5180
  %5185 = fsub reassoc ninf nsz double %5173, %5167
  %5186 = fsub reassoc ninf nsz double %175, %5167
  %5187 = fmul reassoc ninf nsz double %5184, %5186
  %5188 = fdiv reassoc ninf nsz double %5187, %5185
  %5189 = fadd reassoc ninf nsz double %5188, %5180
  br label %after_if2167

true_block2177:                                   ; preds = %after_if2167
  %5190 = add i32 %180, 178
  %5191 = sext i32 %5190 to i64
  %5192 = shl nsw i64 %5191, 3
  %5193 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5192
  %5194 = bitcast i8* %5193 to double*
  %5195 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5194, i32 64)
  %5196 = add i32 %180, 179
  %5197 = sext i32 %5196 to i64
  %5198 = shl nsw i64 %5197, 3
  %5199 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5198
  %5200 = bitcast i8* %5199 to double*
  %5201 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5200, i32 64)
  %5202 = fcmp reassoc ninf nsz oge double %175, %5195
  %5203 = fcmp reassoc ninf nsz ole double %175, %5201
  %.0811 = select i1 %5202, i1 %5203, i1 false
  br i1 %.0811, label %true_block2183, label %after_if2179

after_if2179:                                     ; preds = %true_block2183, %true_block2177, %after_if2167
  %.1791350 = phi double [ %5217, %true_block2183 ], [ %.1781349, %true_block2177 ], [ %.1781349, %after_if2167 ]
  %.178 = phi i1 [ true, %true_block2183 ], [ %.177, %true_block2177 ], [ %.177, %after_if2167 ]
  %5204 = icmp ugt i32 %201, 179
  %5205 = xor i1 %.178, true
  %spec.select2005 = select i1 %5204, i1 %5205, i1 false
  br i1 %spec.select2005, label %true_block2189, label %after_if2191

true_block2183:                                   ; preds = %true_block2177
  %getch.i2351 = getelementptr i8, i8* %12, i64 418612680
  %5206 = getelementptr inbounds i8, i8* %getch.i2351, i64 %5192
  %5207 = bitcast i8* %5206 to double*
  %5208 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5207, i32 64)
  %5209 = getelementptr inbounds i8, i8* %getch.i2351, i64 %5198
  %5210 = bitcast i8* %5209 to double*
  %5211 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5210, i32 64)
  %5212 = fsub reassoc ninf nsz double %5211, %5208
  %5213 = fsub reassoc ninf nsz double %5201, %5195
  %5214 = fsub reassoc ninf nsz double %175, %5195
  %5215 = fmul reassoc ninf nsz double %5212, %5214
  %5216 = fdiv reassoc ninf nsz double %5215, %5213
  %5217 = fadd reassoc ninf nsz double %5216, %5208
  br label %after_if2179

true_block2189:                                   ; preds = %after_if2179
  %5218 = add i32 %180, 179
  %5219 = sext i32 %5218 to i64
  %5220 = shl nsw i64 %5219, 3
  %5221 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5220
  %5222 = bitcast i8* %5221 to double*
  %5223 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5222, i32 64)
  %5224 = add i32 %180, 180
  %5225 = sext i32 %5224 to i64
  %5226 = shl nsw i64 %5225, 3
  %5227 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5226
  %5228 = bitcast i8* %5227 to double*
  %5229 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5228, i32 64)
  %5230 = fcmp reassoc ninf nsz oge double %175, %5223
  %5231 = fcmp reassoc ninf nsz ole double %175, %5229
  %.0809 = select i1 %5230, i1 %5231, i1 false
  br i1 %.0809, label %true_block2195, label %after_if2191

after_if2191:                                     ; preds = %true_block2195, %true_block2189, %after_if2179
  %.1801351 = phi double [ %5245, %true_block2195 ], [ %.1791350, %true_block2189 ], [ %.1791350, %after_if2179 ]
  %.179 = phi i1 [ true, %true_block2195 ], [ %.178, %true_block2189 ], [ %.178, %after_if2179 ]
  %5232 = icmp ugt i32 %201, 180
  %5233 = xor i1 %.179, true
  %spec.select2006 = select i1 %5232, i1 %5233, i1 false
  br i1 %spec.select2006, label %true_block2201, label %after_if2203

true_block2195:                                   ; preds = %true_block2189
  %getch.i2350 = getelementptr i8, i8* %12, i64 418612680
  %5234 = getelementptr inbounds i8, i8* %getch.i2350, i64 %5220
  %5235 = bitcast i8* %5234 to double*
  %5236 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5235, i32 64)
  %5237 = getelementptr inbounds i8, i8* %getch.i2350, i64 %5226
  %5238 = bitcast i8* %5237 to double*
  %5239 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5238, i32 64)
  %5240 = fsub reassoc ninf nsz double %5239, %5236
  %5241 = fsub reassoc ninf nsz double %5229, %5223
  %5242 = fsub reassoc ninf nsz double %175, %5223
  %5243 = fmul reassoc ninf nsz double %5240, %5242
  %5244 = fdiv reassoc ninf nsz double %5243, %5241
  %5245 = fadd reassoc ninf nsz double %5244, %5236
  br label %after_if2191

true_block2201:                                   ; preds = %after_if2191
  %5246 = add i32 %180, 180
  %5247 = sext i32 %5246 to i64
  %5248 = shl nsw i64 %5247, 3
  %5249 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5248
  %5250 = bitcast i8* %5249 to double*
  %5251 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5250, i32 64)
  %5252 = add i32 %180, 181
  %5253 = sext i32 %5252 to i64
  %5254 = shl nsw i64 %5253, 3
  %5255 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5254
  %5256 = bitcast i8* %5255 to double*
  %5257 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5256, i32 64)
  %5258 = fcmp reassoc ninf nsz oge double %175, %5251
  %5259 = fcmp reassoc ninf nsz ole double %175, %5257
  %.0807 = select i1 %5258, i1 %5259, i1 false
  br i1 %.0807, label %true_block2207, label %after_if2203

after_if2203:                                     ; preds = %true_block2207, %true_block2201, %after_if2191
  %.1811352 = phi double [ %5273, %true_block2207 ], [ %.1801351, %true_block2201 ], [ %.1801351, %after_if2191 ]
  %.180 = phi i1 [ true, %true_block2207 ], [ %.179, %true_block2201 ], [ %.179, %after_if2191 ]
  %5260 = icmp ugt i32 %201, 181
  %5261 = xor i1 %.180, true
  %spec.select2007 = select i1 %5260, i1 %5261, i1 false
  br i1 %spec.select2007, label %true_block2213, label %after_if2215

true_block2207:                                   ; preds = %true_block2201
  %getch.i2349 = getelementptr i8, i8* %12, i64 418612680
  %5262 = getelementptr inbounds i8, i8* %getch.i2349, i64 %5248
  %5263 = bitcast i8* %5262 to double*
  %5264 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5263, i32 64)
  %5265 = getelementptr inbounds i8, i8* %getch.i2349, i64 %5254
  %5266 = bitcast i8* %5265 to double*
  %5267 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5266, i32 64)
  %5268 = fsub reassoc ninf nsz double %5267, %5264
  %5269 = fsub reassoc ninf nsz double %5257, %5251
  %5270 = fsub reassoc ninf nsz double %175, %5251
  %5271 = fmul reassoc ninf nsz double %5268, %5270
  %5272 = fdiv reassoc ninf nsz double %5271, %5269
  %5273 = fadd reassoc ninf nsz double %5272, %5264
  br label %after_if2203

true_block2213:                                   ; preds = %after_if2203
  %5274 = add i32 %180, 181
  %5275 = sext i32 %5274 to i64
  %5276 = shl nsw i64 %5275, 3
  %5277 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5276
  %5278 = bitcast i8* %5277 to double*
  %5279 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5278, i32 64)
  %5280 = add i32 %180, 182
  %5281 = sext i32 %5280 to i64
  %5282 = shl nsw i64 %5281, 3
  %5283 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5282
  %5284 = bitcast i8* %5283 to double*
  %5285 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5284, i32 64)
  %5286 = fcmp reassoc ninf nsz oge double %175, %5279
  %5287 = fcmp reassoc ninf nsz ole double %175, %5285
  %.0805 = select i1 %5286, i1 %5287, i1 false
  br i1 %.0805, label %true_block2219, label %after_if2215

after_if2215:                                     ; preds = %true_block2219, %true_block2213, %after_if2203
  %.1821353 = phi double [ %5301, %true_block2219 ], [ %.1811352, %true_block2213 ], [ %.1811352, %after_if2203 ]
  %.181 = phi i1 [ true, %true_block2219 ], [ %.180, %true_block2213 ], [ %.180, %after_if2203 ]
  %5288 = icmp ugt i32 %201, 182
  %5289 = xor i1 %.181, true
  %spec.select2008 = select i1 %5288, i1 %5289, i1 false
  br i1 %spec.select2008, label %true_block2225, label %after_if2227

true_block2219:                                   ; preds = %true_block2213
  %getch.i2348 = getelementptr i8, i8* %12, i64 418612680
  %5290 = getelementptr inbounds i8, i8* %getch.i2348, i64 %5276
  %5291 = bitcast i8* %5290 to double*
  %5292 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5291, i32 64)
  %5293 = getelementptr inbounds i8, i8* %getch.i2348, i64 %5282
  %5294 = bitcast i8* %5293 to double*
  %5295 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5294, i32 64)
  %5296 = fsub reassoc ninf nsz double %5295, %5292
  %5297 = fsub reassoc ninf nsz double %5285, %5279
  %5298 = fsub reassoc ninf nsz double %175, %5279
  %5299 = fmul reassoc ninf nsz double %5296, %5298
  %5300 = fdiv reassoc ninf nsz double %5299, %5297
  %5301 = fadd reassoc ninf nsz double %5300, %5292
  br label %after_if2215

true_block2225:                                   ; preds = %after_if2215
  %5302 = add i32 %180, 182
  %5303 = sext i32 %5302 to i64
  %5304 = shl nsw i64 %5303, 3
  %5305 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5304
  %5306 = bitcast i8* %5305 to double*
  %5307 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5306, i32 64)
  %5308 = add i32 %180, 183
  %5309 = sext i32 %5308 to i64
  %5310 = shl nsw i64 %5309, 3
  %5311 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5310
  %5312 = bitcast i8* %5311 to double*
  %5313 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5312, i32 64)
  %5314 = fcmp reassoc ninf nsz oge double %175, %5307
  %5315 = fcmp reassoc ninf nsz ole double %175, %5313
  %.0803 = select i1 %5314, i1 %5315, i1 false
  br i1 %.0803, label %true_block2231, label %after_if2227

after_if2227:                                     ; preds = %true_block2231, %true_block2225, %after_if2215
  %.1831354 = phi double [ %5329, %true_block2231 ], [ %.1821353, %true_block2225 ], [ %.1821353, %after_if2215 ]
  %.182 = phi i1 [ true, %true_block2231 ], [ %.181, %true_block2225 ], [ %.181, %after_if2215 ]
  %5316 = icmp ugt i32 %201, 183
  %5317 = xor i1 %.182, true
  %spec.select2009 = select i1 %5316, i1 %5317, i1 false
  br i1 %spec.select2009, label %true_block2237, label %after_if2239

true_block2231:                                   ; preds = %true_block2225
  %getch.i2347 = getelementptr i8, i8* %12, i64 418612680
  %5318 = getelementptr inbounds i8, i8* %getch.i2347, i64 %5304
  %5319 = bitcast i8* %5318 to double*
  %5320 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5319, i32 64)
  %5321 = getelementptr inbounds i8, i8* %getch.i2347, i64 %5310
  %5322 = bitcast i8* %5321 to double*
  %5323 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5322, i32 64)
  %5324 = fsub reassoc ninf nsz double %5323, %5320
  %5325 = fsub reassoc ninf nsz double %5313, %5307
  %5326 = fsub reassoc ninf nsz double %175, %5307
  %5327 = fmul reassoc ninf nsz double %5324, %5326
  %5328 = fdiv reassoc ninf nsz double %5327, %5325
  %5329 = fadd reassoc ninf nsz double %5328, %5320
  br label %after_if2227

true_block2237:                                   ; preds = %after_if2227
  %5330 = add i32 %180, 183
  %5331 = sext i32 %5330 to i64
  %5332 = shl nsw i64 %5331, 3
  %5333 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5332
  %5334 = bitcast i8* %5333 to double*
  %5335 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5334, i32 64)
  %5336 = add i32 %180, 184
  %5337 = sext i32 %5336 to i64
  %5338 = shl nsw i64 %5337, 3
  %5339 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5338
  %5340 = bitcast i8* %5339 to double*
  %5341 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5340, i32 64)
  %5342 = fcmp reassoc ninf nsz oge double %175, %5335
  %5343 = fcmp reassoc ninf nsz ole double %175, %5341
  %.0801 = select i1 %5342, i1 %5343, i1 false
  br i1 %.0801, label %true_block2243, label %after_if2239

after_if2239:                                     ; preds = %true_block2243, %true_block2237, %after_if2227
  %.1841355 = phi double [ %5357, %true_block2243 ], [ %.1831354, %true_block2237 ], [ %.1831354, %after_if2227 ]
  %.183 = phi i1 [ true, %true_block2243 ], [ %.182, %true_block2237 ], [ %.182, %after_if2227 ]
  %5344 = icmp ugt i32 %201, 184
  %5345 = xor i1 %.183, true
  %spec.select2010 = select i1 %5344, i1 %5345, i1 false
  br i1 %spec.select2010, label %true_block2249, label %after_if2251

true_block2243:                                   ; preds = %true_block2237
  %getch.i2346 = getelementptr i8, i8* %12, i64 418612680
  %5346 = getelementptr inbounds i8, i8* %getch.i2346, i64 %5332
  %5347 = bitcast i8* %5346 to double*
  %5348 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5347, i32 64)
  %5349 = getelementptr inbounds i8, i8* %getch.i2346, i64 %5338
  %5350 = bitcast i8* %5349 to double*
  %5351 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5350, i32 64)
  %5352 = fsub reassoc ninf nsz double %5351, %5348
  %5353 = fsub reassoc ninf nsz double %5341, %5335
  %5354 = fsub reassoc ninf nsz double %175, %5335
  %5355 = fmul reassoc ninf nsz double %5352, %5354
  %5356 = fdiv reassoc ninf nsz double %5355, %5353
  %5357 = fadd reassoc ninf nsz double %5356, %5348
  br label %after_if2239

true_block2249:                                   ; preds = %after_if2239
  %5358 = add i32 %180, 184
  %5359 = sext i32 %5358 to i64
  %5360 = shl nsw i64 %5359, 3
  %5361 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5360
  %5362 = bitcast i8* %5361 to double*
  %5363 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5362, i32 64)
  %5364 = add i32 %180, 185
  %5365 = sext i32 %5364 to i64
  %5366 = shl nsw i64 %5365, 3
  %5367 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5366
  %5368 = bitcast i8* %5367 to double*
  %5369 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5368, i32 64)
  %5370 = fcmp reassoc ninf nsz oge double %175, %5363
  %5371 = fcmp reassoc ninf nsz ole double %175, %5369
  %.0799 = select i1 %5370, i1 %5371, i1 false
  br i1 %.0799, label %true_block2255, label %after_if2251

after_if2251:                                     ; preds = %true_block2255, %true_block2249, %after_if2239
  %.1851356 = phi double [ %5385, %true_block2255 ], [ %.1841355, %true_block2249 ], [ %.1841355, %after_if2239 ]
  %.184 = phi i1 [ true, %true_block2255 ], [ %.183, %true_block2249 ], [ %.183, %after_if2239 ]
  %5372 = icmp ugt i32 %201, 185
  %5373 = xor i1 %.184, true
  %spec.select2011 = select i1 %5372, i1 %5373, i1 false
  br i1 %spec.select2011, label %true_block2261, label %after_if2263

true_block2255:                                   ; preds = %true_block2249
  %getch.i2345 = getelementptr i8, i8* %12, i64 418612680
  %5374 = getelementptr inbounds i8, i8* %getch.i2345, i64 %5360
  %5375 = bitcast i8* %5374 to double*
  %5376 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5375, i32 64)
  %5377 = getelementptr inbounds i8, i8* %getch.i2345, i64 %5366
  %5378 = bitcast i8* %5377 to double*
  %5379 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5378, i32 64)
  %5380 = fsub reassoc ninf nsz double %5379, %5376
  %5381 = fsub reassoc ninf nsz double %5369, %5363
  %5382 = fsub reassoc ninf nsz double %175, %5363
  %5383 = fmul reassoc ninf nsz double %5380, %5382
  %5384 = fdiv reassoc ninf nsz double %5383, %5381
  %5385 = fadd reassoc ninf nsz double %5384, %5376
  br label %after_if2251

true_block2261:                                   ; preds = %after_if2251
  %5386 = add i32 %180, 185
  %5387 = sext i32 %5386 to i64
  %5388 = shl nsw i64 %5387, 3
  %5389 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5388
  %5390 = bitcast i8* %5389 to double*
  %5391 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5390, i32 64)
  %5392 = add i32 %180, 186
  %5393 = sext i32 %5392 to i64
  %5394 = shl nsw i64 %5393, 3
  %5395 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5394
  %5396 = bitcast i8* %5395 to double*
  %5397 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5396, i32 64)
  %5398 = fcmp reassoc ninf nsz oge double %175, %5391
  %5399 = fcmp reassoc ninf nsz ole double %175, %5397
  %.0797 = select i1 %5398, i1 %5399, i1 false
  br i1 %.0797, label %true_block2267, label %after_if2263

after_if2263:                                     ; preds = %true_block2267, %true_block2261, %after_if2251
  %.1861357 = phi double [ %5413, %true_block2267 ], [ %.1851356, %true_block2261 ], [ %.1851356, %after_if2251 ]
  %.185 = phi i1 [ true, %true_block2267 ], [ %.184, %true_block2261 ], [ %.184, %after_if2251 ]
  %5400 = icmp ugt i32 %201, 186
  %5401 = xor i1 %.185, true
  %spec.select2012 = select i1 %5400, i1 %5401, i1 false
  br i1 %spec.select2012, label %true_block2273, label %after_if2275

true_block2267:                                   ; preds = %true_block2261
  %getch.i2344 = getelementptr i8, i8* %12, i64 418612680
  %5402 = getelementptr inbounds i8, i8* %getch.i2344, i64 %5388
  %5403 = bitcast i8* %5402 to double*
  %5404 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5403, i32 64)
  %5405 = getelementptr inbounds i8, i8* %getch.i2344, i64 %5394
  %5406 = bitcast i8* %5405 to double*
  %5407 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5406, i32 64)
  %5408 = fsub reassoc ninf nsz double %5407, %5404
  %5409 = fsub reassoc ninf nsz double %5397, %5391
  %5410 = fsub reassoc ninf nsz double %175, %5391
  %5411 = fmul reassoc ninf nsz double %5408, %5410
  %5412 = fdiv reassoc ninf nsz double %5411, %5409
  %5413 = fadd reassoc ninf nsz double %5412, %5404
  br label %after_if2263

true_block2273:                                   ; preds = %after_if2263
  %5414 = add i32 %180, 186
  %5415 = sext i32 %5414 to i64
  %5416 = shl nsw i64 %5415, 3
  %5417 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5416
  %5418 = bitcast i8* %5417 to double*
  %5419 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5418, i32 64)
  %5420 = add i32 %180, 187
  %5421 = sext i32 %5420 to i64
  %5422 = shl nsw i64 %5421, 3
  %5423 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5422
  %5424 = bitcast i8* %5423 to double*
  %5425 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5424, i32 64)
  %5426 = fcmp reassoc ninf nsz oge double %175, %5419
  %5427 = fcmp reassoc ninf nsz ole double %175, %5425
  %.0795 = select i1 %5426, i1 %5427, i1 false
  br i1 %.0795, label %true_block2279, label %after_if2275

after_if2275:                                     ; preds = %true_block2279, %true_block2273, %after_if2263
  %.1871358 = phi double [ %5441, %true_block2279 ], [ %.1861357, %true_block2273 ], [ %.1861357, %after_if2263 ]
  %.186 = phi i1 [ true, %true_block2279 ], [ %.185, %true_block2273 ], [ %.185, %after_if2263 ]
  %5428 = icmp ugt i32 %201, 187
  %5429 = xor i1 %.186, true
  %spec.select2013 = select i1 %5428, i1 %5429, i1 false
  br i1 %spec.select2013, label %true_block2285, label %after_if2287

true_block2279:                                   ; preds = %true_block2273
  %getch.i2343 = getelementptr i8, i8* %12, i64 418612680
  %5430 = getelementptr inbounds i8, i8* %getch.i2343, i64 %5416
  %5431 = bitcast i8* %5430 to double*
  %5432 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5431, i32 64)
  %5433 = getelementptr inbounds i8, i8* %getch.i2343, i64 %5422
  %5434 = bitcast i8* %5433 to double*
  %5435 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5434, i32 64)
  %5436 = fsub reassoc ninf nsz double %5435, %5432
  %5437 = fsub reassoc ninf nsz double %5425, %5419
  %5438 = fsub reassoc ninf nsz double %175, %5419
  %5439 = fmul reassoc ninf nsz double %5436, %5438
  %5440 = fdiv reassoc ninf nsz double %5439, %5437
  %5441 = fadd reassoc ninf nsz double %5440, %5432
  br label %after_if2275

true_block2285:                                   ; preds = %after_if2275
  %5442 = add i32 %180, 187
  %5443 = sext i32 %5442 to i64
  %5444 = shl nsw i64 %5443, 3
  %5445 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5444
  %5446 = bitcast i8* %5445 to double*
  %5447 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5446, i32 64)
  %5448 = add i32 %180, 188
  %5449 = sext i32 %5448 to i64
  %5450 = shl nsw i64 %5449, 3
  %5451 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5450
  %5452 = bitcast i8* %5451 to double*
  %5453 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5452, i32 64)
  %5454 = fcmp reassoc ninf nsz oge double %175, %5447
  %5455 = fcmp reassoc ninf nsz ole double %175, %5453
  %.0793 = select i1 %5454, i1 %5455, i1 false
  br i1 %.0793, label %true_block2291, label %after_if2287

after_if2287:                                     ; preds = %true_block2291, %true_block2285, %after_if2275
  %.1881359 = phi double [ %5469, %true_block2291 ], [ %.1871358, %true_block2285 ], [ %.1871358, %after_if2275 ]
  %.187 = phi i1 [ true, %true_block2291 ], [ %.186, %true_block2285 ], [ %.186, %after_if2275 ]
  %5456 = icmp ugt i32 %201, 188
  %5457 = xor i1 %.187, true
  %spec.select2014 = select i1 %5456, i1 %5457, i1 false
  br i1 %spec.select2014, label %true_block2297, label %after_if2299

true_block2291:                                   ; preds = %true_block2285
  %getch.i2342 = getelementptr i8, i8* %12, i64 418612680
  %5458 = getelementptr inbounds i8, i8* %getch.i2342, i64 %5444
  %5459 = bitcast i8* %5458 to double*
  %5460 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5459, i32 64)
  %5461 = getelementptr inbounds i8, i8* %getch.i2342, i64 %5450
  %5462 = bitcast i8* %5461 to double*
  %5463 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5462, i32 64)
  %5464 = fsub reassoc ninf nsz double %5463, %5460
  %5465 = fsub reassoc ninf nsz double %5453, %5447
  %5466 = fsub reassoc ninf nsz double %175, %5447
  %5467 = fmul reassoc ninf nsz double %5464, %5466
  %5468 = fdiv reassoc ninf nsz double %5467, %5465
  %5469 = fadd reassoc ninf nsz double %5468, %5460
  br label %after_if2287

true_block2297:                                   ; preds = %after_if2287
  %5470 = add i32 %180, 188
  %5471 = sext i32 %5470 to i64
  %5472 = shl nsw i64 %5471, 3
  %5473 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5472
  %5474 = bitcast i8* %5473 to double*
  %5475 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5474, i32 64)
  %5476 = add i32 %180, 189
  %5477 = sext i32 %5476 to i64
  %5478 = shl nsw i64 %5477, 3
  %5479 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5478
  %5480 = bitcast i8* %5479 to double*
  %5481 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5480, i32 64)
  %5482 = fcmp reassoc ninf nsz oge double %175, %5475
  %5483 = fcmp reassoc ninf nsz ole double %175, %5481
  %.0791 = select i1 %5482, i1 %5483, i1 false
  br i1 %.0791, label %true_block2303, label %after_if2299

after_if2299:                                     ; preds = %true_block2303, %true_block2297, %after_if2287
  %.1891360 = phi double [ %5497, %true_block2303 ], [ %.1881359, %true_block2297 ], [ %.1881359, %after_if2287 ]
  %.188 = phi i1 [ true, %true_block2303 ], [ %.187, %true_block2297 ], [ %.187, %after_if2287 ]
  %5484 = icmp ugt i32 %201, 189
  %5485 = xor i1 %.188, true
  %spec.select2015 = select i1 %5484, i1 %5485, i1 false
  br i1 %spec.select2015, label %true_block2309, label %after_if2311

true_block2303:                                   ; preds = %true_block2297
  %getch.i2341 = getelementptr i8, i8* %12, i64 418612680
  %5486 = getelementptr inbounds i8, i8* %getch.i2341, i64 %5472
  %5487 = bitcast i8* %5486 to double*
  %5488 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5487, i32 64)
  %5489 = getelementptr inbounds i8, i8* %getch.i2341, i64 %5478
  %5490 = bitcast i8* %5489 to double*
  %5491 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5490, i32 64)
  %5492 = fsub reassoc ninf nsz double %5491, %5488
  %5493 = fsub reassoc ninf nsz double %5481, %5475
  %5494 = fsub reassoc ninf nsz double %175, %5475
  %5495 = fmul reassoc ninf nsz double %5492, %5494
  %5496 = fdiv reassoc ninf nsz double %5495, %5493
  %5497 = fadd reassoc ninf nsz double %5496, %5488
  br label %after_if2299

true_block2309:                                   ; preds = %after_if2299
  %5498 = add i32 %180, 189
  %5499 = sext i32 %5498 to i64
  %5500 = shl nsw i64 %5499, 3
  %5501 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5500
  %5502 = bitcast i8* %5501 to double*
  %5503 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5502, i32 64)
  %5504 = add i32 %180, 190
  %5505 = sext i32 %5504 to i64
  %5506 = shl nsw i64 %5505, 3
  %5507 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5506
  %5508 = bitcast i8* %5507 to double*
  %5509 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5508, i32 64)
  %5510 = fcmp reassoc ninf nsz oge double %175, %5503
  %5511 = fcmp reassoc ninf nsz ole double %175, %5509
  %.0789 = select i1 %5510, i1 %5511, i1 false
  br i1 %.0789, label %true_block2315, label %after_if2311

after_if2311:                                     ; preds = %true_block2315, %true_block2309, %after_if2299
  %.1901361 = phi double [ %5525, %true_block2315 ], [ %.1891360, %true_block2309 ], [ %.1891360, %after_if2299 ]
  %.189 = phi i1 [ true, %true_block2315 ], [ %.188, %true_block2309 ], [ %.188, %after_if2299 ]
  %5512 = icmp ugt i32 %201, 190
  %5513 = xor i1 %.189, true
  %spec.select2016 = select i1 %5512, i1 %5513, i1 false
  br i1 %spec.select2016, label %true_block2321, label %after_if2323

true_block2315:                                   ; preds = %true_block2309
  %getch.i2340 = getelementptr i8, i8* %12, i64 418612680
  %5514 = getelementptr inbounds i8, i8* %getch.i2340, i64 %5500
  %5515 = bitcast i8* %5514 to double*
  %5516 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5515, i32 64)
  %5517 = getelementptr inbounds i8, i8* %getch.i2340, i64 %5506
  %5518 = bitcast i8* %5517 to double*
  %5519 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5518, i32 64)
  %5520 = fsub reassoc ninf nsz double %5519, %5516
  %5521 = fsub reassoc ninf nsz double %5509, %5503
  %5522 = fsub reassoc ninf nsz double %175, %5503
  %5523 = fmul reassoc ninf nsz double %5520, %5522
  %5524 = fdiv reassoc ninf nsz double %5523, %5521
  %5525 = fadd reassoc ninf nsz double %5524, %5516
  br label %after_if2311

true_block2321:                                   ; preds = %after_if2311
  %5526 = add i32 %180, 190
  %5527 = sext i32 %5526 to i64
  %5528 = shl nsw i64 %5527, 3
  %5529 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5528
  %5530 = bitcast i8* %5529 to double*
  %5531 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5530, i32 64)
  %5532 = add i32 %180, 191
  %5533 = sext i32 %5532 to i64
  %5534 = shl nsw i64 %5533, 3
  %5535 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5534
  %5536 = bitcast i8* %5535 to double*
  %5537 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5536, i32 64)
  %5538 = fcmp reassoc ninf nsz oge double %175, %5531
  %5539 = fcmp reassoc ninf nsz ole double %175, %5537
  %.0787 = select i1 %5538, i1 %5539, i1 false
  br i1 %.0787, label %true_block2327, label %after_if2323

after_if2323:                                     ; preds = %true_block2327, %true_block2321, %after_if2311
  %.1911362 = phi double [ %5553, %true_block2327 ], [ %.1901361, %true_block2321 ], [ %.1901361, %after_if2311 ]
  %.190 = phi i1 [ true, %true_block2327 ], [ %.189, %true_block2321 ], [ %.189, %after_if2311 ]
  %5540 = icmp ugt i32 %201, 191
  %5541 = xor i1 %.190, true
  %spec.select2017 = select i1 %5540, i1 %5541, i1 false
  br i1 %spec.select2017, label %true_block2333, label %after_if2335

true_block2327:                                   ; preds = %true_block2321
  %getch.i2339 = getelementptr i8, i8* %12, i64 418612680
  %5542 = getelementptr inbounds i8, i8* %getch.i2339, i64 %5528
  %5543 = bitcast i8* %5542 to double*
  %5544 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5543, i32 64)
  %5545 = getelementptr inbounds i8, i8* %getch.i2339, i64 %5534
  %5546 = bitcast i8* %5545 to double*
  %5547 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5546, i32 64)
  %5548 = fsub reassoc ninf nsz double %5547, %5544
  %5549 = fsub reassoc ninf nsz double %5537, %5531
  %5550 = fsub reassoc ninf nsz double %175, %5531
  %5551 = fmul reassoc ninf nsz double %5548, %5550
  %5552 = fdiv reassoc ninf nsz double %5551, %5549
  %5553 = fadd reassoc ninf nsz double %5552, %5544
  br label %after_if2323

true_block2333:                                   ; preds = %after_if2323
  %5554 = add i32 %180, 191
  %5555 = sext i32 %5554 to i64
  %5556 = shl nsw i64 %5555, 3
  %5557 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5556
  %5558 = bitcast i8* %5557 to double*
  %5559 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5558, i32 64)
  %5560 = add i32 %180, 192
  %5561 = sext i32 %5560 to i64
  %5562 = shl nsw i64 %5561, 3
  %5563 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5562
  %5564 = bitcast i8* %5563 to double*
  %5565 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5564, i32 64)
  %5566 = fcmp reassoc ninf nsz oge double %175, %5559
  %5567 = fcmp reassoc ninf nsz ole double %175, %5565
  %.0785 = select i1 %5566, i1 %5567, i1 false
  br i1 %.0785, label %true_block2339, label %after_if2335

after_if2335:                                     ; preds = %true_block2339, %true_block2333, %after_if2323
  %.1921363 = phi double [ %5581, %true_block2339 ], [ %.1911362, %true_block2333 ], [ %.1911362, %after_if2323 ]
  %.191 = phi i1 [ true, %true_block2339 ], [ %.190, %true_block2333 ], [ %.190, %after_if2323 ]
  %5568 = icmp ugt i32 %201, 192
  %5569 = xor i1 %.191, true
  %spec.select2018 = select i1 %5568, i1 %5569, i1 false
  br i1 %spec.select2018, label %true_block2345, label %after_if2347

true_block2339:                                   ; preds = %true_block2333
  %getch.i2338 = getelementptr i8, i8* %12, i64 418612680
  %5570 = getelementptr inbounds i8, i8* %getch.i2338, i64 %5556
  %5571 = bitcast i8* %5570 to double*
  %5572 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5571, i32 64)
  %5573 = getelementptr inbounds i8, i8* %getch.i2338, i64 %5562
  %5574 = bitcast i8* %5573 to double*
  %5575 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5574, i32 64)
  %5576 = fsub reassoc ninf nsz double %5575, %5572
  %5577 = fsub reassoc ninf nsz double %5565, %5559
  %5578 = fsub reassoc ninf nsz double %175, %5559
  %5579 = fmul reassoc ninf nsz double %5576, %5578
  %5580 = fdiv reassoc ninf nsz double %5579, %5577
  %5581 = fadd reassoc ninf nsz double %5580, %5572
  br label %after_if2335

true_block2345:                                   ; preds = %after_if2335
  %5582 = add i32 %180, 192
  %5583 = sext i32 %5582 to i64
  %5584 = shl nsw i64 %5583, 3
  %5585 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5584
  %5586 = bitcast i8* %5585 to double*
  %5587 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5586, i32 64)
  %5588 = add i32 %180, 193
  %5589 = sext i32 %5588 to i64
  %5590 = shl nsw i64 %5589, 3
  %5591 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5590
  %5592 = bitcast i8* %5591 to double*
  %5593 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5592, i32 64)
  %5594 = fcmp reassoc ninf nsz oge double %175, %5587
  %5595 = fcmp reassoc ninf nsz ole double %175, %5593
  %.0783 = select i1 %5594, i1 %5595, i1 false
  br i1 %.0783, label %true_block2351, label %after_if2347

after_if2347:                                     ; preds = %true_block2351, %true_block2345, %after_if2335
  %.1931364 = phi double [ %5609, %true_block2351 ], [ %.1921363, %true_block2345 ], [ %.1921363, %after_if2335 ]
  %.192 = phi i1 [ true, %true_block2351 ], [ %.191, %true_block2345 ], [ %.191, %after_if2335 ]
  %5596 = icmp ugt i32 %201, 193
  %5597 = xor i1 %.192, true
  %spec.select2019 = select i1 %5596, i1 %5597, i1 false
  br i1 %spec.select2019, label %true_block2357, label %after_if2359

true_block2351:                                   ; preds = %true_block2345
  %getch.i2337 = getelementptr i8, i8* %12, i64 418612680
  %5598 = getelementptr inbounds i8, i8* %getch.i2337, i64 %5584
  %5599 = bitcast i8* %5598 to double*
  %5600 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5599, i32 64)
  %5601 = getelementptr inbounds i8, i8* %getch.i2337, i64 %5590
  %5602 = bitcast i8* %5601 to double*
  %5603 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5602, i32 64)
  %5604 = fsub reassoc ninf nsz double %5603, %5600
  %5605 = fsub reassoc ninf nsz double %5593, %5587
  %5606 = fsub reassoc ninf nsz double %175, %5587
  %5607 = fmul reassoc ninf nsz double %5604, %5606
  %5608 = fdiv reassoc ninf nsz double %5607, %5605
  %5609 = fadd reassoc ninf nsz double %5608, %5600
  br label %after_if2347

true_block2357:                                   ; preds = %after_if2347
  %5610 = add i32 %180, 193
  %5611 = sext i32 %5610 to i64
  %5612 = shl nsw i64 %5611, 3
  %5613 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5612
  %5614 = bitcast i8* %5613 to double*
  %5615 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5614, i32 64)
  %5616 = add i32 %180, 194
  %5617 = sext i32 %5616 to i64
  %5618 = shl nsw i64 %5617, 3
  %5619 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5618
  %5620 = bitcast i8* %5619 to double*
  %5621 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5620, i32 64)
  %5622 = fcmp reassoc ninf nsz oge double %175, %5615
  %5623 = fcmp reassoc ninf nsz ole double %175, %5621
  %.0781 = select i1 %5622, i1 %5623, i1 false
  br i1 %.0781, label %true_block2363, label %after_if2359

after_if2359:                                     ; preds = %true_block2363, %true_block2357, %after_if2347
  %.1941365 = phi double [ %5637, %true_block2363 ], [ %.1931364, %true_block2357 ], [ %.1931364, %after_if2347 ]
  %.193 = phi i1 [ true, %true_block2363 ], [ %.192, %true_block2357 ], [ %.192, %after_if2347 ]
  %5624 = icmp ugt i32 %201, 194
  %5625 = xor i1 %.193, true
  %spec.select2020 = select i1 %5624, i1 %5625, i1 false
  br i1 %spec.select2020, label %true_block2369, label %after_if2371

true_block2363:                                   ; preds = %true_block2357
  %getch.i2336 = getelementptr i8, i8* %12, i64 418612680
  %5626 = getelementptr inbounds i8, i8* %getch.i2336, i64 %5612
  %5627 = bitcast i8* %5626 to double*
  %5628 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5627, i32 64)
  %5629 = getelementptr inbounds i8, i8* %getch.i2336, i64 %5618
  %5630 = bitcast i8* %5629 to double*
  %5631 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5630, i32 64)
  %5632 = fsub reassoc ninf nsz double %5631, %5628
  %5633 = fsub reassoc ninf nsz double %5621, %5615
  %5634 = fsub reassoc ninf nsz double %175, %5615
  %5635 = fmul reassoc ninf nsz double %5632, %5634
  %5636 = fdiv reassoc ninf nsz double %5635, %5633
  %5637 = fadd reassoc ninf nsz double %5636, %5628
  br label %after_if2359

true_block2369:                                   ; preds = %after_if2359
  %5638 = add i32 %180, 194
  %5639 = sext i32 %5638 to i64
  %5640 = shl nsw i64 %5639, 3
  %5641 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5640
  %5642 = bitcast i8* %5641 to double*
  %5643 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5642, i32 64)
  %5644 = add i32 %180, 195
  %5645 = sext i32 %5644 to i64
  %5646 = shl nsw i64 %5645, 3
  %5647 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5646
  %5648 = bitcast i8* %5647 to double*
  %5649 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5648, i32 64)
  %5650 = fcmp reassoc ninf nsz oge double %175, %5643
  %5651 = fcmp reassoc ninf nsz ole double %175, %5649
  %.0779 = select i1 %5650, i1 %5651, i1 false
  br i1 %.0779, label %true_block2375, label %after_if2371

after_if2371:                                     ; preds = %true_block2375, %true_block2369, %after_if2359
  %.1951366 = phi double [ %5665, %true_block2375 ], [ %.1941365, %true_block2369 ], [ %.1941365, %after_if2359 ]
  %.194 = phi i1 [ true, %true_block2375 ], [ %.193, %true_block2369 ], [ %.193, %after_if2359 ]
  %5652 = icmp ugt i32 %201, 195
  %5653 = xor i1 %.194, true
  %spec.select2021 = select i1 %5652, i1 %5653, i1 false
  br i1 %spec.select2021, label %true_block2381, label %after_if2383

true_block2375:                                   ; preds = %true_block2369
  %getch.i2335 = getelementptr i8, i8* %12, i64 418612680
  %5654 = getelementptr inbounds i8, i8* %getch.i2335, i64 %5640
  %5655 = bitcast i8* %5654 to double*
  %5656 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5655, i32 64)
  %5657 = getelementptr inbounds i8, i8* %getch.i2335, i64 %5646
  %5658 = bitcast i8* %5657 to double*
  %5659 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5658, i32 64)
  %5660 = fsub reassoc ninf nsz double %5659, %5656
  %5661 = fsub reassoc ninf nsz double %5649, %5643
  %5662 = fsub reassoc ninf nsz double %175, %5643
  %5663 = fmul reassoc ninf nsz double %5660, %5662
  %5664 = fdiv reassoc ninf nsz double %5663, %5661
  %5665 = fadd reassoc ninf nsz double %5664, %5656
  br label %after_if2371

true_block2381:                                   ; preds = %after_if2371
  %5666 = add i32 %180, 195
  %5667 = sext i32 %5666 to i64
  %5668 = shl nsw i64 %5667, 3
  %5669 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5668
  %5670 = bitcast i8* %5669 to double*
  %5671 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5670, i32 64)
  %5672 = add i32 %180, 196
  %5673 = sext i32 %5672 to i64
  %5674 = shl nsw i64 %5673, 3
  %5675 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5674
  %5676 = bitcast i8* %5675 to double*
  %5677 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5676, i32 64)
  %5678 = fcmp reassoc ninf nsz oge double %175, %5671
  %5679 = fcmp reassoc ninf nsz ole double %175, %5677
  %.0777 = select i1 %5678, i1 %5679, i1 false
  br i1 %.0777, label %true_block2387, label %after_if2383

after_if2383:                                     ; preds = %true_block2387, %true_block2381, %after_if2371
  %.1961367 = phi double [ %5693, %true_block2387 ], [ %.1951366, %true_block2381 ], [ %.1951366, %after_if2371 ]
  %.195 = phi i1 [ true, %true_block2387 ], [ %.194, %true_block2381 ], [ %.194, %after_if2371 ]
  %5680 = icmp ugt i32 %201, 196
  %5681 = xor i1 %.195, true
  %spec.select2022 = select i1 %5680, i1 %5681, i1 false
  br i1 %spec.select2022, label %true_block2393, label %after_if2395

true_block2387:                                   ; preds = %true_block2381
  %getch.i2334 = getelementptr i8, i8* %12, i64 418612680
  %5682 = getelementptr inbounds i8, i8* %getch.i2334, i64 %5668
  %5683 = bitcast i8* %5682 to double*
  %5684 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5683, i32 64)
  %5685 = getelementptr inbounds i8, i8* %getch.i2334, i64 %5674
  %5686 = bitcast i8* %5685 to double*
  %5687 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5686, i32 64)
  %5688 = fsub reassoc ninf nsz double %5687, %5684
  %5689 = fsub reassoc ninf nsz double %5677, %5671
  %5690 = fsub reassoc ninf nsz double %175, %5671
  %5691 = fmul reassoc ninf nsz double %5688, %5690
  %5692 = fdiv reassoc ninf nsz double %5691, %5689
  %5693 = fadd reassoc ninf nsz double %5692, %5684
  br label %after_if2383

true_block2393:                                   ; preds = %after_if2383
  %5694 = add i32 %180, 196
  %5695 = sext i32 %5694 to i64
  %5696 = shl nsw i64 %5695, 3
  %5697 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5696
  %5698 = bitcast i8* %5697 to double*
  %5699 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5698, i32 64)
  %5700 = add i32 %180, 197
  %5701 = sext i32 %5700 to i64
  %5702 = shl nsw i64 %5701, 3
  %5703 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5702
  %5704 = bitcast i8* %5703 to double*
  %5705 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5704, i32 64)
  %5706 = fcmp reassoc ninf nsz oge double %175, %5699
  %5707 = fcmp reassoc ninf nsz ole double %175, %5705
  %.0775 = select i1 %5706, i1 %5707, i1 false
  br i1 %.0775, label %true_block2399, label %after_if2395

after_if2395:                                     ; preds = %true_block2399, %true_block2393, %after_if2383
  %.1971368 = phi double [ %5721, %true_block2399 ], [ %.1961367, %true_block2393 ], [ %.1961367, %after_if2383 ]
  %.196 = phi i1 [ true, %true_block2399 ], [ %.195, %true_block2393 ], [ %.195, %after_if2383 ]
  %5708 = icmp ugt i32 %201, 197
  %5709 = xor i1 %.196, true
  %spec.select2023 = select i1 %5708, i1 %5709, i1 false
  br i1 %spec.select2023, label %true_block2405, label %after_if2407

true_block2399:                                   ; preds = %true_block2393
  %getch.i2333 = getelementptr i8, i8* %12, i64 418612680
  %5710 = getelementptr inbounds i8, i8* %getch.i2333, i64 %5696
  %5711 = bitcast i8* %5710 to double*
  %5712 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5711, i32 64)
  %5713 = getelementptr inbounds i8, i8* %getch.i2333, i64 %5702
  %5714 = bitcast i8* %5713 to double*
  %5715 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5714, i32 64)
  %5716 = fsub reassoc ninf nsz double %5715, %5712
  %5717 = fsub reassoc ninf nsz double %5705, %5699
  %5718 = fsub reassoc ninf nsz double %175, %5699
  %5719 = fmul reassoc ninf nsz double %5716, %5718
  %5720 = fdiv reassoc ninf nsz double %5719, %5717
  %5721 = fadd reassoc ninf nsz double %5720, %5712
  br label %after_if2395

true_block2405:                                   ; preds = %after_if2395
  %5722 = add i32 %180, 197
  %5723 = sext i32 %5722 to i64
  %5724 = shl nsw i64 %5723, 3
  %5725 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5724
  %5726 = bitcast i8* %5725 to double*
  %5727 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5726, i32 64)
  %5728 = add i32 %180, 198
  %5729 = sext i32 %5728 to i64
  %5730 = shl nsw i64 %5729, 3
  %5731 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5730
  %5732 = bitcast i8* %5731 to double*
  %5733 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5732, i32 64)
  %5734 = fcmp reassoc ninf nsz oge double %175, %5727
  %5735 = fcmp reassoc ninf nsz ole double %175, %5733
  %.0773 = select i1 %5734, i1 %5735, i1 false
  br i1 %.0773, label %true_block2411, label %after_if2407

after_if2407:                                     ; preds = %true_block2411, %true_block2405, %after_if2395
  %.198 = phi double [ %5749, %true_block2411 ], [ %.1971368, %true_block2405 ], [ %.1971368, %after_if2395 ]
  %.197 = phi i1 [ true, %true_block2411 ], [ %.196, %true_block2405 ], [ %.196, %after_if2395 ]
  %5736 = icmp ugt i32 %201, 198
  %5737 = xor i1 %.197, true
  %.0772 = select i1 %5736, i1 %5737, i1 false
  br i1 %.0772, label %true_block2417, label %after_if31

true_block2411:                                   ; preds = %true_block2405
  %getch.i2332 = getelementptr i8, i8* %12, i64 418612680
  %5738 = getelementptr inbounds i8, i8* %getch.i2332, i64 %5724
  %5739 = bitcast i8* %5738 to double*
  %5740 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5739, i32 64)
  %5741 = getelementptr inbounds i8, i8* %getch.i2332, i64 %5730
  %5742 = bitcast i8* %5741 to double*
  %5743 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5742, i32 64)
  %5744 = fsub reassoc ninf nsz double %5743, %5740
  %5745 = fsub reassoc ninf nsz double %5733, %5727
  %5746 = fsub reassoc ninf nsz double %175, %5727
  %5747 = fmul reassoc ninf nsz double %5744, %5746
  %5748 = fdiv reassoc ninf nsz double %5747, %5745
  %5749 = fadd reassoc ninf nsz double %5748, %5740
  br label %after_if2407

true_block2417:                                   ; preds = %after_if2407
  %5750 = add i32 %180, 198
  %5751 = sext i32 %5750 to i64
  %5752 = shl nsw i64 %5751, 3
  %5753 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5752
  %5754 = bitcast i8* %5753 to double*
  %5755 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5754, i32 64)
  %5756 = add i32 %180, 199
  %5757 = sext i32 %5756 to i64
  %5758 = shl nsw i64 %5757, 3
  %5759 = getelementptr inbounds i8, i8* %getch.i2533, i64 %5758
  %5760 = bitcast i8* %5759 to double*
  %5761 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5760, i32 64)
  %5762 = fcmp reassoc ninf nsz oge double %175, %5755
  %5763 = fcmp reassoc ninf nsz ole double %175, %5761
  %.0771 = select i1 %5762, i1 %5763, i1 false
  br i1 %.0771, label %true_block2423, label %after_if31

true_block2423:                                   ; preds = %true_block2417
  %getch.i2331 = getelementptr i8, i8* %12, i64 418612680
  %5764 = getelementptr inbounds i8, i8* %getch.i2331, i64 %5752
  %5765 = bitcast i8* %5764 to double*
  %5766 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5765, i32 64)
  %5767 = getelementptr inbounds i8, i8* %getch.i2331, i64 %5758
  %5768 = bitcast i8* %5767 to double*
  %5769 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %5768, i32 64)
  %5770 = fsub reassoc ninf nsz double %5769, %5766
  %5771 = fsub reassoc ninf nsz double %5761, %5755
  %5772 = fsub reassoc ninf nsz double %175, %5755
  %5773 = fmul reassoc ninf nsz double %5770, %5772
  %5774 = fdiv reassoc ninf nsz double %5773, %5771
  %5775 = fadd reassoc ninf nsz double %5774, %5766
  br label %after_if31

false_block2427:                                  ; preds = %after_if31
  %5776 = fsub reassoc ninf nsz double %.01171, %40
  %5777 = fcmp reassoc ninf nsz ole double %189, 1.000000e-02
  %5778 = fcmp reassoc ninf nsz oge double %5776, 1.000000e-01
  %.0766 = select i1 %5777, i1 true, i1 %5778
  br i1 %.0766, label %true_block2432, label %false_block2433

true_block2432:                                   ; preds = %after_if31, %false_block2427
  %5779 = fmul reassoc ninf nsz double %190, %28
  %5780 = fmul reassoc ninf nsz double %5779, %190
  %5781 = fmul reassoc ninf nsz double %28, %28
  br label %after_if2434

false_block2433:                                  ; preds = %false_block2427
  %5782 = tail call double @llvm.sqrt.f64(double %28)
  %5783 = fmul reassoc ninf nsz double %5782, 6.264000e+00
  %5784 = fadd reassoc ninf nsz double %190, %5783
  %5785 = tail call double @llvm.sqrt.f64(double %189)
  %5786 = fmul reassoc ninf nsz double %5785, 6.264000e+00
  br label %while_loop_body2435

after_if2434:                                     ; preds = %after_while2436, %true_block2432
  %.0770 = phi double [ %5779, %true_block2432 ], [ %5797, %after_while2436 ]
  %.0769 = phi double [ %5780, %true_block2432 ], [ %5798, %after_while2436 ]
  %.0768.in = phi double [ %5781, %true_block2432 ], [ %5799, %after_while2436 ]
  %.0768 = fmul reassoc ninf nsz double %.0768.in, 4.905000e+00
  br label %after_if9

while_loop_body2435:                              ; preds = %after_break2437.3, %false_block2433
  %lsr.iv = phi i32 [ %lsr.iv.next, %after_break2437.3 ], [ -28, %false_block2433 ]
  %.0763 = phi double [ %190, %false_block2433 ], [ %5826, %after_break2437.3 ]
  %5787 = fsub reassoc ninf nsz double %.0763, %5786
  %5788 = fadd reassoc ninf nsz double %5787, %5784
  %5789 = fsub reassoc ninf nsz double %5784, %5787
  %5790 = fmul reassoc ninf nsz double %5789, %5789
  %5791 = fmul reassoc ninf nsz double %5790, 0x3F6A1887B2C1A188
  %5792 = fmul reassoc ninf nsz double %5791, %5788
  %5793 = fdiv reassoc ninf nsz double %5792, %189
  %5794 = fsub reassoc ninf nsz double %5793, %.0763
  %5795 = tail call double @llvm.fabs.f64(double %5794)
  %5796 = fcmp reassoc ninf nsz ugt double %5795, 1.000000e-03
  br i1 %5796, label %after_break2437.1, label %after_while2436

after_while2436:                                  ; preds = %after_break2437.3, %after_break2437.2, %after_break2437.1, %while_loop_body2435
  %.1764 = phi double [ %5793, %while_loop_body2435 ], [ %5806, %after_break2437.1 ], [ %5816, %after_break2437.2 ], [ %5826, %after_break2437.3 ]
  %5797 = fmul reassoc ninf nsz double %.1764, %189
  %5798 = fmul reassoc ninf nsz double %5797, %.1764
  %5799 = fmul reassoc ninf nsz double %189, %189
  br label %after_if2434

after_break2437.1:                                ; preds = %while_loop_body2435
  %5800 = fsub reassoc ninf nsz double %5793, %5786
  %5801 = fadd reassoc ninf nsz double %5800, %5784
  %5802 = fsub reassoc ninf nsz double %5784, %5800
  %5803 = fmul reassoc ninf nsz double %5802, %5802
  %5804 = fmul reassoc ninf nsz double %5803, 0x3F6A1887B2C1A188
  %5805 = fmul reassoc ninf nsz double %5804, %5801
  %5806 = fdiv reassoc ninf nsz double %5805, %189
  %5807 = fsub reassoc ninf nsz double %5806, %5793
  %5808 = tail call double @llvm.fabs.f64(double %5807)
  %5809 = fcmp reassoc ninf nsz ole double %5808, 1.000000e-03
  %exitcond10970.2 = icmp eq i32 %lsr.iv, 0
  %or.cond10975 = select i1 %5809, i1 true, i1 %exitcond10970.2
  br i1 %or.cond10975, label %after_while2436, label %after_break2437.2

after_break2437.2:                                ; preds = %after_break2437.1
  %5810 = fsub reassoc ninf nsz double %5806, %5786
  %5811 = fadd reassoc ninf nsz double %5810, %5784
  %5812 = fsub reassoc ninf nsz double %5784, %5810
  %5813 = fmul reassoc ninf nsz double %5812, %5812
  %5814 = fmul reassoc ninf nsz double %5813, 0x3F6A1887B2C1A188
  %5815 = fmul reassoc ninf nsz double %5814, %5811
  %5816 = fdiv reassoc ninf nsz double %5815, %189
  %5817 = fsub reassoc ninf nsz double %5816, %5806
  %5818 = tail call double @llvm.fabs.f64(double %5817)
  %5819 = fcmp reassoc ninf nsz ugt double %5818, 1.000000e-03
  br i1 %5819, label %after_break2437.3, label %after_while2436

after_break2437.3:                                ; preds = %after_break2437.2
  %5820 = fsub reassoc ninf nsz double %5816, %5786
  %5821 = fadd reassoc ninf nsz double %5820, %5784
  %5822 = fsub reassoc ninf nsz double %5784, %5820
  %5823 = fmul reassoc ninf nsz double %5822, %5822
  %5824 = fmul reassoc ninf nsz double %5823, 0x3F6A1887B2C1A188
  %5825 = fmul reassoc ninf nsz double %5824, %5821
  %5826 = fdiv reassoc ninf nsz double %5825, %189
  %5827 = fsub reassoc ninf nsz double %5826, %5816
  %5828 = tail call double @llvm.fabs.f64(double %5827)
  %5829 = fcmp reassoc ninf nsz ugt double %5828, 1.000000e-03
  %lsr.iv.next = add nsw i32 %lsr.iv, 4
  br i1 %5829, label %while_loop_body2435, label %after_while2436

true_block2442:                                   ; preds = %false_block11
  %5830 = trunc i64 %24 to i32
  %5831 = bitcast %struct.RuntimeContext.333* %0 to { i32, i32 }**
  %5832 = load { i32, i32 }*, { i32, i32 }** %5831, align 8
  %5833 = bitcast { i32, i32 }* %5832 to i32*
  %5834 = load i32, i32* %5833, align 4
  %5835 = getelementptr { i32, i32 }, { i32, i32 }* %5832, i64 0, i32 1
  %5836 = load i32, i32* %5835, align 4
  %5837 = mul i32 %5836, 207234
  %5838 = add i32 %5837, %5830
  %getch.i2330 = getelementptr i8, i8* %12, i64 87038280
  %5839 = sext i32 %5838 to i64
  %5840 = shl nsw i64 %5839, 3
  %5841 = getelementptr inbounds i8, i8* %getch.i2330, i64 %5840
  %5842 = bitcast i8* %5841 to double*
  %5843 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5842, i32 64)
  %getch.i2329 = getelementptr i8, i8* %12, i64 169931880
  %5844 = getelementptr inbounds i8, i8* %getch.i2329, i64 %5840
  %5845 = bitcast i8* %5844 to double*
  %5846 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5845, i32 64)
  %5847 = sitofp i32 %5834 to double
  %5848 = fmul reassoc ninf nsz double %5846, %5847
  %5849 = fsub reassoc ninf nsz double %5843, %37
  %5850 = fadd reassoc ninf nsz double %5849, %5848
  %5851 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %5850, double 1.000000e-02)
  %5852 = tail call double @llvm.sqrt.f64(double %28)
  %5853 = fmul reassoc ninf nsz double %5852, 6.264000e+00
  %5854 = fadd reassoc ninf nsz double %53, %5853
  %5855 = tail call double @llvm.sqrt.f64(double %5851)
  %5856 = fmul reassoc ninf nsz double %5855, 6.264000e+00
  br label %while_loop_body2445

while_loop_body2445:                              ; preds = %after_break2447.3, %true_block2442
  %lsr.iv10983 = phi i32 [ %lsr.iv.next10984, %after_break2447.3 ], [ -28, %true_block2442 ]
  %.0760 = phi double [ %53, %true_block2442 ], [ %5897, %after_break2447.3 ]
  %5857 = fsub reassoc ninf nsz double %.0760, %5856
  %5858 = fadd reassoc ninf nsz double %5857, %5854
  %5859 = fsub reassoc ninf nsz double %5854, %5857
  %5860 = fmul reassoc ninf nsz double %5859, %5859
  %5861 = fmul reassoc ninf nsz double %5860, 0x3F6A1887B2C1A188
  %5862 = fmul reassoc ninf nsz double %5861, %5858
  %5863 = fdiv reassoc ninf nsz double %5862, %5851
  %5864 = fsub reassoc ninf nsz double %5863, %.0760
  %5865 = tail call double @llvm.fabs.f64(double %5864)
  %5866 = fcmp reassoc ninf nsz ugt double %5865, 1.000000e-04
  br i1 %5866, label %after_break2447.1, label %after_while2446

after_while2446:                                  ; preds = %after_break2447.3, %after_break2447.2, %after_break2447.1, %while_loop_body2445
  %.1 = phi double [ %5863, %while_loop_body2445 ], [ %5877, %after_break2447.1 ], [ %5887, %after_break2447.2 ], [ %5897, %after_break2447.3 ]
  %5867 = fmul reassoc ninf nsz double %.1, %5851
  %5868 = fmul reassoc ninf nsz double %5867, %.1
  %5869 = fmul reassoc ninf nsz double %5851, %5851
  %5870 = fmul reassoc ninf nsz double %5869, 4.905000e+00
  br label %after_if9

after_break2447.1:                                ; preds = %while_loop_body2445
  %5871 = fsub reassoc ninf nsz double %5863, %5856
  %5872 = fadd reassoc ninf nsz double %5871, %5854
  %5873 = fsub reassoc ninf nsz double %5854, %5871
  %5874 = fmul reassoc ninf nsz double %5873, %5873
  %5875 = fmul reassoc ninf nsz double %5874, 0x3F6A1887B2C1A188
  %5876 = fmul reassoc ninf nsz double %5875, %5872
  %5877 = fdiv reassoc ninf nsz double %5876, %5851
  %5878 = fsub reassoc ninf nsz double %5877, %5863
  %5879 = tail call double @llvm.fabs.f64(double %5878)
  %5880 = fcmp reassoc ninf nsz ole double %5879, 1.000000e-04
  %exitcond10971.2 = icmp eq i32 %lsr.iv10983, 0
  %or.cond10976 = select i1 %5880, i1 true, i1 %exitcond10971.2
  br i1 %or.cond10976, label %after_while2446, label %after_break2447.2

after_break2447.2:                                ; preds = %after_break2447.1
  %5881 = fsub reassoc ninf nsz double %5877, %5856
  %5882 = fadd reassoc ninf nsz double %5881, %5854
  %5883 = fsub reassoc ninf nsz double %5854, %5881
  %5884 = fmul reassoc ninf nsz double %5883, %5883
  %5885 = fmul reassoc ninf nsz double %5884, 0x3F6A1887B2C1A188
  %5886 = fmul reassoc ninf nsz double %5885, %5882
  %5887 = fdiv reassoc ninf nsz double %5886, %5851
  %5888 = fsub reassoc ninf nsz double %5887, %5877
  %5889 = tail call double @llvm.fabs.f64(double %5888)
  %5890 = fcmp reassoc ninf nsz ugt double %5889, 1.000000e-04
  br i1 %5890, label %after_break2447.3, label %after_while2446

after_break2447.3:                                ; preds = %after_break2447.2
  %5891 = fsub reassoc ninf nsz double %5887, %5856
  %5892 = fadd reassoc ninf nsz double %5891, %5854
  %5893 = fsub reassoc ninf nsz double %5854, %5891
  %5894 = fmul reassoc ninf nsz double %5893, %5893
  %5895 = fmul reassoc ninf nsz double %5894, 0x3F6A1887B2C1A188
  %5896 = fmul reassoc ninf nsz double %5895, %5892
  %5897 = fdiv reassoc ninf nsz double %5896, %5851
  %5898 = fsub reassoc ninf nsz double %5897, %5887
  %5899 = tail call double @llvm.fabs.f64(double %5898)
  %5900 = fcmp reassoc ninf nsz ugt double %5899, 1.000000e-04
  %lsr.iv.next10984 = add nsw i32 %lsr.iv10983, 4
  br i1 %5900, label %while_loop_body2445, label %after_while2446

true_block2452:                                   ; preds = %false_block11
  %5901 = fmul reassoc ninf nsz double %28, %28
  %5902 = fmul reassoc ninf nsz double %5901, 4.905000e+00
  br label %after_if9

true_block2455:                                   ; preds = %false_block11
  %5903 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %53, double 0.000000e+00)
  %5904 = fmul reassoc ninf nsz double %5903, %28
  %5905 = fmul reassoc ninf nsz double %5904, %5903
  %5906 = fmul reassoc ninf nsz double %28, %28
  %5907 = fmul reassoc ninf nsz double %5906, 0x40139BB4F2289093
  br label %after_if9

true_block2458:                                   ; preds = %false_block11
  %getch.i2328 = getelementptr i8, i8* %12, i64 84551472
  %5908 = getelementptr inbounds i8, i8* %getch.i2328, i64 %25
  %5909 = bitcast i8* %5908 to double*
  %5910 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %5909, i32 64)
  %5911 = fcmp reassoc ninf nsz ole double %40, %5910
  %5912 = fcmp reassoc ninf nsz ole double %.01383, %5910
  %.0754 = select i1 %5911, i1 %5912, i1 false
  br i1 %.0754, label %true_block2464, label %false_block2465

true_block2464:                                   ; preds = %true_block2458
  %5913 = fmul reassoc ninf nsz double %28, %28
  %5914 = fmul reassoc ninf nsz double %5913, 4.905000e+00
  br label %after_if9

false_block2465:                                  ; preds = %true_block2458
  %5915 = fcmp ole double %.01383, %5910
  %5916 = fcmp reassoc ninf nsz ogt double %40, %5910
  %.0753 = select i1 %5916, i1 %5915, i1 false
  br i1 %.0753, label %true_block2470, label %false_block2471

true_block2470:                                   ; preds = %false_block2465
  %5917 = fsub reassoc ninf nsz double %40, %5910
  %5918 = tail call i32 @llvm.nvvm.d2i.hi(double %5917)
  %5919 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %5920 = and i32 %5919, 2146435072
  %5921 = tail call double @llvm.fabs.f64(double %5917)
  %5922 = tail call i32 @llvm.nvvm.d2i.hi(double %5921)
  %5923 = tail call i32 @llvm.nvvm.d2i.lo(double %5921)
  %5924 = lshr i32 %5922, 20
  %5925 = icmp ult i32 %5922, 1048576
  %5926 = fmul double %5921, 0x4350000000000000
  %5927 = tail call i32 @llvm.nvvm.d2i.hi(double %5926)
  %5928 = tail call i32 @llvm.nvvm.d2i.lo(double %5926)
  %5929 = lshr i32 %5927, 20
  %5930 = add nsw i32 %5929, -54
  %ilo.0.i.i.i2298 = select i1 %5925, i32 %5928, i32 %5923
  %ihi.0.i.i.i2299 = select i1 %5925, i32 %5927, i32 %5922
  %expo.0.i.i.i2300 = select i1 %5925, i32 %5930, i32 %5924
  %5931 = and i32 %ihi.0.i.i.i2299, -2146435073
  %5932 = or i32 %5931, 1072693248
  %5933 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2298, i32 %5932)
  %5934 = icmp ugt i32 %5932, 1073127582
  %5935 = tail call i32 @llvm.nvvm.d2i.lo(double %5933)
  %5936 = tail call i32 @llvm.nvvm.d2i.hi(double %5933)
  %5937 = add i32 %5936, -1048576
  %5938 = tail call double @llvm.nvvm.lohi.i2d(i32 %5935, i32 %5937)
  %m.0.i.i.i2301 = select i1 %5934, double %5938, double %5933
  %expo.1.i.v.i.i2302 = select i1 %5934, i32 -1022, i32 -1023
  %expo.1.i.i.i2303 = add nsw i32 %expo.1.i.v.i.i2302, %expo.0.i.i.i2300
  %5939 = fadd double %m.0.i.i.i2301, -1.000000e+00
  %5940 = fadd double %m.0.i.i.i2301, 1.000000e+00
  %5941 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %5940)
  %5942 = fneg double %5940
  %5943 = tail call double @llvm.fma.f64(double %5942, double %5941, double 1.000000e+00)
  %5944 = tail call double @llvm.fma.f64(double %5943, double %5943, double %5943)
  %5945 = tail call double @llvm.fma.f64(double %5944, double %5941, double %5941)
  %5946 = fmul double %5939, %5945
  %5947 = fadd double %5946, %5946
  %5948 = fmul double %5947, %5947
  %5949 = tail call double @llvm.fma.f64(double %5948, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %5950 = tail call double @llvm.fma.f64(double %5949, double %5948, double 0x3EF3B20A75488A3F)
  %5951 = tail call double @llvm.fma.f64(double %5950, double %5948, double 0x3F1745CDE4FAECD5)
  %5952 = tail call double @llvm.fma.f64(double %5951, double %5948, double 0x3F3C71C7258A578B)
  %5953 = tail call double @llvm.fma.f64(double %5952, double %5948, double 0x3F6249249242B910)
  %5954 = tail call double @llvm.fma.f64(double %5953, double %5948, double 0x3F89999999999DFB)
  %5955 = fmul double %5948, %5954
  %5956 = fsub double %5939, %5947
  %5957 = fmul double %5956, 2.000000e+00
  %5958 = fneg double %5947
  %5959 = tail call double @llvm.fma.f64(double %5958, double %5939, double %5957)
  %5960 = fmul double %5945, %5959
  %5961 = fadd double %5955, 0x3FB5555555555555
  %5962 = fsub double 0x3FB5555555555555, %5961
  %5963 = fadd double %5955, %5962
  %5964 = fadd double %5963, 0.000000e+00
  %5965 = fadd double %5964, 0xBC46A4CB00B9E7B0
  %5966 = fadd double %5961, %5965
  %5967 = fsub double %5961, %5966
  %5968 = fadd double %5965, %5967
  %5969 = fneg double %5948
  %5970 = tail call double @llvm.fma.f64(double %5947, double %5947, double %5969)
  %5971 = tail call i32 @llvm.nvvm.d2i.lo(double %5960)
  %5972 = tail call i32 @llvm.nvvm.d2i.hi(double %5960)
  %5973 = add i32 %5972, 1048576
  %5974 = tail call double @llvm.nvvm.lohi.i2d(i32 %5971, i32 %5973)
  %5975 = tail call double @llvm.fma.f64(double %5947, double %5974, double %5970)
  %5976 = fmul double %5947, %5948
  %5977 = fneg double %5976
  %5978 = tail call double @llvm.fma.f64(double %5948, double %5947, double %5977)
  %5979 = tail call double @llvm.fma.f64(double %5948, double %5960, double %5978)
  %5980 = tail call double @llvm.fma.f64(double %5975, double %5947, double %5979)
  %5981 = fmul double %5976, %5966
  %5982 = fneg double %5981
  %5983 = tail call double @llvm.fma.f64(double %5966, double %5976, double %5982)
  %5984 = tail call double @llvm.fma.f64(double %5966, double %5980, double %5983)
  %5985 = tail call double @llvm.fma.f64(double %5968, double %5976, double %5984)
  %5986 = fadd double %5981, %5985
  %5987 = fsub double %5981, %5986
  %5988 = fadd double %5985, %5987
  %5989 = fadd double %5947, %5986
  %5990 = fsub double %5947, %5989
  %5991 = fadd double %5986, %5990
  %5992 = fadd double %5988, %5991
  %5993 = fadd double %5960, %5992
  %5994 = fadd double %5989, %5993
  %5995 = fsub double %5989, %5994
  %5996 = fadd double %5993, %5995
  %5997 = xor i32 %expo.1.i.i.i2303, -2147483648
  %5998 = tail call double @llvm.nvvm.lohi.i2d(i32 %5997, i32 1127219200)
  %5999 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %6000 = fsub double %5998, %5999
  %6001 = tail call double @llvm.fma.f64(double %6000, double 0x3FE62E42FEFA39EF, double %5994)
  %6002 = fneg double %6000
  %6003 = tail call double @llvm.fma.f64(double %6002, double 0x3FE62E42FEFA39EF, double %6001)
  %6004 = fsub double %6003, %5994
  %6005 = fsub double %5996, %6004
  %6006 = tail call double @llvm.fma.f64(double %6000, double 0x3C7ABC9E3B39803F, double %6005)
  %6007 = fadd double %6001, %6006
  %6008 = fsub double %6001, %6007
  %6009 = fadd double %6006, %6008
  %6010 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %6011 = shl i32 %5919, 1
  %6012 = icmp ugt i32 %6011, -33554433
  %6013 = and i32 %5919, -15728641
  %spec.select.i.i2304 = select i1 %6012, i32 %6013, i32 %5919
  %6014 = tail call double @llvm.nvvm.lohi.i2d(i32 %6010, i32 %spec.select.i.i2304)
  %6015 = fmul double %6014, %6007
  %6016 = fneg double %6015
  %6017 = tail call double @llvm.fma.f64(double %6007, double %6014, double %6016)
  %6018 = tail call double @llvm.fma.f64(double %6009, double %6014, double %6017)
  %6019 = fadd double %6015, %6018
  %6020 = tail call double @llvm.fma.f64(double %6019, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %6021 = tail call i32 @llvm.nvvm.d2i.lo(double %6020)
  %6022 = fadd double %6020, 0xC338000000000000
  %6023 = tail call double @llvm.fma.f64(double %6022, double 0xBFE62E42FEFA39EF, double %6019)
  %6024 = tail call double @llvm.fma.f64(double %6022, double 0xBC7ABC9E3B39803F, double %6023)
  %6025 = tail call double @llvm.fma.f64(double %6024, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %6026 = tail call double @llvm.fma.f64(double %6025, double %6024, double 0x3EC71DEE62401315)
  %6027 = tail call double @llvm.fma.f64(double %6026, double %6024, double 0x3EFA01997C89EB71)
  %6028 = tail call double @llvm.fma.f64(double %6027, double %6024, double 0x3F2A01A014761F65)
  %6029 = tail call double @llvm.fma.f64(double %6028, double %6024, double 0x3F56C16C1852B7AF)
  %6030 = tail call double @llvm.fma.f64(double %6029, double %6024, double 0x3F81111111122322)
  %6031 = tail call double @llvm.fma.f64(double %6030, double %6024, double 0x3FA55555555502A1)
  %6032 = tail call double @llvm.fma.f64(double %6031, double %6024, double 0x3FC5555555555511)
  %6033 = tail call double @llvm.fma.f64(double %6032, double %6024, double 0x3FE000000000000B)
  %6034 = tail call double @llvm.fma.f64(double %6033, double %6024, double 1.000000e+00)
  %6035 = tail call double @llvm.fma.f64(double %6034, double %6024, double 1.000000e+00)
  %6036 = tail call i32 @llvm.nvvm.d2i.lo(double %6035)
  %6037 = tail call i32 @llvm.nvvm.d2i.hi(double %6035)
  %6038 = shl i32 %6021, 20
  %6039 = add i32 %6037, %6038
  %6040 = tail call double @llvm.nvvm.lohi.i2d(i32 %6036, i32 %6039)
  %6041 = tail call i32 @llvm.nvvm.d2i.hi(double %6019)
  %6042 = bitcast i32 %6041 to float
  %6043 = tail call float @llvm.fabs.f32(float %6042)
  %6044 = fcmp uge float %6043, 0x4010C46560000000
  br i1 %6044, label %__internal_fast_icmp_abs_lt.exit.i.i.i2306, label %__internal_accurate_pow.exit.i2309

__internal_fast_icmp_abs_lt.exit.i.i.i2306:       ; preds = %true_block2470
  %6045 = fcmp olt double %6019, 0.000000e+00
  %6046 = fadd double %6019, 0x7FF0000000000000
  %z.0.i.i.i2305 = select i1 %6045, double 0.000000e+00, double %6046
  %6047 = fcmp olt float %6043, 0x4010E90000000000
  br i1 %6047, label %6048, label %__internal_accurate_pow.exit.i2309

6048:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2306
  %6049 = sdiv i32 %6021, 2
  %6050 = shl i32 %6049, 20
  %6051 = add i32 %6037, %6050
  %6052 = tail call double @llvm.nvvm.lohi.i2d(i32 %6036, i32 %6051)
  %6053 = sub nsw i32 %6021, %6049
  %6054 = shl i32 %6053, 20
  %6055 = add nsw i32 %6054, 1072693248
  %6056 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %6055)
  %6057 = fmul double %6056, %6052
  br label %__internal_accurate_pow.exit.i2309

__internal_accurate_pow.exit.i2309:               ; preds = %6048, %__internal_fast_icmp_abs_lt.exit.i.i.i2306, %true_block2470
  %z.2.i.i.i2307 = phi double [ %6040, %true_block2470 ], [ %6057, %6048 ], [ %z.0.i.i.i2305, %__internal_fast_icmp_abs_lt.exit.i.i.i2306 ]
  %6058 = icmp eq i32 %5920, 1073741824
  %6059 = icmp slt i32 %5918, 0
  %spec.select.i2308 = select i1 %6059, i1 %6058, i1 false
  %6060 = fcmp oeq double %5917, 0.000000e+00
  br i1 %6060, label %6061, label %6066

6061:                                             ; preds = %__internal_accurate_pow.exit.i2309
  %6062 = icmp eq i32 %5920, 1073741824
  %spec.select1.i2310 = select i1 %6062, i32 %5918, i32 0
  %6063 = icmp slt i32 %5919, 0
  %6064 = or i32 %spec.select1.i2310, 2146435072
  %thi.1.i2311 = select i1 %6063, i32 %6064, i32 %spec.select1.i2310
  %6065 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2311)
  br label %6081

6066:                                             ; preds = %__internal_accurate_pow.exit.i2309
  %6067 = icmp slt i32 %5918, 0
  %6068 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2307)
  %6069 = and i32 %6068, 2147483647
  %6070 = icmp ne i32 %6069, 2146435072
  %6071 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2307)
  %6072 = icmp ne i32 %6071, 0
  %6073 = select i1 %6070, i1 true, i1 %6072
  %6074 = fsub double %6015, %6019
  %6075 = fadd double %6018, %6074
  %6076 = tail call double @llvm.fma.f64(double %z.2.i.i.i2307, double %6075, double %z.2.i.i.i2307)
  %tmp.0.i.i2312 = select i1 %6073, double %6076, double %z.2.i.i.i2307
  %6077 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2312)
  %6078 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2312)
  %6079 = xor i32 %6078, -2147483648
  %6080 = tail call double @llvm.nvvm.lohi.i2d(i32 %6077, i32 %6079)
  %t.0.i2313 = select i1 %spec.select.i2308, double %6080, double %tmp.0.i.i2312
  %t.1.i2314 = select i1 %6067, double 0xFFF8000000000000, double %t.0.i2313
  br label %6081

6081:                                             ; preds = %6066, %6061
  %t.2.i2315 = phi double [ %6065, %6061 ], [ %t.1.i2314, %6066 ]
  %6082 = fadd double %5917, 1.500000e+00
  %6083 = tail call i32 @llvm.nvvm.d2i.hi(double %6082)
  %6084 = and i32 %6083, 2146435072
  %6085 = icmp eq i32 %6084, 2146435072
  br i1 %6085, label %6086, label %__nv_pow.exit2327

6086:                                             ; preds = %6081
  %6087 = fcmp ugt double %5921, 0x7FF0000000000000
  br i1 %6087, label %__nv_pow.exit2327, label %__nv_isinfd.exit5.i2316

__nv_isinfd.exit5.i2316:                          ; preds = %6086
  %6088 = and i32 %5919, 2147483647
  %6089 = icmp eq i32 %6088, 2146435072
  %6090 = icmp eq i32 %6010, 0
  %6091 = select i1 %6089, i1 %6090, i1 false
  br i1 %6091, label %6092, label %__nv_isinfd.exit.i2324

6092:                                             ; preds = %__nv_isinfd.exit5.i2316
  %6093 = fcmp ogt double %5921, 1.000000e+00
  %thi.2.i2317 = select i1 %6093, i32 2146435072, i32 0
  %6094 = icmp slt i32 %5919, 0
  %6095 = xor i32 %thi.2.i2317, 2146435072
  %thi.3.i2318 = select i1 %6094, i32 %6095, i32 %thi.2.i2317
  %6096 = fcmp oeq double %5917, -1.000000e+00
  %thi.4.i2319 = select i1 %6096, i32 1072693248, i32 %thi.3.i2318
  %6097 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2319)
  br label %__nv_pow.exit2327

__nv_isinfd.exit.i2324:                           ; preds = %__nv_isinfd.exit5.i2316
  %6098 = tail call i32 @llvm.nvvm.d2i.lo(double %5917)
  %6099 = and i32 %5918, 2147483647
  %6100 = icmp eq i32 %6099, 2146435072
  %6101 = icmp eq i32 %6098, 0
  %6102 = select i1 %6100, i1 %6101, i1 false
  %.inv.i2320 = icmp slt i32 %5919, 0
  %spec.select8.i2321 = select i1 %.inv.i2320, i32 0, i32 2146435072
  %6103 = or i32 %spec.select8.i2321, -2147483648
  %thi.6.i2322 = select i1 %spec.select.i2308, i32 %6103, i32 %spec.select8.i2321
  %6104 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2322)
  %spec.select10.i2323 = select i1 %6102, double %6104, double %t.2.i2315
  br label %__nv_pow.exit2327

__nv_pow.exit2327:                                ; preds = %6081, %6086, %6092, %__nv_isinfd.exit.i2324
  %t.6.i2325 = phi double [ %t.2.i2315, %6081 ], [ %6097, %6092 ], [ %6082, %6086 ], [ %spec.select10.i2323, %__nv_isinfd.exit.i2324 ]
  %6105 = fcmp oeq double %5917, 1.000000e+00
  %t.6.i2325.op = fmul reassoc ninf nsz double %t.6.i2325, 1.330000e+00
  %6106 = select i1 %6105, double 1.330000e+00, double %t.6.i2325.op
  %6107 = fmul reassoc ninf nsz double %6106, %53
  %6108 = fmul reassoc ninf nsz double %6106, %56
  %6109 = fsub reassoc ninf nsz double %5910, %37
  %6110 = fmul reassoc ninf nsz double %6109, %6109
  %6111 = fmul reassoc ninf nsz double %6110, 4.905000e+00
  br label %after_if9

false_block2471:                                  ; preds = %false_block2465
  %6112 = fcmp ole double %40, %5910
  %6113 = fcmp reassoc ninf nsz ogt double %.01383, %5910
  %.0752 = select i1 %6112, i1 %6113, i1 false
  br i1 %.0752, label %true_block2476, label %false_block2477

true_block2476:                                   ; preds = %false_block2471
  %6114 = fsub reassoc ninf nsz double %.01383, %5910
  %6115 = tail call i32 @llvm.nvvm.d2i.hi(double %6114)
  %6116 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %6117 = and i32 %6116, 2146435072
  %6118 = tail call double @llvm.fabs.f64(double %6114)
  %6119 = tail call i32 @llvm.nvvm.d2i.hi(double %6118)
  %6120 = tail call i32 @llvm.nvvm.d2i.lo(double %6118)
  %6121 = lshr i32 %6119, 20
  %6122 = icmp ult i32 %6119, 1048576
  %6123 = fmul double %6118, 0x4350000000000000
  %6124 = tail call i32 @llvm.nvvm.d2i.hi(double %6123)
  %6125 = tail call i32 @llvm.nvvm.d2i.lo(double %6123)
  %6126 = lshr i32 %6124, 20
  %6127 = add nsw i32 %6126, -54
  %ilo.0.i.i.i2268 = select i1 %6122, i32 %6125, i32 %6120
  %ihi.0.i.i.i2269 = select i1 %6122, i32 %6124, i32 %6119
  %expo.0.i.i.i2270 = select i1 %6122, i32 %6127, i32 %6121
  %6128 = and i32 %ihi.0.i.i.i2269, -2146435073
  %6129 = or i32 %6128, 1072693248
  %6130 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2268, i32 %6129)
  %6131 = icmp ugt i32 %6129, 1073127582
  %6132 = tail call i32 @llvm.nvvm.d2i.lo(double %6130)
  %6133 = tail call i32 @llvm.nvvm.d2i.hi(double %6130)
  %6134 = add i32 %6133, -1048576
  %6135 = tail call double @llvm.nvvm.lohi.i2d(i32 %6132, i32 %6134)
  %m.0.i.i.i2271 = select i1 %6131, double %6135, double %6130
  %expo.1.i.v.i.i2272 = select i1 %6131, i32 -1022, i32 -1023
  %expo.1.i.i.i2273 = add nsw i32 %expo.1.i.v.i.i2272, %expo.0.i.i.i2270
  %6136 = fadd double %m.0.i.i.i2271, -1.000000e+00
  %6137 = fadd double %m.0.i.i.i2271, 1.000000e+00
  %6138 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %6137)
  %6139 = fneg double %6137
  %6140 = tail call double @llvm.fma.f64(double %6139, double %6138, double 1.000000e+00)
  %6141 = tail call double @llvm.fma.f64(double %6140, double %6140, double %6140)
  %6142 = tail call double @llvm.fma.f64(double %6141, double %6138, double %6138)
  %6143 = fmul double %6136, %6142
  %6144 = fadd double %6143, %6143
  %6145 = fmul double %6144, %6144
  %6146 = tail call double @llvm.fma.f64(double %6145, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %6147 = tail call double @llvm.fma.f64(double %6146, double %6145, double 0x3EF3B20A75488A3F)
  %6148 = tail call double @llvm.fma.f64(double %6147, double %6145, double 0x3F1745CDE4FAECD5)
  %6149 = tail call double @llvm.fma.f64(double %6148, double %6145, double 0x3F3C71C7258A578B)
  %6150 = tail call double @llvm.fma.f64(double %6149, double %6145, double 0x3F6249249242B910)
  %6151 = tail call double @llvm.fma.f64(double %6150, double %6145, double 0x3F89999999999DFB)
  %6152 = fmul double %6145, %6151
  %6153 = fsub double %6136, %6144
  %6154 = fmul double %6153, 2.000000e+00
  %6155 = fneg double %6144
  %6156 = tail call double @llvm.fma.f64(double %6155, double %6136, double %6154)
  %6157 = fmul double %6142, %6156
  %6158 = fadd double %6152, 0x3FB5555555555555
  %6159 = fsub double 0x3FB5555555555555, %6158
  %6160 = fadd double %6152, %6159
  %6161 = fadd double %6160, 0.000000e+00
  %6162 = fadd double %6161, 0xBC46A4CB00B9E7B0
  %6163 = fadd double %6158, %6162
  %6164 = fsub double %6158, %6163
  %6165 = fadd double %6162, %6164
  %6166 = fneg double %6145
  %6167 = tail call double @llvm.fma.f64(double %6144, double %6144, double %6166)
  %6168 = tail call i32 @llvm.nvvm.d2i.lo(double %6157)
  %6169 = tail call i32 @llvm.nvvm.d2i.hi(double %6157)
  %6170 = add i32 %6169, 1048576
  %6171 = tail call double @llvm.nvvm.lohi.i2d(i32 %6168, i32 %6170)
  %6172 = tail call double @llvm.fma.f64(double %6144, double %6171, double %6167)
  %6173 = fmul double %6144, %6145
  %6174 = fneg double %6173
  %6175 = tail call double @llvm.fma.f64(double %6145, double %6144, double %6174)
  %6176 = tail call double @llvm.fma.f64(double %6145, double %6157, double %6175)
  %6177 = tail call double @llvm.fma.f64(double %6172, double %6144, double %6176)
  %6178 = fmul double %6173, %6163
  %6179 = fneg double %6178
  %6180 = tail call double @llvm.fma.f64(double %6163, double %6173, double %6179)
  %6181 = tail call double @llvm.fma.f64(double %6163, double %6177, double %6180)
  %6182 = tail call double @llvm.fma.f64(double %6165, double %6173, double %6181)
  %6183 = fadd double %6178, %6182
  %6184 = fsub double %6178, %6183
  %6185 = fadd double %6182, %6184
  %6186 = fadd double %6144, %6183
  %6187 = fsub double %6144, %6186
  %6188 = fadd double %6183, %6187
  %6189 = fadd double %6185, %6188
  %6190 = fadd double %6157, %6189
  %6191 = fadd double %6186, %6190
  %6192 = fsub double %6186, %6191
  %6193 = fadd double %6190, %6192
  %6194 = xor i32 %expo.1.i.i.i2273, -2147483648
  %6195 = tail call double @llvm.nvvm.lohi.i2d(i32 %6194, i32 1127219200)
  %6196 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %6197 = fsub double %6195, %6196
  %6198 = tail call double @llvm.fma.f64(double %6197, double 0x3FE62E42FEFA39EF, double %6191)
  %6199 = fneg double %6197
  %6200 = tail call double @llvm.fma.f64(double %6199, double 0x3FE62E42FEFA39EF, double %6198)
  %6201 = fsub double %6200, %6191
  %6202 = fsub double %6193, %6201
  %6203 = tail call double @llvm.fma.f64(double %6197, double 0x3C7ABC9E3B39803F, double %6202)
  %6204 = fadd double %6198, %6203
  %6205 = fsub double %6198, %6204
  %6206 = fadd double %6203, %6205
  %6207 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %6208 = shl i32 %6116, 1
  %6209 = icmp ugt i32 %6208, -33554433
  %6210 = and i32 %6116, -15728641
  %spec.select.i.i2274 = select i1 %6209, i32 %6210, i32 %6116
  %6211 = tail call double @llvm.nvvm.lohi.i2d(i32 %6207, i32 %spec.select.i.i2274)
  %6212 = fmul double %6211, %6204
  %6213 = fneg double %6212
  %6214 = tail call double @llvm.fma.f64(double %6204, double %6211, double %6213)
  %6215 = tail call double @llvm.fma.f64(double %6206, double %6211, double %6214)
  %6216 = fadd double %6212, %6215
  %6217 = tail call double @llvm.fma.f64(double %6216, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %6218 = tail call i32 @llvm.nvvm.d2i.lo(double %6217)
  %6219 = fadd double %6217, 0xC338000000000000
  %6220 = tail call double @llvm.fma.f64(double %6219, double 0xBFE62E42FEFA39EF, double %6216)
  %6221 = tail call double @llvm.fma.f64(double %6219, double 0xBC7ABC9E3B39803F, double %6220)
  %6222 = tail call double @llvm.fma.f64(double %6221, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %6223 = tail call double @llvm.fma.f64(double %6222, double %6221, double 0x3EC71DEE62401315)
  %6224 = tail call double @llvm.fma.f64(double %6223, double %6221, double 0x3EFA01997C89EB71)
  %6225 = tail call double @llvm.fma.f64(double %6224, double %6221, double 0x3F2A01A014761F65)
  %6226 = tail call double @llvm.fma.f64(double %6225, double %6221, double 0x3F56C16C1852B7AF)
  %6227 = tail call double @llvm.fma.f64(double %6226, double %6221, double 0x3F81111111122322)
  %6228 = tail call double @llvm.fma.f64(double %6227, double %6221, double 0x3FA55555555502A1)
  %6229 = tail call double @llvm.fma.f64(double %6228, double %6221, double 0x3FC5555555555511)
  %6230 = tail call double @llvm.fma.f64(double %6229, double %6221, double 0x3FE000000000000B)
  %6231 = tail call double @llvm.fma.f64(double %6230, double %6221, double 1.000000e+00)
  %6232 = tail call double @llvm.fma.f64(double %6231, double %6221, double 1.000000e+00)
  %6233 = tail call i32 @llvm.nvvm.d2i.lo(double %6232)
  %6234 = tail call i32 @llvm.nvvm.d2i.hi(double %6232)
  %6235 = shl i32 %6218, 20
  %6236 = add i32 %6234, %6235
  %6237 = tail call double @llvm.nvvm.lohi.i2d(i32 %6233, i32 %6236)
  %6238 = tail call i32 @llvm.nvvm.d2i.hi(double %6216)
  %6239 = bitcast i32 %6238 to float
  %6240 = tail call float @llvm.fabs.f32(float %6239)
  %6241 = fcmp uge float %6240, 0x4010C46560000000
  br i1 %6241, label %__internal_fast_icmp_abs_lt.exit.i.i.i2276, label %__internal_accurate_pow.exit.i2279

__internal_fast_icmp_abs_lt.exit.i.i.i2276:       ; preds = %true_block2476
  %6242 = fcmp olt double %6216, 0.000000e+00
  %6243 = fadd double %6216, 0x7FF0000000000000
  %z.0.i.i.i2275 = select i1 %6242, double 0.000000e+00, double %6243
  %6244 = fcmp olt float %6240, 0x4010E90000000000
  br i1 %6244, label %6245, label %__internal_accurate_pow.exit.i2279

6245:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2276
  %6246 = sdiv i32 %6218, 2
  %6247 = shl i32 %6246, 20
  %6248 = add i32 %6234, %6247
  %6249 = tail call double @llvm.nvvm.lohi.i2d(i32 %6233, i32 %6248)
  %6250 = sub nsw i32 %6218, %6246
  %6251 = shl i32 %6250, 20
  %6252 = add nsw i32 %6251, 1072693248
  %6253 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %6252)
  %6254 = fmul double %6253, %6249
  br label %__internal_accurate_pow.exit.i2279

__internal_accurate_pow.exit.i2279:               ; preds = %6245, %__internal_fast_icmp_abs_lt.exit.i.i.i2276, %true_block2476
  %z.2.i.i.i2277 = phi double [ %6237, %true_block2476 ], [ %6254, %6245 ], [ %z.0.i.i.i2275, %__internal_fast_icmp_abs_lt.exit.i.i.i2276 ]
  %6255 = icmp eq i32 %6117, 1073741824
  %6256 = icmp slt i32 %6115, 0
  %spec.select.i2278 = select i1 %6256, i1 %6255, i1 false
  %6257 = fcmp oeq double %6114, 0.000000e+00
  br i1 %6257, label %6258, label %6263

6258:                                             ; preds = %__internal_accurate_pow.exit.i2279
  %6259 = icmp eq i32 %6117, 1073741824
  %spec.select1.i2280 = select i1 %6259, i32 %6115, i32 0
  %6260 = icmp slt i32 %6116, 0
  %6261 = or i32 %spec.select1.i2280, 2146435072
  %thi.1.i2281 = select i1 %6260, i32 %6261, i32 %spec.select1.i2280
  %6262 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2281)
  br label %6278

6263:                                             ; preds = %__internal_accurate_pow.exit.i2279
  %6264 = icmp slt i32 %6115, 0
  %6265 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2277)
  %6266 = and i32 %6265, 2147483647
  %6267 = icmp ne i32 %6266, 2146435072
  %6268 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2277)
  %6269 = icmp ne i32 %6268, 0
  %6270 = select i1 %6267, i1 true, i1 %6269
  %6271 = fsub double %6212, %6216
  %6272 = fadd double %6215, %6271
  %6273 = tail call double @llvm.fma.f64(double %z.2.i.i.i2277, double %6272, double %z.2.i.i.i2277)
  %tmp.0.i.i2282 = select i1 %6270, double %6273, double %z.2.i.i.i2277
  %6274 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2282)
  %6275 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2282)
  %6276 = xor i32 %6275, -2147483648
  %6277 = tail call double @llvm.nvvm.lohi.i2d(i32 %6274, i32 %6276)
  %t.0.i2283 = select i1 %spec.select.i2278, double %6277, double %tmp.0.i.i2282
  %t.1.i2284 = select i1 %6264, double 0xFFF8000000000000, double %t.0.i2283
  br label %6278

6278:                                             ; preds = %6263, %6258
  %t.2.i2285 = phi double [ %6262, %6258 ], [ %t.1.i2284, %6263 ]
  %6279 = fadd double %6114, 1.500000e+00
  %6280 = tail call i32 @llvm.nvvm.d2i.hi(double %6279)
  %6281 = and i32 %6280, 2146435072
  %6282 = icmp eq i32 %6281, 2146435072
  br i1 %6282, label %6283, label %__nv_pow.exit2297

6283:                                             ; preds = %6278
  %6284 = fcmp ugt double %6118, 0x7FF0000000000000
  br i1 %6284, label %__nv_pow.exit2297, label %__nv_isinfd.exit5.i2286

__nv_isinfd.exit5.i2286:                          ; preds = %6283
  %6285 = and i32 %6116, 2147483647
  %6286 = icmp eq i32 %6285, 2146435072
  %6287 = icmp eq i32 %6207, 0
  %6288 = select i1 %6286, i1 %6287, i1 false
  br i1 %6288, label %6289, label %__nv_isinfd.exit.i2294

6289:                                             ; preds = %__nv_isinfd.exit5.i2286
  %6290 = fcmp ogt double %6118, 1.000000e+00
  %thi.2.i2287 = select i1 %6290, i32 2146435072, i32 0
  %6291 = icmp slt i32 %6116, 0
  %6292 = xor i32 %thi.2.i2287, 2146435072
  %thi.3.i2288 = select i1 %6291, i32 %6292, i32 %thi.2.i2287
  %6293 = fcmp oeq double %6114, -1.000000e+00
  %thi.4.i2289 = select i1 %6293, i32 1072693248, i32 %thi.3.i2288
  %6294 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2289)
  br label %__nv_pow.exit2297

__nv_isinfd.exit.i2294:                           ; preds = %__nv_isinfd.exit5.i2286
  %6295 = tail call i32 @llvm.nvvm.d2i.lo(double %6114)
  %6296 = and i32 %6115, 2147483647
  %6297 = icmp eq i32 %6296, 2146435072
  %6298 = icmp eq i32 %6295, 0
  %6299 = select i1 %6297, i1 %6298, i1 false
  %.inv.i2290 = icmp slt i32 %6116, 0
  %spec.select8.i2291 = select i1 %.inv.i2290, i32 0, i32 2146435072
  %6300 = or i32 %spec.select8.i2291, -2147483648
  %thi.6.i2292 = select i1 %spec.select.i2278, i32 %6300, i32 %spec.select8.i2291
  %6301 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2292)
  %spec.select10.i2293 = select i1 %6299, double %6301, double %t.2.i2285
  br label %__nv_pow.exit2297

__nv_pow.exit2297:                                ; preds = %6278, %6283, %6289, %__nv_isinfd.exit.i2294
  %t.6.i2295 = phi double [ %t.2.i2285, %6278 ], [ %6294, %6289 ], [ %6279, %6283 ], [ %spec.select10.i2293, %__nv_isinfd.exit.i2294 ]
  %6302 = fcmp oeq double %6114, 1.000000e+00
  %t.6.i2295.op = fmul reassoc ninf nsz double %t.6.i2295, -1.330000e+00
  %6303 = select i1 %6302, double -1.330000e+00, double %t.6.i2295.op
  %6304 = fmul reassoc ninf nsz double %.01382, %47
  %6305 = fmul reassoc ninf nsz double %.01381, %50
  %6306 = fadd reassoc ninf nsz double %6305, %6304
  %6307 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %6306, double 0.000000e+00)
  %6308 = fmul reassoc ninf nsz double %6303, %6307
  %6309 = fmul reassoc ninf nsz double %.01381, %47
  %6310 = fmul reassoc ninf nsz double %.01382, %50
  %6311 = fsub reassoc ninf nsz double %6309, %6310
  %6312 = fmul reassoc ninf nsz double %6303, %6311
  %6313 = fsub reassoc ninf nsz double %40, %37
  %6314 = fmul reassoc ninf nsz double %6313, %6313
  %6315 = fmul reassoc ninf nsz double %6314, 4.905000e+00
  br label %after_if9

false_block2477:                                  ; preds = %false_block2471
  %6316 = fcmp ogt double %.01383, %5910
  %6317 = fcmp ogt double %40, %5910
  %.0751 = select i1 %6317, i1 %6316, i1 false
  br i1 %.0751, label %true_block2482, label %after_if9

true_block2482:                                   ; preds = %false_block2477
  %6318 = fsub reassoc ninf nsz double %40, %.01383
  %6319 = tail call double @llvm.fabs.f64(double %6318)
  %6320 = fcmp reassoc ninf nsz ugt double %40, %.01383
  br i1 %6320, label %false_block2486, label %true_block2485

true_block2485:                                   ; preds = %true_block2482
  %6321 = fsub reassoc ninf nsz double %40, %5910
  %6322 = fmul reassoc ninf nsz double %.01382, %47
  %6323 = fmul reassoc ninf nsz double %.01381, %50
  %6324 = fadd reassoc ninf nsz double %6323, %6322
  %6325 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %6324, double 0.000000e+00)
  %6326 = fmul reassoc ninf nsz double %.01381, %47
  %6327 = fmul reassoc ninf nsz double %.01382, %50
  %6328 = fsub reassoc ninf nsz double %6326, %6327
  %6329 = fadd reassoc ninf nsz double %6321, %6319
  %6330 = fdiv reassoc ninf nsz double %6319, %6329
  %6331 = tail call i32 @llvm.nvvm.d2i.hi(double %6330)
  %6332 = tail call i32 @llvm.nvvm.d2i.hi(double 3.333300e-01)
  %6333 = and i32 %6332, 2146435072
  %6334 = tail call double @llvm.fabs.f64(double %6330)
  %6335 = tail call i32 @llvm.nvvm.d2i.hi(double %6334)
  %6336 = tail call i32 @llvm.nvvm.d2i.lo(double %6334)
  %6337 = lshr i32 %6335, 20
  %6338 = icmp ult i32 %6335, 1048576
  %6339 = fmul double %6334, 0x4350000000000000
  %6340 = tail call i32 @llvm.nvvm.d2i.hi(double %6339)
  %6341 = tail call i32 @llvm.nvvm.d2i.lo(double %6339)
  %6342 = lshr i32 %6340, 20
  %6343 = add nsw i32 %6342, -54
  %ilo.0.i.i.i2238 = select i1 %6338, i32 %6341, i32 %6336
  %ihi.0.i.i.i2239 = select i1 %6338, i32 %6340, i32 %6335
  %expo.0.i.i.i2240 = select i1 %6338, i32 %6343, i32 %6337
  %6344 = and i32 %ihi.0.i.i.i2239, -2146435073
  %6345 = or i32 %6344, 1072693248
  %6346 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2238, i32 %6345)
  %6347 = icmp ugt i32 %6345, 1073127582
  %6348 = tail call i32 @llvm.nvvm.d2i.lo(double %6346)
  %6349 = tail call i32 @llvm.nvvm.d2i.hi(double %6346)
  %6350 = add i32 %6349, -1048576
  %6351 = tail call double @llvm.nvvm.lohi.i2d(i32 %6348, i32 %6350)
  %m.0.i.i.i2241 = select i1 %6347, double %6351, double %6346
  %expo.1.i.v.i.i2242 = select i1 %6347, i32 -1022, i32 -1023
  %expo.1.i.i.i2243 = add nsw i32 %expo.1.i.v.i.i2242, %expo.0.i.i.i2240
  %6352 = fadd double %m.0.i.i.i2241, -1.000000e+00
  %6353 = fadd double %m.0.i.i.i2241, 1.000000e+00
  %6354 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %6353)
  %6355 = fneg double %6353
  %6356 = tail call double @llvm.fma.f64(double %6355, double %6354, double 1.000000e+00)
  %6357 = tail call double @llvm.fma.f64(double %6356, double %6356, double %6356)
  %6358 = tail call double @llvm.fma.f64(double %6357, double %6354, double %6354)
  %6359 = fmul double %6352, %6358
  %6360 = fadd double %6359, %6359
  %6361 = fmul double %6360, %6360
  %6362 = tail call double @llvm.fma.f64(double %6361, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %6363 = tail call double @llvm.fma.f64(double %6362, double %6361, double 0x3EF3B20A75488A3F)
  %6364 = tail call double @llvm.fma.f64(double %6363, double %6361, double 0x3F1745CDE4FAECD5)
  %6365 = tail call double @llvm.fma.f64(double %6364, double %6361, double 0x3F3C71C7258A578B)
  %6366 = tail call double @llvm.fma.f64(double %6365, double %6361, double 0x3F6249249242B910)
  %6367 = tail call double @llvm.fma.f64(double %6366, double %6361, double 0x3F89999999999DFB)
  %6368 = fmul double %6361, %6367
  %6369 = fsub double %6352, %6360
  %6370 = fmul double %6369, 2.000000e+00
  %6371 = fneg double %6360
  %6372 = tail call double @llvm.fma.f64(double %6371, double %6352, double %6370)
  %6373 = fmul double %6358, %6372
  %6374 = fadd double %6368, 0x3FB5555555555555
  %6375 = fsub double 0x3FB5555555555555, %6374
  %6376 = fadd double %6368, %6375
  %6377 = fadd double %6376, 0.000000e+00
  %6378 = fadd double %6377, 0xBC46A4CB00B9E7B0
  %6379 = fadd double %6374, %6378
  %6380 = fsub double %6374, %6379
  %6381 = fadd double %6378, %6380
  %6382 = fneg double %6361
  %6383 = tail call double @llvm.fma.f64(double %6360, double %6360, double %6382)
  %6384 = tail call i32 @llvm.nvvm.d2i.lo(double %6373)
  %6385 = tail call i32 @llvm.nvvm.d2i.hi(double %6373)
  %6386 = add i32 %6385, 1048576
  %6387 = tail call double @llvm.nvvm.lohi.i2d(i32 %6384, i32 %6386)
  %6388 = tail call double @llvm.fma.f64(double %6360, double %6387, double %6383)
  %6389 = fmul double %6360, %6361
  %6390 = fneg double %6389
  %6391 = tail call double @llvm.fma.f64(double %6361, double %6360, double %6390)
  %6392 = tail call double @llvm.fma.f64(double %6361, double %6373, double %6391)
  %6393 = tail call double @llvm.fma.f64(double %6388, double %6360, double %6392)
  %6394 = fmul double %6389, %6379
  %6395 = fneg double %6394
  %6396 = tail call double @llvm.fma.f64(double %6379, double %6389, double %6395)
  %6397 = tail call double @llvm.fma.f64(double %6379, double %6393, double %6396)
  %6398 = tail call double @llvm.fma.f64(double %6381, double %6389, double %6397)
  %6399 = fadd double %6394, %6398
  %6400 = fsub double %6394, %6399
  %6401 = fadd double %6398, %6400
  %6402 = fadd double %6360, %6399
  %6403 = fsub double %6360, %6402
  %6404 = fadd double %6399, %6403
  %6405 = fadd double %6401, %6404
  %6406 = fadd double %6373, %6405
  %6407 = fadd double %6402, %6406
  %6408 = fsub double %6402, %6407
  %6409 = fadd double %6406, %6408
  %6410 = xor i32 %expo.1.i.i.i2243, -2147483648
  %6411 = tail call double @llvm.nvvm.lohi.i2d(i32 %6410, i32 1127219200)
  %6412 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %6413 = fsub double %6411, %6412
  %6414 = tail call double @llvm.fma.f64(double %6413, double 0x3FE62E42FEFA39EF, double %6407)
  %6415 = fneg double %6413
  %6416 = tail call double @llvm.fma.f64(double %6415, double 0x3FE62E42FEFA39EF, double %6414)
  %6417 = fsub double %6416, %6407
  %6418 = fsub double %6409, %6417
  %6419 = tail call double @llvm.fma.f64(double %6413, double 0x3C7ABC9E3B39803F, double %6418)
  %6420 = fadd double %6414, %6419
  %6421 = fsub double %6414, %6420
  %6422 = fadd double %6419, %6421
  %6423 = tail call i32 @llvm.nvvm.d2i.lo(double 3.333300e-01)
  %6424 = shl i32 %6332, 1
  %6425 = icmp ugt i32 %6424, -33554433
  %6426 = and i32 %6332, -15728641
  %spec.select.i.i2244 = select i1 %6425, i32 %6426, i32 %6332
  %6427 = tail call double @llvm.nvvm.lohi.i2d(i32 %6423, i32 %spec.select.i.i2244)
  %6428 = fmul double %6427, %6420
  %6429 = fneg double %6428
  %6430 = tail call double @llvm.fma.f64(double %6420, double %6427, double %6429)
  %6431 = tail call double @llvm.fma.f64(double %6422, double %6427, double %6430)
  %6432 = fadd double %6428, %6431
  %6433 = tail call double @llvm.fma.f64(double %6432, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %6434 = tail call i32 @llvm.nvvm.d2i.lo(double %6433)
  %6435 = fadd double %6433, 0xC338000000000000
  %6436 = tail call double @llvm.fma.f64(double %6435, double 0xBFE62E42FEFA39EF, double %6432)
  %6437 = tail call double @llvm.fma.f64(double %6435, double 0xBC7ABC9E3B39803F, double %6436)
  %6438 = tail call double @llvm.fma.f64(double %6437, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %6439 = tail call double @llvm.fma.f64(double %6438, double %6437, double 0x3EC71DEE62401315)
  %6440 = tail call double @llvm.fma.f64(double %6439, double %6437, double 0x3EFA01997C89EB71)
  %6441 = tail call double @llvm.fma.f64(double %6440, double %6437, double 0x3F2A01A014761F65)
  %6442 = tail call double @llvm.fma.f64(double %6441, double %6437, double 0x3F56C16C1852B7AF)
  %6443 = tail call double @llvm.fma.f64(double %6442, double %6437, double 0x3F81111111122322)
  %6444 = tail call double @llvm.fma.f64(double %6443, double %6437, double 0x3FA55555555502A1)
  %6445 = tail call double @llvm.fma.f64(double %6444, double %6437, double 0x3FC5555555555511)
  %6446 = tail call double @llvm.fma.f64(double %6445, double %6437, double 0x3FE000000000000B)
  %6447 = tail call double @llvm.fma.f64(double %6446, double %6437, double 1.000000e+00)
  %6448 = tail call double @llvm.fma.f64(double %6447, double %6437, double 1.000000e+00)
  %6449 = tail call i32 @llvm.nvvm.d2i.lo(double %6448)
  %6450 = tail call i32 @llvm.nvvm.d2i.hi(double %6448)
  %6451 = shl i32 %6434, 20
  %6452 = add i32 %6450, %6451
  %6453 = tail call double @llvm.nvvm.lohi.i2d(i32 %6449, i32 %6452)
  %6454 = tail call i32 @llvm.nvvm.d2i.hi(double %6432)
  %6455 = bitcast i32 %6454 to float
  %6456 = tail call float @llvm.fabs.f32(float %6455)
  %6457 = fcmp uge float %6456, 0x4010C46560000000
  br i1 %6457, label %__internal_fast_icmp_abs_lt.exit.i.i.i2246, label %__internal_accurate_pow.exit.i2249

__internal_fast_icmp_abs_lt.exit.i.i.i2246:       ; preds = %true_block2485
  %6458 = fcmp olt double %6432, 0.000000e+00
  %6459 = fadd double %6432, 0x7FF0000000000000
  %z.0.i.i.i2245 = select i1 %6458, double 0.000000e+00, double %6459
  %6460 = fcmp olt float %6456, 0x4010E90000000000
  br i1 %6460, label %6461, label %__internal_accurate_pow.exit.i2249

6461:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2246
  %6462 = sdiv i32 %6434, 2
  %6463 = shl i32 %6462, 20
  %6464 = add i32 %6450, %6463
  %6465 = tail call double @llvm.nvvm.lohi.i2d(i32 %6449, i32 %6464)
  %6466 = sub nsw i32 %6434, %6462
  %6467 = shl i32 %6466, 20
  %6468 = add nsw i32 %6467, 1072693248
  %6469 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %6468)
  %6470 = fmul double %6469, %6465
  br label %__internal_accurate_pow.exit.i2249

__internal_accurate_pow.exit.i2249:               ; preds = %6461, %__internal_fast_icmp_abs_lt.exit.i.i.i2246, %true_block2485
  %z.2.i.i.i2247 = phi double [ %6453, %true_block2485 ], [ %6470, %6461 ], [ %z.0.i.i.i2245, %__internal_fast_icmp_abs_lt.exit.i.i.i2246 ]
  %6471 = icmp eq i32 %6333, 1126170624
  %6472 = icmp slt i32 %6331, 0
  %spec.select.i2248 = select i1 %6472, i1 %6471, i1 false
  %6473 = fcmp oeq double %6330, 0.000000e+00
  br i1 %6473, label %6474, label %6479

6474:                                             ; preds = %__internal_accurate_pow.exit.i2249
  %6475 = icmp eq i32 %6333, 1126170624
  %spec.select1.i2250 = select i1 %6475, i32 %6331, i32 0
  %6476 = icmp slt i32 %6332, 0
  %6477 = or i32 %spec.select1.i2250, 2146435072
  %thi.1.i2251 = select i1 %6476, i32 %6477, i32 %spec.select1.i2250
  %6478 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2251)
  br label %6494

6479:                                             ; preds = %__internal_accurate_pow.exit.i2249
  %6480 = icmp slt i32 %6331, 0
  %6481 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2247)
  %6482 = and i32 %6481, 2147483647
  %6483 = icmp ne i32 %6482, 2146435072
  %6484 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2247)
  %6485 = icmp ne i32 %6484, 0
  %6486 = select i1 %6483, i1 true, i1 %6485
  %6487 = fsub double %6428, %6432
  %6488 = fadd double %6431, %6487
  %6489 = tail call double @llvm.fma.f64(double %z.2.i.i.i2247, double %6488, double %z.2.i.i.i2247)
  %tmp.0.i.i2252 = select i1 %6486, double %6489, double %z.2.i.i.i2247
  %6490 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2252)
  %6491 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2252)
  %6492 = xor i32 %6491, -2147483648
  %6493 = tail call double @llvm.nvvm.lohi.i2d(i32 %6490, i32 %6492)
  %t.0.i2253 = select i1 %spec.select.i2248, double %6493, double %tmp.0.i.i2252
  %t.1.i2254 = select i1 %6480, double 0xFFF8000000000000, double %t.0.i2253
  br label %6494

6494:                                             ; preds = %6479, %6474
  %t.2.i2255 = phi double [ %6478, %6474 ], [ %t.1.i2254, %6479 ]
  %6495 = fadd double %6330, 3.333300e-01
  %6496 = tail call i32 @llvm.nvvm.d2i.hi(double %6495)
  %6497 = and i32 %6496, 2146435072
  %6498 = icmp eq i32 %6497, 2146435072
  br i1 %6498, label %6499, label %__nv_pow.exit2267

6499:                                             ; preds = %6494
  %6500 = fcmp ugt double %6334, 0x7FF0000000000000
  br i1 %6500, label %__nv_pow.exit2267, label %__nv_isinfd.exit5.i2256

__nv_isinfd.exit5.i2256:                          ; preds = %6499
  %6501 = and i32 %6332, 2147483647
  %6502 = icmp eq i32 %6501, 2146435072
  %6503 = icmp eq i32 %6423, 0
  %6504 = select i1 %6502, i1 %6503, i1 false
  br i1 %6504, label %6505, label %__nv_isinfd.exit.i2264

6505:                                             ; preds = %__nv_isinfd.exit5.i2256
  %6506 = fcmp ogt double %6334, 1.000000e+00
  %thi.2.i2257 = select i1 %6506, i32 2146435072, i32 0
  %6507 = icmp slt i32 %6332, 0
  %6508 = xor i32 %thi.2.i2257, 2146435072
  %thi.3.i2258 = select i1 %6507, i32 %6508, i32 %thi.2.i2257
  %6509 = fcmp oeq double %6330, -1.000000e+00
  %thi.4.i2259 = select i1 %6509, i32 1072693248, i32 %thi.3.i2258
  %6510 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2259)
  br label %__nv_pow.exit2267

__nv_isinfd.exit.i2264:                           ; preds = %__nv_isinfd.exit5.i2256
  %6511 = tail call i32 @llvm.nvvm.d2i.lo(double %6330)
  %6512 = and i32 %6331, 2147483647
  %6513 = icmp eq i32 %6512, 2146435072
  %6514 = icmp eq i32 %6511, 0
  %6515 = select i1 %6513, i1 %6514, i1 false
  %.inv.i2260 = icmp slt i32 %6332, 0
  %spec.select8.i2261 = select i1 %.inv.i2260, i32 0, i32 2146435072
  %6516 = or i32 %spec.select8.i2261, -2147483648
  %thi.6.i2262 = select i1 %spec.select.i2248, i32 %6516, i32 %spec.select8.i2261
  %6517 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2262)
  %spec.select10.i2263 = select i1 %6515, double %6517, double %t.2.i2255
  br label %__nv_pow.exit2267

__nv_pow.exit2267:                                ; preds = %6494, %6499, %6505, %__nv_isinfd.exit.i2264
  %t.6.i2265 = phi double [ %t.2.i2255, %6494 ], [ %6510, %6505 ], [ %6495, %6499 ], [ %spec.select10.i2263, %__nv_isinfd.exit.i2264 ]
  %6518 = fcmp oeq double %6330, 1.000000e+00
  %t.6.i2265.op = fmul reassoc ninf nsz double %t.6.i2265, 1.050000e+00
  %6519 = select i1 %6518, double 1.050000e+00, double %t.6.i2265.op
  %6520 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %6519, double 1.000000e+00)
  %6521 = fcmp reassoc ninf nsz olt double %40, %.01383
  %6522 = fcmp reassoc ninf nsz ogt double %6325, 0.000000e+00
  %.0749 = select i1 %6521, i1 %6522, i1 false
  %.0750 = select i1 %.0749, double 0.000000e+00, double %6325
  %6523 = fmul reassoc ninf nsz double %6520, 1.700000e+00
  %6524 = tail call i32 @llvm.nvvm.d2i.hi(double %6329)
  %6525 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %6526 = and i32 %6525, 2146435072
  %6527 = tail call double @llvm.fabs.f64(double %6329)
  %6528 = tail call i32 @llvm.nvvm.d2i.hi(double %6527)
  %6529 = tail call i32 @llvm.nvvm.d2i.lo(double %6527)
  %6530 = lshr i32 %6528, 20
  %6531 = icmp ult i32 %6528, 1048576
  %6532 = fmul double %6527, 0x4350000000000000
  %6533 = tail call i32 @llvm.nvvm.d2i.hi(double %6532)
  %6534 = tail call i32 @llvm.nvvm.d2i.lo(double %6532)
  %6535 = lshr i32 %6533, 20
  %6536 = add nsw i32 %6535, -54
  %ilo.0.i.i.i2208 = select i1 %6531, i32 %6534, i32 %6529
  %ihi.0.i.i.i2209 = select i1 %6531, i32 %6533, i32 %6528
  %expo.0.i.i.i2210 = select i1 %6531, i32 %6536, i32 %6530
  %6537 = and i32 %ihi.0.i.i.i2209, -2146435073
  %6538 = or i32 %6537, 1072693248
  %6539 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2208, i32 %6538)
  %6540 = icmp ugt i32 %6538, 1073127582
  %6541 = tail call i32 @llvm.nvvm.d2i.lo(double %6539)
  %6542 = tail call i32 @llvm.nvvm.d2i.hi(double %6539)
  %6543 = add i32 %6542, -1048576
  %6544 = tail call double @llvm.nvvm.lohi.i2d(i32 %6541, i32 %6543)
  %m.0.i.i.i2211 = select i1 %6540, double %6544, double %6539
  %expo.1.i.v.i.i2212 = select i1 %6540, i32 -1022, i32 -1023
  %expo.1.i.i.i2213 = add nsw i32 %expo.1.i.v.i.i2212, %expo.0.i.i.i2210
  %6545 = fadd double %m.0.i.i.i2211, -1.000000e+00
  %6546 = fadd double %m.0.i.i.i2211, 1.000000e+00
  %6547 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %6546)
  %6548 = fneg double %6546
  %6549 = tail call double @llvm.fma.f64(double %6548, double %6547, double 1.000000e+00)
  %6550 = tail call double @llvm.fma.f64(double %6549, double %6549, double %6549)
  %6551 = tail call double @llvm.fma.f64(double %6550, double %6547, double %6547)
  %6552 = fmul double %6545, %6551
  %6553 = fadd double %6552, %6552
  %6554 = fmul double %6553, %6553
  %6555 = tail call double @llvm.fma.f64(double %6554, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %6556 = tail call double @llvm.fma.f64(double %6555, double %6554, double 0x3EF3B20A75488A3F)
  %6557 = tail call double @llvm.fma.f64(double %6556, double %6554, double 0x3F1745CDE4FAECD5)
  %6558 = tail call double @llvm.fma.f64(double %6557, double %6554, double 0x3F3C71C7258A578B)
  %6559 = tail call double @llvm.fma.f64(double %6558, double %6554, double 0x3F6249249242B910)
  %6560 = tail call double @llvm.fma.f64(double %6559, double %6554, double 0x3F89999999999DFB)
  %6561 = fmul double %6554, %6560
  %6562 = fsub double %6545, %6553
  %6563 = fmul double %6562, 2.000000e+00
  %6564 = fneg double %6553
  %6565 = tail call double @llvm.fma.f64(double %6564, double %6545, double %6563)
  %6566 = fmul double %6551, %6565
  %6567 = fadd double %6561, 0x3FB5555555555555
  %6568 = fsub double 0x3FB5555555555555, %6567
  %6569 = fadd double %6561, %6568
  %6570 = fadd double %6569, 0.000000e+00
  %6571 = fadd double %6570, 0xBC46A4CB00B9E7B0
  %6572 = fadd double %6567, %6571
  %6573 = fsub double %6567, %6572
  %6574 = fadd double %6571, %6573
  %6575 = fneg double %6554
  %6576 = tail call double @llvm.fma.f64(double %6553, double %6553, double %6575)
  %6577 = tail call i32 @llvm.nvvm.d2i.lo(double %6566)
  %6578 = tail call i32 @llvm.nvvm.d2i.hi(double %6566)
  %6579 = add i32 %6578, 1048576
  %6580 = tail call double @llvm.nvvm.lohi.i2d(i32 %6577, i32 %6579)
  %6581 = tail call double @llvm.fma.f64(double %6553, double %6580, double %6576)
  %6582 = fmul double %6553, %6554
  %6583 = fneg double %6582
  %6584 = tail call double @llvm.fma.f64(double %6554, double %6553, double %6583)
  %6585 = tail call double @llvm.fma.f64(double %6554, double %6566, double %6584)
  %6586 = tail call double @llvm.fma.f64(double %6581, double %6553, double %6585)
  %6587 = fmul double %6582, %6572
  %6588 = fneg double %6587
  %6589 = tail call double @llvm.fma.f64(double %6572, double %6582, double %6588)
  %6590 = tail call double @llvm.fma.f64(double %6572, double %6586, double %6589)
  %6591 = tail call double @llvm.fma.f64(double %6574, double %6582, double %6590)
  %6592 = fadd double %6587, %6591
  %6593 = fsub double %6587, %6592
  %6594 = fadd double %6591, %6593
  %6595 = fadd double %6553, %6592
  %6596 = fsub double %6553, %6595
  %6597 = fadd double %6592, %6596
  %6598 = fadd double %6594, %6597
  %6599 = fadd double %6566, %6598
  %6600 = fadd double %6595, %6599
  %6601 = fsub double %6595, %6600
  %6602 = fadd double %6599, %6601
  %6603 = xor i32 %expo.1.i.i.i2213, -2147483648
  %6604 = tail call double @llvm.nvvm.lohi.i2d(i32 %6603, i32 1127219200)
  %6605 = fsub double %6604, %6412
  %6606 = tail call double @llvm.fma.f64(double %6605, double 0x3FE62E42FEFA39EF, double %6600)
  %6607 = fneg double %6605
  %6608 = tail call double @llvm.fma.f64(double %6607, double 0x3FE62E42FEFA39EF, double %6606)
  %6609 = fsub double %6608, %6600
  %6610 = fsub double %6602, %6609
  %6611 = tail call double @llvm.fma.f64(double %6605, double 0x3C7ABC9E3B39803F, double %6610)
  %6612 = fadd double %6606, %6611
  %6613 = fsub double %6606, %6612
  %6614 = fadd double %6611, %6613
  %6615 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %6616 = shl i32 %6525, 1
  %6617 = icmp ugt i32 %6616, -33554433
  %6618 = and i32 %6525, -15728641
  %spec.select.i.i2214 = select i1 %6617, i32 %6618, i32 %6525
  %6619 = tail call double @llvm.nvvm.lohi.i2d(i32 %6615, i32 %spec.select.i.i2214)
  %6620 = fmul double %6619, %6612
  %6621 = fneg double %6620
  %6622 = tail call double @llvm.fma.f64(double %6612, double %6619, double %6621)
  %6623 = tail call double @llvm.fma.f64(double %6614, double %6619, double %6622)
  %6624 = fadd double %6620, %6623
  %6625 = tail call double @llvm.fma.f64(double %6624, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %6626 = tail call i32 @llvm.nvvm.d2i.lo(double %6625)
  %6627 = fadd double %6625, 0xC338000000000000
  %6628 = tail call double @llvm.fma.f64(double %6627, double 0xBFE62E42FEFA39EF, double %6624)
  %6629 = tail call double @llvm.fma.f64(double %6627, double 0xBC7ABC9E3B39803F, double %6628)
  %6630 = tail call double @llvm.fma.f64(double %6629, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %6631 = tail call double @llvm.fma.f64(double %6630, double %6629, double 0x3EC71DEE62401315)
  %6632 = tail call double @llvm.fma.f64(double %6631, double %6629, double 0x3EFA01997C89EB71)
  %6633 = tail call double @llvm.fma.f64(double %6632, double %6629, double 0x3F2A01A014761F65)
  %6634 = tail call double @llvm.fma.f64(double %6633, double %6629, double 0x3F56C16C1852B7AF)
  %6635 = tail call double @llvm.fma.f64(double %6634, double %6629, double 0x3F81111111122322)
  %6636 = tail call double @llvm.fma.f64(double %6635, double %6629, double 0x3FA55555555502A1)
  %6637 = tail call double @llvm.fma.f64(double %6636, double %6629, double 0x3FC5555555555511)
  %6638 = tail call double @llvm.fma.f64(double %6637, double %6629, double 0x3FE000000000000B)
  %6639 = tail call double @llvm.fma.f64(double %6638, double %6629, double 1.000000e+00)
  %6640 = tail call double @llvm.fma.f64(double %6639, double %6629, double 1.000000e+00)
  %6641 = tail call i32 @llvm.nvvm.d2i.lo(double %6640)
  %6642 = tail call i32 @llvm.nvvm.d2i.hi(double %6640)
  %6643 = shl i32 %6626, 20
  %6644 = add i32 %6642, %6643
  %6645 = tail call double @llvm.nvvm.lohi.i2d(i32 %6641, i32 %6644)
  %6646 = tail call i32 @llvm.nvvm.d2i.hi(double %6624)
  %6647 = bitcast i32 %6646 to float
  %6648 = tail call float @llvm.fabs.f32(float %6647)
  %6649 = fcmp uge float %6648, 0x4010C46560000000
  br i1 %6649, label %__internal_fast_icmp_abs_lt.exit.i.i.i2216, label %__internal_accurate_pow.exit.i2219

__internal_fast_icmp_abs_lt.exit.i.i.i2216:       ; preds = %__nv_pow.exit2267
  %6650 = fcmp olt double %6624, 0.000000e+00
  %6651 = fadd double %6624, 0x7FF0000000000000
  %z.0.i.i.i2215 = select i1 %6650, double 0.000000e+00, double %6651
  %6652 = fcmp olt float %6648, 0x4010E90000000000
  br i1 %6652, label %6653, label %__internal_accurate_pow.exit.i2219

6653:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2216
  %6654 = sdiv i32 %6626, 2
  %6655 = shl i32 %6654, 20
  %6656 = add i32 %6642, %6655
  %6657 = tail call double @llvm.nvvm.lohi.i2d(i32 %6641, i32 %6656)
  %6658 = sub nsw i32 %6626, %6654
  %6659 = shl i32 %6658, 20
  %6660 = add nsw i32 %6659, 1072693248
  %6661 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %6660)
  %6662 = fmul double %6661, %6657
  br label %__internal_accurate_pow.exit.i2219

__internal_accurate_pow.exit.i2219:               ; preds = %6653, %__internal_fast_icmp_abs_lt.exit.i.i.i2216, %__nv_pow.exit2267
  %z.2.i.i.i2217 = phi double [ %6645, %__nv_pow.exit2267 ], [ %6662, %6653 ], [ %z.0.i.i.i2215, %__internal_fast_icmp_abs_lt.exit.i.i.i2216 ]
  %6663 = icmp eq i32 %6526, 1073741824
  %6664 = icmp slt i32 %6524, 0
  %spec.select.i2218 = select i1 %6664, i1 %6663, i1 false
  %6665 = fcmp oeq double %6329, 0.000000e+00
  br i1 %6665, label %6666, label %6671

6666:                                             ; preds = %__internal_accurate_pow.exit.i2219
  %6667 = icmp eq i32 %6526, 1073741824
  %spec.select1.i2220 = select i1 %6667, i32 %6524, i32 0
  %6668 = icmp slt i32 %6525, 0
  %6669 = or i32 %spec.select1.i2220, 2146435072
  %thi.1.i2221 = select i1 %6668, i32 %6669, i32 %spec.select1.i2220
  %6670 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2221)
  br label %6686

6671:                                             ; preds = %__internal_accurate_pow.exit.i2219
  %6672 = icmp slt i32 %6524, 0
  %6673 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2217)
  %6674 = and i32 %6673, 2147483647
  %6675 = icmp ne i32 %6674, 2146435072
  %6676 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2217)
  %6677 = icmp ne i32 %6676, 0
  %6678 = select i1 %6675, i1 true, i1 %6677
  %6679 = fsub double %6620, %6624
  %6680 = fadd double %6623, %6679
  %6681 = tail call double @llvm.fma.f64(double %z.2.i.i.i2217, double %6680, double %z.2.i.i.i2217)
  %tmp.0.i.i2222 = select i1 %6678, double %6681, double %z.2.i.i.i2217
  %6682 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2222)
  %6683 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2222)
  %6684 = xor i32 %6683, -2147483648
  %6685 = tail call double @llvm.nvvm.lohi.i2d(i32 %6682, i32 %6684)
  %t.0.i2223 = select i1 %spec.select.i2218, double %6685, double %tmp.0.i.i2222
  %t.1.i2224 = select i1 %6672, double 0xFFF8000000000000, double %t.0.i2223
  br label %6686

6686:                                             ; preds = %6671, %6666
  %t.2.i2225 = phi double [ %6670, %6666 ], [ %t.1.i2224, %6671 ]
  %6687 = fadd double %6329, 1.500000e+00
  %6688 = tail call i32 @llvm.nvvm.d2i.hi(double %6687)
  %6689 = and i32 %6688, 2146435072
  %6690 = icmp eq i32 %6689, 2146435072
  br i1 %6690, label %6691, label %__nv_pow.exit2237

6691:                                             ; preds = %6686
  %6692 = fcmp ugt double %6527, 0x7FF0000000000000
  br i1 %6692, label %__nv_pow.exit2237, label %__nv_isinfd.exit5.i2226

__nv_isinfd.exit5.i2226:                          ; preds = %6691
  %6693 = and i32 %6525, 2147483647
  %6694 = icmp eq i32 %6693, 2146435072
  %6695 = icmp eq i32 %6615, 0
  %6696 = select i1 %6694, i1 %6695, i1 false
  br i1 %6696, label %6697, label %__nv_isinfd.exit.i2234

6697:                                             ; preds = %__nv_isinfd.exit5.i2226
  %6698 = fcmp ogt double %6527, 1.000000e+00
  %thi.2.i2227 = select i1 %6698, i32 2146435072, i32 0
  %6699 = icmp slt i32 %6525, 0
  %6700 = xor i32 %thi.2.i2227, 2146435072
  %thi.3.i2228 = select i1 %6699, i32 %6700, i32 %thi.2.i2227
  %6701 = fcmp oeq double %6329, -1.000000e+00
  %thi.4.i2229 = select i1 %6701, i32 1072693248, i32 %thi.3.i2228
  %6702 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2229)
  br label %__nv_pow.exit2237

__nv_isinfd.exit.i2234:                           ; preds = %__nv_isinfd.exit5.i2226
  %6703 = tail call i32 @llvm.nvvm.d2i.lo(double %6329)
  %6704 = and i32 %6524, 2147483647
  %6705 = icmp eq i32 %6704, 2146435072
  %6706 = icmp eq i32 %6703, 0
  %6707 = select i1 %6705, i1 %6706, i1 false
  %.inv.i2230 = icmp slt i32 %6525, 0
  %spec.select8.i2231 = select i1 %.inv.i2230, i32 0, i32 2146435072
  %6708 = or i32 %spec.select8.i2231, -2147483648
  %thi.6.i2232 = select i1 %spec.select.i2218, i32 %6708, i32 %spec.select8.i2231
  %6709 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2232)
  %spec.select10.i2233 = select i1 %6707, double %6709, double %t.2.i2225
  br label %__nv_pow.exit2237

__nv_pow.exit2237:                                ; preds = %6686, %6691, %6697, %__nv_isinfd.exit.i2234
  %t.6.i2235 = phi double [ %t.2.i2225, %6686 ], [ %6702, %6697 ], [ %6687, %6691 ], [ %spec.select10.i2233, %__nv_isinfd.exit.i2234 ]
  %6710 = fcmp oeq double %6329, 1.000000e+00
  %t.7.i2236 = select i1 %6710, double 1.000000e+00, double %t.6.i2235
  %6711 = fmul reassoc ninf nsz double %6523, %t.7.i2236
  %6712 = fcmp reassoc ninf nsz olt double %6318, 0.000000e+00
  %6713 = tail call double @llvm.fabs.f64(double %6711)
  %neg2494 = fneg reassoc ninf nsz double %6713
  %6714 = select reassoc ninf nsz i1 %6712, double %neg2494, double %6713
  %6715 = tail call double @llvm.fabs.f64(double %.0750)
  %6716 = fmul reassoc ninf nsz double %6714, %6715
  %6717 = fmul reassoc ninf nsz double %6714, %6328
  %6718 = fsub reassoc ninf nsz double %5910, %37
  %6719 = fmul reassoc ninf nsz double %6718, %6718
  %6720 = fmul reassoc ninf nsz double %6719, 4.905000e+00
  br label %after_if9

false_block2486:                                  ; preds = %true_block2482
  %6721 = fsub reassoc ninf nsz double %.01383, %5910
  %6722 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %53, double 0.000000e+00)
  %6723 = fadd reassoc ninf nsz double %6721, %6319
  %6724 = fdiv reassoc ninf nsz double %6319, %6723
  %6725 = tail call i32 @llvm.nvvm.d2i.hi(double %6724)
  %6726 = tail call i32 @llvm.nvvm.d2i.hi(double 3.333300e-01)
  %6727 = and i32 %6726, 2146435072
  %6728 = tail call double @llvm.fabs.f64(double %6724)
  %6729 = tail call i32 @llvm.nvvm.d2i.hi(double %6728)
  %6730 = tail call i32 @llvm.nvvm.d2i.lo(double %6728)
  %6731 = lshr i32 %6729, 20
  %6732 = icmp ult i32 %6729, 1048576
  %6733 = fmul double %6728, 0x4350000000000000
  %6734 = tail call i32 @llvm.nvvm.d2i.hi(double %6733)
  %6735 = tail call i32 @llvm.nvvm.d2i.lo(double %6733)
  %6736 = lshr i32 %6734, 20
  %6737 = add nsw i32 %6736, -54
  %ilo.0.i.i.i2178 = select i1 %6732, i32 %6735, i32 %6730
  %ihi.0.i.i.i2179 = select i1 %6732, i32 %6734, i32 %6729
  %expo.0.i.i.i2180 = select i1 %6732, i32 %6737, i32 %6731
  %6738 = and i32 %ihi.0.i.i.i2179, -2146435073
  %6739 = or i32 %6738, 1072693248
  %6740 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2178, i32 %6739)
  %6741 = icmp ugt i32 %6739, 1073127582
  %6742 = tail call i32 @llvm.nvvm.d2i.lo(double %6740)
  %6743 = tail call i32 @llvm.nvvm.d2i.hi(double %6740)
  %6744 = add i32 %6743, -1048576
  %6745 = tail call double @llvm.nvvm.lohi.i2d(i32 %6742, i32 %6744)
  %m.0.i.i.i2181 = select i1 %6741, double %6745, double %6740
  %expo.1.i.v.i.i2182 = select i1 %6741, i32 -1022, i32 -1023
  %expo.1.i.i.i2183 = add nsw i32 %expo.1.i.v.i.i2182, %expo.0.i.i.i2180
  %6746 = fadd double %m.0.i.i.i2181, -1.000000e+00
  %6747 = fadd double %m.0.i.i.i2181, 1.000000e+00
  %6748 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %6747)
  %6749 = fneg double %6747
  %6750 = tail call double @llvm.fma.f64(double %6749, double %6748, double 1.000000e+00)
  %6751 = tail call double @llvm.fma.f64(double %6750, double %6750, double %6750)
  %6752 = tail call double @llvm.fma.f64(double %6751, double %6748, double %6748)
  %6753 = fmul double %6746, %6752
  %6754 = fadd double %6753, %6753
  %6755 = fmul double %6754, %6754
  %6756 = tail call double @llvm.fma.f64(double %6755, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %6757 = tail call double @llvm.fma.f64(double %6756, double %6755, double 0x3EF3B20A75488A3F)
  %6758 = tail call double @llvm.fma.f64(double %6757, double %6755, double 0x3F1745CDE4FAECD5)
  %6759 = tail call double @llvm.fma.f64(double %6758, double %6755, double 0x3F3C71C7258A578B)
  %6760 = tail call double @llvm.fma.f64(double %6759, double %6755, double 0x3F6249249242B910)
  %6761 = tail call double @llvm.fma.f64(double %6760, double %6755, double 0x3F89999999999DFB)
  %6762 = fmul double %6755, %6761
  %6763 = fsub double %6746, %6754
  %6764 = fmul double %6763, 2.000000e+00
  %6765 = fneg double %6754
  %6766 = tail call double @llvm.fma.f64(double %6765, double %6746, double %6764)
  %6767 = fmul double %6752, %6766
  %6768 = fadd double %6762, 0x3FB5555555555555
  %6769 = fsub double 0x3FB5555555555555, %6768
  %6770 = fadd double %6762, %6769
  %6771 = fadd double %6770, 0.000000e+00
  %6772 = fadd double %6771, 0xBC46A4CB00B9E7B0
  %6773 = fadd double %6768, %6772
  %6774 = fsub double %6768, %6773
  %6775 = fadd double %6772, %6774
  %6776 = fneg double %6755
  %6777 = tail call double @llvm.fma.f64(double %6754, double %6754, double %6776)
  %6778 = tail call i32 @llvm.nvvm.d2i.lo(double %6767)
  %6779 = tail call i32 @llvm.nvvm.d2i.hi(double %6767)
  %6780 = add i32 %6779, 1048576
  %6781 = tail call double @llvm.nvvm.lohi.i2d(i32 %6778, i32 %6780)
  %6782 = tail call double @llvm.fma.f64(double %6754, double %6781, double %6777)
  %6783 = fmul double %6754, %6755
  %6784 = fneg double %6783
  %6785 = tail call double @llvm.fma.f64(double %6755, double %6754, double %6784)
  %6786 = tail call double @llvm.fma.f64(double %6755, double %6767, double %6785)
  %6787 = tail call double @llvm.fma.f64(double %6782, double %6754, double %6786)
  %6788 = fmul double %6783, %6773
  %6789 = fneg double %6788
  %6790 = tail call double @llvm.fma.f64(double %6773, double %6783, double %6789)
  %6791 = tail call double @llvm.fma.f64(double %6773, double %6787, double %6790)
  %6792 = tail call double @llvm.fma.f64(double %6775, double %6783, double %6791)
  %6793 = fadd double %6788, %6792
  %6794 = fsub double %6788, %6793
  %6795 = fadd double %6792, %6794
  %6796 = fadd double %6754, %6793
  %6797 = fsub double %6754, %6796
  %6798 = fadd double %6793, %6797
  %6799 = fadd double %6795, %6798
  %6800 = fadd double %6767, %6799
  %6801 = fadd double %6796, %6800
  %6802 = fsub double %6796, %6801
  %6803 = fadd double %6800, %6802
  %6804 = xor i32 %expo.1.i.i.i2183, -2147483648
  %6805 = tail call double @llvm.nvvm.lohi.i2d(i32 %6804, i32 1127219200)
  %6806 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %6807 = fsub double %6805, %6806
  %6808 = tail call double @llvm.fma.f64(double %6807, double 0x3FE62E42FEFA39EF, double %6801)
  %6809 = fneg double %6807
  %6810 = tail call double @llvm.fma.f64(double %6809, double 0x3FE62E42FEFA39EF, double %6808)
  %6811 = fsub double %6810, %6801
  %6812 = fsub double %6803, %6811
  %6813 = tail call double @llvm.fma.f64(double %6807, double 0x3C7ABC9E3B39803F, double %6812)
  %6814 = fadd double %6808, %6813
  %6815 = fsub double %6808, %6814
  %6816 = fadd double %6813, %6815
  %6817 = tail call i32 @llvm.nvvm.d2i.lo(double 3.333300e-01)
  %6818 = shl i32 %6726, 1
  %6819 = icmp ugt i32 %6818, -33554433
  %6820 = and i32 %6726, -15728641
  %spec.select.i.i2184 = select i1 %6819, i32 %6820, i32 %6726
  %6821 = tail call double @llvm.nvvm.lohi.i2d(i32 %6817, i32 %spec.select.i.i2184)
  %6822 = fmul double %6821, %6814
  %6823 = fneg double %6822
  %6824 = tail call double @llvm.fma.f64(double %6814, double %6821, double %6823)
  %6825 = tail call double @llvm.fma.f64(double %6816, double %6821, double %6824)
  %6826 = fadd double %6822, %6825
  %6827 = tail call double @llvm.fma.f64(double %6826, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %6828 = tail call i32 @llvm.nvvm.d2i.lo(double %6827)
  %6829 = fadd double %6827, 0xC338000000000000
  %6830 = tail call double @llvm.fma.f64(double %6829, double 0xBFE62E42FEFA39EF, double %6826)
  %6831 = tail call double @llvm.fma.f64(double %6829, double 0xBC7ABC9E3B39803F, double %6830)
  %6832 = tail call double @llvm.fma.f64(double %6831, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %6833 = tail call double @llvm.fma.f64(double %6832, double %6831, double 0x3EC71DEE62401315)
  %6834 = tail call double @llvm.fma.f64(double %6833, double %6831, double 0x3EFA01997C89EB71)
  %6835 = tail call double @llvm.fma.f64(double %6834, double %6831, double 0x3F2A01A014761F65)
  %6836 = tail call double @llvm.fma.f64(double %6835, double %6831, double 0x3F56C16C1852B7AF)
  %6837 = tail call double @llvm.fma.f64(double %6836, double %6831, double 0x3F81111111122322)
  %6838 = tail call double @llvm.fma.f64(double %6837, double %6831, double 0x3FA55555555502A1)
  %6839 = tail call double @llvm.fma.f64(double %6838, double %6831, double 0x3FC5555555555511)
  %6840 = tail call double @llvm.fma.f64(double %6839, double %6831, double 0x3FE000000000000B)
  %6841 = tail call double @llvm.fma.f64(double %6840, double %6831, double 1.000000e+00)
  %6842 = tail call double @llvm.fma.f64(double %6841, double %6831, double 1.000000e+00)
  %6843 = tail call i32 @llvm.nvvm.d2i.lo(double %6842)
  %6844 = tail call i32 @llvm.nvvm.d2i.hi(double %6842)
  %6845 = shl i32 %6828, 20
  %6846 = add i32 %6844, %6845
  %6847 = tail call double @llvm.nvvm.lohi.i2d(i32 %6843, i32 %6846)
  %6848 = tail call i32 @llvm.nvvm.d2i.hi(double %6826)
  %6849 = bitcast i32 %6848 to float
  %6850 = tail call float @llvm.fabs.f32(float %6849)
  %6851 = fcmp uge float %6850, 0x4010C46560000000
  br i1 %6851, label %__internal_fast_icmp_abs_lt.exit.i.i.i2186, label %__internal_accurate_pow.exit.i2189

__internal_fast_icmp_abs_lt.exit.i.i.i2186:       ; preds = %false_block2486
  %6852 = fcmp olt double %6826, 0.000000e+00
  %6853 = fadd double %6826, 0x7FF0000000000000
  %z.0.i.i.i2185 = select i1 %6852, double 0.000000e+00, double %6853
  %6854 = fcmp olt float %6850, 0x4010E90000000000
  br i1 %6854, label %6855, label %__internal_accurate_pow.exit.i2189

6855:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2186
  %6856 = sdiv i32 %6828, 2
  %6857 = shl i32 %6856, 20
  %6858 = add i32 %6844, %6857
  %6859 = tail call double @llvm.nvvm.lohi.i2d(i32 %6843, i32 %6858)
  %6860 = sub nsw i32 %6828, %6856
  %6861 = shl i32 %6860, 20
  %6862 = add nsw i32 %6861, 1072693248
  %6863 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %6862)
  %6864 = fmul double %6863, %6859
  br label %__internal_accurate_pow.exit.i2189

__internal_accurate_pow.exit.i2189:               ; preds = %6855, %__internal_fast_icmp_abs_lt.exit.i.i.i2186, %false_block2486
  %z.2.i.i.i2187 = phi double [ %6847, %false_block2486 ], [ %6864, %6855 ], [ %z.0.i.i.i2185, %__internal_fast_icmp_abs_lt.exit.i.i.i2186 ]
  %6865 = icmp eq i32 %6727, 1126170624
  %6866 = icmp slt i32 %6725, 0
  %spec.select.i2188 = select i1 %6866, i1 %6865, i1 false
  %6867 = fcmp oeq double %6724, 0.000000e+00
  br i1 %6867, label %6868, label %6873

6868:                                             ; preds = %__internal_accurate_pow.exit.i2189
  %6869 = icmp eq i32 %6727, 1126170624
  %spec.select1.i2190 = select i1 %6869, i32 %6725, i32 0
  %6870 = icmp slt i32 %6726, 0
  %6871 = or i32 %spec.select1.i2190, 2146435072
  %thi.1.i2191 = select i1 %6870, i32 %6871, i32 %spec.select1.i2190
  %6872 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2191)
  br label %6888

6873:                                             ; preds = %__internal_accurate_pow.exit.i2189
  %6874 = icmp slt i32 %6725, 0
  %6875 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2187)
  %6876 = and i32 %6875, 2147483647
  %6877 = icmp ne i32 %6876, 2146435072
  %6878 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2187)
  %6879 = icmp ne i32 %6878, 0
  %6880 = select i1 %6877, i1 true, i1 %6879
  %6881 = fsub double %6822, %6826
  %6882 = fadd double %6825, %6881
  %6883 = tail call double @llvm.fma.f64(double %z.2.i.i.i2187, double %6882, double %z.2.i.i.i2187)
  %tmp.0.i.i2192 = select i1 %6880, double %6883, double %z.2.i.i.i2187
  %6884 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2192)
  %6885 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2192)
  %6886 = xor i32 %6885, -2147483648
  %6887 = tail call double @llvm.nvvm.lohi.i2d(i32 %6884, i32 %6886)
  %t.0.i2193 = select i1 %spec.select.i2188, double %6887, double %tmp.0.i.i2192
  %t.1.i2194 = select i1 %6874, double 0xFFF8000000000000, double %t.0.i2193
  br label %6888

6888:                                             ; preds = %6873, %6868
  %t.2.i2195 = phi double [ %6872, %6868 ], [ %t.1.i2194, %6873 ]
  %6889 = fadd double %6724, 3.333300e-01
  %6890 = tail call i32 @llvm.nvvm.d2i.hi(double %6889)
  %6891 = and i32 %6890, 2146435072
  %6892 = icmp eq i32 %6891, 2146435072
  br i1 %6892, label %6893, label %__nv_pow.exit2207

6893:                                             ; preds = %6888
  %6894 = fcmp ugt double %6728, 0x7FF0000000000000
  br i1 %6894, label %__nv_pow.exit2207, label %__nv_isinfd.exit5.i2196

__nv_isinfd.exit5.i2196:                          ; preds = %6893
  %6895 = and i32 %6726, 2147483647
  %6896 = icmp eq i32 %6895, 2146435072
  %6897 = icmp eq i32 %6817, 0
  %6898 = select i1 %6896, i1 %6897, i1 false
  br i1 %6898, label %6899, label %__nv_isinfd.exit.i2204

6899:                                             ; preds = %__nv_isinfd.exit5.i2196
  %6900 = fcmp ogt double %6728, 1.000000e+00
  %thi.2.i2197 = select i1 %6900, i32 2146435072, i32 0
  %6901 = icmp slt i32 %6726, 0
  %6902 = xor i32 %thi.2.i2197, 2146435072
  %thi.3.i2198 = select i1 %6901, i32 %6902, i32 %thi.2.i2197
  %6903 = fcmp oeq double %6724, -1.000000e+00
  %thi.4.i2199 = select i1 %6903, i32 1072693248, i32 %thi.3.i2198
  %6904 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2199)
  br label %__nv_pow.exit2207

__nv_isinfd.exit.i2204:                           ; preds = %__nv_isinfd.exit5.i2196
  %6905 = tail call i32 @llvm.nvvm.d2i.lo(double %6724)
  %6906 = and i32 %6725, 2147483647
  %6907 = icmp eq i32 %6906, 2146435072
  %6908 = icmp eq i32 %6905, 0
  %6909 = select i1 %6907, i1 %6908, i1 false
  %.inv.i2200 = icmp slt i32 %6726, 0
  %spec.select8.i2201 = select i1 %.inv.i2200, i32 0, i32 2146435072
  %6910 = or i32 %spec.select8.i2201, -2147483648
  %thi.6.i2202 = select i1 %spec.select.i2188, i32 %6910, i32 %spec.select8.i2201
  %6911 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2202)
  %spec.select10.i2203 = select i1 %6909, double %6911, double %t.2.i2195
  br label %__nv_pow.exit2207

__nv_pow.exit2207:                                ; preds = %6888, %6893, %6899, %__nv_isinfd.exit.i2204
  %t.6.i2205 = phi double [ %t.2.i2195, %6888 ], [ %6904, %6899 ], [ %6889, %6893 ], [ %spec.select10.i2203, %__nv_isinfd.exit.i2204 ]
  %6912 = fcmp oeq double %6724, 1.000000e+00
  %t.6.i2205.op = fmul reassoc ninf nsz double %t.6.i2205, 1.050000e+00
  %6913 = select i1 %6912, double 1.050000e+00, double %t.6.i2205.op
  %6914 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %6913, double 1.000000e+00)
  %6915 = fmul reassoc ninf nsz double %6914, 1.700000e+00
  %6916 = tail call i32 @llvm.nvvm.d2i.hi(double %6723)
  %6917 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %6918 = and i32 %6917, 2146435072
  %6919 = tail call double @llvm.fabs.f64(double %6723)
  %6920 = tail call i32 @llvm.nvvm.d2i.hi(double %6919)
  %6921 = tail call i32 @llvm.nvvm.d2i.lo(double %6919)
  %6922 = lshr i32 %6920, 20
  %6923 = icmp ult i32 %6920, 1048576
  %6924 = fmul double %6919, 0x4350000000000000
  %6925 = tail call i32 @llvm.nvvm.d2i.hi(double %6924)
  %6926 = tail call i32 @llvm.nvvm.d2i.lo(double %6924)
  %6927 = lshr i32 %6925, 20
  %6928 = add nsw i32 %6927, -54
  %ilo.0.i.i.i2148 = select i1 %6923, i32 %6926, i32 %6921
  %ihi.0.i.i.i2149 = select i1 %6923, i32 %6925, i32 %6920
  %expo.0.i.i.i2150 = select i1 %6923, i32 %6928, i32 %6922
  %6929 = and i32 %ihi.0.i.i.i2149, -2146435073
  %6930 = or i32 %6929, 1072693248
  %6931 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2148, i32 %6930)
  %6932 = icmp ugt i32 %6930, 1073127582
  %6933 = tail call i32 @llvm.nvvm.d2i.lo(double %6931)
  %6934 = tail call i32 @llvm.nvvm.d2i.hi(double %6931)
  %6935 = add i32 %6934, -1048576
  %6936 = tail call double @llvm.nvvm.lohi.i2d(i32 %6933, i32 %6935)
  %m.0.i.i.i2151 = select i1 %6932, double %6936, double %6931
  %expo.1.i.v.i.i2152 = select i1 %6932, i32 -1022, i32 -1023
  %expo.1.i.i.i2153 = add nsw i32 %expo.1.i.v.i.i2152, %expo.0.i.i.i2150
  %6937 = fadd double %m.0.i.i.i2151, -1.000000e+00
  %6938 = fadd double %m.0.i.i.i2151, 1.000000e+00
  %6939 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %6938)
  %6940 = fneg double %6938
  %6941 = tail call double @llvm.fma.f64(double %6940, double %6939, double 1.000000e+00)
  %6942 = tail call double @llvm.fma.f64(double %6941, double %6941, double %6941)
  %6943 = tail call double @llvm.fma.f64(double %6942, double %6939, double %6939)
  %6944 = fmul double %6937, %6943
  %6945 = fadd double %6944, %6944
  %6946 = fmul double %6945, %6945
  %6947 = tail call double @llvm.fma.f64(double %6946, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %6948 = tail call double @llvm.fma.f64(double %6947, double %6946, double 0x3EF3B20A75488A3F)
  %6949 = tail call double @llvm.fma.f64(double %6948, double %6946, double 0x3F1745CDE4FAECD5)
  %6950 = tail call double @llvm.fma.f64(double %6949, double %6946, double 0x3F3C71C7258A578B)
  %6951 = tail call double @llvm.fma.f64(double %6950, double %6946, double 0x3F6249249242B910)
  %6952 = tail call double @llvm.fma.f64(double %6951, double %6946, double 0x3F89999999999DFB)
  %6953 = fmul double %6946, %6952
  %6954 = fsub double %6937, %6945
  %6955 = fmul double %6954, 2.000000e+00
  %6956 = fneg double %6945
  %6957 = tail call double @llvm.fma.f64(double %6956, double %6937, double %6955)
  %6958 = fmul double %6943, %6957
  %6959 = fadd double %6953, 0x3FB5555555555555
  %6960 = fsub double 0x3FB5555555555555, %6959
  %6961 = fadd double %6953, %6960
  %6962 = fadd double %6961, 0.000000e+00
  %6963 = fadd double %6962, 0xBC46A4CB00B9E7B0
  %6964 = fadd double %6959, %6963
  %6965 = fsub double %6959, %6964
  %6966 = fadd double %6963, %6965
  %6967 = fneg double %6946
  %6968 = tail call double @llvm.fma.f64(double %6945, double %6945, double %6967)
  %6969 = tail call i32 @llvm.nvvm.d2i.lo(double %6958)
  %6970 = tail call i32 @llvm.nvvm.d2i.hi(double %6958)
  %6971 = add i32 %6970, 1048576
  %6972 = tail call double @llvm.nvvm.lohi.i2d(i32 %6969, i32 %6971)
  %6973 = tail call double @llvm.fma.f64(double %6945, double %6972, double %6968)
  %6974 = fmul double %6945, %6946
  %6975 = fneg double %6974
  %6976 = tail call double @llvm.fma.f64(double %6946, double %6945, double %6975)
  %6977 = tail call double @llvm.fma.f64(double %6946, double %6958, double %6976)
  %6978 = tail call double @llvm.fma.f64(double %6973, double %6945, double %6977)
  %6979 = fmul double %6974, %6964
  %6980 = fneg double %6979
  %6981 = tail call double @llvm.fma.f64(double %6964, double %6974, double %6980)
  %6982 = tail call double @llvm.fma.f64(double %6964, double %6978, double %6981)
  %6983 = tail call double @llvm.fma.f64(double %6966, double %6974, double %6982)
  %6984 = fadd double %6979, %6983
  %6985 = fsub double %6979, %6984
  %6986 = fadd double %6983, %6985
  %6987 = fadd double %6945, %6984
  %6988 = fsub double %6945, %6987
  %6989 = fadd double %6984, %6988
  %6990 = fadd double %6986, %6989
  %6991 = fadd double %6958, %6990
  %6992 = fadd double %6987, %6991
  %6993 = fsub double %6987, %6992
  %6994 = fadd double %6991, %6993
  %6995 = xor i32 %expo.1.i.i.i2153, -2147483648
  %6996 = tail call double @llvm.nvvm.lohi.i2d(i32 %6995, i32 1127219200)
  %6997 = fsub double %6996, %6806
  %6998 = tail call double @llvm.fma.f64(double %6997, double 0x3FE62E42FEFA39EF, double %6992)
  %6999 = fneg double %6997
  %7000 = tail call double @llvm.fma.f64(double %6999, double 0x3FE62E42FEFA39EF, double %6998)
  %7001 = fsub double %7000, %6992
  %7002 = fsub double %6994, %7001
  %7003 = tail call double @llvm.fma.f64(double %6997, double 0x3C7ABC9E3B39803F, double %7002)
  %7004 = fadd double %6998, %7003
  %7005 = fsub double %6998, %7004
  %7006 = fadd double %7003, %7005
  %7007 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %7008 = shl i32 %6917, 1
  %7009 = icmp ugt i32 %7008, -33554433
  %7010 = and i32 %6917, -15728641
  %spec.select.i.i2154 = select i1 %7009, i32 %7010, i32 %6917
  %7011 = tail call double @llvm.nvvm.lohi.i2d(i32 %7007, i32 %spec.select.i.i2154)
  %7012 = fmul double %7011, %7004
  %7013 = fneg double %7012
  %7014 = tail call double @llvm.fma.f64(double %7004, double %7011, double %7013)
  %7015 = tail call double @llvm.fma.f64(double %7006, double %7011, double %7014)
  %7016 = fadd double %7012, %7015
  %7017 = tail call double @llvm.fma.f64(double %7016, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %7018 = tail call i32 @llvm.nvvm.d2i.lo(double %7017)
  %7019 = fadd double %7017, 0xC338000000000000
  %7020 = tail call double @llvm.fma.f64(double %7019, double 0xBFE62E42FEFA39EF, double %7016)
  %7021 = tail call double @llvm.fma.f64(double %7019, double 0xBC7ABC9E3B39803F, double %7020)
  %7022 = tail call double @llvm.fma.f64(double %7021, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %7023 = tail call double @llvm.fma.f64(double %7022, double %7021, double 0x3EC71DEE62401315)
  %7024 = tail call double @llvm.fma.f64(double %7023, double %7021, double 0x3EFA01997C89EB71)
  %7025 = tail call double @llvm.fma.f64(double %7024, double %7021, double 0x3F2A01A014761F65)
  %7026 = tail call double @llvm.fma.f64(double %7025, double %7021, double 0x3F56C16C1852B7AF)
  %7027 = tail call double @llvm.fma.f64(double %7026, double %7021, double 0x3F81111111122322)
  %7028 = tail call double @llvm.fma.f64(double %7027, double %7021, double 0x3FA55555555502A1)
  %7029 = tail call double @llvm.fma.f64(double %7028, double %7021, double 0x3FC5555555555511)
  %7030 = tail call double @llvm.fma.f64(double %7029, double %7021, double 0x3FE000000000000B)
  %7031 = tail call double @llvm.fma.f64(double %7030, double %7021, double 1.000000e+00)
  %7032 = tail call double @llvm.fma.f64(double %7031, double %7021, double 1.000000e+00)
  %7033 = tail call i32 @llvm.nvvm.d2i.lo(double %7032)
  %7034 = tail call i32 @llvm.nvvm.d2i.hi(double %7032)
  %7035 = shl i32 %7018, 20
  %7036 = add i32 %7034, %7035
  %7037 = tail call double @llvm.nvvm.lohi.i2d(i32 %7033, i32 %7036)
  %7038 = tail call i32 @llvm.nvvm.d2i.hi(double %7016)
  %7039 = bitcast i32 %7038 to float
  %7040 = tail call float @llvm.fabs.f32(float %7039)
  %7041 = fcmp uge float %7040, 0x4010C46560000000
  br i1 %7041, label %__internal_fast_icmp_abs_lt.exit.i.i.i2156, label %__internal_accurate_pow.exit.i2159

__internal_fast_icmp_abs_lt.exit.i.i.i2156:       ; preds = %__nv_pow.exit2207
  %7042 = fcmp olt double %7016, 0.000000e+00
  %7043 = fadd double %7016, 0x7FF0000000000000
  %z.0.i.i.i2155 = select i1 %7042, double 0.000000e+00, double %7043
  %7044 = fcmp olt float %7040, 0x4010E90000000000
  br i1 %7044, label %7045, label %__internal_accurate_pow.exit.i2159

7045:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2156
  %7046 = sdiv i32 %7018, 2
  %7047 = shl i32 %7046, 20
  %7048 = add i32 %7034, %7047
  %7049 = tail call double @llvm.nvvm.lohi.i2d(i32 %7033, i32 %7048)
  %7050 = sub nsw i32 %7018, %7046
  %7051 = shl i32 %7050, 20
  %7052 = add nsw i32 %7051, 1072693248
  %7053 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %7052)
  %7054 = fmul double %7053, %7049
  br label %__internal_accurate_pow.exit.i2159

__internal_accurate_pow.exit.i2159:               ; preds = %7045, %__internal_fast_icmp_abs_lt.exit.i.i.i2156, %__nv_pow.exit2207
  %z.2.i.i.i2157 = phi double [ %7037, %__nv_pow.exit2207 ], [ %7054, %7045 ], [ %z.0.i.i.i2155, %__internal_fast_icmp_abs_lt.exit.i.i.i2156 ]
  %7055 = icmp eq i32 %6918, 1073741824
  %7056 = icmp slt i32 %6916, 0
  %spec.select.i2158 = select i1 %7056, i1 %7055, i1 false
  %7057 = fcmp oeq double %6723, 0.000000e+00
  br i1 %7057, label %7058, label %7063

7058:                                             ; preds = %__internal_accurate_pow.exit.i2159
  %7059 = icmp eq i32 %6918, 1073741824
  %spec.select1.i2160 = select i1 %7059, i32 %6916, i32 0
  %7060 = icmp slt i32 %6917, 0
  %7061 = or i32 %spec.select1.i2160, 2146435072
  %thi.1.i2161 = select i1 %7060, i32 %7061, i32 %spec.select1.i2160
  %7062 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2161)
  br label %7078

7063:                                             ; preds = %__internal_accurate_pow.exit.i2159
  %7064 = icmp slt i32 %6916, 0
  %7065 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2157)
  %7066 = and i32 %7065, 2147483647
  %7067 = icmp ne i32 %7066, 2146435072
  %7068 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2157)
  %7069 = icmp ne i32 %7068, 0
  %7070 = select i1 %7067, i1 true, i1 %7069
  %7071 = fsub double %7012, %7016
  %7072 = fadd double %7015, %7071
  %7073 = tail call double @llvm.fma.f64(double %z.2.i.i.i2157, double %7072, double %z.2.i.i.i2157)
  %tmp.0.i.i2162 = select i1 %7070, double %7073, double %z.2.i.i.i2157
  %7074 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2162)
  %7075 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2162)
  %7076 = xor i32 %7075, -2147483648
  %7077 = tail call double @llvm.nvvm.lohi.i2d(i32 %7074, i32 %7076)
  %t.0.i2163 = select i1 %spec.select.i2158, double %7077, double %tmp.0.i.i2162
  %t.1.i2164 = select i1 %7064, double 0xFFF8000000000000, double %t.0.i2163
  br label %7078

7078:                                             ; preds = %7063, %7058
  %t.2.i2165 = phi double [ %7062, %7058 ], [ %t.1.i2164, %7063 ]
  %7079 = fadd double %6723, 1.500000e+00
  %7080 = tail call i32 @llvm.nvvm.d2i.hi(double %7079)
  %7081 = and i32 %7080, 2146435072
  %7082 = icmp eq i32 %7081, 2146435072
  br i1 %7082, label %7083, label %__nv_pow.exit2177

7083:                                             ; preds = %7078
  %7084 = fcmp ugt double %6919, 0x7FF0000000000000
  br i1 %7084, label %__nv_pow.exit2177, label %__nv_isinfd.exit5.i2166

__nv_isinfd.exit5.i2166:                          ; preds = %7083
  %7085 = and i32 %6917, 2147483647
  %7086 = icmp eq i32 %7085, 2146435072
  %7087 = icmp eq i32 %7007, 0
  %7088 = select i1 %7086, i1 %7087, i1 false
  br i1 %7088, label %7089, label %__nv_isinfd.exit.i2174

7089:                                             ; preds = %__nv_isinfd.exit5.i2166
  %7090 = fcmp ogt double %6919, 1.000000e+00
  %thi.2.i2167 = select i1 %7090, i32 2146435072, i32 0
  %7091 = icmp slt i32 %6917, 0
  %7092 = xor i32 %thi.2.i2167, 2146435072
  %thi.3.i2168 = select i1 %7091, i32 %7092, i32 %thi.2.i2167
  %7093 = fcmp oeq double %6723, -1.000000e+00
  %thi.4.i2169 = select i1 %7093, i32 1072693248, i32 %thi.3.i2168
  %7094 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2169)
  br label %__nv_pow.exit2177

__nv_isinfd.exit.i2174:                           ; preds = %__nv_isinfd.exit5.i2166
  %7095 = tail call i32 @llvm.nvvm.d2i.lo(double %6723)
  %7096 = and i32 %6916, 2147483647
  %7097 = icmp eq i32 %7096, 2146435072
  %7098 = icmp eq i32 %7095, 0
  %7099 = select i1 %7097, i1 %7098, i1 false
  %.inv.i2170 = icmp slt i32 %6917, 0
  %spec.select8.i2171 = select i1 %.inv.i2170, i32 0, i32 2146435072
  %7100 = or i32 %spec.select8.i2171, -2147483648
  %thi.6.i2172 = select i1 %spec.select.i2158, i32 %7100, i32 %spec.select8.i2171
  %7101 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2172)
  %spec.select10.i2173 = select i1 %7099, double %7101, double %t.2.i2165
  br label %__nv_pow.exit2177

__nv_pow.exit2177:                                ; preds = %7078, %7083, %7089, %__nv_isinfd.exit.i2174
  %t.6.i2175 = phi double [ %t.2.i2165, %7078 ], [ %7094, %7089 ], [ %7079, %7083 ], [ %spec.select10.i2173, %__nv_isinfd.exit.i2174 ]
  %7102 = fcmp oeq double %6723, 1.000000e+00
  %t.7.i2176 = select i1 %7102, double 1.000000e+00, double %t.6.i2175
  %7103 = fmul reassoc ninf nsz double %6915, %t.7.i2176
  %7104 = fcmp reassoc ninf nsz olt double %6318, 0.000000e+00
  %7105 = tail call double @llvm.fabs.f64(double %7103)
  %neg2495 = fneg reassoc ninf nsz double %7105
  %7106 = select reassoc ninf nsz i1 %7104, double %neg2495, double %7105
  %7107 = tail call double @llvm.fabs.f64(double %6722)
  %7108 = fmul reassoc ninf nsz double %6318, %7107
  %7109 = fmul reassoc ninf nsz double %7108, %6722
  %7110 = fmul reassoc ninf nsz double %7108, %56
  %7111 = fsub reassoc ninf nsz double %5910, %37
  %7112 = fmul reassoc ninf nsz double %7111, %7111
  %7113 = fmul reassoc ninf nsz double %7112, 4.905000e+00
  br label %after_if9

true_block2496:                                   ; preds = %false_block11
  %getch.i2147 = getelementptr i8, i8* %12, i64 84551472
  %7114 = getelementptr inbounds i8, i8* %getch.i2147, i64 %25
  %7115 = bitcast i8* %7114 to double*
  %7116 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %7115, i32 64)
  %7117 = fcmp reassoc ninf nsz ogt double %40, %7116
  %7118 = fcmp reassoc ninf nsz ogt double %.01383, %7116
  %.0745 = select i1 %7117, i1 true, i1 %7118
  br i1 %.0745, label %true_block2502, label %false_block2503

true_block2502:                                   ; preds = %true_block2496
  %7119 = bitcast i8* %15 to double*
  store double 0.000000e+00, double* %7119, align 8
  %7120 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %40, double %.01383)
  %7121 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %40, double %.01383)
  %7122 = fsub reassoc ninf nsz double %7120, %7116
  %7123 = fsub reassoc ninf nsz double %7121, %7116
  %7124 = fdiv reassoc ninf nsz double %7123, %7122
  %7125 = fcmp reassoc ninf nsz ugt double %7124, 6.670000e-01
  br i1 %7125, label %false_block2506, label %true_block2505

false_block2503:                                  ; preds = %true_block2496
  %7126 = fmul reassoc ninf nsz double %28, %28
  %7127 = fmul reassoc ninf nsz double %7126, 4.905000e+00
  br label %after_if9

true_block2505:                                   ; preds = %true_block2502
  %7128 = tail call i32 @llvm.nvvm.d2i.hi(double %7122)
  %7129 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %7130 = and i32 %7129, 2146435072
  %7131 = tail call double @llvm.fabs.f64(double %7122)
  %7132 = tail call i32 @llvm.nvvm.d2i.hi(double %7131)
  %7133 = tail call i32 @llvm.nvvm.d2i.lo(double %7131)
  %7134 = lshr i32 %7132, 20
  %7135 = icmp ult i32 %7132, 1048576
  %7136 = fmul double %7131, 0x4350000000000000
  %7137 = tail call i32 @llvm.nvvm.d2i.hi(double %7136)
  %7138 = tail call i32 @llvm.nvvm.d2i.lo(double %7136)
  %7139 = lshr i32 %7137, 20
  %7140 = add nsw i32 %7139, -54
  %ilo.0.i.i.i2117 = select i1 %7135, i32 %7138, i32 %7133
  %ihi.0.i.i.i2118 = select i1 %7135, i32 %7137, i32 %7132
  %expo.0.i.i.i2119 = select i1 %7135, i32 %7140, i32 %7134
  %7141 = and i32 %ihi.0.i.i.i2118, -2146435073
  %7142 = or i32 %7141, 1072693248
  %7143 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2117, i32 %7142)
  %7144 = icmp ugt i32 %7142, 1073127582
  %7145 = tail call i32 @llvm.nvvm.d2i.lo(double %7143)
  %7146 = tail call i32 @llvm.nvvm.d2i.hi(double %7143)
  %7147 = add i32 %7146, -1048576
  %7148 = tail call double @llvm.nvvm.lohi.i2d(i32 %7145, i32 %7147)
  %m.0.i.i.i2120 = select i1 %7144, double %7148, double %7143
  %expo.1.i.v.i.i2121 = select i1 %7144, i32 -1022, i32 -1023
  %expo.1.i.i.i2122 = add nsw i32 %expo.1.i.v.i.i2121, %expo.0.i.i.i2119
  %7149 = fadd double %m.0.i.i.i2120, -1.000000e+00
  %7150 = fadd double %m.0.i.i.i2120, 1.000000e+00
  %7151 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %7150)
  %7152 = fneg double %7150
  %7153 = tail call double @llvm.fma.f64(double %7152, double %7151, double 1.000000e+00)
  %7154 = tail call double @llvm.fma.f64(double %7153, double %7153, double %7153)
  %7155 = tail call double @llvm.fma.f64(double %7154, double %7151, double %7151)
  %7156 = fmul double %7149, %7155
  %7157 = fadd double %7156, %7156
  %7158 = fmul double %7157, %7157
  %7159 = tail call double @llvm.fma.f64(double %7158, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %7160 = tail call double @llvm.fma.f64(double %7159, double %7158, double 0x3EF3B20A75488A3F)
  %7161 = tail call double @llvm.fma.f64(double %7160, double %7158, double 0x3F1745CDE4FAECD5)
  %7162 = tail call double @llvm.fma.f64(double %7161, double %7158, double 0x3F3C71C7258A578B)
  %7163 = tail call double @llvm.fma.f64(double %7162, double %7158, double 0x3F6249249242B910)
  %7164 = tail call double @llvm.fma.f64(double %7163, double %7158, double 0x3F89999999999DFB)
  %7165 = fmul double %7158, %7164
  %7166 = fsub double %7149, %7157
  %7167 = fmul double %7166, 2.000000e+00
  %7168 = fneg double %7157
  %7169 = tail call double @llvm.fma.f64(double %7168, double %7149, double %7167)
  %7170 = fmul double %7155, %7169
  %7171 = fadd double %7165, 0x3FB5555555555555
  %7172 = fsub double 0x3FB5555555555555, %7171
  %7173 = fadd double %7165, %7172
  %7174 = fadd double %7173, 0.000000e+00
  %7175 = fadd double %7174, 0xBC46A4CB00B9E7B0
  %7176 = fadd double %7171, %7175
  %7177 = fsub double %7171, %7176
  %7178 = fadd double %7175, %7177
  %7179 = fneg double %7158
  %7180 = tail call double @llvm.fma.f64(double %7157, double %7157, double %7179)
  %7181 = tail call i32 @llvm.nvvm.d2i.lo(double %7170)
  %7182 = tail call i32 @llvm.nvvm.d2i.hi(double %7170)
  %7183 = add i32 %7182, 1048576
  %7184 = tail call double @llvm.nvvm.lohi.i2d(i32 %7181, i32 %7183)
  %7185 = tail call double @llvm.fma.f64(double %7157, double %7184, double %7180)
  %7186 = fmul double %7157, %7158
  %7187 = fneg double %7186
  %7188 = tail call double @llvm.fma.f64(double %7158, double %7157, double %7187)
  %7189 = tail call double @llvm.fma.f64(double %7158, double %7170, double %7188)
  %7190 = tail call double @llvm.fma.f64(double %7185, double %7157, double %7189)
  %7191 = fmul double %7186, %7176
  %7192 = fneg double %7191
  %7193 = tail call double @llvm.fma.f64(double %7176, double %7186, double %7192)
  %7194 = tail call double @llvm.fma.f64(double %7176, double %7190, double %7193)
  %7195 = tail call double @llvm.fma.f64(double %7178, double %7186, double %7194)
  %7196 = fadd double %7191, %7195
  %7197 = fsub double %7191, %7196
  %7198 = fadd double %7195, %7197
  %7199 = fadd double %7157, %7196
  %7200 = fsub double %7157, %7199
  %7201 = fadd double %7196, %7200
  %7202 = fadd double %7198, %7201
  %7203 = fadd double %7170, %7202
  %7204 = fadd double %7199, %7203
  %7205 = fsub double %7199, %7204
  %7206 = fadd double %7203, %7205
  %7207 = xor i32 %expo.1.i.i.i2122, -2147483648
  %7208 = tail call double @llvm.nvvm.lohi.i2d(i32 %7207, i32 1127219200)
  %7209 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %7210 = fsub double %7208, %7209
  %7211 = tail call double @llvm.fma.f64(double %7210, double 0x3FE62E42FEFA39EF, double %7204)
  %7212 = fneg double %7210
  %7213 = tail call double @llvm.fma.f64(double %7212, double 0x3FE62E42FEFA39EF, double %7211)
  %7214 = fsub double %7213, %7204
  %7215 = fsub double %7206, %7214
  %7216 = tail call double @llvm.fma.f64(double %7210, double 0x3C7ABC9E3B39803F, double %7215)
  %7217 = fadd double %7211, %7216
  %7218 = fsub double %7211, %7217
  %7219 = fadd double %7216, %7218
  %7220 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %7221 = shl i32 %7129, 1
  %7222 = icmp ugt i32 %7221, -33554433
  %7223 = and i32 %7129, -15728641
  %spec.select.i.i2123 = select i1 %7222, i32 %7223, i32 %7129
  %7224 = tail call double @llvm.nvvm.lohi.i2d(i32 %7220, i32 %spec.select.i.i2123)
  %7225 = fmul double %7224, %7217
  %7226 = fneg double %7225
  %7227 = tail call double @llvm.fma.f64(double %7217, double %7224, double %7226)
  %7228 = tail call double @llvm.fma.f64(double %7219, double %7224, double %7227)
  %7229 = fadd double %7225, %7228
  %7230 = tail call double @llvm.fma.f64(double %7229, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %7231 = tail call i32 @llvm.nvvm.d2i.lo(double %7230)
  %7232 = fadd double %7230, 0xC338000000000000
  %7233 = tail call double @llvm.fma.f64(double %7232, double 0xBFE62E42FEFA39EF, double %7229)
  %7234 = tail call double @llvm.fma.f64(double %7232, double 0xBC7ABC9E3B39803F, double %7233)
  %7235 = tail call double @llvm.fma.f64(double %7234, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %7236 = tail call double @llvm.fma.f64(double %7235, double %7234, double 0x3EC71DEE62401315)
  %7237 = tail call double @llvm.fma.f64(double %7236, double %7234, double 0x3EFA01997C89EB71)
  %7238 = tail call double @llvm.fma.f64(double %7237, double %7234, double 0x3F2A01A014761F65)
  %7239 = tail call double @llvm.fma.f64(double %7238, double %7234, double 0x3F56C16C1852B7AF)
  %7240 = tail call double @llvm.fma.f64(double %7239, double %7234, double 0x3F81111111122322)
  %7241 = tail call double @llvm.fma.f64(double %7240, double %7234, double 0x3FA55555555502A1)
  %7242 = tail call double @llvm.fma.f64(double %7241, double %7234, double 0x3FC5555555555511)
  %7243 = tail call double @llvm.fma.f64(double %7242, double %7234, double 0x3FE000000000000B)
  %7244 = tail call double @llvm.fma.f64(double %7243, double %7234, double 1.000000e+00)
  %7245 = tail call double @llvm.fma.f64(double %7244, double %7234, double 1.000000e+00)
  %7246 = tail call i32 @llvm.nvvm.d2i.lo(double %7245)
  %7247 = tail call i32 @llvm.nvvm.d2i.hi(double %7245)
  %7248 = shl i32 %7231, 20
  %7249 = add i32 %7247, %7248
  %7250 = tail call double @llvm.nvvm.lohi.i2d(i32 %7246, i32 %7249)
  %7251 = tail call i32 @llvm.nvvm.d2i.hi(double %7229)
  %7252 = bitcast i32 %7251 to float
  %7253 = tail call float @llvm.fabs.f32(float %7252)
  %7254 = fcmp uge float %7253, 0x4010C46560000000
  br i1 %7254, label %__internal_fast_icmp_abs_lt.exit.i.i.i2125, label %__internal_accurate_pow.exit.i2128

__internal_fast_icmp_abs_lt.exit.i.i.i2125:       ; preds = %true_block2505
  %7255 = fcmp olt double %7229, 0.000000e+00
  %7256 = fadd double %7229, 0x7FF0000000000000
  %z.0.i.i.i2124 = select i1 %7255, double 0.000000e+00, double %7256
  %7257 = fcmp olt float %7253, 0x4010E90000000000
  br i1 %7257, label %7258, label %__internal_accurate_pow.exit.i2128

7258:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2125
  %7259 = sdiv i32 %7231, 2
  %7260 = shl i32 %7259, 20
  %7261 = add i32 %7247, %7260
  %7262 = tail call double @llvm.nvvm.lohi.i2d(i32 %7246, i32 %7261)
  %7263 = sub nsw i32 %7231, %7259
  %7264 = shl i32 %7263, 20
  %7265 = add nsw i32 %7264, 1072693248
  %7266 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %7265)
  %7267 = fmul double %7266, %7262
  br label %__internal_accurate_pow.exit.i2128

__internal_accurate_pow.exit.i2128:               ; preds = %7258, %__internal_fast_icmp_abs_lt.exit.i.i.i2125, %true_block2505
  %z.2.i.i.i2126 = phi double [ %7250, %true_block2505 ], [ %7267, %7258 ], [ %z.0.i.i.i2124, %__internal_fast_icmp_abs_lt.exit.i.i.i2125 ]
  %7268 = icmp eq i32 %7130, 1073741824
  %7269 = icmp slt i32 %7128, 0
  %spec.select.i2127 = select i1 %7269, i1 %7268, i1 false
  %7270 = fcmp oeq double %7122, 0.000000e+00
  br i1 %7270, label %7271, label %7276

7271:                                             ; preds = %__internal_accurate_pow.exit.i2128
  %7272 = icmp eq i32 %7130, 1073741824
  %spec.select1.i2129 = select i1 %7272, i32 %7128, i32 0
  %7273 = icmp slt i32 %7129, 0
  %7274 = or i32 %spec.select1.i2129, 2146435072
  %thi.1.i2130 = select i1 %7273, i32 %7274, i32 %spec.select1.i2129
  %7275 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2130)
  br label %7291

7276:                                             ; preds = %__internal_accurate_pow.exit.i2128
  %7277 = icmp slt i32 %7128, 0
  %7278 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2126)
  %7279 = and i32 %7278, 2147483647
  %7280 = icmp ne i32 %7279, 2146435072
  %7281 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2126)
  %7282 = icmp ne i32 %7281, 0
  %7283 = select i1 %7280, i1 true, i1 %7282
  %7284 = fsub double %7225, %7229
  %7285 = fadd double %7228, %7284
  %7286 = tail call double @llvm.fma.f64(double %z.2.i.i.i2126, double %7285, double %z.2.i.i.i2126)
  %tmp.0.i.i2131 = select i1 %7283, double %7286, double %z.2.i.i.i2126
  %7287 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2131)
  %7288 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2131)
  %7289 = xor i32 %7288, -2147483648
  %7290 = tail call double @llvm.nvvm.lohi.i2d(i32 %7287, i32 %7289)
  %t.0.i2132 = select i1 %spec.select.i2127, double %7290, double %tmp.0.i.i2131
  %t.1.i2133 = select i1 %7277, double 0xFFF8000000000000, double %t.0.i2132
  br label %7291

7291:                                             ; preds = %7276, %7271
  %t.2.i2134 = phi double [ %7275, %7271 ], [ %t.1.i2133, %7276 ]
  %7292 = fadd double %7122, 1.500000e+00
  %7293 = tail call i32 @llvm.nvvm.d2i.hi(double %7292)
  %7294 = and i32 %7293, 2146435072
  %7295 = icmp eq i32 %7294, 2146435072
  br i1 %7295, label %7296, label %__nv_pow.exit2146

7296:                                             ; preds = %7291
  %7297 = fcmp ugt double %7131, 0x7FF0000000000000
  br i1 %7297, label %__nv_pow.exit2146, label %__nv_isinfd.exit5.i2135

__nv_isinfd.exit5.i2135:                          ; preds = %7296
  %7298 = and i32 %7129, 2147483647
  %7299 = icmp eq i32 %7298, 2146435072
  %7300 = icmp eq i32 %7220, 0
  %7301 = select i1 %7299, i1 %7300, i1 false
  br i1 %7301, label %7302, label %__nv_isinfd.exit.i2143

7302:                                             ; preds = %__nv_isinfd.exit5.i2135
  %7303 = fcmp ogt double %7131, 1.000000e+00
  %thi.2.i2136 = select i1 %7303, i32 2146435072, i32 0
  %7304 = icmp slt i32 %7129, 0
  %7305 = xor i32 %thi.2.i2136, 2146435072
  %thi.3.i2137 = select i1 %7304, i32 %7305, i32 %thi.2.i2136
  %7306 = fcmp oeq double %7122, -1.000000e+00
  %thi.4.i2138 = select i1 %7306, i32 1072693248, i32 %thi.3.i2137
  %7307 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2138)
  br label %__nv_pow.exit2146

__nv_isinfd.exit.i2143:                           ; preds = %__nv_isinfd.exit5.i2135
  %7308 = tail call i32 @llvm.nvvm.d2i.lo(double %7122)
  %7309 = and i32 %7128, 2147483647
  %7310 = icmp eq i32 %7309, 2146435072
  %7311 = icmp eq i32 %7308, 0
  %7312 = select i1 %7310, i1 %7311, i1 false
  %.inv.i2139 = icmp slt i32 %7129, 0
  %spec.select8.i2140 = select i1 %.inv.i2139, i32 0, i32 2146435072
  %7313 = or i32 %spec.select8.i2140, -2147483648
  %thi.6.i2141 = select i1 %spec.select.i2127, i32 %7313, i32 %spec.select8.i2140
  %7314 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2141)
  %spec.select10.i2142 = select i1 %7312, double %7314, double %t.2.i2134
  br label %__nv_pow.exit2146

__nv_pow.exit2146:                                ; preds = %7291, %7296, %7302, %__nv_isinfd.exit.i2143
  %t.6.i2144 = phi double [ %t.2.i2134, %7291 ], [ %7307, %7302 ], [ %7292, %7296 ], [ %spec.select10.i2142, %__nv_isinfd.exit.i2143 ]
  %7315 = fcmp oeq double %7122, 1.000000e+00
  %t.6.i2144.op = fmul reassoc ninf nsz double %t.6.i2144, 3.840000e-01
  %7316 = select i1 %7315, double 3.840000e-01, double %t.6.i2144.op
  %7317 = fsub reassoc ninf nsz double %40, %.01383
  %7318 = fcmp reassoc ninf nsz olt double %7317, 0.000000e+00
  %7319 = tail call double @llvm.fabs.f64(double %7316)
  %neg2508 = fneg reassoc ninf nsz double %7319
  %7320 = select reassoc ninf nsz i1 %7318, double %neg2508, double %7319
  br label %after_if2507

false_block2506:                                  ; preds = %true_block2502
  %7321 = fsub reassoc ninf nsz double %7120, %7121
  %7322 = fcmp reassoc ninf nsz ogt double %7321, 0x3FB70A3D70A3D70A
  br i1 %7322, label %true_block2509, label %false_block2510

after_if2507:                                     ; preds = %true_block2509, %false_block2510, %__nv_pow.exit2146
  %.0744 = phi double [ %7320, %__nv_pow.exit2146 ], [ %7340, %true_block2509 ], [ %7346, %false_block2510 ]
  %getch.i = getelementptr i8, i8* %12, i64 9947232
  %7323 = getelementptr inbounds i8, i8* %getch.i, i64 %14
  %7324 = bitcast i8* %7323 to double*
  %7325 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %7324, i32 64)
  %7326 = fdiv reassoc ninf nsz double 1.000000e+02, %7325
  %7327 = fmul reassoc ninf nsz double %7326, %.0744
  %7328 = fmul reassoc ninf nsz double %.0744, %.0744
  %7329 = fdiv reassoc ninf nsz double %7328, 0.000000e+00
  %7330 = fcmp reassoc ninf nsz olt double %.0744, 0.000000e+00
  %7331 = tail call double @llvm.fabs.f64(double %7329)
  %neg2514 = fneg reassoc ninf nsz double %7331
  %7332 = select reassoc ninf nsz i1 %7330, double %neg2514, double %7331
  %7333 = fmul reassoc ninf nsz double %7332, %7326
  br label %after_if9

true_block2509:                                   ; preds = %false_block2506
  %7334 = tail call double @llvm.sqrt.f64(double %7321)
  %7335 = fmul reassoc ninf nsz double %7334, 4.430000e+00
  %7336 = fmul reassoc ninf nsz double %7335, %7123
  %7337 = fsub reassoc ninf nsz double %40, %.01383
  %7338 = fcmp reassoc ninf nsz olt double %7337, 0.000000e+00
  %7339 = tail call double @llvm.fabs.f64(double %7336)
  %neg2512 = fneg reassoc ninf nsz double %7339
  %7340 = select reassoc ninf nsz i1 %7338, double %neg2512, double %7339
  br label %after_if2507

false_block2510:                                  ; preds = %false_block2506
  %7341 = fmul reassoc ninf nsz double %7321, 1.329000e+01
  %7342 = fmul reassoc ninf nsz double %7341, %7123
  %7343 = fsub reassoc ninf nsz double %40, %.01383
  %7344 = fcmp reassoc ninf nsz olt double %7343, 0.000000e+00
  %7345 = tail call double @llvm.fabs.f64(double %7342)
  %neg2513 = fneg reassoc ninf nsz double %7345
  %7346 = select reassoc ninf nsz i1 %7344, double %neg2513, double %7345
  br label %after_if2507

false_block2519:                                  ; preds = %false_block8
  %7347 = fcmp reassoc ninf nsz ugt double %44, %.01384
  br i1 %7347, label %false_block2522, label %true_block2521

true_block2521:                                   ; preds = %false_block2519
  %7348 = tail call i32 @llvm.nvvm.d2i.hi(double %.01168)
  %7349 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %7350 = and i32 %7349, 2146435072
  %7351 = tail call double @llvm.fabs.f64(double %.01168)
  %7352 = tail call i32 @llvm.nvvm.d2i.hi(double %7351)
  %7353 = tail call i32 @llvm.nvvm.d2i.lo(double %7351)
  %7354 = lshr i32 %7352, 20
  %7355 = icmp ult i32 %7352, 1048576
  %7356 = fmul double %7351, 0x4350000000000000
  %7357 = tail call i32 @llvm.nvvm.d2i.hi(double %7356)
  %7358 = tail call i32 @llvm.nvvm.d2i.lo(double %7356)
  %7359 = lshr i32 %7357, 20
  %7360 = add nsw i32 %7359, -54
  %ilo.0.i.i.i2088 = select i1 %7355, i32 %7358, i32 %7353
  %ihi.0.i.i.i2089 = select i1 %7355, i32 %7357, i32 %7352
  %expo.0.i.i.i2090 = select i1 %7355, i32 %7360, i32 %7354
  %7361 = and i32 %ihi.0.i.i.i2089, -2146435073
  %7362 = or i32 %7361, 1072693248
  %7363 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2088, i32 %7362)
  %7364 = icmp ugt i32 %7362, 1073127582
  %7365 = tail call i32 @llvm.nvvm.d2i.lo(double %7363)
  %7366 = tail call i32 @llvm.nvvm.d2i.hi(double %7363)
  %7367 = add i32 %7366, -1048576
  %7368 = tail call double @llvm.nvvm.lohi.i2d(i32 %7365, i32 %7367)
  %m.0.i.i.i2091 = select i1 %7364, double %7368, double %7363
  %expo.1.i.v.i.i2092 = select i1 %7364, i32 -1022, i32 -1023
  %expo.1.i.i.i2093 = add nsw i32 %expo.1.i.v.i.i2092, %expo.0.i.i.i2090
  %7369 = fadd double %m.0.i.i.i2091, -1.000000e+00
  %7370 = fadd double %m.0.i.i.i2091, 1.000000e+00
  %7371 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %7370)
  %7372 = fneg double %7370
  %7373 = tail call double @llvm.fma.f64(double %7372, double %7371, double 1.000000e+00)
  %7374 = tail call double @llvm.fma.f64(double %7373, double %7373, double %7373)
  %7375 = tail call double @llvm.fma.f64(double %7374, double %7371, double %7371)
  %7376 = fmul double %7369, %7375
  %7377 = fadd double %7376, %7376
  %7378 = fmul double %7377, %7377
  %7379 = tail call double @llvm.fma.f64(double %7378, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %7380 = tail call double @llvm.fma.f64(double %7379, double %7378, double 0x3EF3B20A75488A3F)
  %7381 = tail call double @llvm.fma.f64(double %7380, double %7378, double 0x3F1745CDE4FAECD5)
  %7382 = tail call double @llvm.fma.f64(double %7381, double %7378, double 0x3F3C71C7258A578B)
  %7383 = tail call double @llvm.fma.f64(double %7382, double %7378, double 0x3F6249249242B910)
  %7384 = tail call double @llvm.fma.f64(double %7383, double %7378, double 0x3F89999999999DFB)
  %7385 = fmul double %7378, %7384
  %7386 = fsub double %7369, %7377
  %7387 = fmul double %7386, 2.000000e+00
  %7388 = fneg double %7377
  %7389 = tail call double @llvm.fma.f64(double %7388, double %7369, double %7387)
  %7390 = fmul double %7375, %7389
  %7391 = fadd double %7385, 0x3FB5555555555555
  %7392 = fsub double 0x3FB5555555555555, %7391
  %7393 = fadd double %7385, %7392
  %7394 = fadd double %7393, 0.000000e+00
  %7395 = fadd double %7394, 0xBC46A4CB00B9E7B0
  %7396 = fadd double %7391, %7395
  %7397 = fsub double %7391, %7396
  %7398 = fadd double %7395, %7397
  %7399 = fneg double %7378
  %7400 = tail call double @llvm.fma.f64(double %7377, double %7377, double %7399)
  %7401 = tail call i32 @llvm.nvvm.d2i.lo(double %7390)
  %7402 = tail call i32 @llvm.nvvm.d2i.hi(double %7390)
  %7403 = add i32 %7402, 1048576
  %7404 = tail call double @llvm.nvvm.lohi.i2d(i32 %7401, i32 %7403)
  %7405 = tail call double @llvm.fma.f64(double %7377, double %7404, double %7400)
  %7406 = fmul double %7377, %7378
  %7407 = fneg double %7406
  %7408 = tail call double @llvm.fma.f64(double %7378, double %7377, double %7407)
  %7409 = tail call double @llvm.fma.f64(double %7378, double %7390, double %7408)
  %7410 = tail call double @llvm.fma.f64(double %7405, double %7377, double %7409)
  %7411 = fmul double %7406, %7396
  %7412 = fneg double %7411
  %7413 = tail call double @llvm.fma.f64(double %7396, double %7406, double %7412)
  %7414 = tail call double @llvm.fma.f64(double %7396, double %7410, double %7413)
  %7415 = tail call double @llvm.fma.f64(double %7398, double %7406, double %7414)
  %7416 = fadd double %7411, %7415
  %7417 = fsub double %7411, %7416
  %7418 = fadd double %7415, %7417
  %7419 = fadd double %7377, %7416
  %7420 = fsub double %7377, %7419
  %7421 = fadd double %7416, %7420
  %7422 = fadd double %7418, %7421
  %7423 = fadd double %7390, %7422
  %7424 = fadd double %7419, %7423
  %7425 = fsub double %7419, %7424
  %7426 = fadd double %7423, %7425
  %7427 = xor i32 %expo.1.i.i.i2093, -2147483648
  %7428 = tail call double @llvm.nvvm.lohi.i2d(i32 %7427, i32 1127219200)
  %7429 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %7430 = fsub double %7428, %7429
  %7431 = tail call double @llvm.fma.f64(double %7430, double 0x3FE62E42FEFA39EF, double %7424)
  %7432 = fneg double %7430
  %7433 = tail call double @llvm.fma.f64(double %7432, double 0x3FE62E42FEFA39EF, double %7431)
  %7434 = fsub double %7433, %7424
  %7435 = fsub double %7426, %7434
  %7436 = tail call double @llvm.fma.f64(double %7430, double 0x3C7ABC9E3B39803F, double %7435)
  %7437 = fadd double %7431, %7436
  %7438 = fsub double %7431, %7437
  %7439 = fadd double %7436, %7438
  %7440 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %7441 = shl i32 %7349, 1
  %7442 = icmp ugt i32 %7441, -33554433
  %7443 = and i32 %7349, -15728641
  %spec.select.i.i2094 = select i1 %7442, i32 %7443, i32 %7349
  %7444 = tail call double @llvm.nvvm.lohi.i2d(i32 %7440, i32 %spec.select.i.i2094)
  %7445 = fmul double %7444, %7437
  %7446 = fneg double %7445
  %7447 = tail call double @llvm.fma.f64(double %7437, double %7444, double %7446)
  %7448 = tail call double @llvm.fma.f64(double %7439, double %7444, double %7447)
  %7449 = fadd double %7445, %7448
  %7450 = tail call double @llvm.fma.f64(double %7449, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %7451 = tail call i32 @llvm.nvvm.d2i.lo(double %7450)
  %7452 = fadd double %7450, 0xC338000000000000
  %7453 = tail call double @llvm.fma.f64(double %7452, double 0xBFE62E42FEFA39EF, double %7449)
  %7454 = tail call double @llvm.fma.f64(double %7452, double 0xBC7ABC9E3B39803F, double %7453)
  %7455 = tail call double @llvm.fma.f64(double %7454, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %7456 = tail call double @llvm.fma.f64(double %7455, double %7454, double 0x3EC71DEE62401315)
  %7457 = tail call double @llvm.fma.f64(double %7456, double %7454, double 0x3EFA01997C89EB71)
  %7458 = tail call double @llvm.fma.f64(double %7457, double %7454, double 0x3F2A01A014761F65)
  %7459 = tail call double @llvm.fma.f64(double %7458, double %7454, double 0x3F56C16C1852B7AF)
  %7460 = tail call double @llvm.fma.f64(double %7459, double %7454, double 0x3F81111111122322)
  %7461 = tail call double @llvm.fma.f64(double %7460, double %7454, double 0x3FA55555555502A1)
  %7462 = tail call double @llvm.fma.f64(double %7461, double %7454, double 0x3FC5555555555511)
  %7463 = tail call double @llvm.fma.f64(double %7462, double %7454, double 0x3FE000000000000B)
  %7464 = tail call double @llvm.fma.f64(double %7463, double %7454, double 1.000000e+00)
  %7465 = tail call double @llvm.fma.f64(double %7464, double %7454, double 1.000000e+00)
  %7466 = tail call i32 @llvm.nvvm.d2i.lo(double %7465)
  %7467 = tail call i32 @llvm.nvvm.d2i.hi(double %7465)
  %7468 = shl i32 %7451, 20
  %7469 = add i32 %7467, %7468
  %7470 = tail call double @llvm.nvvm.lohi.i2d(i32 %7466, i32 %7469)
  %7471 = tail call i32 @llvm.nvvm.d2i.hi(double %7449)
  %7472 = bitcast i32 %7471 to float
  %7473 = tail call float @llvm.fabs.f32(float %7472)
  %7474 = fcmp uge float %7473, 0x4010C46560000000
  br i1 %7474, label %__internal_fast_icmp_abs_lt.exit.i.i.i2096, label %__internal_accurate_pow.exit.i2099

__internal_fast_icmp_abs_lt.exit.i.i.i2096:       ; preds = %true_block2521
  %7475 = fcmp olt double %7449, 0.000000e+00
  %7476 = fadd double %7449, 0x7FF0000000000000
  %z.0.i.i.i2095 = select i1 %7475, double 0.000000e+00, double %7476
  %7477 = fcmp olt float %7473, 0x4010E90000000000
  br i1 %7477, label %7478, label %__internal_accurate_pow.exit.i2099

7478:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2096
  %7479 = sdiv i32 %7451, 2
  %7480 = shl i32 %7479, 20
  %7481 = add i32 %7467, %7480
  %7482 = tail call double @llvm.nvvm.lohi.i2d(i32 %7466, i32 %7481)
  %7483 = sub nsw i32 %7451, %7479
  %7484 = shl i32 %7483, 20
  %7485 = add nsw i32 %7484, 1072693248
  %7486 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %7485)
  %7487 = fmul double %7486, %7482
  br label %__internal_accurate_pow.exit.i2099

__internal_accurate_pow.exit.i2099:               ; preds = %7478, %__internal_fast_icmp_abs_lt.exit.i.i.i2096, %true_block2521
  %z.2.i.i.i2097 = phi double [ %7470, %true_block2521 ], [ %7487, %7478 ], [ %z.0.i.i.i2095, %__internal_fast_icmp_abs_lt.exit.i.i.i2096 ]
  %7488 = icmp eq i32 %7350, 1073741824
  %7489 = icmp slt i32 %7348, 0
  %spec.select.i2098 = select i1 %7489, i1 %7488, i1 false
  %7490 = fcmp oeq double %.01168, 0.000000e+00
  br i1 %7490, label %7491, label %7496

7491:                                             ; preds = %__internal_accurate_pow.exit.i2099
  %7492 = icmp eq i32 %7350, 1073741824
  %spec.select1.i2100 = select i1 %7492, i32 %7348, i32 0
  %7493 = icmp slt i32 %7349, 0
  %7494 = or i32 %spec.select1.i2100, 2146435072
  %thi.1.i2101 = select i1 %7493, i32 %7494, i32 %spec.select1.i2100
  %7495 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2101)
  br label %7511

7496:                                             ; preds = %__internal_accurate_pow.exit.i2099
  %7497 = icmp slt i32 %7348, 0
  %7498 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2097)
  %7499 = and i32 %7498, 2147483647
  %7500 = icmp ne i32 %7499, 2146435072
  %7501 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2097)
  %7502 = icmp ne i32 %7501, 0
  %7503 = select i1 %7500, i1 true, i1 %7502
  %7504 = fsub double %7445, %7449
  %7505 = fadd double %7448, %7504
  %7506 = tail call double @llvm.fma.f64(double %z.2.i.i.i2097, double %7505, double %z.2.i.i.i2097)
  %tmp.0.i.i2102 = select i1 %7503, double %7506, double %z.2.i.i.i2097
  %7507 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2102)
  %7508 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2102)
  %7509 = xor i32 %7508, -2147483648
  %7510 = tail call double @llvm.nvvm.lohi.i2d(i32 %7507, i32 %7509)
  %t.0.i2103 = select i1 %spec.select.i2098, double %7510, double %tmp.0.i.i2102
  %t.1.i2104 = select i1 %7497, double 0xFFF8000000000000, double %t.0.i2103
  br label %7511

7511:                                             ; preds = %7496, %7491
  %t.2.i2105 = phi double [ %7495, %7491 ], [ %t.1.i2104, %7496 ]
  %7512 = fadd double %.01168, 1.500000e+00
  %7513 = tail call i32 @llvm.nvvm.d2i.hi(double %7512)
  %7514 = and i32 %7513, 2146435072
  %7515 = icmp eq i32 %7514, 2146435072
  br i1 %7515, label %7516, label %__nv_pow.exit2116

7516:                                             ; preds = %7511
  %7517 = fcmp ugt double %7351, 0x7FF0000000000000
  br i1 %7517, label %__nv_pow.exit2116, label %__nv_isinfd.exit5.i2106

__nv_isinfd.exit5.i2106:                          ; preds = %7516
  %7518 = and i32 %7349, 2147483647
  %7519 = icmp eq i32 %7518, 2146435072
  %7520 = icmp eq i32 %7440, 0
  %7521 = select i1 %7519, i1 %7520, i1 false
  br i1 %7521, label %7522, label %__nv_isinfd.exit.i2113

7522:                                             ; preds = %__nv_isinfd.exit5.i2106
  %7523 = fcmp ogt double %7351, 1.000000e+00
  %thi.2.i2107 = select i1 %7523, i32 2146435072, i32 0
  %7524 = icmp slt i32 %7349, 0
  %7525 = xor i32 %thi.2.i2107, 2146435072
  %thi.3.i2108 = select i1 %7524, i32 %7525, i32 %thi.2.i2107
  %7526 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.3.i2108)
  br label %__nv_pow.exit2116

__nv_isinfd.exit.i2113:                           ; preds = %__nv_isinfd.exit5.i2106
  %7527 = tail call i32 @llvm.nvvm.d2i.lo(double %.01168)
  %7528 = and i32 %7348, 2147483647
  %7529 = icmp eq i32 %7528, 2146435072
  %7530 = icmp eq i32 %7527, 0
  %7531 = select i1 %7529, i1 %7530, i1 false
  %.inv.i2109 = icmp slt i32 %7349, 0
  %spec.select8.i2110 = select i1 %.inv.i2109, i32 0, i32 2146435072
  %7532 = or i32 %spec.select8.i2110, -2147483648
  %thi.6.i2111 = select i1 %spec.select.i2098, i32 %7532, i32 %spec.select8.i2110
  %7533 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2111)
  %spec.select10.i2112 = select i1 %7531, double %7533, double %t.2.i2105
  br label %__nv_pow.exit2116

__nv_pow.exit2116:                                ; preds = %7511, %7516, %7522, %__nv_isinfd.exit.i2113
  %t.6.i2114 = phi double [ %t.2.i2105, %7511 ], [ %7526, %7522 ], [ %7512, %7516 ], [ %spec.select10.i2112, %__nv_isinfd.exit.i2113 ]
  %7534 = fcmp oeq double %.01168, 1.000000e+00
  %t.6.i2114.op = fmul reassoc ninf nsz double %t.6.i2114, -1.700000e+00
  %7535 = select i1 %7534, double -1.700000e+00, double %t.6.i2114.op
  %7536 = fmul reassoc ninf nsz double %53, %28
  %7537 = tail call double @llvm.fabs.f64(double %53)
  %7538 = fmul reassoc ninf nsz double %7536, %7537
  %7539 = fmul reassoc ninf nsz double %28, %28
  %7540 = fmul reassoc ninf nsz double %7539, 4.905000e+00
  br label %after_if9

false_block2522:                                  ; preds = %false_block2519
  %7541 = fcmp reassoc ninf nsz ugt double %.01383, %37
  br i1 %7541, label %false_block2525, label %true_block2524

true_block2524:                                   ; preds = %false_block2522
  %7542 = tail call i32 @llvm.nvvm.d2i.hi(double %28)
  %7543 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %7544 = and i32 %7543, 2146435072
  %7545 = tail call double @llvm.fabs.f64(double %28)
  %7546 = tail call i32 @llvm.nvvm.d2i.hi(double %7545)
  %7547 = tail call i32 @llvm.nvvm.d2i.lo(double %7545)
  %7548 = lshr i32 %7546, 20
  %7549 = icmp ult i32 %7546, 1048576
  %7550 = fmul double %7545, 0x4350000000000000
  %7551 = tail call i32 @llvm.nvvm.d2i.hi(double %7550)
  %7552 = tail call i32 @llvm.nvvm.d2i.lo(double %7550)
  %7553 = lshr i32 %7551, 20
  %7554 = add nsw i32 %7553, -54
  %ilo.0.i.i.i2058 = select i1 %7549, i32 %7552, i32 %7547
  %ihi.0.i.i.i2059 = select i1 %7549, i32 %7551, i32 %7546
  %expo.0.i.i.i2060 = select i1 %7549, i32 %7554, i32 %7548
  %7555 = and i32 %ihi.0.i.i.i2059, -2146435073
  %7556 = or i32 %7555, 1072693248
  %7557 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2058, i32 %7556)
  %7558 = icmp ugt i32 %7556, 1073127582
  %7559 = tail call i32 @llvm.nvvm.d2i.lo(double %7557)
  %7560 = tail call i32 @llvm.nvvm.d2i.hi(double %7557)
  %7561 = add i32 %7560, -1048576
  %7562 = tail call double @llvm.nvvm.lohi.i2d(i32 %7559, i32 %7561)
  %m.0.i.i.i2061 = select i1 %7558, double %7562, double %7557
  %expo.1.i.v.i.i2062 = select i1 %7558, i32 -1022, i32 -1023
  %expo.1.i.i.i2063 = add nsw i32 %expo.1.i.v.i.i2062, %expo.0.i.i.i2060
  %7563 = fadd double %m.0.i.i.i2061, -1.000000e+00
  %7564 = fadd double %m.0.i.i.i2061, 1.000000e+00
  %7565 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %7564)
  %7566 = fneg double %7564
  %7567 = tail call double @llvm.fma.f64(double %7566, double %7565, double 1.000000e+00)
  %7568 = tail call double @llvm.fma.f64(double %7567, double %7567, double %7567)
  %7569 = tail call double @llvm.fma.f64(double %7568, double %7565, double %7565)
  %7570 = fmul double %7563, %7569
  %7571 = fadd double %7570, %7570
  %7572 = fmul double %7571, %7571
  %7573 = tail call double @llvm.fma.f64(double %7572, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %7574 = tail call double @llvm.fma.f64(double %7573, double %7572, double 0x3EF3B20A75488A3F)
  %7575 = tail call double @llvm.fma.f64(double %7574, double %7572, double 0x3F1745CDE4FAECD5)
  %7576 = tail call double @llvm.fma.f64(double %7575, double %7572, double 0x3F3C71C7258A578B)
  %7577 = tail call double @llvm.fma.f64(double %7576, double %7572, double 0x3F6249249242B910)
  %7578 = tail call double @llvm.fma.f64(double %7577, double %7572, double 0x3F89999999999DFB)
  %7579 = fmul double %7572, %7578
  %7580 = fsub double %7563, %7571
  %7581 = fmul double %7580, 2.000000e+00
  %7582 = fneg double %7571
  %7583 = tail call double @llvm.fma.f64(double %7582, double %7563, double %7581)
  %7584 = fmul double %7569, %7583
  %7585 = fadd double %7579, 0x3FB5555555555555
  %7586 = fsub double 0x3FB5555555555555, %7585
  %7587 = fadd double %7579, %7586
  %7588 = fadd double %7587, 0.000000e+00
  %7589 = fadd double %7588, 0xBC46A4CB00B9E7B0
  %7590 = fadd double %7585, %7589
  %7591 = fsub double %7585, %7590
  %7592 = fadd double %7589, %7591
  %7593 = fneg double %7572
  %7594 = tail call double @llvm.fma.f64(double %7571, double %7571, double %7593)
  %7595 = tail call i32 @llvm.nvvm.d2i.lo(double %7584)
  %7596 = tail call i32 @llvm.nvvm.d2i.hi(double %7584)
  %7597 = add i32 %7596, 1048576
  %7598 = tail call double @llvm.nvvm.lohi.i2d(i32 %7595, i32 %7597)
  %7599 = tail call double @llvm.fma.f64(double %7571, double %7598, double %7594)
  %7600 = fmul double %7571, %7572
  %7601 = fneg double %7600
  %7602 = tail call double @llvm.fma.f64(double %7572, double %7571, double %7601)
  %7603 = tail call double @llvm.fma.f64(double %7572, double %7584, double %7602)
  %7604 = tail call double @llvm.fma.f64(double %7599, double %7571, double %7603)
  %7605 = fmul double %7600, %7590
  %7606 = fneg double %7605
  %7607 = tail call double @llvm.fma.f64(double %7590, double %7600, double %7606)
  %7608 = tail call double @llvm.fma.f64(double %7590, double %7604, double %7607)
  %7609 = tail call double @llvm.fma.f64(double %7592, double %7600, double %7608)
  %7610 = fadd double %7605, %7609
  %7611 = fsub double %7605, %7610
  %7612 = fadd double %7609, %7611
  %7613 = fadd double %7571, %7610
  %7614 = fsub double %7571, %7613
  %7615 = fadd double %7610, %7614
  %7616 = fadd double %7612, %7615
  %7617 = fadd double %7584, %7616
  %7618 = fadd double %7613, %7617
  %7619 = fsub double %7613, %7618
  %7620 = fadd double %7617, %7619
  %7621 = xor i32 %expo.1.i.i.i2063, -2147483648
  %7622 = tail call double @llvm.nvvm.lohi.i2d(i32 %7621, i32 1127219200)
  %7623 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %7624 = fsub double %7622, %7623
  %7625 = tail call double @llvm.fma.f64(double %7624, double 0x3FE62E42FEFA39EF, double %7618)
  %7626 = fneg double %7624
  %7627 = tail call double @llvm.fma.f64(double %7626, double 0x3FE62E42FEFA39EF, double %7625)
  %7628 = fsub double %7627, %7618
  %7629 = fsub double %7620, %7628
  %7630 = tail call double @llvm.fma.f64(double %7624, double 0x3C7ABC9E3B39803F, double %7629)
  %7631 = fadd double %7625, %7630
  %7632 = fsub double %7625, %7631
  %7633 = fadd double %7630, %7632
  %7634 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %7635 = shl i32 %7543, 1
  %7636 = icmp ugt i32 %7635, -33554433
  %7637 = and i32 %7543, -15728641
  %spec.select.i.i2064 = select i1 %7636, i32 %7637, i32 %7543
  %7638 = tail call double @llvm.nvvm.lohi.i2d(i32 %7634, i32 %spec.select.i.i2064)
  %7639 = fmul double %7638, %7631
  %7640 = fneg double %7639
  %7641 = tail call double @llvm.fma.f64(double %7631, double %7638, double %7640)
  %7642 = tail call double @llvm.fma.f64(double %7633, double %7638, double %7641)
  %7643 = fadd double %7639, %7642
  %7644 = tail call double @llvm.fma.f64(double %7643, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %7645 = tail call i32 @llvm.nvvm.d2i.lo(double %7644)
  %7646 = fadd double %7644, 0xC338000000000000
  %7647 = tail call double @llvm.fma.f64(double %7646, double 0xBFE62E42FEFA39EF, double %7643)
  %7648 = tail call double @llvm.fma.f64(double %7646, double 0xBC7ABC9E3B39803F, double %7647)
  %7649 = tail call double @llvm.fma.f64(double %7648, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %7650 = tail call double @llvm.fma.f64(double %7649, double %7648, double 0x3EC71DEE62401315)
  %7651 = tail call double @llvm.fma.f64(double %7650, double %7648, double 0x3EFA01997C89EB71)
  %7652 = tail call double @llvm.fma.f64(double %7651, double %7648, double 0x3F2A01A014761F65)
  %7653 = tail call double @llvm.fma.f64(double %7652, double %7648, double 0x3F56C16C1852B7AF)
  %7654 = tail call double @llvm.fma.f64(double %7653, double %7648, double 0x3F81111111122322)
  %7655 = tail call double @llvm.fma.f64(double %7654, double %7648, double 0x3FA55555555502A1)
  %7656 = tail call double @llvm.fma.f64(double %7655, double %7648, double 0x3FC5555555555511)
  %7657 = tail call double @llvm.fma.f64(double %7656, double %7648, double 0x3FE000000000000B)
  %7658 = tail call double @llvm.fma.f64(double %7657, double %7648, double 1.000000e+00)
  %7659 = tail call double @llvm.fma.f64(double %7658, double %7648, double 1.000000e+00)
  %7660 = tail call i32 @llvm.nvvm.d2i.lo(double %7659)
  %7661 = tail call i32 @llvm.nvvm.d2i.hi(double %7659)
  %7662 = shl i32 %7645, 20
  %7663 = add i32 %7661, %7662
  %7664 = tail call double @llvm.nvvm.lohi.i2d(i32 %7660, i32 %7663)
  %7665 = tail call i32 @llvm.nvvm.d2i.hi(double %7643)
  %7666 = bitcast i32 %7665 to float
  %7667 = tail call float @llvm.fabs.f32(float %7666)
  %7668 = fcmp uge float %7667, 0x4010C46560000000
  br i1 %7668, label %__internal_fast_icmp_abs_lt.exit.i.i.i2066, label %__internal_accurate_pow.exit.i2069

__internal_fast_icmp_abs_lt.exit.i.i.i2066:       ; preds = %true_block2524
  %7669 = fcmp olt double %7643, 0.000000e+00
  %7670 = fadd double %7643, 0x7FF0000000000000
  %z.0.i.i.i2065 = select i1 %7669, double 0.000000e+00, double %7670
  %7671 = fcmp olt float %7667, 0x4010E90000000000
  br i1 %7671, label %7672, label %__internal_accurate_pow.exit.i2069

7672:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2066
  %7673 = sdiv i32 %7645, 2
  %7674 = shl i32 %7673, 20
  %7675 = add i32 %7661, %7674
  %7676 = tail call double @llvm.nvvm.lohi.i2d(i32 %7660, i32 %7675)
  %7677 = sub nsw i32 %7645, %7673
  %7678 = shl i32 %7677, 20
  %7679 = add nsw i32 %7678, 1072693248
  %7680 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %7679)
  %7681 = fmul double %7680, %7676
  br label %__internal_accurate_pow.exit.i2069

__internal_accurate_pow.exit.i2069:               ; preds = %7672, %__internal_fast_icmp_abs_lt.exit.i.i.i2066, %true_block2524
  %z.2.i.i.i2067 = phi double [ %7664, %true_block2524 ], [ %7681, %7672 ], [ %z.0.i.i.i2065, %__internal_fast_icmp_abs_lt.exit.i.i.i2066 ]
  %7682 = icmp eq i32 %7544, 1073741824
  %7683 = icmp slt i32 %7542, 0
  %spec.select.i2068 = select i1 %7683, i1 %7682, i1 false
  %7684 = fcmp oeq double %28, 0.000000e+00
  br i1 %7684, label %7685, label %7690

7685:                                             ; preds = %__internal_accurate_pow.exit.i2069
  %7686 = icmp eq i32 %7544, 1073741824
  %spec.select1.i2070 = select i1 %7686, i32 %7542, i32 0
  %7687 = icmp slt i32 %7543, 0
  %7688 = or i32 %spec.select1.i2070, 2146435072
  %thi.1.i2071 = select i1 %7687, i32 %7688, i32 %spec.select1.i2070
  %7689 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2071)
  br label %7705

7690:                                             ; preds = %__internal_accurate_pow.exit.i2069
  %7691 = icmp slt i32 %7542, 0
  %7692 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2067)
  %7693 = and i32 %7692, 2147483647
  %7694 = icmp ne i32 %7693, 2146435072
  %7695 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2067)
  %7696 = icmp ne i32 %7695, 0
  %7697 = select i1 %7694, i1 true, i1 %7696
  %7698 = fsub double %7639, %7643
  %7699 = fadd double %7642, %7698
  %7700 = tail call double @llvm.fma.f64(double %z.2.i.i.i2067, double %7699, double %z.2.i.i.i2067)
  %tmp.0.i.i2072 = select i1 %7697, double %7700, double %z.2.i.i.i2067
  %7701 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2072)
  %7702 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2072)
  %7703 = xor i32 %7702, -2147483648
  %7704 = tail call double @llvm.nvvm.lohi.i2d(i32 %7701, i32 %7703)
  %t.0.i2073 = select i1 %spec.select.i2068, double %7704, double %tmp.0.i.i2072
  %t.1.i2074 = select i1 %7691, double 0xFFF8000000000000, double %t.0.i2073
  br label %7705

7705:                                             ; preds = %7690, %7685
  %t.2.i2075 = phi double [ %7689, %7685 ], [ %t.1.i2074, %7690 ]
  %7706 = fadd double %28, 1.500000e+00
  %7707 = tail call i32 @llvm.nvvm.d2i.hi(double %7706)
  %7708 = and i32 %7707, 2146435072
  %7709 = icmp eq i32 %7708, 2146435072
  br i1 %7709, label %7710, label %__nv_pow.exit2087

7710:                                             ; preds = %7705
  %7711 = fcmp ugt double %7545, 0x7FF0000000000000
  br i1 %7711, label %__nv_pow.exit2087, label %__nv_isinfd.exit5.i2076

__nv_isinfd.exit5.i2076:                          ; preds = %7710
  %7712 = and i32 %7543, 2147483647
  %7713 = icmp eq i32 %7712, 2146435072
  %7714 = icmp eq i32 %7634, 0
  %7715 = select i1 %7713, i1 %7714, i1 false
  br i1 %7715, label %7716, label %__nv_isinfd.exit.i2084

7716:                                             ; preds = %__nv_isinfd.exit5.i2076
  %7717 = fcmp ogt double %7545, 1.000000e+00
  %thi.2.i2077 = select i1 %7717, i32 2146435072, i32 0
  %7718 = icmp slt i32 %7543, 0
  %7719 = xor i32 %thi.2.i2077, 2146435072
  %thi.3.i2078 = select i1 %7718, i32 %7719, i32 %thi.2.i2077
  %7720 = fcmp oeq double %28, -1.000000e+00
  %thi.4.i2079 = select i1 %7720, i32 1072693248, i32 %thi.3.i2078
  %7721 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i2079)
  br label %__nv_pow.exit2087

__nv_isinfd.exit.i2084:                           ; preds = %__nv_isinfd.exit5.i2076
  %7722 = tail call i32 @llvm.nvvm.d2i.lo(double %28)
  %7723 = and i32 %7542, 2147483647
  %7724 = icmp eq i32 %7723, 2146435072
  %7725 = icmp eq i32 %7722, 0
  %7726 = select i1 %7724, i1 %7725, i1 false
  %.inv.i2080 = icmp slt i32 %7543, 0
  %spec.select8.i2081 = select i1 %.inv.i2080, i32 0, i32 2146435072
  %7727 = or i32 %spec.select8.i2081, -2147483648
  %thi.6.i2082 = select i1 %spec.select.i2068, i32 %7727, i32 %spec.select8.i2081
  %7728 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2082)
  %spec.select10.i2083 = select i1 %7726, double %7728, double %t.2.i2075
  br label %__nv_pow.exit2087

__nv_pow.exit2087:                                ; preds = %7705, %7710, %7716, %__nv_isinfd.exit.i2084
  %t.6.i2085 = phi double [ %t.2.i2075, %7705 ], [ %7721, %7716 ], [ %7706, %7710 ], [ %spec.select10.i2083, %__nv_isinfd.exit.i2084 ]
  %7729 = fcmp oeq double %28, 1.000000e+00
  %t.6.i2085.op = fmul reassoc ninf nsz double %t.6.i2085, 1.700000e+00
  %7730 = select i1 %7729, double 1.700000e+00, double %t.6.i2085.op
  %7731 = tail call double @llvm.fabs.f64(double %53)
  %7732 = fmul reassoc ninf nsz double %7731, %28
  %7733 = fmul reassoc ninf nsz double %7732, %53
  %7734 = fmul reassoc ninf nsz double %7732, %56
  br label %after_if9

false_block2525:                                  ; preds = %false_block2522
  %7735 = fcmp reassoc ninf nsz ugt double %28, 1.000000e-02
  br i1 %7735, label %false_block2528, label %true_block2527

true_block2527:                                   ; preds = %false_block2525
  %7736 = fcmp reassoc ninf nsz ogt double %.01383, %44
  br i1 %7736, label %true_block2530, label %false_block2531

false_block2528:                                  ; preds = %false_block2525
  %7737 = fcmp reassoc ninf nsz ugt double %.01168, 1.000000e-02
  br i1 %7737, label %false_block2534, label %true_block2533

true_block2530:                                   ; preds = %true_block2527
  %7738 = fsub reassoc ninf nsz double %.01383, %37
  %7739 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %7738, double 1.000000e-03)
  %7740 = tail call double @llvm.sqrt.f64(double %7739)
  %7741 = fmul reassoc ninf nsz double %7740, -1.700000e+00
  %7742 = fmul reassoc ninf nsz double %7741, %7739
  %7743 = fmul reassoc ninf nsz double %7742, %7741
  %7744 = fmul reassoc ninf nsz double %.01381, %47
  %7745 = fmul reassoc ninf nsz double %.01382, %50
  %7746 = fsub reassoc ninf nsz double %7744, %7745
  %7747 = fmul reassoc ninf nsz double %7742, %7746
  %7748 = fmul reassoc ninf nsz double %28, %28
  %7749 = fmul reassoc ninf nsz double %7748, 4.905000e+00
  br label %after_if9

false_block2531:                                  ; preds = %true_block2527
  %7750 = tail call i32 @llvm.nvvm.d2i.hi(double %28)
  %7751 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %7752 = and i32 %7751, 2146435072
  %7753 = tail call double @llvm.fabs.f64(double %28)
  %7754 = tail call i32 @llvm.nvvm.d2i.hi(double %7753)
  %7755 = tail call i32 @llvm.nvvm.d2i.lo(double %7753)
  %7756 = lshr i32 %7754, 20
  %7757 = icmp ult i32 %7754, 1048576
  %7758 = fmul double %7753, 0x4350000000000000
  %7759 = tail call i32 @llvm.nvvm.d2i.hi(double %7758)
  %7760 = tail call i32 @llvm.nvvm.d2i.lo(double %7758)
  %7761 = lshr i32 %7759, 20
  %7762 = add nsw i32 %7761, -54
  %ilo.0.i.i.i2029 = select i1 %7757, i32 %7760, i32 %7755
  %ihi.0.i.i.i2030 = select i1 %7757, i32 %7759, i32 %7754
  %expo.0.i.i.i2031 = select i1 %7757, i32 %7762, i32 %7756
  %7763 = and i32 %ihi.0.i.i.i2030, -2146435073
  %7764 = or i32 %7763, 1072693248
  %7765 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i2029, i32 %7764)
  %7766 = icmp ugt i32 %7764, 1073127582
  %7767 = tail call i32 @llvm.nvvm.d2i.lo(double %7765)
  %7768 = tail call i32 @llvm.nvvm.d2i.hi(double %7765)
  %7769 = add i32 %7768, -1048576
  %7770 = tail call double @llvm.nvvm.lohi.i2d(i32 %7767, i32 %7769)
  %m.0.i.i.i2032 = select i1 %7766, double %7770, double %7765
  %expo.1.i.v.i.i2033 = select i1 %7766, i32 -1022, i32 -1023
  %expo.1.i.i.i2034 = add nsw i32 %expo.1.i.v.i.i2033, %expo.0.i.i.i2031
  %7771 = fadd double %m.0.i.i.i2032, -1.000000e+00
  %7772 = fadd double %m.0.i.i.i2032, 1.000000e+00
  %7773 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %7772)
  %7774 = fneg double %7772
  %7775 = tail call double @llvm.fma.f64(double %7774, double %7773, double 1.000000e+00)
  %7776 = tail call double @llvm.fma.f64(double %7775, double %7775, double %7775)
  %7777 = tail call double @llvm.fma.f64(double %7776, double %7773, double %7773)
  %7778 = fmul double %7771, %7777
  %7779 = fadd double %7778, %7778
  %7780 = fmul double %7779, %7779
  %7781 = tail call double @llvm.fma.f64(double %7780, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %7782 = tail call double @llvm.fma.f64(double %7781, double %7780, double 0x3EF3B20A75488A3F)
  %7783 = tail call double @llvm.fma.f64(double %7782, double %7780, double 0x3F1745CDE4FAECD5)
  %7784 = tail call double @llvm.fma.f64(double %7783, double %7780, double 0x3F3C71C7258A578B)
  %7785 = tail call double @llvm.fma.f64(double %7784, double %7780, double 0x3F6249249242B910)
  %7786 = tail call double @llvm.fma.f64(double %7785, double %7780, double 0x3F89999999999DFB)
  %7787 = fmul double %7780, %7786
  %7788 = fsub double %7771, %7779
  %7789 = fmul double %7788, 2.000000e+00
  %7790 = fneg double %7779
  %7791 = tail call double @llvm.fma.f64(double %7790, double %7771, double %7789)
  %7792 = fmul double %7777, %7791
  %7793 = fadd double %7787, 0x3FB5555555555555
  %7794 = fsub double 0x3FB5555555555555, %7793
  %7795 = fadd double %7787, %7794
  %7796 = fadd double %7795, 0.000000e+00
  %7797 = fadd double %7796, 0xBC46A4CB00B9E7B0
  %7798 = fadd double %7793, %7797
  %7799 = fsub double %7793, %7798
  %7800 = fadd double %7797, %7799
  %7801 = fneg double %7780
  %7802 = tail call double @llvm.fma.f64(double %7779, double %7779, double %7801)
  %7803 = tail call i32 @llvm.nvvm.d2i.lo(double %7792)
  %7804 = tail call i32 @llvm.nvvm.d2i.hi(double %7792)
  %7805 = add i32 %7804, 1048576
  %7806 = tail call double @llvm.nvvm.lohi.i2d(i32 %7803, i32 %7805)
  %7807 = tail call double @llvm.fma.f64(double %7779, double %7806, double %7802)
  %7808 = fmul double %7779, %7780
  %7809 = fneg double %7808
  %7810 = tail call double @llvm.fma.f64(double %7780, double %7779, double %7809)
  %7811 = tail call double @llvm.fma.f64(double %7780, double %7792, double %7810)
  %7812 = tail call double @llvm.fma.f64(double %7807, double %7779, double %7811)
  %7813 = fmul double %7808, %7798
  %7814 = fneg double %7813
  %7815 = tail call double @llvm.fma.f64(double %7798, double %7808, double %7814)
  %7816 = tail call double @llvm.fma.f64(double %7798, double %7812, double %7815)
  %7817 = tail call double @llvm.fma.f64(double %7800, double %7808, double %7816)
  %7818 = fadd double %7813, %7817
  %7819 = fsub double %7813, %7818
  %7820 = fadd double %7817, %7819
  %7821 = fadd double %7779, %7818
  %7822 = fsub double %7779, %7821
  %7823 = fadd double %7818, %7822
  %7824 = fadd double %7820, %7823
  %7825 = fadd double %7792, %7824
  %7826 = fadd double %7821, %7825
  %7827 = fsub double %7821, %7826
  %7828 = fadd double %7825, %7827
  %7829 = xor i32 %expo.1.i.i.i2034, -2147483648
  %7830 = tail call double @llvm.nvvm.lohi.i2d(i32 %7829, i32 1127219200)
  %7831 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %7832 = fsub double %7830, %7831
  %7833 = tail call double @llvm.fma.f64(double %7832, double 0x3FE62E42FEFA39EF, double %7826)
  %7834 = fneg double %7832
  %7835 = tail call double @llvm.fma.f64(double %7834, double 0x3FE62E42FEFA39EF, double %7833)
  %7836 = fsub double %7835, %7826
  %7837 = fsub double %7828, %7836
  %7838 = tail call double @llvm.fma.f64(double %7832, double 0x3C7ABC9E3B39803F, double %7837)
  %7839 = fadd double %7833, %7838
  %7840 = fsub double %7833, %7839
  %7841 = fadd double %7838, %7840
  %7842 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %7843 = shl i32 %7751, 1
  %7844 = icmp ugt i32 %7843, -33554433
  %7845 = and i32 %7751, -15728641
  %spec.select.i.i2035 = select i1 %7844, i32 %7845, i32 %7751
  %7846 = tail call double @llvm.nvvm.lohi.i2d(i32 %7842, i32 %spec.select.i.i2035)
  %7847 = fmul double %7846, %7839
  %7848 = fneg double %7847
  %7849 = tail call double @llvm.fma.f64(double %7839, double %7846, double %7848)
  %7850 = tail call double @llvm.fma.f64(double %7841, double %7846, double %7849)
  %7851 = fadd double %7847, %7850
  %7852 = tail call double @llvm.fma.f64(double %7851, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %7853 = tail call i32 @llvm.nvvm.d2i.lo(double %7852)
  %7854 = fadd double %7852, 0xC338000000000000
  %7855 = tail call double @llvm.fma.f64(double %7854, double 0xBFE62E42FEFA39EF, double %7851)
  %7856 = tail call double @llvm.fma.f64(double %7854, double 0xBC7ABC9E3B39803F, double %7855)
  %7857 = tail call double @llvm.fma.f64(double %7856, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %7858 = tail call double @llvm.fma.f64(double %7857, double %7856, double 0x3EC71DEE62401315)
  %7859 = tail call double @llvm.fma.f64(double %7858, double %7856, double 0x3EFA01997C89EB71)
  %7860 = tail call double @llvm.fma.f64(double %7859, double %7856, double 0x3F2A01A014761F65)
  %7861 = tail call double @llvm.fma.f64(double %7860, double %7856, double 0x3F56C16C1852B7AF)
  %7862 = tail call double @llvm.fma.f64(double %7861, double %7856, double 0x3F81111111122322)
  %7863 = tail call double @llvm.fma.f64(double %7862, double %7856, double 0x3FA55555555502A1)
  %7864 = tail call double @llvm.fma.f64(double %7863, double %7856, double 0x3FC5555555555511)
  %7865 = tail call double @llvm.fma.f64(double %7864, double %7856, double 0x3FE000000000000B)
  %7866 = tail call double @llvm.fma.f64(double %7865, double %7856, double 1.000000e+00)
  %7867 = tail call double @llvm.fma.f64(double %7866, double %7856, double 1.000000e+00)
  %7868 = tail call i32 @llvm.nvvm.d2i.lo(double %7867)
  %7869 = tail call i32 @llvm.nvvm.d2i.hi(double %7867)
  %7870 = shl i32 %7853, 20
  %7871 = add i32 %7869, %7870
  %7872 = tail call double @llvm.nvvm.lohi.i2d(i32 %7868, i32 %7871)
  %7873 = tail call i32 @llvm.nvvm.d2i.hi(double %7851)
  %7874 = bitcast i32 %7873 to float
  %7875 = tail call float @llvm.fabs.f32(float %7874)
  %7876 = fcmp uge float %7875, 0x4010C46560000000
  br i1 %7876, label %__internal_fast_icmp_abs_lt.exit.i.i.i2037, label %__internal_accurate_pow.exit.i2040

__internal_fast_icmp_abs_lt.exit.i.i.i2037:       ; preds = %false_block2531
  %7877 = fcmp olt double %7851, 0.000000e+00
  %7878 = fadd double %7851, 0x7FF0000000000000
  %z.0.i.i.i2036 = select i1 %7877, double 0.000000e+00, double %7878
  %7879 = fcmp olt float %7875, 0x4010E90000000000
  br i1 %7879, label %7880, label %__internal_accurate_pow.exit.i2040

7880:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i2037
  %7881 = sdiv i32 %7853, 2
  %7882 = shl i32 %7881, 20
  %7883 = add i32 %7869, %7882
  %7884 = tail call double @llvm.nvvm.lohi.i2d(i32 %7868, i32 %7883)
  %7885 = sub nsw i32 %7853, %7881
  %7886 = shl i32 %7885, 20
  %7887 = add nsw i32 %7886, 1072693248
  %7888 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %7887)
  %7889 = fmul double %7888, %7884
  br label %__internal_accurate_pow.exit.i2040

__internal_accurate_pow.exit.i2040:               ; preds = %7880, %__internal_fast_icmp_abs_lt.exit.i.i.i2037, %false_block2531
  %z.2.i.i.i2038 = phi double [ %7872, %false_block2531 ], [ %7889, %7880 ], [ %z.0.i.i.i2036, %__internal_fast_icmp_abs_lt.exit.i.i.i2037 ]
  %7890 = icmp eq i32 %7752, 1073741824
  %7891 = icmp slt i32 %7750, 0
  %spec.select.i2039 = select i1 %7891, i1 %7890, i1 false
  %7892 = fcmp oeq double %28, 0.000000e+00
  br i1 %7892, label %7893, label %7898

7893:                                             ; preds = %__internal_accurate_pow.exit.i2040
  %7894 = icmp eq i32 %7752, 1073741824
  %spec.select1.i2041 = select i1 %7894, i32 %7750, i32 0
  %7895 = icmp slt i32 %7751, 0
  %7896 = or i32 %spec.select1.i2041, 2146435072
  %thi.1.i2042 = select i1 %7895, i32 %7896, i32 %spec.select1.i2041
  %7897 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i2042)
  br label %7913

7898:                                             ; preds = %__internal_accurate_pow.exit.i2040
  %7899 = icmp slt i32 %7750, 0
  %7900 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i2038)
  %7901 = and i32 %7900, 2147483647
  %7902 = icmp ne i32 %7901, 2146435072
  %7903 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i2038)
  %7904 = icmp ne i32 %7903, 0
  %7905 = select i1 %7902, i1 true, i1 %7904
  %7906 = fsub double %7847, %7851
  %7907 = fadd double %7850, %7906
  %7908 = tail call double @llvm.fma.f64(double %z.2.i.i.i2038, double %7907, double %z.2.i.i.i2038)
  %tmp.0.i.i2043 = select i1 %7905, double %7908, double %z.2.i.i.i2038
  %7909 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i2043)
  %7910 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i2043)
  %7911 = xor i32 %7910, -2147483648
  %7912 = tail call double @llvm.nvvm.lohi.i2d(i32 %7909, i32 %7911)
  %t.0.i2044 = select i1 %spec.select.i2039, double %7912, double %tmp.0.i.i2043
  %t.1.i2045 = select i1 %7899, double 0xFFF8000000000000, double %t.0.i2044
  br label %7913

7913:                                             ; preds = %7898, %7893
  %t.2.i2046 = phi double [ %7897, %7893 ], [ %t.1.i2045, %7898 ]
  %7914 = fadd double %28, 1.500000e+00
  %7915 = tail call i32 @llvm.nvvm.d2i.hi(double %7914)
  %7916 = and i32 %7915, 2146435072
  %7917 = icmp eq i32 %7916, 2146435072
  br i1 %7917, label %7918, label %__nv_pow.exit2057

7918:                                             ; preds = %7913
  %7919 = fcmp ugt double %7753, 0x7FF0000000000000
  br i1 %7919, label %__nv_pow.exit2057, label %__nv_isinfd.exit5.i2047

__nv_isinfd.exit5.i2047:                          ; preds = %7918
  %7920 = and i32 %7751, 2147483647
  %7921 = icmp eq i32 %7920, 2146435072
  %7922 = icmp eq i32 %7842, 0
  %7923 = select i1 %7921, i1 %7922, i1 false
  br i1 %7923, label %7924, label %__nv_isinfd.exit.i2054

7924:                                             ; preds = %__nv_isinfd.exit5.i2047
  %7925 = fcmp ogt double %7753, 1.000000e+00
  %thi.2.i2048 = select i1 %7925, i32 2146435072, i32 0
  %7926 = icmp slt i32 %7751, 0
  %7927 = xor i32 %thi.2.i2048, 2146435072
  %thi.3.i2049 = select i1 %7926, i32 %7927, i32 %thi.2.i2048
  %7928 = fcmp oeq double %28, -1.000000e+00
  %thi.4.i = select i1 %7928, i32 1072693248, i32 %thi.3.i2049
  %7929 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i)
  br label %__nv_pow.exit2057

__nv_isinfd.exit.i2054:                           ; preds = %__nv_isinfd.exit5.i2047
  %7930 = tail call i32 @llvm.nvvm.d2i.lo(double %28)
  %7931 = and i32 %7750, 2147483647
  %7932 = icmp eq i32 %7931, 2146435072
  %7933 = icmp eq i32 %7930, 0
  %7934 = select i1 %7932, i1 %7933, i1 false
  %.inv.i2050 = icmp slt i32 %7751, 0
  %spec.select8.i2051 = select i1 %.inv.i2050, i32 0, i32 2146435072
  %7935 = or i32 %spec.select8.i2051, -2147483648
  %thi.6.i2052 = select i1 %spec.select.i2039, i32 %7935, i32 %spec.select8.i2051
  %7936 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i2052)
  %spec.select10.i2053 = select i1 %7934, double %7936, double %t.2.i2046
  br label %__nv_pow.exit2057

__nv_pow.exit2057:                                ; preds = %7913, %7918, %7924, %__nv_isinfd.exit.i2054
  %t.6.i2055 = phi double [ %t.2.i2046, %7913 ], [ %7929, %7924 ], [ %7914, %7918 ], [ %spec.select10.i2053, %__nv_isinfd.exit.i2054 ]
  %7937 = fcmp oeq double %28, 1.000000e+00
  %t.6.i2055.op = fmul reassoc ninf nsz double %t.6.i2055, 1.700000e+00
  %7938 = select i1 %7937, double 1.700000e+00, double %t.6.i2055.op
  %7939 = fmul reassoc ninf nsz double %28, %28
  %7940 = fmul reassoc ninf nsz double %7939, 4.905000e+00
  br label %after_if9

true_block2533:                                   ; preds = %false_block2528
  %7941 = fcmp reassoc ninf nsz ogt double %44, %.01383
  br i1 %7941, label %true_block2536, label %false_block2537

false_block2534:                                  ; preds = %false_block2528
  %7942 = trunc i64 %24 to i32
  %7943 = icmp eq i32 %18, 0
  %7944 = icmp slt i32 %7942, %23
  %spec.select2024 = select i1 %7943, i1 %7944, i1 false
  br i1 %spec.select2024, label %true_block2542, label %false_block2543

true_block2536:                                   ; preds = %true_block2533
  %7945 = fsub reassoc ninf nsz double %44, %.01384
  %7946 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %7945, double 1.000000e-03)
  %7947 = tail call double @llvm.sqrt.f64(double %7946)
  %7948 = fmul reassoc ninf nsz double %7947, 1.700000e+00
  %7949 = fsub reassoc ninf nsz double %.01383, %37
  %7950 = fmul reassoc ninf nsz double %7948, %7946
  %7951 = fmul reassoc ninf nsz double %7950, %7948
  %7952 = fmul reassoc ninf nsz double %7950, %56
  %7953 = fmul reassoc ninf nsz double %7949, %7949
  %7954 = fmul reassoc ninf nsz double %7953, 4.905000e+00
  br label %after_if9

false_block2537:                                  ; preds = %true_block2533
  %7955 = tail call i32 @llvm.nvvm.d2i.hi(double %.01168)
  %7956 = tail call i32 @llvm.nvvm.d2i.hi(double 1.500000e+00)
  %7957 = and i32 %7956, 2146435072
  %7958 = tail call double @llvm.fabs.f64(double %.01168)
  %7959 = tail call i32 @llvm.nvvm.d2i.hi(double %7958)
  %7960 = tail call i32 @llvm.nvvm.d2i.lo(double %7958)
  %7961 = lshr i32 %7959, 20
  %7962 = icmp ult i32 %7959, 1048576
  %7963 = fmul double %7958, 0x4350000000000000
  %7964 = tail call i32 @llvm.nvvm.d2i.hi(double %7963)
  %7965 = tail call i32 @llvm.nvvm.d2i.lo(double %7963)
  %7966 = lshr i32 %7964, 20
  %7967 = add nsw i32 %7966, -54
  %ilo.0.i.i.i = select i1 %7962, i32 %7965, i32 %7960
  %ihi.0.i.i.i = select i1 %7962, i32 %7964, i32 %7959
  %expo.0.i.i.i = select i1 %7962, i32 %7967, i32 %7961
  %7968 = and i32 %ihi.0.i.i.i, -2146435073
  %7969 = or i32 %7968, 1072693248
  %7970 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i, i32 %7969)
  %7971 = icmp ugt i32 %7969, 1073127582
  %7972 = tail call i32 @llvm.nvvm.d2i.lo(double %7970)
  %7973 = tail call i32 @llvm.nvvm.d2i.hi(double %7970)
  %7974 = add i32 %7973, -1048576
  %7975 = tail call double @llvm.nvvm.lohi.i2d(i32 %7972, i32 %7974)
  %m.0.i.i.i = select i1 %7971, double %7975, double %7970
  %expo.1.i.v.i.i = select i1 %7971, i32 -1022, i32 -1023
  %expo.1.i.i.i = add nsw i32 %expo.1.i.v.i.i, %expo.0.i.i.i
  %7976 = fadd double %m.0.i.i.i, -1.000000e+00
  %7977 = fadd double %m.0.i.i.i, 1.000000e+00
  %7978 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %7977)
  %7979 = fneg double %7977
  %7980 = tail call double @llvm.fma.f64(double %7979, double %7978, double 1.000000e+00)
  %7981 = tail call double @llvm.fma.f64(double %7980, double %7980, double %7980)
  %7982 = tail call double @llvm.fma.f64(double %7981, double %7978, double %7978)
  %7983 = fmul double %7976, %7982
  %7984 = fadd double %7983, %7983
  %7985 = fmul double %7984, %7984
  %7986 = tail call double @llvm.fma.f64(double %7985, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %7987 = tail call double @llvm.fma.f64(double %7986, double %7985, double 0x3EF3B20A75488A3F)
  %7988 = tail call double @llvm.fma.f64(double %7987, double %7985, double 0x3F1745CDE4FAECD5)
  %7989 = tail call double @llvm.fma.f64(double %7988, double %7985, double 0x3F3C71C7258A578B)
  %7990 = tail call double @llvm.fma.f64(double %7989, double %7985, double 0x3F6249249242B910)
  %7991 = tail call double @llvm.fma.f64(double %7990, double %7985, double 0x3F89999999999DFB)
  %7992 = fmul double %7985, %7991
  %7993 = fsub double %7976, %7984
  %7994 = fmul double %7993, 2.000000e+00
  %7995 = fneg double %7984
  %7996 = tail call double @llvm.fma.f64(double %7995, double %7976, double %7994)
  %7997 = fmul double %7982, %7996
  %7998 = fadd double %7992, 0x3FB5555555555555
  %7999 = fsub double 0x3FB5555555555555, %7998
  %8000 = fadd double %7992, %7999
  %8001 = fadd double %8000, 0.000000e+00
  %8002 = fadd double %8001, 0xBC46A4CB00B9E7B0
  %8003 = fadd double %7998, %8002
  %8004 = fsub double %7998, %8003
  %8005 = fadd double %8002, %8004
  %8006 = fneg double %7985
  %8007 = tail call double @llvm.fma.f64(double %7984, double %7984, double %8006)
  %8008 = tail call i32 @llvm.nvvm.d2i.lo(double %7997)
  %8009 = tail call i32 @llvm.nvvm.d2i.hi(double %7997)
  %8010 = add i32 %8009, 1048576
  %8011 = tail call double @llvm.nvvm.lohi.i2d(i32 %8008, i32 %8010)
  %8012 = tail call double @llvm.fma.f64(double %7984, double %8011, double %8007)
  %8013 = fmul double %7984, %7985
  %8014 = fneg double %8013
  %8015 = tail call double @llvm.fma.f64(double %7985, double %7984, double %8014)
  %8016 = tail call double @llvm.fma.f64(double %7985, double %7997, double %8015)
  %8017 = tail call double @llvm.fma.f64(double %8012, double %7984, double %8016)
  %8018 = fmul double %8013, %8003
  %8019 = fneg double %8018
  %8020 = tail call double @llvm.fma.f64(double %8003, double %8013, double %8019)
  %8021 = tail call double @llvm.fma.f64(double %8003, double %8017, double %8020)
  %8022 = tail call double @llvm.fma.f64(double %8005, double %8013, double %8021)
  %8023 = fadd double %8018, %8022
  %8024 = fsub double %8018, %8023
  %8025 = fadd double %8022, %8024
  %8026 = fadd double %7984, %8023
  %8027 = fsub double %7984, %8026
  %8028 = fadd double %8023, %8027
  %8029 = fadd double %8025, %8028
  %8030 = fadd double %7997, %8029
  %8031 = fadd double %8026, %8030
  %8032 = fsub double %8026, %8031
  %8033 = fadd double %8030, %8032
  %8034 = xor i32 %expo.1.i.i.i, -2147483648
  %8035 = tail call double @llvm.nvvm.lohi.i2d(i32 %8034, i32 1127219200)
  %8036 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %8037 = fsub double %8035, %8036
  %8038 = tail call double @llvm.fma.f64(double %8037, double 0x3FE62E42FEFA39EF, double %8031)
  %8039 = fneg double %8037
  %8040 = tail call double @llvm.fma.f64(double %8039, double 0x3FE62E42FEFA39EF, double %8038)
  %8041 = fsub double %8040, %8031
  %8042 = fsub double %8033, %8041
  %8043 = tail call double @llvm.fma.f64(double %8037, double 0x3C7ABC9E3B39803F, double %8042)
  %8044 = fadd double %8038, %8043
  %8045 = fsub double %8038, %8044
  %8046 = fadd double %8043, %8045
  %8047 = tail call i32 @llvm.nvvm.d2i.lo(double 1.500000e+00)
  %8048 = shl i32 %7956, 1
  %8049 = icmp ugt i32 %8048, -33554433
  %8050 = and i32 %7956, -15728641
  %spec.select.i.i = select i1 %8049, i32 %8050, i32 %7956
  %8051 = tail call double @llvm.nvvm.lohi.i2d(i32 %8047, i32 %spec.select.i.i)
  %8052 = fmul double %8051, %8044
  %8053 = fneg double %8052
  %8054 = tail call double @llvm.fma.f64(double %8044, double %8051, double %8053)
  %8055 = tail call double @llvm.fma.f64(double %8046, double %8051, double %8054)
  %8056 = fadd double %8052, %8055
  %8057 = tail call double @llvm.fma.f64(double %8056, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %8058 = tail call i32 @llvm.nvvm.d2i.lo(double %8057)
  %8059 = fadd double %8057, 0xC338000000000000
  %8060 = tail call double @llvm.fma.f64(double %8059, double 0xBFE62E42FEFA39EF, double %8056)
  %8061 = tail call double @llvm.fma.f64(double %8059, double 0xBC7ABC9E3B39803F, double %8060)
  %8062 = tail call double @llvm.fma.f64(double %8061, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %8063 = tail call double @llvm.fma.f64(double %8062, double %8061, double 0x3EC71DEE62401315)
  %8064 = tail call double @llvm.fma.f64(double %8063, double %8061, double 0x3EFA01997C89EB71)
  %8065 = tail call double @llvm.fma.f64(double %8064, double %8061, double 0x3F2A01A014761F65)
  %8066 = tail call double @llvm.fma.f64(double %8065, double %8061, double 0x3F56C16C1852B7AF)
  %8067 = tail call double @llvm.fma.f64(double %8066, double %8061, double 0x3F81111111122322)
  %8068 = tail call double @llvm.fma.f64(double %8067, double %8061, double 0x3FA55555555502A1)
  %8069 = tail call double @llvm.fma.f64(double %8068, double %8061, double 0x3FC5555555555511)
  %8070 = tail call double @llvm.fma.f64(double %8069, double %8061, double 0x3FE000000000000B)
  %8071 = tail call double @llvm.fma.f64(double %8070, double %8061, double 1.000000e+00)
  %8072 = tail call double @llvm.fma.f64(double %8071, double %8061, double 1.000000e+00)
  %8073 = tail call i32 @llvm.nvvm.d2i.lo(double %8072)
  %8074 = tail call i32 @llvm.nvvm.d2i.hi(double %8072)
  %8075 = shl i32 %8058, 20
  %8076 = add i32 %8074, %8075
  %8077 = tail call double @llvm.nvvm.lohi.i2d(i32 %8073, i32 %8076)
  %8078 = tail call i32 @llvm.nvvm.d2i.hi(double %8056)
  %8079 = bitcast i32 %8078 to float
  %8080 = tail call float @llvm.fabs.f32(float %8079)
  %8081 = fcmp uge float %8080, 0x4010C46560000000
  br i1 %8081, label %__internal_fast_icmp_abs_lt.exit.i.i.i, label %__internal_accurate_pow.exit.i

__internal_fast_icmp_abs_lt.exit.i.i.i:           ; preds = %false_block2537
  %8082 = fcmp olt double %8056, 0.000000e+00
  %8083 = fadd double %8056, 0x7FF0000000000000
  %z.0.i.i.i = select i1 %8082, double 0.000000e+00, double %8083
  %8084 = fcmp olt float %8080, 0x4010E90000000000
  br i1 %8084, label %8085, label %__internal_accurate_pow.exit.i

8085:                                             ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i
  %8086 = sdiv i32 %8058, 2
  %8087 = shl i32 %8086, 20
  %8088 = add i32 %8074, %8087
  %8089 = tail call double @llvm.nvvm.lohi.i2d(i32 %8073, i32 %8088)
  %8090 = sub nsw i32 %8058, %8086
  %8091 = shl i32 %8090, 20
  %8092 = add nsw i32 %8091, 1072693248
  %8093 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %8092)
  %8094 = fmul double %8093, %8089
  br label %__internal_accurate_pow.exit.i

__internal_accurate_pow.exit.i:                   ; preds = %8085, %__internal_fast_icmp_abs_lt.exit.i.i.i, %false_block2537
  %z.2.i.i.i = phi double [ %8077, %false_block2537 ], [ %8094, %8085 ], [ %z.0.i.i.i, %__internal_fast_icmp_abs_lt.exit.i.i.i ]
  %8095 = icmp eq i32 %7957, 1073741824
  %8096 = icmp slt i32 %7955, 0
  %spec.select.i = select i1 %8096, i1 %8095, i1 false
  %8097 = fcmp oeq double %.01168, 0.000000e+00
  br i1 %8097, label %8098, label %8103

8098:                                             ; preds = %__internal_accurate_pow.exit.i
  %8099 = icmp eq i32 %7957, 1073741824
  %spec.select1.i = select i1 %8099, i32 %7955, i32 0
  %8100 = icmp slt i32 %7956, 0
  %8101 = or i32 %spec.select1.i, 2146435072
  %thi.1.i = select i1 %8100, i32 %8101, i32 %spec.select1.i
  %8102 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i)
  br label %8118

8103:                                             ; preds = %__internal_accurate_pow.exit.i
  %8104 = icmp slt i32 %7955, 0
  %8105 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i)
  %8106 = and i32 %8105, 2147483647
  %8107 = icmp ne i32 %8106, 2146435072
  %8108 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i)
  %8109 = icmp ne i32 %8108, 0
  %8110 = select i1 %8107, i1 true, i1 %8109
  %8111 = fsub double %8052, %8056
  %8112 = fadd double %8055, %8111
  %8113 = tail call double @llvm.fma.f64(double %z.2.i.i.i, double %8112, double %z.2.i.i.i)
  %tmp.0.i.i = select i1 %8110, double %8113, double %z.2.i.i.i
  %8114 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i)
  %8115 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i)
  %8116 = xor i32 %8115, -2147483648
  %8117 = tail call double @llvm.nvvm.lohi.i2d(i32 %8114, i32 %8116)
  %t.0.i = select i1 %spec.select.i, double %8117, double %tmp.0.i.i
  %t.1.i = select i1 %8104, double 0xFFF8000000000000, double %t.0.i
  br label %8118

8118:                                             ; preds = %8103, %8098
  %t.2.i = phi double [ %8102, %8098 ], [ %t.1.i, %8103 ]
  %8119 = fadd double %.01168, 1.500000e+00
  %8120 = tail call i32 @llvm.nvvm.d2i.hi(double %8119)
  %8121 = and i32 %8120, 2146435072
  %8122 = icmp eq i32 %8121, 2146435072
  br i1 %8122, label %8123, label %__nv_pow.exit

8123:                                             ; preds = %8118
  %8124 = fcmp ugt double %7958, 0x7FF0000000000000
  br i1 %8124, label %__nv_pow.exit, label %__nv_isinfd.exit5.i

__nv_isinfd.exit5.i:                              ; preds = %8123
  %8125 = and i32 %7956, 2147483647
  %8126 = icmp eq i32 %8125, 2146435072
  %8127 = icmp eq i32 %8047, 0
  %8128 = select i1 %8126, i1 %8127, i1 false
  br i1 %8128, label %8129, label %__nv_isinfd.exit.i

8129:                                             ; preds = %__nv_isinfd.exit5.i
  %8130 = fcmp ogt double %7958, 1.000000e+00
  %thi.2.i = select i1 %8130, i32 2146435072, i32 0
  %8131 = icmp slt i32 %7956, 0
  %8132 = xor i32 %thi.2.i, 2146435072
  %thi.3.i = select i1 %8131, i32 %8132, i32 %thi.2.i
  %8133 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.3.i)
  br label %__nv_pow.exit

__nv_isinfd.exit.i:                               ; preds = %__nv_isinfd.exit5.i
  %8134 = tail call i32 @llvm.nvvm.d2i.lo(double %.01168)
  %8135 = and i32 %7955, 2147483647
  %8136 = icmp eq i32 %8135, 2146435072
  %8137 = icmp eq i32 %8134, 0
  %8138 = select i1 %8136, i1 %8137, i1 false
  %.inv.i = icmp slt i32 %7956, 0
  %spec.select8.i = select i1 %.inv.i, i32 0, i32 2146435072
  %8139 = or i32 %spec.select8.i, -2147483648
  %thi.6.i = select i1 %spec.select.i, i32 %8139, i32 %spec.select8.i
  %8140 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i)
  %spec.select10.i = select i1 %8138, double %8140, double %t.2.i
  br label %__nv_pow.exit

__nv_pow.exit:                                    ; preds = %8118, %8123, %8129, %__nv_isinfd.exit.i
  %t.6.i = phi double [ %t.2.i, %8118 ], [ %8133, %8129 ], [ %8119, %8123 ], [ %spec.select10.i, %__nv_isinfd.exit.i ]
  %8141 = fcmp oeq double %.01168, 1.000000e+00
  %t.6.i.op = fmul reassoc ninf nsz double %t.6.i, -1.700000e+00
  %8142 = select i1 %8141, double -1.700000e+00, double %t.6.i.op
  %8143 = fmul reassoc ninf nsz double %53, %53
  %8144 = fmul reassoc ninf nsz double %8143, %28
  %8145 = fmul reassoc ninf nsz double %28, %28
  %8146 = fmul reassoc ninf nsz double %8145, 4.905000e+00
  br label %after_if9

true_block2542:                                   ; preds = %false_block2534
  %8147 = fsub reassoc ninf nsz double %.01383, %37
  %8148 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %8147, double 1.000000e-03)
  %8149 = fmul reassoc ninf nsz double %.01382, %47
  %8150 = fmul reassoc ninf nsz double %.01381, %50
  %8151 = fadd reassoc ninf nsz double %8150, %8149
  %8152 = fdiv reassoc ninf nsz double %.01168, %8148
  %8153 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %8152, double 1.500000e+00)
  %8154 = fmul reassoc ninf nsz double %8153, %8151
  %8155 = fcmp reassoc ninf nsz ugt double %8148, 1.000000e-02
  %8156 = fcmp reassoc ninf nsz olt double %8151, 0.000000e+00
  %8157 = select reassoc ninf nsz i1 %8156, double -1.000000e-03, double 1.000000e-03
  %.0741 = select i1 %8155, double %8154, double %8157
  %8158 = fmul reassoc ninf nsz double %.01381, %47
  %8159 = fmul reassoc ninf nsz double %.01382, %50
  %8160 = fsub reassoc ninf nsz double %8158, %8159
  %8161 = fmul reassoc ninf nsz double %8148, 9.810000e+00
  %8162 = tail call double @llvm.sqrt.f64(double %8161)
  %neg2570 = fneg reassoc ninf nsz double %8162
  %factor10923 = fmul reassoc ninf nsz double %8162, -2.000000e+00
  %8163 = fadd reassoc ninf nsz double %factor10923, %.0741
  %8164 = fadd reassoc ninf nsz double %8163, %59
  %8165 = fmul reassoc ninf nsz double %8164, 5.000000e-01
  %8166 = fsub reassoc ninf nsz double %59, %8163
  %8167 = fmul reassoc ninf nsz double %8166, 2.500000e-01
  %8168 = tail call double @llvm.fabs.f64(double %8167)
  %8169 = fcmp reassoc ninf nsz olt double %8168, %8165
  br i1 %8169, label %after_if2553, label %false_block2552

false_block2543:                                  ; preds = %false_block2534
  %neg2634 = fneg reassoc ninf nsz double %50
  %8170 = sext i32 %23 to i64
  %8171 = shl nsw i64 %8170, 3
  %8172 = getelementptr inbounds i8, i8* %getch.i2550, i64 %8171
  %8173 = bitcast i8* %8172 to double*
  %8174 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %8173, i32 64)
  %8175 = getelementptr inbounds i8, i8* %getch.i2549, i64 %8171
  %8176 = bitcast i8* %8175 to double*
  %8177 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %8176, i32 64)
  %8178 = getelementptr inbounds i8, i8* %getch.i2548, i64 %8171
  %8179 = bitcast i8* %8178 to double*
  %8180 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %8179, i32 64)
  %8181 = fmul reassoc ninf nsz double %8180, %neg2634
  %8182 = fmul reassoc ninf nsz double %8177, %47
  %8183 = fsub reassoc ninf nsz double %8181, %8182
  %8184 = fmul reassoc ninf nsz double %8177, %50
  %8185 = fmul reassoc ninf nsz double %8180, %47
  %8186 = fsub reassoc ninf nsz double %8184, %8185
  %8187 = fmul reassoc ninf nsz double %8174, 9.810000e+00
  %8188 = tail call double @llvm.sqrt.f64(double %8187)
  %factor10877 = fmul reassoc ninf nsz double %8188, 2.000000e+00
  %8189 = fadd reassoc ninf nsz double %8183, %factor10877
  %8190 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %28, double 1.000000e-03)
  %8191 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %37, double %40)
  %8192 = fsub reassoc ninf nsz double %8191, %.01384
  %8193 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %8192, double 1.000000e-03)
  %8194 = fmul reassoc ninf nsz double %34, %neg2634
  %8195 = fsub reassoc ninf nsz double %8194, %51
  %8196 = fdiv reassoc ninf nsz double %8190, %8193
  %8197 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %8196, double 1.500000e+00)
  %8198 = fmul reassoc ninf nsz double %8197, %8195
  %8199 = fcmp reassoc ninf nsz ole double %8190, 1.000000e-02
  %8200 = fcmp reassoc ninf nsz ole double %8193, 1.000000e-02
  %.0727 = select i1 %8199, i1 true, i1 %8200
  %8201 = fcmp reassoc ninf nsz olt double %8195, 0.000000e+00
  %8202 = select reassoc ninf nsz i1 %8201, double -1.000000e-03, double 1.000000e-03
  %.0728 = select i1 %.0727, double %8202, double %8198
  %8203 = fsub reassoc ninf nsz double %55, %54
  %8204 = fmul reassoc ninf nsz double %8193, 9.810000e+00
  %8205 = tail call double @llvm.sqrt.f64(double %8204)
  %neg2660 = fneg reassoc ninf nsz double %8205
  %factor10879 = fmul reassoc ninf nsz double %8205, -2.000000e+00
  %8206 = fadd reassoc ninf nsz double %factor10879, %.0728
  %8207 = fadd reassoc ninf nsz double %8189, %8206
  %8208 = fmul reassoc ninf nsz double %8207, 5.000000e-01
  %8209 = fsub reassoc ninf nsz double %8189, %8206
  %8210 = fmul reassoc ninf nsz double %8209, 2.500000e-01
  %8211 = tail call double @llvm.fabs.f64(double %8210)
  %8212 = fcmp reassoc ninf nsz olt double %8211, %8208
  br i1 %8212, label %after_if2643, label %false_block2642

false_block2552:                                  ; preds = %true_block2542
  %8213 = fcmp reassoc ninf nsz oge double %8165, 0.000000e+00
  %8214 = fcmp reassoc ninf nsz olt double %8165, %8168
  %.0734 = select i1 %8213, i1 %8214, i1 false
  %neg2560 = fneg reassoc ninf nsz double %8168
  %8215 = fcmp reassoc ninf nsz oge double %8165, %neg2560
  %8216 = fcmp reassoc ninf nsz olt double %8165, 0.000000e+00
  %not..0734 = xor i1 %.0734, true
  %8217 = select i1 %not..0734, i1 %8215, i1 false
  %spec.select10863 = select i1 %8217, i1 %8216, i1 false
  br label %after_if2553

after_if2553:                                     ; preds = %false_block2552, %true_block2542
  %8218 = phi i1 [ false, %true_block2542 ], [ %.0734, %false_block2552 ]
  %8219 = phi i1 [ false, %true_block2542 ], [ %spec.select10863, %false_block2552 ]
  %8220 = fcmp reassoc ninf nsz olt double %53, %58
  %8221 = fcmp reassoc ninf nsz oge double %.0741, %neg2570
  %.0731 = select i1 %8220, i1 %8221, i1 false
  %8222 = fcmp reassoc ninf nsz oge double %53, %58
  %.0730 = select i1 %8222, i1 %8221, i1 false
  %8223 = fcmp reassoc ninf nsz olt double %.0741, %neg2570
  %not..0730 = xor i1 %.0730, true
  %8224 = select i1 %not..0730, i1 %8220, i1 false
  %spec.select10865 = select i1 %8224, i1 %8223, i1 false
  br i1 %.0731, label %after_if2573, label %false_block2572

false_block2572:                                  ; preds = %after_if2553
  br label %after_if2573

after_if2573:                                     ; preds = %false_block2572, %after_if2553
  %8225 = phi i1 [ false, %after_if2553 ], [ %.0730, %false_block2572 ]
  %8226 = phi i1 [ false, %after_if2553 ], [ %spec.select10865, %false_block2572 ]
  br i1 %.0731, label %true_block2588, label %false_block2589

true_block2588:                                   ; preds = %after_if2573
  %8227 = fcmp olt double %8168, %8165
  br i1 %8227, label %true_block2591, label %false_block2592

false_block2589:                                  ; preds = %after_if2573
  br i1 %8225, label %true_block2600, label %false_block2601

after_if2590:                                     ; preds = %true_block2630, %false_block2631, %true_block2627, %true_block2624, %true_block2621, %false_block2622, %true_block2618, %true_block2615, %true_block2609, %false_block2610, %true_block2606, %true_block2603, %true_block2597, %false_block2598, %true_block2594, %true_block2591
  %.0739 = phi double [ %8237, %true_block2591 ], [ %8245, %true_block2594 ], [ %8253, %true_block2597 ], [ %8261, %false_block2598 ], [ %8267, %true_block2603 ], [ %8291, %true_block2606 ], [ %8307, %true_block2609 ], [ %8319, %false_block2610 ], [ %8343, %true_block2615 ], [ %8369, %true_block2618 ], [ %8394, %true_block2621 ], [ %8401, %false_block2622 ], [ %8418, %true_block2624 ], [ %8451, %true_block2627 ], [ %8489, %true_block2630 ], [ %8503, %false_block2631 ]
  %.0738 = phi double [ %8238, %true_block2591 ], [ %8246, %true_block2594 ], [ %8254, %true_block2597 ], [ %8262, %false_block2598 ], [ %8268, %true_block2603 ], [ %8292, %true_block2606 ], [ %8308, %true_block2609 ], [ %8320, %false_block2610 ], [ %8346, %true_block2615 ], [ %8372, %true_block2618 ], [ %8397, %true_block2621 ], [ %8402, %false_block2622 ], [ %8421, %true_block2624 ], [ %8454, %true_block2627 ], [ %8493, %true_block2630 ], [ %8504, %false_block2631 ]
  %.0737 = phi double [ %8239, %true_block2591 ], [ %8247, %true_block2594 ], [ %8255, %true_block2597 ], [ %8263, %false_block2598 ], [ %8269, %true_block2603 ], [ %8293, %true_block2606 ], [ %8309, %true_block2609 ], [ %8321, %false_block2610 ], [ %8347, %true_block2615 ], [ %8373, %true_block2618 ], [ %8398, %true_block2621 ], [ %8403, %false_block2622 ], [ %8422, %true_block2624 ], [ %8455, %true_block2627 ], [ %8494, %true_block2630 ], [ %8505, %false_block2631 ]
  %.0736 = phi double [ %8241, %true_block2591 ], [ %8249, %true_block2594 ], [ %8257, %true_block2597 ], [ %8265, %false_block2598 ], [ %8271, %true_block2603 ], [ %8294, %true_block2606 ], [ %8310, %true_block2609 ], [ %8322, %false_block2610 ], [ %8349, %true_block2615 ], [ %8375, %true_block2618 ], [ %8400, %true_block2621 ], [ %8405, %false_block2622 ], [ %8423, %true_block2624 ], [ %8457, %true_block2627 ], [ %8497, %true_block2630 ], [ %8506, %false_block2631 ]
  %8228 = fsub reassoc ninf nsz double 1.000000e+00, %8153
  %8229 = fmul reassoc ninf nsz double %.01168, 5.000000e-01
  %8230 = fmul reassoc ninf nsz double %8151, %8151
  %8231 = fmul reassoc ninf nsz double %8230, %8229
  %8232 = fmul reassoc ninf nsz double %8231, %8228
  %8233 = fadd reassoc ninf nsz double %.0738, %8232
  br label %after_if9

true_block2591:                                   ; preds = %true_block2588
  %8234 = fmul reassoc ninf nsz double %59, 0x3FD5555555555555
  %8235 = fmul reassoc ninf nsz double %8234, %8234
  %8236 = fmul reassoc ninf nsz double %8235, 0x3FBA1887B2C1A188
  %8237 = fmul reassoc ninf nsz double %8236, %8234
  %8238 = fmul reassoc ninf nsz double %8237, %8234
  %8239 = fmul reassoc ninf nsz double %8237, %56
  %8240 = fmul reassoc ninf nsz double %8235, 5.000000e-01
  %8241 = fmul reassoc ninf nsz double %8240, %8236
  br label %after_if2590

false_block2592:                                  ; preds = %true_block2588
  br i1 %8218, label %true_block2594, label %false_block2595

true_block2594:                                   ; preds = %false_block2592
  %8242 = fsub reassoc ninf nsz double %59, %8165
  %8243 = fmul reassoc ninf nsz double %8242, %8242
  %8244 = fmul reassoc ninf nsz double %8243, 0x3F9A1887B2C1A188
  %8245 = fmul reassoc ninf nsz double %8244, %8165
  %8246 = fmul reassoc ninf nsz double %8245, %8165
  %8247 = fmul reassoc ninf nsz double %8245, %56
  %8248 = fmul reassoc ninf nsz double %8243, 1.250000e-01
  %8249 = fmul reassoc ninf nsz double %8248, %8244
  br label %after_if2590

false_block2595:                                  ; preds = %false_block2592
  br i1 %8219, label %true_block2597, label %false_block2598

true_block2597:                                   ; preds = %false_block2595
  %8250 = fsub reassoc ninf nsz double %8163, %8165
  %8251 = fmul reassoc ninf nsz double %8250, %8250
  %8252 = fmul reassoc ninf nsz double %8251, 0x3F9A1887B2C1A188
  %8253 = fmul reassoc ninf nsz double %8252, %8165
  %8254 = fmul reassoc ninf nsz double %8253, %8165
  %8255 = fmul reassoc ninf nsz double %8253, %8160
  %8256 = fmul reassoc ninf nsz double %8251, 1.250000e-01
  %8257 = fmul reassoc ninf nsz double %8256, %8252
  br label %after_if2590

false_block2598:                                  ; preds = %false_block2595
  %8258 = fmul reassoc ninf nsz double %8163, 0x3FD5555555555555
  %8259 = fmul reassoc ninf nsz double %8258, %8258
  %8260 = fmul reassoc ninf nsz double %8259, 0x3FBA1887B2C1A188
  %8261 = fmul reassoc ninf nsz double %8260, %8258
  %8262 = fmul reassoc ninf nsz double %8261, %8258
  %8263 = fmul reassoc ninf nsz double %8261, %8160
  %8264 = fmul reassoc ninf nsz double %8259, 5.000000e-01
  %8265 = fmul reassoc ninf nsz double %8264, %8260
  br label %after_if2590

true_block2600:                                   ; preds = %false_block2589
  %8266 = fcmp olt double %8168, %8165
  %8267 = fmul reassoc ninf nsz double %53, %28
  %8268 = fmul reassoc ninf nsz double %8267, %53
  br i1 %8266, label %true_block2603, label %false_block2604

false_block2601:                                  ; preds = %false_block2589
  br i1 %8226, label %true_block2612, label %false_block2613

true_block2603:                                   ; preds = %true_block2600
  %8269 = fmul reassoc ninf nsz double %8267, %56
  %8270 = fmul reassoc ninf nsz double %28, %28
  %8271 = fmul reassoc ninf nsz double %8270, 4.905000e+00
  br label %after_if2590

false_block2604:                                  ; preds = %true_block2600
  %8272 = fmul reassoc ninf nsz double %28, %28
  %8273 = fmul reassoc ninf nsz double %8272, 4.905000e+00
  %8274 = fmul reassoc ninf nsz double %59, 0x3FD5555555555555
  %8275 = fmul reassoc ninf nsz double %8274, %8274
  %8276 = fmul reassoc ninf nsz double %8275, 0x3FBA1887B2C1A188
  %8277 = fmul reassoc ninf nsz double %8276, %8274
  %8278 = fsub reassoc ninf nsz double %8267, %8277
  %8279 = fmul reassoc ninf nsz double %8277, %8274
  %8280 = fsub reassoc ninf nsz double %8268, %8279
  br i1 %8218, label %true_block2606, label %false_block2607

true_block2606:                                   ; preds = %false_block2604
  %8281 = fmul reassoc ninf nsz double %8275, -5.000000e-01
  %8282 = fmul reassoc ninf nsz double %8281, %8276
  %8283 = fadd reassoc ninf nsz double %8282, %8273
  %8284 = fsub reassoc ninf nsz double %59, %8165
  %8285 = fmul reassoc ninf nsz double %8284, %8284
  %8286 = fmul reassoc ninf nsz double %8285, 0x3F9A1887B2C1A188
  %8287 = fmul reassoc ninf nsz double %8286, %8165
  %8288 = fmul reassoc ninf nsz double %8287, %8165
  %8289 = fmul reassoc ninf nsz double %8285, 1.250000e-01
  %8290 = fmul reassoc ninf nsz double %8289, %8286
  %8291 = fadd reassoc ninf nsz double %8287, %8278
  %8292 = fadd reassoc ninf nsz double %8280, %8288
  %8293 = fmul reassoc ninf nsz double %8291, %56
  %8294 = fadd reassoc ninf nsz double %8283, %8290
  br label %after_if2590

false_block2607:                                  ; preds = %false_block2604
  %8295 = fmul reassoc ninf nsz double %8278, %56
  %8296 = fmul reassoc ninf nsz double %8275, 5.000000e-01
  %8297 = fmul reassoc ninf nsz double %8296, %8276
  %8298 = fsub reassoc ninf nsz double %8273, %8297
  br i1 %8219, label %true_block2609, label %false_block2610

true_block2609:                                   ; preds = %false_block2607
  %8299 = fsub reassoc ninf nsz double %8163, %8165
  %8300 = fmul reassoc ninf nsz double %8299, %8299
  %8301 = fmul reassoc ninf nsz double %8300, 0x3F9A1887B2C1A188
  %8302 = fmul reassoc ninf nsz double %8301, %8165
  %8303 = fmul reassoc ninf nsz double %8302, %8165
  %8304 = fmul reassoc ninf nsz double %8302, %8160
  %8305 = fmul reassoc ninf nsz double %8300, 1.250000e-01
  %8306 = fmul reassoc ninf nsz double %8305, %8301
  %8307 = fadd reassoc ninf nsz double %8302, %8278
  %8308 = fadd reassoc ninf nsz double %8303, %8280
  %8309 = fadd reassoc ninf nsz double %8304, %8295
  %8310 = fadd reassoc ninf nsz double %8306, %8298
  br label %after_if2590

false_block2610:                                  ; preds = %false_block2607
  %8311 = fmul reassoc ninf nsz double %8163, 0x3FD5555555555555
  %8312 = fmul reassoc ninf nsz double %8311, %8311
  %8313 = fmul reassoc ninf nsz double %8312, 0x3FBA1887B2C1A188
  %8314 = fmul reassoc ninf nsz double %8313, %8311
  %8315 = fmul reassoc ninf nsz double %8314, %8311
  %8316 = fmul reassoc ninf nsz double %8314, %8160
  %8317 = fmul reassoc ninf nsz double %8312, 5.000000e-01
  %8318 = fmul reassoc ninf nsz double %8317, %8313
  %8319 = fadd reassoc ninf nsz double %8314, %8278
  %8320 = fadd reassoc ninf nsz double %8315, %8280
  %8321 = fadd reassoc ninf nsz double %8316, %8295
  %8322 = fadd reassoc ninf nsz double %8318, %8298
  br label %after_if2590

true_block2612:                                   ; preds = %false_block2601
  %8323 = fcmp olt double %8168, %8165
  br i1 %8323, label %true_block2615, label %false_block2616

false_block2613:                                  ; preds = %false_block2601
  %8324 = fcmp olt double %8168, %8165
  %8325 = fmul reassoc ninf nsz double %53, %28
  %8326 = fmul reassoc ninf nsz double %8325, %53
  br i1 %8324, label %true_block2624, label %false_block2625

true_block2615:                                   ; preds = %true_block2612
  %8327 = fmul reassoc ninf nsz double %59, 0x3FD5555555555555
  %8328 = fmul reassoc ninf nsz double %8327, %8327
  %8329 = fmul reassoc ninf nsz double %8328, 0x3FBA1887B2C1A188
  %8330 = fmul reassoc ninf nsz double %8329, %8327
  %8331 = fmul reassoc ninf nsz double %8330, %8327
  %8332 = fmul reassoc ninf nsz double %8330, %56
  %8333 = fmul reassoc ninf nsz double %8329, %8328
  %8334 = fmul reassoc ninf nsz double %8163, 0x3FD5555555555555
  %8335 = fmul reassoc ninf nsz double %8334, %8334
  %8336 = fmul reassoc ninf nsz double %8335, 0x3FBA1887B2C1A188
  %8337 = fmul reassoc ninf nsz double %8336, %8334
  %8338 = fmul reassoc ninf nsz double %.0741, %8148
  %8339 = fmul reassoc ninf nsz double %8338, %.0741
  %8340 = fmul reassoc ninf nsz double %8148, %8148
  %8341 = fmul reassoc ninf nsz double %8340, 4.905000e+00
  %8342 = fadd reassoc ninf nsz double %8338, %8330
  %8343 = fsub reassoc ninf nsz double %8342, %8337
  %8344 = fadd reassoc ninf nsz double %8339, %8331
  %8345 = fmul reassoc ninf nsz double %8337, %8334
  %8346 = fsub reassoc ninf nsz double %8344, %8345
  %reass.add10965 = fsub reassoc ninf nsz double %8338, %8337
  %reass.mul10966 = fmul reassoc ninf nsz double %reass.add10965, %8160
  %8347 = fadd reassoc ninf nsz double %reass.mul10966, %8332
  %8348 = fmul reassoc ninf nsz double %8336, %8335
  %reass.add10963 = fsub reassoc ninf nsz double %8333, %8348
  %reass.mul10964 = fmul reassoc ninf nsz double %reass.add10963, 5.000000e-01
  %8349 = fadd reassoc ninf nsz double %reass.mul10964, %8341
  br label %after_if2590

false_block2616:                                  ; preds = %true_block2612
  br i1 %8218, label %true_block2618, label %false_block2619

true_block2618:                                   ; preds = %false_block2616
  %8350 = fsub reassoc ninf nsz double %59, %8165
  %8351 = fmul reassoc ninf nsz double %8350, %8350
  %8352 = fmul reassoc ninf nsz double %8351, 0x3F9A1887B2C1A188
  %8353 = fmul reassoc ninf nsz double %8352, %8165
  %8354 = fmul reassoc ninf nsz double %8353, %8165
  %8355 = fmul reassoc ninf nsz double %8353, %56
  %8356 = fmul reassoc ninf nsz double %8351, 1.250000e-01
  %8357 = fmul reassoc ninf nsz double %8356, %8352
  %8358 = fmul reassoc ninf nsz double %8163, 0x3FD5555555555555
  %8359 = fmul reassoc ninf nsz double %8358, %8358
  %8360 = fmul reassoc ninf nsz double %8359, 0x3FBA1887B2C1A188
  %8361 = fmul reassoc ninf nsz double %8360, %8358
  %8362 = fmul reassoc ninf nsz double %8359, -5.000000e-01
  %8363 = fmul reassoc ninf nsz double %8362, %8360
  %8364 = fmul reassoc ninf nsz double %.0741, %8148
  %8365 = fmul reassoc ninf nsz double %8364, %.0741
  %8366 = fmul reassoc ninf nsz double %8148, %8148
  %8367 = fmul reassoc ninf nsz double %8366, 4.905000e+00
  %8368 = fsub reassoc ninf nsz double %8364, %8361
  %8369 = fadd reassoc ninf nsz double %8368, %8353
  %8370 = fmul reassoc ninf nsz double %8361, %8358
  %8371 = fsub reassoc ninf nsz double %8365, %8370
  %8372 = fadd reassoc ninf nsz double %8371, %8354
  %reass.mul10958 = fmul reassoc ninf nsz double %8368, %8160
  %8373 = fadd reassoc ninf nsz double %reass.mul10958, %8355
  %8374 = fadd reassoc ninf nsz double %8363, %8367
  %8375 = fadd reassoc ninf nsz double %8374, %8357
  br label %after_if2590

false_block2619:                                  ; preds = %false_block2616
  br i1 %8219, label %true_block2621, label %false_block2622

true_block2621:                                   ; preds = %false_block2619
  %8376 = fsub reassoc ninf nsz double %8163, %8165
  %8377 = fmul reassoc ninf nsz double %8376, %8376
  %8378 = fmul reassoc ninf nsz double %8377, 0x3F9A1887B2C1A188
  %8379 = fmul reassoc ninf nsz double %8378, %8165
  %8380 = fmul reassoc ninf nsz double %8379, %8165
  %8381 = fmul reassoc ninf nsz double %8377, 1.250000e-01
  %8382 = fmul reassoc ninf nsz double %8381, %8378
  %8383 = fmul reassoc ninf nsz double %8376, 0x3FD5555555555555
  %8384 = fmul reassoc ninf nsz double %8383, %8383
  %8385 = fmul reassoc ninf nsz double %8384, 0x3FBA1887B2C1A188
  %8386 = fmul reassoc ninf nsz double %8385, %8383
  %8387 = fsub reassoc ninf nsz double %8379, %8386
  %8388 = fmul reassoc ninf nsz double %8384, -5.000000e-01
  %8389 = fmul reassoc ninf nsz double %8388, %8385
  %8390 = fmul reassoc ninf nsz double %.0741, %8148
  %8391 = fmul reassoc ninf nsz double %8390, %.0741
  %8392 = fmul reassoc ninf nsz double %8148, %8148
  %8393 = fmul reassoc ninf nsz double %8392, 4.905000e+00
  %8394 = fadd reassoc ninf nsz double %8387, %8390
  %8395 = fadd reassoc ninf nsz double %8380, %8391
  %8396 = fmul reassoc ninf nsz double %8386, %8383
  %8397 = fsub reassoc ninf nsz double %8395, %8396
  %8398 = fmul reassoc ninf nsz double %8394, %8160
  %8399 = fadd reassoc ninf nsz double %8382, %8393
  %8400 = fadd reassoc ninf nsz double %8399, %8389
  br label %after_if2590

false_block2622:                                  ; preds = %false_block2619
  %8401 = fmul reassoc ninf nsz double %.0741, %8148
  %8402 = fmul reassoc ninf nsz double %8401, %.0741
  %8403 = fmul reassoc ninf nsz double %8401, %8160
  %8404 = fmul reassoc ninf nsz double %8148, %8148
  %8405 = fmul reassoc ninf nsz double %8404, 4.905000e+00
  br label %after_if2590

true_block2624:                                   ; preds = %false_block2613
  %8406 = fmul reassoc ninf nsz double %8325, %56
  %8407 = fmul reassoc ninf nsz double %28, %28
  %8408 = fmul reassoc ninf nsz double %8163, 0x3FD5555555555555
  %8409 = fmul reassoc ninf nsz double %8408, %8408
  %8410 = fmul reassoc ninf nsz double %8409, 0x3FBA1887B2C1A188
  %8411 = fmul reassoc ninf nsz double %8410, %8408
  %8412 = fmul reassoc ninf nsz double %8409, 5.000000e-01
  %8413 = fmul reassoc ninf nsz double %8412, %8410
  %8414 = fmul reassoc ninf nsz double %.0741, %8148
  %8415 = fmul reassoc ninf nsz double %8414, %.0741
  %8416 = fmul reassoc ninf nsz double %8148, %8148
  %8417 = fadd reassoc ninf nsz double %8414, %8325
  %8418 = fsub reassoc ninf nsz double %8417, %8411
  %8419 = fadd reassoc ninf nsz double %8415, %8326
  %8420 = fmul reassoc ninf nsz double %8411, %8408
  %8421 = fsub reassoc ninf nsz double %8419, %8420
  %reass.add10951 = fsub reassoc ninf nsz double %8414, %8411
  %reass.mul10952 = fmul reassoc ninf nsz double %reass.add10951, %8160
  %8422 = fadd reassoc ninf nsz double %reass.mul10952, %8406
  %reass.add10949 = fadd reassoc ninf nsz double %8416, %8407
  %reass.mul10950 = fmul reassoc ninf nsz double %reass.add10949, 4.905000e+00
  %8423 = fsub reassoc ninf nsz double %reass.mul10950, %8413
  br label %after_if2590

false_block2625:                                  ; preds = %false_block2613
  %8424 = fmul reassoc ninf nsz double %28, %28
  br i1 %8218, label %true_block2627, label %false_block2628

true_block2627:                                   ; preds = %false_block2625
  %8425 = fmul reassoc ninf nsz double %59, 0x3FD5555555555555
  %8426 = fmul reassoc ninf nsz double %8425, %8425
  %8427 = fmul reassoc ninf nsz double %8426, 0x3FBA1887B2C1A188
  %8428 = fmul reassoc ninf nsz double %8427, %8425
  %8429 = fsub reassoc ninf nsz double %8325, %8428
  %8430 = fmul reassoc ninf nsz double %8427, %8426
  %8431 = fsub reassoc ninf nsz double %59, %8165
  %8432 = fmul reassoc ninf nsz double %8431, %8431
  %8433 = fmul reassoc ninf nsz double %8432, 0x3F9A1887B2C1A188
  %8434 = fmul reassoc ninf nsz double %8433, %8165
  %8435 = fmul reassoc ninf nsz double %8434, %8165
  %8436 = fmul reassoc ninf nsz double %8432, 1.250000e-01
  %8437 = fmul reassoc ninf nsz double %8436, %8433
  %8438 = fadd reassoc ninf nsz double %8429, %8434
  %8439 = fmul reassoc ninf nsz double %8438, %56
  %8440 = fmul reassoc ninf nsz double %8163, 0x3FD5555555555555
  %8441 = fmul reassoc ninf nsz double %8440, %8440
  %8442 = fmul reassoc ninf nsz double %8441, 0x3FBA1887B2C1A188
  %8443 = fmul reassoc ninf nsz double %8442, %8440
  %.neg10934 = fmul reassoc ninf nsz double %8428, %8425
  %.neg10935 = fmul reassoc ninf nsz double %8443, %8440
  %8444 = fmul reassoc ninf nsz double %8442, %8441
  %8445 = fmul reassoc ninf nsz double %.0741, %8148
  %8446 = fmul reassoc ninf nsz double %8445, %.0741
  %8447 = fmul reassoc ninf nsz double %8148, %8148
  %8448 = fadd reassoc ninf nsz double %8325, %8445
  %8449 = fadd reassoc ninf nsz double %8428, %8443
  %8450 = fsub reassoc ninf nsz double %8448, %8449
  %8451 = fadd reassoc ninf nsz double %8450, %8434
  %reass.add10942 = fadd reassoc ninf nsz double %.neg10935, %.neg10934
  %8452 = fadd reassoc ninf nsz double %8446, %8326
  %8453 = fadd reassoc ninf nsz double %8452, %8435
  %8454 = fsub reassoc ninf nsz double %8453, %reass.add10942
  %reass.add10944 = fsub reassoc ninf nsz double %8445, %8443
  %reass.mul10945 = fmul reassoc ninf nsz double %reass.add10944, %8160
  %8455 = fadd reassoc ninf nsz double %reass.mul10945, %8439
  %reass.add10938 = fadd reassoc ninf nsz double %8444, %8430
  %reass.mul10939 = fmul reassoc ninf nsz double %reass.add10938, -5.000000e-01
  %reass.add10940 = fadd reassoc ninf nsz double %8447, %8424
  %reass.mul10941 = fmul reassoc ninf nsz double %reass.add10940, 4.905000e+00
  %8456 = fadd reassoc ninf nsz double %8437, %reass.mul10941
  %8457 = fadd reassoc ninf nsz double %8456, %reass.mul10939
  br label %after_if2590

false_block2628:                                  ; preds = %false_block2625
  %8458 = fmul reassoc ninf nsz double %8424, 4.905000e+00
  %8459 = fmul reassoc ninf nsz double %59, 0x3FD5555555555555
  %8460 = fmul reassoc ninf nsz double %8459, %8459
  %8461 = fmul reassoc ninf nsz double %8460, 0x3FBA1887B2C1A188
  %8462 = fmul reassoc ninf nsz double %8461, %8459
  %8463 = fsub reassoc ninf nsz double %8325, %8462
  %8464 = fmul reassoc ninf nsz double %8462, %8459
  %8465 = fsub reassoc ninf nsz double %8326, %8464
  %8466 = fmul reassoc ninf nsz double %8463, %56
  %8467 = fmul reassoc ninf nsz double %8460, 5.000000e-01
  %8468 = fmul reassoc ninf nsz double %8467, %8461
  %8469 = fsub reassoc ninf nsz double %8458, %8468
  br i1 %8219, label %true_block2630, label %false_block2631

true_block2630:                                   ; preds = %false_block2628
  %8470 = fsub reassoc ninf nsz double %8163, %8165
  %8471 = fmul reassoc ninf nsz double %8470, %8470
  %8472 = fmul reassoc ninf nsz double %8471, 0x3F9A1887B2C1A188
  %8473 = fmul reassoc ninf nsz double %8472, %8165
  %8474 = fmul reassoc ninf nsz double %8473, %8165
  %8475 = fmul reassoc ninf nsz double %8471, 1.250000e-01
  %8476 = fmul reassoc ninf nsz double %8475, %8472
  %8477 = fmul reassoc ninf nsz double %8470, 0x3FD5555555555555
  %8478 = fmul reassoc ninf nsz double %8477, %8477
  %8479 = fmul reassoc ninf nsz double %8478, 0x3FBA1887B2C1A188
  %8480 = fmul reassoc ninf nsz double %8479, %8477
  %8481 = fmul reassoc ninf nsz double %8478, -5.000000e-01
  %8482 = fmul reassoc ninf nsz double %8481, %8479
  %8483 = fmul reassoc ninf nsz double %.0741, %8148
  %8484 = fmul reassoc ninf nsz double %8483, %.0741
  %8485 = fmul reassoc ninf nsz double %8148, %8148
  %8486 = fmul reassoc ninf nsz double %8485, 4.905000e+00
  %8487 = fadd reassoc ninf nsz double %8483, %8463
  %8488 = fadd reassoc ninf nsz double %8487, %8473
  %8489 = fsub reassoc ninf nsz double %8488, %8480
  %8490 = fadd reassoc ninf nsz double %8484, %8465
  %8491 = fadd reassoc ninf nsz double %8490, %8474
  %8492 = fmul reassoc ninf nsz double %8480, %8477
  %8493 = fsub reassoc ninf nsz double %8491, %8492
  %reass.add10927 = fadd reassoc ninf nsz double %8473, %8483
  %reass.add10929 = fsub reassoc ninf nsz double %reass.add10927, %8480
  %reass.mul10930 = fmul reassoc ninf nsz double %reass.add10929, %8160
  %8494 = fadd reassoc ninf nsz double %reass.mul10930, %8466
  %8495 = fadd reassoc ninf nsz double %8486, %8469
  %8496 = fadd reassoc ninf nsz double %8495, %8476
  %8497 = fadd reassoc ninf nsz double %8496, %8482
  br label %after_if2590

false_block2631:                                  ; preds = %false_block2628
  %8498 = fmul reassoc ninf nsz double %.0741, %8148
  %8499 = fmul reassoc ninf nsz double %8498, %.0741
  %8500 = fmul reassoc ninf nsz double %8498, %8160
  %8501 = fmul reassoc ninf nsz double %8148, %8148
  %8502 = fmul reassoc ninf nsz double %8501, 4.905000e+00
  %8503 = fadd reassoc ninf nsz double %8498, %8463
  %8504 = fadd reassoc ninf nsz double %8499, %8465
  %8505 = fadd reassoc ninf nsz double %8500, %8466
  %8506 = fadd reassoc ninf nsz double %8502, %8469
  br label %after_if2590

false_block2642:                                  ; preds = %false_block2543
  %8507 = fcmp reassoc ninf nsz oge double %8208, 0.000000e+00
  %8508 = fcmp reassoc ninf nsz olt double %8208, %8211
  %.0721 = select i1 %8507, i1 %8508, i1 false
  %neg2650 = fneg reassoc ninf nsz double %8211
  %8509 = fcmp reassoc ninf nsz oge double %8208, %neg2650
  %8510 = fcmp reassoc ninf nsz olt double %8208, 0.000000e+00
  %not..0721 = xor i1 %.0721, true
  %8511 = select i1 %not..0721, i1 %8509, i1 false
  %spec.select10867 = select i1 %8511, i1 %8510, i1 false
  br label %after_if2643

after_if2643:                                     ; preds = %false_block2642, %false_block2543
  %8512 = phi i1 [ false, %false_block2543 ], [ %.0721, %false_block2642 ]
  %8513 = phi i1 [ false, %false_block2543 ], [ %spec.select10867, %false_block2642 ]
  %8514 = fcmp reassoc ninf nsz olt double %8183, %8188
  %8515 = fcmp reassoc ninf nsz oge double %.0728, %neg2660
  %.0718 = select i1 %8514, i1 %8515, i1 false
  %8516 = fcmp reassoc ninf nsz oge double %8183, %8188
  %.0717 = select i1 %8516, i1 %8515, i1 false
  %8517 = fcmp reassoc ninf nsz olt double %.0728, %neg2660
  %not..0717 = xor i1 %.0717, true
  %8518 = select i1 %not..0717, i1 %8514, i1 false
  %spec.select10869 = select i1 %8518, i1 %8517, i1 false
  br i1 %.0718, label %after_if2663, label %false_block2662

false_block2662:                                  ; preds = %after_if2643
  br label %after_if2663

after_if2663:                                     ; preds = %false_block2662, %after_if2643
  %8519 = phi i1 [ false, %after_if2643 ], [ %.0717, %false_block2662 ]
  %8520 = phi i1 [ false, %after_if2643 ], [ %spec.select10869, %false_block2662 ]
  br i1 %.0718, label %true_block2678, label %false_block2679

true_block2678:                                   ; preds = %after_if2663
  %8521 = fcmp olt double %8211, %8208
  br i1 %8521, label %true_block2681, label %false_block2682

false_block2679:                                  ; preds = %after_if2663
  br i1 %8519, label %true_block2690, label %false_block2691

after_if2680:                                     ; preds = %true_block2720, %false_block2721, %true_block2717, %true_block2714, %true_block2711, %false_block2712, %true_block2708, %true_block2705, %true_block2699, %false_block2700, %true_block2696, %true_block2693, %true_block2687, %false_block2688, %true_block2684, %true_block2681
  %.0726 = phi double [ %8538, %true_block2681 ], [ %8546, %true_block2684 ], [ %8554, %true_block2687 ], [ %8562, %false_block2688 ], [ %8568, %true_block2693 ], [ %8592, %true_block2696 ], [ %8608, %true_block2699 ], [ %8620, %false_block2700 ], [ %8644, %true_block2705 ], [ %8670, %true_block2708 ], [ %8695, %true_block2711 ], [ %8702, %false_block2712 ], [ %8719, %true_block2714 ], [ %8752, %true_block2717 ], [ %8790, %true_block2720 ], [ %8804, %false_block2721 ]
  %.0725 = phi double [ %8539, %true_block2681 ], [ %8547, %true_block2684 ], [ %8555, %true_block2687 ], [ %8563, %false_block2688 ], [ %8569, %true_block2693 ], [ %8593, %true_block2696 ], [ %8609, %true_block2699 ], [ %8621, %false_block2700 ], [ %8647, %true_block2705 ], [ %8673, %true_block2708 ], [ %8698, %true_block2711 ], [ %8703, %false_block2712 ], [ %8722, %true_block2714 ], [ %8755, %true_block2717 ], [ %8794, %true_block2720 ], [ %8805, %false_block2721 ]
  %.0724 = phi double [ %8540, %true_block2681 ], [ %8548, %true_block2684 ], [ %8556, %true_block2687 ], [ %8564, %false_block2688 ], [ %8570, %true_block2693 ], [ %8594, %true_block2696 ], [ %8610, %true_block2699 ], [ %8622, %false_block2700 ], [ %8648, %true_block2705 ], [ %8674, %true_block2708 ], [ %8699, %true_block2711 ], [ %8704, %false_block2712 ], [ %8723, %true_block2714 ], [ %8756, %true_block2717 ], [ %8795, %true_block2720 ], [ %8806, %false_block2721 ]
  %.0723 = phi double [ %8542, %true_block2681 ], [ %8550, %true_block2684 ], [ %8558, %true_block2687 ], [ %8566, %false_block2688 ], [ %8572, %true_block2693 ], [ %8595, %true_block2696 ], [ %8611, %true_block2699 ], [ %8623, %false_block2700 ], [ %8650, %true_block2705 ], [ %8676, %true_block2708 ], [ %8701, %true_block2711 ], [ %8706, %false_block2712 ], [ %8724, %true_block2714 ], [ %8758, %true_block2717 ], [ %8798, %true_block2720 ], [ %8807, %false_block2721 ]
  %neg2723 = fneg reassoc ninf nsz double %.0726
  %8522 = fsub reassoc ninf nsz double 1.000000e+00, %8197
  %8523 = fmul reassoc ninf nsz double %8190, 5.000000e-01
  %8524 = fmul reassoc ninf nsz double %8195, %8195
  %8525 = fmul reassoc ninf nsz double %8524, %8523
  %8526 = fmul reassoc ninf nsz double %8525, %8522
  %8527 = fadd reassoc ninf nsz double %.0725, %8526
  %8528 = fmul reassoc ninf nsz double %.0723, 0x3FCA1887B2C1A188
  %8529 = tail call double @llvm.sqrt.f64(double %8528)
  %8530 = fsub reassoc ninf nsz double %.01384, %37
  %8531 = fadd reassoc ninf nsz double %8530, %8529
  %8532 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %8531, double 0.000000e+00)
  %8533 = fmul reassoc ninf nsz double %8532, %8532
  %8534 = fmul reassoc ninf nsz double %8533, 4.905000e+00
  br label %after_if9

true_block2681:                                   ; preds = %true_block2678
  %8535 = fmul reassoc ninf nsz double %8189, 0x3FD5555555555555
  %8536 = fmul reassoc ninf nsz double %8535, %8535
  %8537 = fmul reassoc ninf nsz double %8536, 0x3FBA1887B2C1A188
  %8538 = fmul reassoc ninf nsz double %8537, %8535
  %8539 = fmul reassoc ninf nsz double %8538, %8535
  %8540 = fmul reassoc ninf nsz double %8538, %8186
  %8541 = fmul reassoc ninf nsz double %8536, 5.000000e-01
  %8542 = fmul reassoc ninf nsz double %8541, %8537
  br label %after_if2680

false_block2682:                                  ; preds = %true_block2678
  br i1 %8512, label %true_block2684, label %false_block2685

true_block2684:                                   ; preds = %false_block2682
  %8543 = fsub reassoc ninf nsz double %8189, %8208
  %8544 = fmul reassoc ninf nsz double %8543, %8543
  %8545 = fmul reassoc ninf nsz double %8544, 0x3F9A1887B2C1A188
  %8546 = fmul reassoc ninf nsz double %8545, %8208
  %8547 = fmul reassoc ninf nsz double %8546, %8208
  %8548 = fmul reassoc ninf nsz double %8546, %8186
  %8549 = fmul reassoc ninf nsz double %8544, 1.250000e-01
  %8550 = fmul reassoc ninf nsz double %8549, %8545
  br label %after_if2680

false_block2685:                                  ; preds = %false_block2682
  br i1 %8513, label %true_block2687, label %false_block2688

true_block2687:                                   ; preds = %false_block2685
  %8551 = fsub reassoc ninf nsz double %8206, %8208
  %8552 = fmul reassoc ninf nsz double %8551, %8551
  %8553 = fmul reassoc ninf nsz double %8552, 0x3F9A1887B2C1A188
  %8554 = fmul reassoc ninf nsz double %8553, %8208
  %8555 = fmul reassoc ninf nsz double %8554, %8208
  %8556 = fmul reassoc ninf nsz double %8554, %8203
  %8557 = fmul reassoc ninf nsz double %8552, 1.250000e-01
  %8558 = fmul reassoc ninf nsz double %8557, %8553
  br label %after_if2680

false_block2688:                                  ; preds = %false_block2685
  %8559 = fmul reassoc ninf nsz double %8206, 0x3FD5555555555555
  %8560 = fmul reassoc ninf nsz double %8559, %8559
  %8561 = fmul reassoc ninf nsz double %8560, 0x3FBA1887B2C1A188
  %8562 = fmul reassoc ninf nsz double %8561, %8559
  %8563 = fmul reassoc ninf nsz double %8562, %8559
  %8564 = fmul reassoc ninf nsz double %8562, %8203
  %8565 = fmul reassoc ninf nsz double %8560, 5.000000e-01
  %8566 = fmul reassoc ninf nsz double %8565, %8561
  br label %after_if2680

true_block2690:                                   ; preds = %false_block2679
  %8567 = fcmp olt double %8211, %8208
  %8568 = fmul reassoc ninf nsz double %8183, %8174
  %8569 = fmul reassoc ninf nsz double %8568, %8183
  br i1 %8567, label %true_block2693, label %false_block2694

false_block2691:                                  ; preds = %false_block2679
  br i1 %8520, label %true_block2702, label %false_block2703

true_block2693:                                   ; preds = %true_block2690
  %8570 = fmul reassoc ninf nsz double %8568, %8186
  %8571 = fmul reassoc ninf nsz double %8174, %8174
  %8572 = fmul reassoc ninf nsz double %8571, 4.905000e+00
  br label %after_if2680

false_block2694:                                  ; preds = %true_block2690
  %8573 = fmul reassoc ninf nsz double %8174, %8174
  %8574 = fmul reassoc ninf nsz double %8573, 4.905000e+00
  %8575 = fmul reassoc ninf nsz double %8189, 0x3FD5555555555555
  %8576 = fmul reassoc ninf nsz double %8575, %8575
  %8577 = fmul reassoc ninf nsz double %8576, 0x3FBA1887B2C1A188
  %8578 = fmul reassoc ninf nsz double %8577, %8575
  %8579 = fsub reassoc ninf nsz double %8568, %8578
  %8580 = fmul reassoc ninf nsz double %8578, %8575
  %8581 = fsub reassoc ninf nsz double %8569, %8580
  br i1 %8512, label %true_block2696, label %false_block2697

true_block2696:                                   ; preds = %false_block2694
  %8582 = fmul reassoc ninf nsz double %8576, -5.000000e-01
  %8583 = fmul reassoc ninf nsz double %8582, %8577
  %8584 = fadd reassoc ninf nsz double %8583, %8574
  %8585 = fsub reassoc ninf nsz double %8189, %8208
  %8586 = fmul reassoc ninf nsz double %8585, %8585
  %8587 = fmul reassoc ninf nsz double %8586, 0x3F9A1887B2C1A188
  %8588 = fmul reassoc ninf nsz double %8587, %8208
  %8589 = fmul reassoc ninf nsz double %8588, %8208
  %8590 = fmul reassoc ninf nsz double %8586, 1.250000e-01
  %8591 = fmul reassoc ninf nsz double %8590, %8587
  %8592 = fadd reassoc ninf nsz double %8588, %8579
  %8593 = fadd reassoc ninf nsz double %8581, %8589
  %8594 = fmul reassoc ninf nsz double %8592, %8186
  %8595 = fadd reassoc ninf nsz double %8584, %8591
  br label %after_if2680

false_block2697:                                  ; preds = %false_block2694
  %8596 = fmul reassoc ninf nsz double %8579, %8186
  %8597 = fmul reassoc ninf nsz double %8576, 5.000000e-01
  %8598 = fmul reassoc ninf nsz double %8597, %8577
  %8599 = fsub reassoc ninf nsz double %8574, %8598
  br i1 %8513, label %true_block2699, label %false_block2700

true_block2699:                                   ; preds = %false_block2697
  %8600 = fsub reassoc ninf nsz double %8206, %8208
  %8601 = fmul reassoc ninf nsz double %8600, %8600
  %8602 = fmul reassoc ninf nsz double %8601, 0x3F9A1887B2C1A188
  %8603 = fmul reassoc ninf nsz double %8602, %8208
  %8604 = fmul reassoc ninf nsz double %8603, %8208
  %8605 = fmul reassoc ninf nsz double %8603, %8203
  %8606 = fmul reassoc ninf nsz double %8601, 1.250000e-01
  %8607 = fmul reassoc ninf nsz double %8606, %8602
  %8608 = fadd reassoc ninf nsz double %8603, %8579
  %8609 = fadd reassoc ninf nsz double %8604, %8581
  %8610 = fadd reassoc ninf nsz double %8605, %8596
  %8611 = fadd reassoc ninf nsz double %8607, %8599
  br label %after_if2680

false_block2700:                                  ; preds = %false_block2697
  %8612 = fmul reassoc ninf nsz double %8206, 0x3FD5555555555555
  %8613 = fmul reassoc ninf nsz double %8612, %8612
  %8614 = fmul reassoc ninf nsz double %8613, 0x3FBA1887B2C1A188
  %8615 = fmul reassoc ninf nsz double %8614, %8612
  %8616 = fmul reassoc ninf nsz double %8615, %8612
  %8617 = fmul reassoc ninf nsz double %8615, %8203
  %8618 = fmul reassoc ninf nsz double %8613, 5.000000e-01
  %8619 = fmul reassoc ninf nsz double %8618, %8614
  %8620 = fadd reassoc ninf nsz double %8579, %8615
  %8621 = fadd reassoc ninf nsz double %8581, %8616
  %8622 = fadd reassoc ninf nsz double %8596, %8617
  %8623 = fadd reassoc ninf nsz double %8599, %8619
  br label %after_if2680

true_block2702:                                   ; preds = %false_block2691
  %8624 = fcmp olt double %8211, %8208
  br i1 %8624, label %true_block2705, label %false_block2706

false_block2703:                                  ; preds = %false_block2691
  %8625 = fcmp olt double %8211, %8208
  %8626 = fmul reassoc ninf nsz double %8183, %8174
  %8627 = fmul reassoc ninf nsz double %8626, %8183
  br i1 %8625, label %true_block2714, label %false_block2715

true_block2705:                                   ; preds = %true_block2702
  %8628 = fmul reassoc ninf nsz double %8189, 0x3FD5555555555555
  %8629 = fmul reassoc ninf nsz double %8628, %8628
  %8630 = fmul reassoc ninf nsz double %8629, 0x3FBA1887B2C1A188
  %8631 = fmul reassoc ninf nsz double %8630, %8628
  %8632 = fmul reassoc ninf nsz double %8631, %8628
  %8633 = fmul reassoc ninf nsz double %8631, %8186
  %8634 = fmul reassoc ninf nsz double %8630, %8629
  %8635 = fmul reassoc ninf nsz double %8206, 0x3FD5555555555555
  %8636 = fmul reassoc ninf nsz double %8635, %8635
  %8637 = fmul reassoc ninf nsz double %8636, 0x3FBA1887B2C1A188
  %8638 = fmul reassoc ninf nsz double %8637, %8635
  %8639 = fmul reassoc ninf nsz double %.0728, %8193
  %8640 = fmul reassoc ninf nsz double %8639, %.0728
  %8641 = fmul reassoc ninf nsz double %8193, %8193
  %8642 = fmul reassoc ninf nsz double %8641, 4.905000e+00
  %8643 = fsub reassoc ninf nsz double %8639, %8638
  %8644 = fadd reassoc ninf nsz double %8643, %8631
  %8645 = fmul reassoc ninf nsz double %8638, %8635
  %8646 = fsub reassoc ninf nsz double %8640, %8645
  %8647 = fadd reassoc ninf nsz double %8646, %8632
  %reass.mul10919 = fmul reassoc ninf nsz double %8643, %8203
  %8648 = fadd reassoc ninf nsz double %reass.mul10919, %8633
  %8649 = fmul reassoc ninf nsz double %8637, %8636
  %reass.add10916 = fsub reassoc ninf nsz double %8634, %8649
  %reass.mul10917 = fmul reassoc ninf nsz double %reass.add10916, 5.000000e-01
  %8650 = fadd reassoc ninf nsz double %reass.mul10917, %8642
  br label %after_if2680

false_block2706:                                  ; preds = %true_block2702
  br i1 %8512, label %true_block2708, label %false_block2709

true_block2708:                                   ; preds = %false_block2706
  %8651 = fsub reassoc ninf nsz double %8189, %8208
  %8652 = fmul reassoc ninf nsz double %8651, %8651
  %8653 = fmul reassoc ninf nsz double %8652, 0x3F9A1887B2C1A188
  %8654 = fmul reassoc ninf nsz double %8653, %8208
  %8655 = fmul reassoc ninf nsz double %8654, %8208
  %8656 = fmul reassoc ninf nsz double %8654, %8186
  %8657 = fmul reassoc ninf nsz double %8652, 1.250000e-01
  %8658 = fmul reassoc ninf nsz double %8657, %8653
  %8659 = fmul reassoc ninf nsz double %8206, 0x3FD5555555555555
  %8660 = fmul reassoc ninf nsz double %8659, %8659
  %8661 = fmul reassoc ninf nsz double %8660, 0x3FBA1887B2C1A188
  %8662 = fmul reassoc ninf nsz double %8661, %8659
  %8663 = fmul reassoc ninf nsz double %8660, -5.000000e-01
  %8664 = fmul reassoc ninf nsz double %8663, %8661
  %8665 = fmul reassoc ninf nsz double %.0728, %8193
  %8666 = fmul reassoc ninf nsz double %8665, %.0728
  %8667 = fmul reassoc ninf nsz double %8193, %8193
  %8668 = fmul reassoc ninf nsz double %8667, 4.905000e+00
  %8669 = fsub reassoc ninf nsz double %8665, %8662
  %8670 = fadd reassoc ninf nsz double %8669, %8654
  %8671 = fmul reassoc ninf nsz double %8662, %8659
  %8672 = fsub reassoc ninf nsz double %8666, %8671
  %8673 = fadd reassoc ninf nsz double %8672, %8655
  %reass.mul10911 = fmul reassoc ninf nsz double %8669, %8203
  %8674 = fadd reassoc ninf nsz double %reass.mul10911, %8656
  %8675 = fadd reassoc ninf nsz double %8664, %8668
  %8676 = fadd reassoc ninf nsz double %8675, %8658
  br label %after_if2680

false_block2709:                                  ; preds = %false_block2706
  br i1 %8513, label %true_block2711, label %false_block2712

true_block2711:                                   ; preds = %false_block2709
  %8677 = fsub reassoc ninf nsz double %8206, %8208
  %8678 = fmul reassoc ninf nsz double %8677, %8677
  %8679 = fmul reassoc ninf nsz double %8678, 0x3F9A1887B2C1A188
  %8680 = fmul reassoc ninf nsz double %8679, %8208
  %8681 = fmul reassoc ninf nsz double %8680, %8208
  %8682 = fmul reassoc ninf nsz double %8678, 1.250000e-01
  %8683 = fmul reassoc ninf nsz double %8682, %8679
  %8684 = fmul reassoc ninf nsz double %8677, 0x3FD5555555555555
  %8685 = fmul reassoc ninf nsz double %8684, %8684
  %8686 = fmul reassoc ninf nsz double %8685, 0x3FBA1887B2C1A188
  %8687 = fmul reassoc ninf nsz double %8686, %8684
  %8688 = fsub reassoc ninf nsz double %8680, %8687
  %8689 = fmul reassoc ninf nsz double %8685, -5.000000e-01
  %8690 = fmul reassoc ninf nsz double %8689, %8686
  %8691 = fmul reassoc ninf nsz double %.0728, %8193
  %8692 = fmul reassoc ninf nsz double %8691, %.0728
  %8693 = fmul reassoc ninf nsz double %8193, %8193
  %8694 = fmul reassoc ninf nsz double %8693, 4.905000e+00
  %8695 = fadd reassoc ninf nsz double %8688, %8691
  %8696 = fadd reassoc ninf nsz double %8681, %8692
  %8697 = fmul reassoc ninf nsz double %8687, %8684
  %8698 = fsub reassoc ninf nsz double %8696, %8697
  %8699 = fmul reassoc ninf nsz double %8695, %8203
  %8700 = fadd reassoc ninf nsz double %8683, %8694
  %8701 = fadd reassoc ninf nsz double %8700, %8690
  br label %after_if2680

false_block2712:                                  ; preds = %false_block2709
  %8702 = fmul reassoc ninf nsz double %.0728, %8193
  %8703 = fmul reassoc ninf nsz double %8702, %.0728
  %8704 = fmul reassoc ninf nsz double %8702, %8203
  %8705 = fmul reassoc ninf nsz double %8193, %8193
  %8706 = fmul reassoc ninf nsz double %8705, 4.905000e+00
  br label %after_if2680

true_block2714:                                   ; preds = %false_block2703
  %8707 = fmul reassoc ninf nsz double %8626, %8186
  %8708 = fmul reassoc ninf nsz double %8174, %8174
  %8709 = fmul reassoc ninf nsz double %8206, 0x3FD5555555555555
  %8710 = fmul reassoc ninf nsz double %8709, %8709
  %8711 = fmul reassoc ninf nsz double %8710, 0x3FBA1887B2C1A188
  %8712 = fmul reassoc ninf nsz double %8711, %8709
  %8713 = fmul reassoc ninf nsz double %8710, 5.000000e-01
  %8714 = fmul reassoc ninf nsz double %8713, %8711
  %8715 = fmul reassoc ninf nsz double %.0728, %8193
  %8716 = fmul reassoc ninf nsz double %8715, %.0728
  %8717 = fmul reassoc ninf nsz double %8193, %8193
  %8718 = fsub reassoc ninf nsz double %8715, %8712
  %8719 = fadd reassoc ninf nsz double %8718, %8626
  %8720 = fmul reassoc ninf nsz double %8712, %8709
  %8721 = fsub reassoc ninf nsz double %8716, %8720
  %8722 = fadd reassoc ninf nsz double %8721, %8627
  %reass.mul10905 = fmul reassoc ninf nsz double %8718, %8203
  %8723 = fadd reassoc ninf nsz double %reass.mul10905, %8707
  %reass.add10902 = fadd reassoc ninf nsz double %8708, %8717
  %reass.mul10903 = fmul reassoc ninf nsz double %reass.add10902, 4.905000e+00
  %8724 = fsub reassoc ninf nsz double %reass.mul10903, %8714
  br label %after_if2680

false_block2715:                                  ; preds = %false_block2703
  %8725 = fmul reassoc ninf nsz double %8174, %8174
  br i1 %8512, label %true_block2717, label %false_block2718

true_block2717:                                   ; preds = %false_block2715
  %8726 = fmul reassoc ninf nsz double %8189, 0x3FD5555555555555
  %8727 = fmul reassoc ninf nsz double %8726, %8726
  %8728 = fmul reassoc ninf nsz double %8727, 0x3FBA1887B2C1A188
  %8729 = fmul reassoc ninf nsz double %8728, %8726
  %8730 = fsub reassoc ninf nsz double %8626, %8729
  %8731 = fmul reassoc ninf nsz double %8728, %8727
  %8732 = fsub reassoc ninf nsz double %8189, %8208
  %8733 = fmul reassoc ninf nsz double %8732, %8732
  %8734 = fmul reassoc ninf nsz double %8733, 0x3F9A1887B2C1A188
  %8735 = fmul reassoc ninf nsz double %8734, %8208
  %8736 = fmul reassoc ninf nsz double %8735, %8208
  %8737 = fmul reassoc ninf nsz double %8733, 1.250000e-01
  %8738 = fmul reassoc ninf nsz double %8737, %8734
  %8739 = fadd reassoc ninf nsz double %8730, %8735
  %8740 = fmul reassoc ninf nsz double %8739, %8186
  %8741 = fmul reassoc ninf nsz double %8206, 0x3FD5555555555555
  %8742 = fmul reassoc ninf nsz double %8741, %8741
  %8743 = fmul reassoc ninf nsz double %8742, 0x3FBA1887B2C1A188
  %8744 = fmul reassoc ninf nsz double %8743, %8741
  %.neg10888 = fmul reassoc ninf nsz double %8744, %8741
  %.neg10889 = fmul reassoc ninf nsz double %8729, %8726
  %8745 = fmul reassoc ninf nsz double %8743, %8742
  %8746 = fmul reassoc ninf nsz double %.0728, %8193
  %8747 = fmul reassoc ninf nsz double %8746, %.0728
  %8748 = fmul reassoc ninf nsz double %8193, %8193
  %8749 = fadd reassoc ninf nsz double %8746, %8626
  %8750 = fadd reassoc ninf nsz double %8744, %8729
  %8751 = fsub reassoc ninf nsz double %8749, %8750
  %8752 = fadd reassoc ninf nsz double %8751, %8735
  %reass.add10895 = fadd reassoc ninf nsz double %.neg10889, %.neg10888
  %8753 = fadd reassoc ninf nsz double %8627, %8747
  %8754 = fadd reassoc ninf nsz double %8753, %8736
  %8755 = fsub reassoc ninf nsz double %8754, %reass.add10895
  %reass.add10897 = fsub reassoc ninf nsz double %8746, %8744
  %reass.mul10898 = fmul reassoc ninf nsz double %reass.add10897, %8203
  %8756 = fadd reassoc ninf nsz double %reass.mul10898, %8740
  %reass.add10892 = fadd reassoc ninf nsz double %8731, %8745
  %reass.mul = fmul reassoc ninf nsz double %reass.add10892, -5.000000e-01
  %reass.add10893 = fadd reassoc ninf nsz double %8725, %8748
  %reass.mul10894 = fmul reassoc ninf nsz double %reass.add10893, 4.905000e+00
  %8757 = fadd reassoc ninf nsz double %8738, %reass.mul10894
  %8758 = fadd reassoc ninf nsz double %8757, %reass.mul
  br label %after_if2680

false_block2718:                                  ; preds = %false_block2715
  %8759 = fmul reassoc ninf nsz double %8725, 4.905000e+00
  %8760 = fmul reassoc ninf nsz double %8189, 0x3FD5555555555555
  %8761 = fmul reassoc ninf nsz double %8760, %8760
  %8762 = fmul reassoc ninf nsz double %8761, 0x3FBA1887B2C1A188
  %8763 = fmul reassoc ninf nsz double %8762, %8760
  %8764 = fsub reassoc ninf nsz double %8626, %8763
  %8765 = fmul reassoc ninf nsz double %8763, %8760
  %8766 = fsub reassoc ninf nsz double %8627, %8765
  %8767 = fmul reassoc ninf nsz double %8764, %8186
  %8768 = fmul reassoc ninf nsz double %8761, 5.000000e-01
  %8769 = fmul reassoc ninf nsz double %8768, %8762
  %8770 = fsub reassoc ninf nsz double %8759, %8769
  br i1 %8513, label %true_block2720, label %false_block2721

true_block2720:                                   ; preds = %false_block2718
  %8771 = fsub reassoc ninf nsz double %8206, %8208
  %8772 = fmul reassoc ninf nsz double %8771, %8771
  %8773 = fmul reassoc ninf nsz double %8772, 0x3F9A1887B2C1A188
  %8774 = fmul reassoc ninf nsz double %8773, %8208
  %8775 = fmul reassoc ninf nsz double %8774, %8208
  %8776 = fmul reassoc ninf nsz double %8772, 1.250000e-01
  %8777 = fmul reassoc ninf nsz double %8776, %8773
  %8778 = fmul reassoc ninf nsz double %8771, 0x3FD5555555555555
  %8779 = fmul reassoc ninf nsz double %8778, %8778
  %8780 = fmul reassoc ninf nsz double %8779, 0x3FBA1887B2C1A188
  %8781 = fmul reassoc ninf nsz double %8780, %8778
  %8782 = fmul reassoc ninf nsz double %8779, -5.000000e-01
  %8783 = fmul reassoc ninf nsz double %8782, %8780
  %8784 = fmul reassoc ninf nsz double %.0728, %8193
  %8785 = fmul reassoc ninf nsz double %8784, %.0728
  %8786 = fmul reassoc ninf nsz double %8193, %8193
  %8787 = fmul reassoc ninf nsz double %8786, 4.905000e+00
  %8788 = fadd reassoc ninf nsz double %8764, %8784
  %8789 = fadd reassoc ninf nsz double %8788, %8774
  %8790 = fsub reassoc ninf nsz double %8789, %8781
  %8791 = fadd reassoc ninf nsz double %8766, %8785
  %8792 = fadd reassoc ninf nsz double %8791, %8775
  %8793 = fmul reassoc ninf nsz double %8781, %8778
  %8794 = fsub reassoc ninf nsz double %8792, %8793
  %reass.add = fadd reassoc ninf nsz double %8774, %8784
  %reass.add10883 = fsub reassoc ninf nsz double %reass.add, %8781
  %reass.mul10884 = fmul reassoc ninf nsz double %reass.add10883, %8203
  %8795 = fadd reassoc ninf nsz double %reass.mul10884, %8767
  %8796 = fadd reassoc ninf nsz double %8770, %8787
  %8797 = fadd reassoc ninf nsz double %8796, %8777
  %8798 = fadd reassoc ninf nsz double %8797, %8783
  br label %after_if2680

false_block2721:                                  ; preds = %false_block2718
  %8799 = fmul reassoc ninf nsz double %.0728, %8193
  %8800 = fmul reassoc ninf nsz double %8799, %.0728
  %8801 = fmul reassoc ninf nsz double %8799, %8203
  %8802 = fmul reassoc ninf nsz double %8193, %8193
  %8803 = fmul reassoc ninf nsz double %8802, 4.905000e+00
  %8804 = fadd reassoc ninf nsz double %8764, %8799
  %8805 = fadd reassoc ninf nsz double %8766, %8800
  %8806 = fadd reassoc ninf nsz double %8767, %8801
  %8807 = fadd reassoc ninf nsz double %8770, %8803
  br label %after_if2680
}

; Function Attrs: argmemonly nocallback nofree nounwind readonly
declare i32 @llvm.nvvm.ldg.global.i.i32.p0i32(i32* nocapture, i32) #1

; Function Attrs: argmemonly nocallback nofree nounwind readonly
declare double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nocapture, i32) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.maxnum.f64(double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.minnum.f64(double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.nctaid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.d2i.hi(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.d2i.lo(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.nvvm.lohi.i2d(i32, i32) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone willreturn
declare double @llvm.nvvm.rcp.approx.ftz.d(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.fabs.f64(double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.sqrt.f64(double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.fma.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fabs.f32(float) #4

attributes #0 = { nofree nounwind "denormal-fp-math-f32"="preserve-sign" "unsafe-fp-math"="true" }
attributes #1 = { argmemonly nocallback nofree nounwind readonly "denormal-fp-math-f32"="preserve-sign" "unsafe-fp-math"="true" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn "denormal-fp-math-f32"="preserve-sign" "unsafe-fp-math"="true" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind readnone willreturn "denormal-fp-math-f32"="preserve-sign" "unsafe-fp-math"="true" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #5 = { nounwind }

!nvvm.annotations = !{!0, !1, !2, !3, !4, !3, !5, !5, !5, !5, !6, !6, !5}
!llvm.ident = !{!7}
!nvvmir.version = !{!8}
!llvm.module.flags = !{!9, !10, !11, !12, !13, !14}

!0 = !{void (%struct.RuntimeContext.333*)* @calculate_flux_c80_0_kernel_0_range_for, !"kernel", i32 1}
!1 = !{void (%struct.RuntimeContext.333*)* @calculate_flux_c80_0_kernel_0_range_for, !"maxntidx", i32 128}
!2 = !{void (%struct.RuntimeContext.333*)* @calculate_flux_c80_0_kernel_0_range_for, !"minctasm", i32 2}
!3 = !{null, !"align", i32 8}
!4 = !{null, !"align", i32 8, !"align", i32 65544, !"align", i32 131080}
!5 = !{null, !"align", i32 16}
!6 = !{null, !"align", i32 16, !"align", i32 65552, !"align", i32 131088}
!7 = !{!"Ubuntu clang version 14.0.6"}
!8 = !{i32 1, i32 4}
!9 = !{i32 1, !"wchar_size", i32 4}
!10 = !{i32 7, !"PIC Level", i32 2}
!11 = !{i32 7, !"PIE Level", i32 2}
!12 = !{i32 7, !"uwtable", i32 1}
!13 = !{i32 7, !"frame-pointer", i32 2}
!14 = !{i32 4, !"nvvm-reflect-ftz", i32 1}
!15 = !{i32 0, i32 1024}
!16 = !{i32 1, i32 1025}
!17 = !{i32 0, i32 2147483647}
!18 = distinct !{!18, !19}
!19 = !{!"llvm.loop.mustprogress"}
