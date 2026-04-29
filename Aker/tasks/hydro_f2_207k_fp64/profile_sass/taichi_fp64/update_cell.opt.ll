; ModuleID = 'kernel'
source_filename = "kernel"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.RuntimeContext.346 = type { i8*, %struct.LLVMRuntime.345*, i32, i64* }
%struct.LLVMRuntime.345 = type { %struct.PreallocatedMemoryChunk.340, %struct.PreallocatedMemoryChunk.340, i8* (i8*, i64, i64)*, void (i8*)*, void (i8*, ...)*, i32 (i8*, i64, i8*, %struct.__va_list_tag.341*)*, i8*, [512 x i8*], [512 x i64], i8*, void (i8*, i32, i32, i8*, void (i8*, i32, i32)*)*, [1024 x %struct.ListManager.342*], [1024 x %struct.NodeManager.343*], [1024 x i8*], i8*, %struct.RandState.344*, i8*, void (i8*, i8*)*, void (i8*)*, [2048 x i8], [32 x i64], i32, i64, i8*, i32, i32, i64 }
%struct.PreallocatedMemoryChunk.340 = type { i8*, i8*, i64 }
%struct.__va_list_tag.341 = type { i32, i32, i8*, i8* }
%struct.ListManager.342 = type { [131072 x i8*], i64, i64, i32, i32, i32, %struct.LLVMRuntime.345* }
%struct.NodeManager.343 = type <{ %struct.LLVMRuntime.345*, i32, i32, i32, i32, %struct.ListManager.342*, %struct.ListManager.342*, %struct.ListManager.342*, i32, [4 x i8] }>
%struct.RandState.344 = type { i32, i32, i32, i32, i32 }

; Function Attrs: nofree nounwind
define void @update_cell_c82_0_kernel_0_range_for(%struct.RuntimeContext.346* nocapture readonly byval(%struct.RuntimeContext.346) align 8 %context) local_unnamed_addr #0 {
entry:
  %context31 = addrspacecast %struct.RuntimeContext.346* %context to %struct.RuntimeContext.346 addrspace(101)*
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !range !15
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !range !16
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !range !17
  %3 = mul nsw i32 %1, %2
  %4 = add nuw nsw i32 %3, %0
  %5 = icmp ult i32 %4, 207234
  br i1 %5, label %.lr.ph.i, label %gpu_parallel_range_for.exit

.lr.ph.i:                                         ; preds = %entry
  %6 = getelementptr inbounds %struct.RuntimeContext.346, %struct.RuntimeContext.346 addrspace(101)* %context31, i64 0, i32 1
  %7 = tail call i32 @llvm.nvvm.d2i.hi(double 3.333300e-01)
  %8 = and i32 %7, 2146435072
  %9 = tail call double @llvm.nvvm.lohi.i2d(i32 -2147483648, i32 1127219200)
  %10 = tail call i32 @llvm.nvvm.d2i.lo(double 3.333300e-01)
  %11 = shl i32 %7, 1
  %12 = icmp ugt i32 %11, -33554433
  %13 = and i32 %7, -15728641
  %spec.select.i.i.i.i = select i1 %12, i32 %13, i32 %7
  %14 = tail call double @llvm.nvvm.lohi.i2d(i32 %10, i32 %spec.select.i.i.i.i)
  %15 = icmp slt i32 %7, 0
  %16 = and i32 %7, 2147483647
  %17 = icmp eq i32 %16, 2146435072
  %18 = icmp eq i32 %10, 0
  %19 = select i1 %17, i1 %18, i1 false
  %spec.select8.i.i.i = select i1 %15, i32 0, i32 2146435072
  %20 = or i32 %spec.select8.i.i.i, -2147483648
  %21 = tail call i32 @llvm.nvvm.read.ptx.sreg.nctaid.x(), !range !18
  %22 = mul i32 %1, %21
  %23 = load %struct.LLVMRuntime.345*, %struct.LLVMRuntime.345* addrspace(101)* %6, align 8
  %24 = addrspacecast %struct.LLVMRuntime.345* %23 to %struct.LLVMRuntime.345 addrspace(1)*
  %25 = shl i32 %4, 2
  %26 = shl i32 %22, 2
  %27 = zext i32 %1 to i64
  %28 = zext i32 %2 to i64
  %29 = mul nuw i64 %27, %28
  %30 = zext i32 %0 to i64
  %31 = add nuw i64 %29, %30
  %32 = shl nuw nsw i64 %31, 3
  %33 = add nuw nsw i64 %32, 82893600
  %34 = zext i32 %22 to i64
  %35 = shl nuw nsw i64 %34, 3
  br label %36

36:                                               ; preds = %function_body.exit.i, %.lr.ph.i
  %lsr.iv7 = phi i64 [ %lsr.iv.next8, %function_body.exit.i ], [ %33, %.lr.ph.i ]
  %lsr.iv = phi i32 [ %lsr.iv.next, %function_body.exit.i ], [ %25, %.lr.ph.i ]
  %.07.i = phi i32 [ %4, %.lr.ph.i ], [ %418, %function_body.exit.i ]
  %37 = bitcast %struct.LLVMRuntime.345 addrspace(1)* %24 to i8 addrspace(1)*
  %sunkaddr = getelementptr inbounds i8, i8 addrspace(1)* %37, i64 88
  %38 = bitcast i8 addrspace(1)* %sunkaddr to i8* addrspace(1)*
  %39 = load i8*, i8* addrspace(1)* %38, align 8
  %scevgep37 = getelementptr i8, i8* %39, i64 %lsr.iv7
  %scevgep3738 = bitcast i8* %scevgep37 to double*
  %scevgep53 = getelementptr double, double* %scevgep3738, i64 -1657872
  %40 = load double, double* %scevgep53, align 8
  %scevgep50 = getelementptr double, double* %scevgep3738, i64 -1450638
  %41 = load double, double* %scevgep50, align 8
  %scevgep47 = getelementptr double, double* %scevgep3738, i64 -1243404
  %42 = load double, double* %scevgep47, align 8
  %scevgep44 = getelementptr double, double* %scevgep3738, i64 -621702
  %43 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %scevgep44, i32 64)
  %getch.i16.i.i = getelementptr i8, i8* %39, i64 9947232
  %44 = zext i32 %lsr.iv to i64
  %45 = shl nuw nsw i64 %44, 3
  %46 = getelementptr inbounds i8, i8* %getch.i16.i.i, i64 %45
  %47 = bitcast i8* %46 to double*
  %48 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %47, i32 64)
  %getch.i15.i.i = getelementptr i8, i8* %39, i64 29841696
  %49 = getelementptr inbounds i8, i8* %getch.i15.i.i, i64 %45
  %50 = bitcast i8* %49 to double*
  %51 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %50, i32 64)
  %getch.i14.i.i = getelementptr i8, i8* %39, i64 36473184
  %52 = getelementptr inbounds i8, i8* %getch.i14.i.i, i64 %45
  %53 = bitcast i8* %52 to double*
  %54 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %53, i32 64)
  %getch.i13.i.i = getelementptr i8, i8* %39, i64 49736160
  %55 = getelementptr inbounds i8, i8* %getch.i13.i.i, i64 %45
  %56 = bitcast i8* %55 to double*
  %57 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %56, i32 64)
  %getch.i12.i.i = getelementptr i8, i8* %39, i64 62999136
  %58 = getelementptr inbounds i8, i8* %getch.i12.i.i, i64 %45
  %59 = bitcast i8* %58 to double*
  %60 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %59, i32 64)
  %61 = fadd reassoc ninf nsz double %60, %57
  %getch.i11.i.i = getelementptr i8, i8* %39, i64 56367648
  %62 = getelementptr inbounds i8, i8* %getch.i11.i.i, i64 %45
  %63 = bitcast i8* %62 to double*
  %64 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %63, i32 64)
  %getch.i10.i.i = getelementptr i8, i8* %39, i64 43104672
  %65 = getelementptr inbounds i8, i8* %getch.i10.i.i, i64 %45
  %66 = bitcast i8* %65 to double*
  %67 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %66, i32 64)
  %68 = fmul reassoc ninf nsz double %67, %48
  %69 = fmul reassoc ninf nsz double %61, %51
  %70 = fmul reassoc ninf nsz double %61, %54
  %71 = fmul reassoc ninf nsz double %64, %51
  %72 = add i32 %lsr.iv, 1
  %73 = zext i32 %72 to i64
  %74 = shl nuw nsw i64 %73, 3
  %75 = getelementptr inbounds i8, i8* %getch.i16.i.i, i64 %74
  %76 = bitcast i8* %75 to double*
  %77 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %76, i32 64)
  %78 = getelementptr inbounds i8, i8* %getch.i15.i.i, i64 %74
  %79 = bitcast i8* %78 to double*
  %80 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %79, i32 64)
  %81 = getelementptr inbounds i8, i8* %getch.i14.i.i, i64 %74
  %82 = bitcast i8* %81 to double*
  %83 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %82, i32 64)
  %84 = getelementptr inbounds i8, i8* %getch.i13.i.i, i64 %74
  %85 = bitcast i8* %84 to double*
  %86 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %85, i32 64)
  %87 = getelementptr inbounds i8, i8* %getch.i12.i.i, i64 %74
  %88 = bitcast i8* %87 to double*
  %89 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %88, i32 64)
  %90 = fadd reassoc ninf nsz double %89, %86
  %91 = getelementptr inbounds i8, i8* %getch.i11.i.i, i64 %74
  %92 = bitcast i8* %91 to double*
  %93 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %92, i32 64)
  %94 = getelementptr inbounds i8, i8* %getch.i10.i.i, i64 %74
  %95 = bitcast i8* %94 to double*
  %96 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %95, i32 64)
  %97 = fmul reassoc ninf nsz double %96, %77
  %98 = fadd reassoc ninf nsz double %97, %68
  %99 = fmul reassoc ninf nsz double %90, %80
  %100 = fmul reassoc ninf nsz double %90, %83
  %101 = fmul reassoc ninf nsz double %93, %80
  %102 = add i32 %lsr.iv, 2
  %103 = zext i32 %102 to i64
  %104 = shl nuw nsw i64 %103, 3
  %105 = getelementptr inbounds i8, i8* %getch.i16.i.i, i64 %104
  %106 = bitcast i8* %105 to double*
  %107 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %106, i32 64)
  %108 = getelementptr inbounds i8, i8* %getch.i15.i.i, i64 %104
  %109 = bitcast i8* %108 to double*
  %110 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %109, i32 64)
  %111 = getelementptr inbounds i8, i8* %getch.i14.i.i, i64 %104
  %112 = bitcast i8* %111 to double*
  %113 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %112, i32 64)
  %114 = getelementptr inbounds i8, i8* %getch.i13.i.i, i64 %104
  %115 = bitcast i8* %114 to double*
  %116 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %115, i32 64)
  %117 = getelementptr inbounds i8, i8* %getch.i12.i.i, i64 %104
  %118 = bitcast i8* %117 to double*
  %119 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %118, i32 64)
  %120 = fadd reassoc ninf nsz double %119, %116
  %121 = getelementptr inbounds i8, i8* %getch.i11.i.i, i64 %104
  %122 = bitcast i8* %121 to double*
  %123 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %122, i32 64)
  %124 = getelementptr inbounds i8, i8* %getch.i10.i.i, i64 %104
  %125 = bitcast i8* %124 to double*
  %126 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %125, i32 64)
  %127 = fmul reassoc ninf nsz double %126, %107
  %128 = fadd reassoc ninf nsz double %98, %127
  %129 = fmul reassoc ninf nsz double %120, %110
  %130 = fmul reassoc ninf nsz double %120, %113
  %131 = fmul reassoc ninf nsz double %123, %110
  %132 = add i32 %lsr.iv, 3
  %133 = zext i32 %132 to i64
  %134 = shl nuw nsw i64 %133, 3
  %135 = getelementptr inbounds i8, i8* %getch.i16.i.i, i64 %134
  %136 = bitcast i8* %135 to double*
  %137 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %136, i32 64)
  %138 = getelementptr inbounds i8, i8* %getch.i15.i.i, i64 %134
  %139 = bitcast i8* %138 to double*
  %140 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %139, i32 64)
  %141 = getelementptr inbounds i8, i8* %getch.i14.i.i, i64 %134
  %142 = bitcast i8* %141 to double*
  %143 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %142, i32 64)
  %144 = getelementptr inbounds i8, i8* %getch.i13.i.i, i64 %134
  %145 = bitcast i8* %144 to double*
  %146 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %145, i32 64)
  %147 = getelementptr inbounds i8, i8* %getch.i12.i.i, i64 %134
  %148 = bitcast i8* %147 to double*
  %149 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %148, i32 64)
  %150 = fadd reassoc ninf nsz double %149, %146
  %151 = getelementptr inbounds i8, i8* %getch.i11.i.i, i64 %134
  %152 = bitcast i8* %151 to double*
  %153 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %152, i32 64)
  %154 = getelementptr inbounds i8, i8* %getch.i10.i.i, i64 %134
  %155 = bitcast i8* %154 to double*
  %156 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nonnull %155, i32 64)
  %157 = fmul reassoc ninf nsz double %156, %137
  %158 = fadd reassoc ninf nsz double %128, %157
  %159 = fmul reassoc ninf nsz double %150, %140
  %.neg.i.neg.i.neg = fmul reassoc ninf nsz double %64, %54
  %.neg371.i.neg.i.neg = fmul reassoc ninf nsz double %93, %83
  %.neg372.i.neg.i.neg = fmul reassoc ninf nsz double %123, %113
  %.neg373.i.neg.i.neg = fmul reassoc ninf nsz double %153, %143
  %reass.add = fadd reassoc ninf nsz double %.neg371.i.neg.i.neg, %.neg.i.neg.i.neg
  %reass.add1 = fadd reassoc ninf nsz double %reass.add, %.neg372.i.neg.i.neg
  %reass.add2 = fadd reassoc ninf nsz double %reass.add1, %.neg373.i.neg.i.neg
  %160 = fadd reassoc ninf nsz double %99, %69
  %161 = fadd reassoc ninf nsz double %160, %129
  %162 = fadd reassoc ninf nsz double %161, %159
  %163 = fsub reassoc ninf nsz double %162, %reass.add2
  %164 = fmul reassoc ninf nsz double %150, %143
  %165 = fmul reassoc ninf nsz double %153, %140
  %166 = fadd reassoc ninf nsz double %70, %71
  %167 = fadd reassoc ninf nsz double %166, %101
  %168 = fadd reassoc ninf nsz double %167, %100
  %169 = fadd reassoc ninf nsz double %168, %131
  %170 = fadd reassoc ninf nsz double %169, %130
  %171 = fadd reassoc ninf nsz double %170, %165
  %172 = fadd reassoc ninf nsz double %171, %164
  %173 = fcmp reassoc ninf nsz ogt double %137, 0.000000e+00
  %174 = fadd reassoc ninf nsz double %107, %48
  br i1 %173, label %true_block.i.i, label %false_block.i.i

true_block.i.i:                                   ; preds = %36
  %175 = fmul reassoc ninf nsz double %174, 5.000000e-01
  %176 = fadd reassoc ninf nsz double %137, %77
  %177 = fmul reassoc ninf nsz double %176, 5.000000e-01
  %178 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %175, double %177)
  br label %after_if.i.i

false_block.i.i:                                  ; preds = %36
  %179 = fadd reassoc ninf nsz double %174, %77
  %180 = fmul reassoc ninf nsz double %179, 5.000000e-01
  %181 = fsub reassoc ninf nsz double %180, %48
  %182 = fsub reassoc ninf nsz double %180, %77
  %183 = fmul reassoc ninf nsz double %181, %182
  %184 = fsub reassoc ninf nsz double %180, %107
  %185 = fmul reassoc ninf nsz double %183, %184
  %186 = fdiv reassoc ninf nsz double %185, %180
  %187 = tail call double @llvm.sqrt.f64(double %186)
  br label %after_if.i.i

after_if.i.i:                                     ; preds = %false_block.i.i, %true_block.i.i
  %.04.i.i = phi double [ %178, %true_block.i.i ], [ %187, %false_block.i.i ]
  %188 = bitcast i8* %scevgep37 to double*
  %189 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %40, double 1.000000e-03)
  %190 = fmul reassoc ninf nsz double %189, 9.810000e+00
  %191 = tail call double @llvm.sqrt.f64(double %190)
  %192 = fadd reassoc ninf nsz double %191, %41
  %193 = fdiv reassoc ninf nsz double %.04.i.i, %192
  %194 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %193, double 5.000000e-01)
  %195 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %194, double 5.000000e-02)
  %scevgep41 = getelementptr double, double* %188, i64 -207234
  %196 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %scevgep41, i32 64)
  %197 = fdiv reassoc ninf nsz double %195, %196
  %198 = fmul reassoc ninf nsz double %197, %158
  %199 = fsub reassoc ninf nsz double %40, %198
  %200 = tail call reassoc ninf nsz double @llvm.maxnum.f64(double %199, double 1.000000e-03)
  %201 = fcmp reassoc ninf nsz ogt double %200, 1.000000e-03
  br i1 %201, label %true_block1.i.i, label %function_body.exit.i

true_block1.i.i:                                  ; preds = %after_if.i.i
  %202 = fcmp reassoc ninf nsz ugt double %200, 1.000000e-02
  br i1 %202, label %false_block5.i.i, label %true_block4.i.i

true_block4.i.i:                                  ; preds = %true_block1.i.i
  %203 = tail call double @llvm.fabs.f64(double %41)
  %204 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %203, double 1.000000e-03)
  %205 = fcmp reassoc ninf nsz olt double %41, 0.000000e+00
  %neg.i.i = fneg reassoc ninf nsz double %204
  %206 = select reassoc ninf nsz i1 %205, double %neg.i.i, double %204
  %207 = tail call double @llvm.fabs.f64(double %42)
  %208 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %207, double 1.000000e-03)
  %209 = fcmp reassoc ninf nsz olt double %42, 0.000000e+00
  %neg7.i.i = fneg reassoc ninf nsz double %208
  %210 = select reassoc ninf nsz i1 %209, double %neg7.i.i, double %208
  br label %function_body.exit.i

false_block5.i.i:                                 ; preds = %true_block1.i.i
  %211 = bitcast i8* %scevgep37 to double*
  %212 = fmul reassoc ninf nsz double %41, %40
  %213 = fmul reassoc ninf nsz double %42, %40
  %214 = tail call reassoc ninf nsz double @llvm.nvvm.ldg.global.f.f64.p0f64(double* %211, i32 64)
  %215 = fmul reassoc ninf nsz double %41, %41
  %216 = fmul reassoc ninf nsz double %42, %42
  %217 = fadd reassoc ninf nsz double %216, %215
  %218 = tail call double @llvm.sqrt.f64(double %217)
  %219 = tail call i32 @llvm.nvvm.d2i.hi(double %40)
  %220 = tail call double @llvm.fabs.f64(double %40)
  %221 = tail call i32 @llvm.nvvm.d2i.hi(double %220)
  %222 = tail call i32 @llvm.nvvm.d2i.lo(double %220)
  %223 = lshr i32 %221, 20
  %224 = icmp ult i32 %221, 1048576
  %225 = fmul double %220, 0x4350000000000000
  %226 = tail call i32 @llvm.nvvm.d2i.hi(double %225)
  %227 = tail call i32 @llvm.nvvm.d2i.lo(double %225)
  %228 = lshr i32 %226, 20
  %229 = add nsw i32 %228, -54
  %ilo.0.i.i.i.i.i = select i1 %224, i32 %227, i32 %222
  %ihi.0.i.i.i.i.i = select i1 %224, i32 %226, i32 %221
  %expo.0.i.i.i.i.i = select i1 %224, i32 %229, i32 %223
  %230 = and i32 %ihi.0.i.i.i.i.i, -2146435073
  %231 = or i32 %230, 1072693248
  %232 = tail call double @llvm.nvvm.lohi.i2d(i32 %ilo.0.i.i.i.i.i, i32 %231)
  %233 = icmp ugt i32 %231, 1073127582
  %234 = tail call i32 @llvm.nvvm.d2i.lo(double %232)
  %235 = tail call i32 @llvm.nvvm.d2i.hi(double %232)
  %236 = add i32 %235, -1048576
  %237 = tail call double @llvm.nvvm.lohi.i2d(i32 %234, i32 %236)
  %m.0.i.i.i.i.i = select i1 %233, double %237, double %232
  %expo.1.i.v.i.i.i.i = select i1 %233, i32 -1022, i32 -1023
  %expo.1.i.i.i.i.i = add nsw i32 %expo.1.i.v.i.i.i.i, %expo.0.i.i.i.i.i
  %238 = fadd double %m.0.i.i.i.i.i, -1.000000e+00
  %239 = fadd double %m.0.i.i.i.i.i, 1.000000e+00
  %240 = tail call double @llvm.nvvm.rcp.approx.ftz.d(double %239)
  %241 = fneg double %239
  %242 = tail call double @llvm.fma.f64(double %241, double %240, double 1.000000e+00)
  %243 = tail call double @llvm.fma.f64(double %242, double %242, double %242)
  %244 = tail call double @llvm.fma.f64(double %243, double %240, double %240)
  %245 = fmul double %238, %244
  %246 = fadd double %245, %245
  %247 = fmul double %246, %246
  %248 = tail call double @llvm.fma.f64(double %247, double 0x3EB0F5FF7D2CAFE2, double 0x3ED0F5D241AD3B5A)
  %249 = tail call double @llvm.fma.f64(double %248, double %247, double 0x3EF3B20A75488A3F)
  %250 = tail call double @llvm.fma.f64(double %249, double %247, double 0x3F1745CDE4FAECD5)
  %251 = tail call double @llvm.fma.f64(double %250, double %247, double 0x3F3C71C7258A578B)
  %252 = tail call double @llvm.fma.f64(double %251, double %247, double 0x3F6249249242B910)
  %253 = tail call double @llvm.fma.f64(double %252, double %247, double 0x3F89999999999DFB)
  %254 = fmul double %247, %253
  %255 = fsub double %238, %246
  %256 = fmul double %255, 2.000000e+00
  %257 = fneg double %246
  %258 = tail call double @llvm.fma.f64(double %257, double %238, double %256)
  %259 = fmul double %244, %258
  %260 = fadd double %254, 0x3FB5555555555555
  %261 = fsub double 0x3FB5555555555555, %260
  %262 = fadd double %254, %261
  %263 = fadd double %262, 0.000000e+00
  %264 = fadd double %263, 0xBC46A4CB00B9E7B0
  %265 = fadd double %260, %264
  %266 = fsub double %260, %265
  %267 = fadd double %264, %266
  %268 = fneg double %247
  %269 = tail call double @llvm.fma.f64(double %246, double %246, double %268)
  %270 = tail call i32 @llvm.nvvm.d2i.lo(double %259)
  %271 = tail call i32 @llvm.nvvm.d2i.hi(double %259)
  %272 = add i32 %271, 1048576
  %273 = tail call double @llvm.nvvm.lohi.i2d(i32 %270, i32 %272)
  %274 = tail call double @llvm.fma.f64(double %246, double %273, double %269)
  %275 = fmul double %246, %247
  %276 = fneg double %275
  %277 = tail call double @llvm.fma.f64(double %247, double %246, double %276)
  %278 = tail call double @llvm.fma.f64(double %247, double %259, double %277)
  %279 = tail call double @llvm.fma.f64(double %274, double %246, double %278)
  %280 = fmul double %275, %265
  %281 = fneg double %280
  %282 = tail call double @llvm.fma.f64(double %265, double %275, double %281)
  %283 = tail call double @llvm.fma.f64(double %265, double %279, double %282)
  %284 = tail call double @llvm.fma.f64(double %267, double %275, double %283)
  %285 = fadd double %280, %284
  %286 = fsub double %280, %285
  %287 = fadd double %284, %286
  %288 = fadd double %246, %285
  %289 = fsub double %246, %288
  %290 = fadd double %285, %289
  %291 = fadd double %287, %290
  %292 = fadd double %259, %291
  %293 = fadd double %288, %292
  %294 = fsub double %288, %293
  %295 = fadd double %292, %294
  %296 = xor i32 %expo.1.i.i.i.i.i, -2147483648
  %297 = tail call double @llvm.nvvm.lohi.i2d(i32 %296, i32 1127219200)
  %298 = fsub double %297, %9
  %299 = tail call double @llvm.fma.f64(double %298, double 0x3FE62E42FEFA39EF, double %293)
  %300 = fneg double %298
  %301 = tail call double @llvm.fma.f64(double %300, double 0x3FE62E42FEFA39EF, double %299)
  %302 = fsub double %301, %293
  %303 = fsub double %295, %302
  %304 = tail call double @llvm.fma.f64(double %298, double 0x3C7ABC9E3B39803F, double %303)
  %305 = fadd double %299, %304
  %306 = fsub double %299, %305
  %307 = fadd double %304, %306
  %308 = fmul double %14, %305
  %309 = fneg double %308
  %310 = tail call double @llvm.fma.f64(double %305, double %14, double %309)
  %311 = tail call double @llvm.fma.f64(double %307, double %14, double %310)
  %312 = fadd double %308, %311
  %313 = tail call double @llvm.fma.f64(double %312, double 0x3FF71547652B82FE, double 0x4338000000000000)
  %314 = tail call i32 @llvm.nvvm.d2i.lo(double %313)
  %315 = fadd double %313, 0xC338000000000000
  %316 = tail call double @llvm.fma.f64(double %315, double 0xBFE62E42FEFA39EF, double %312)
  %317 = tail call double @llvm.fma.f64(double %315, double 0xBC7ABC9E3B39803F, double %316)
  %318 = tail call double @llvm.fma.f64(double %317, double 0x3E5ADE1569CE2BDF, double 0x3E928AF3FCA213EA)
  %319 = tail call double @llvm.fma.f64(double %318, double %317, double 0x3EC71DEE62401315)
  %320 = tail call double @llvm.fma.f64(double %319, double %317, double 0x3EFA01997C89EB71)
  %321 = tail call double @llvm.fma.f64(double %320, double %317, double 0x3F2A01A014761F65)
  %322 = tail call double @llvm.fma.f64(double %321, double %317, double 0x3F56C16C1852B7AF)
  %323 = tail call double @llvm.fma.f64(double %322, double %317, double 0x3F81111111122322)
  %324 = tail call double @llvm.fma.f64(double %323, double %317, double 0x3FA55555555502A1)
  %325 = tail call double @llvm.fma.f64(double %324, double %317, double 0x3FC5555555555511)
  %326 = tail call double @llvm.fma.f64(double %325, double %317, double 0x3FE000000000000B)
  %327 = tail call double @llvm.fma.f64(double %326, double %317, double 1.000000e+00)
  %328 = tail call double @llvm.fma.f64(double %327, double %317, double 1.000000e+00)
  %329 = tail call i32 @llvm.nvvm.d2i.lo(double %328)
  %330 = tail call i32 @llvm.nvvm.d2i.hi(double %328)
  %331 = shl i32 %314, 20
  %332 = add i32 %330, %331
  %333 = tail call double @llvm.nvvm.lohi.i2d(i32 %329, i32 %332)
  %334 = tail call i32 @llvm.nvvm.d2i.hi(double %312)
  %335 = bitcast i32 %334 to float
  %336 = tail call float @llvm.fabs.f32(float %335)
  %337 = fcmp uge float %336, 0x4010C46560000000
  br i1 %337, label %__internal_fast_icmp_abs_lt.exit.i.i.i.i.i, label %__internal_accurate_pow.exit.i.i.i

__internal_fast_icmp_abs_lt.exit.i.i.i.i.i:       ; preds = %false_block5.i.i
  %338 = fcmp olt double %312, 0.000000e+00
  %339 = fadd double %312, 0x7FF0000000000000
  %z.0.i.i.i.i.i = select i1 %338, double 0.000000e+00, double %339
  %340 = fcmp olt float %336, 0x4010E90000000000
  br i1 %340, label %341, label %__internal_accurate_pow.exit.i.i.i

341:                                              ; preds = %__internal_fast_icmp_abs_lt.exit.i.i.i.i.i
  %342 = sdiv i32 %314, 2
  %343 = shl i32 %342, 20
  %344 = add i32 %330, %343
  %345 = tail call double @llvm.nvvm.lohi.i2d(i32 %329, i32 %344)
  %346 = sub nsw i32 %314, %342
  %347 = shl i32 %346, 20
  %348 = add nsw i32 %347, 1072693248
  %349 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %348)
  %350 = fmul double %349, %345
  br label %__internal_accurate_pow.exit.i.i.i

__internal_accurate_pow.exit.i.i.i:               ; preds = %341, %__internal_fast_icmp_abs_lt.exit.i.i.i.i.i, %false_block5.i.i
  %z.2.i.i.i.i.i = phi double [ %333, %false_block5.i.i ], [ %350, %341 ], [ %z.0.i.i.i.i.i, %__internal_fast_icmp_abs_lt.exit.i.i.i.i.i ]
  %351 = icmp eq i32 %8, 1126170624
  %352 = icmp slt i32 %219, 0
  %spec.select.i.i.i = select i1 %352, i1 %351, i1 false
  %353 = fcmp oeq double %40, 0.000000e+00
  br i1 %353, label %354, label %359

354:                                              ; preds = %__internal_accurate_pow.exit.i.i.i
  %355 = icmp slt i32 %7, 0
  %356 = icmp eq i32 %8, 1126170624
  %spec.select1.i.i.i = select i1 %356, i32 %219, i32 0
  %357 = or i32 %spec.select1.i.i.i, 2146435072
  %thi.1.i.i.i = select i1 %355, i32 %357, i32 %spec.select1.i.i.i
  %358 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.1.i.i.i)
  br label %374

359:                                              ; preds = %__internal_accurate_pow.exit.i.i.i
  %360 = icmp slt i32 %219, 0
  %361 = tail call i32 @llvm.nvvm.d2i.hi(double %z.2.i.i.i.i.i)
  %362 = and i32 %361, 2147483647
  %363 = icmp ne i32 %362, 2146435072
  %364 = tail call i32 @llvm.nvvm.d2i.lo(double %z.2.i.i.i.i.i)
  %365 = icmp ne i32 %364, 0
  %366 = select i1 %363, i1 true, i1 %365
  %367 = fsub double %308, %312
  %368 = fadd double %311, %367
  %369 = tail call double @llvm.fma.f64(double %z.2.i.i.i.i.i, double %368, double %z.2.i.i.i.i.i)
  %tmp.0.i.i.i.i = select i1 %366, double %369, double %z.2.i.i.i.i.i
  %370 = tail call i32 @llvm.nvvm.d2i.lo(double %tmp.0.i.i.i.i)
  %371 = tail call i32 @llvm.nvvm.d2i.hi(double %tmp.0.i.i.i.i)
  %372 = xor i32 %371, -2147483648
  %373 = tail call double @llvm.nvvm.lohi.i2d(i32 %370, i32 %372)
  %t.0.i.i.i = select i1 %spec.select.i.i.i, double %373, double %tmp.0.i.i.i.i
  %t.1.i.i.i = select i1 %360, double 0xFFF8000000000000, double %t.0.i.i.i
  br label %374

374:                                              ; preds = %359, %354
  %t.2.i.i.i = phi double [ %358, %354 ], [ %t.1.i.i.i, %359 ]
  %375 = fadd double %40, 3.333300e-01
  %376 = tail call i32 @llvm.nvvm.d2i.hi(double %375)
  %377 = and i32 %376, 2146435072
  %378 = icmp eq i32 %377, 2146435072
  br i1 %378, label %379, label %__nv_pow.exit.i.i

379:                                              ; preds = %374
  %380 = fcmp ugt double %220, 0x7FF0000000000000
  br i1 %380, label %__nv_pow.exit.i.i, label %__nv_isinfd.exit5.i.i.i

__nv_isinfd.exit5.i.i.i:                          ; preds = %379
  br i1 %19, label %381, label %__nv_isinfd.exit.i.i.i

381:                                              ; preds = %__nv_isinfd.exit5.i.i.i
  %382 = icmp slt i32 %7, 0
  %383 = fcmp ogt double %220, 1.000000e+00
  %thi.2.i.i.i = select i1 %383, i32 2146435072, i32 0
  %384 = xor i32 %thi.2.i.i.i, 2146435072
  %thi.3.i.i.i = select i1 %382, i32 %384, i32 %thi.2.i.i.i
  %385 = fcmp oeq double %40, -1.000000e+00
  %thi.4.i.i.i = select i1 %385, i32 1072693248, i32 %thi.3.i.i.i
  %386 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.4.i.i.i)
  br label %__nv_pow.exit.i.i

__nv_isinfd.exit.i.i.i:                           ; preds = %__nv_isinfd.exit5.i.i.i
  %387 = tail call i32 @llvm.nvvm.d2i.lo(double %40)
  %388 = and i32 %219, 2147483647
  %389 = icmp eq i32 %388, 2146435072
  %390 = icmp eq i32 %387, 0
  %391 = select i1 %389, i1 %390, i1 false
  %thi.6.i.i.i = select i1 %spec.select.i.i.i, i32 %20, i32 %spec.select8.i.i.i
  %392 = tail call double @llvm.nvvm.lohi.i2d(i32 0, i32 %thi.6.i.i.i)
  %spec.select2.i.i.i = select i1 %391, double %392, double %t.2.i.i.i
  br label %__nv_pow.exit.i.i

__nv_pow.exit.i.i:                                ; preds = %__nv_isinfd.exit.i.i.i, %381, %379, %374
  %t.6.i.i.i = phi double [ %t.2.i.i.i, %374 ], [ %386, %381 ], [ %375, %379 ], [ %spec.select2.i.i.i, %__nv_isinfd.exit.i.i.i ]
  %393 = fcmp oeq double %40, 1.000000e+00
  %t.7.i.i.i = select i1 %393, double 1.000000e+00, double %t.6.i.i.i
  %394 = fmul reassoc ninf nsz double %218, 5.000000e-01
  %395 = fmul reassoc ninf nsz double %394, %214
  %396 = fdiv reassoc ninf nsz double %395, %t.7.i.i.i
  %.neg377.i.neg.i.neg = fmul reassoc ninf nsz double %197, %163
  %.neg378.i.neg.i.neg = fmul reassoc ninf nsz double %396, %41
  %reass.add3 = fadd reassoc ninf nsz double %.neg378.i.neg.i.neg, %.neg377.i.neg.i.neg
  %397 = fsub reassoc ninf nsz double %212, %reass.add3
  %398 = fdiv reassoc ninf nsz double %397, %200
  %.neg380.i.neg.i.neg = fmul reassoc ninf nsz double %197, %172
  %.neg381.i.neg.i.neg = fmul reassoc ninf nsz double %396, %42
  %reass.add5 = fadd reassoc ninf nsz double %.neg381.i.neg.i.neg, %.neg380.i.neg.i.neg
  %399 = fsub reassoc ninf nsz double %213, %reass.add5
  %400 = fdiv reassoc ninf nsz double %399, %200
  %401 = tail call double @llvm.fabs.f64(double %398)
  %402 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %401, double 5.000000e+00)
  %403 = fcmp reassoc ninf nsz olt double %398, 0.000000e+00
  %neg8.i.i = fneg reassoc ninf nsz double %402
  %404 = select reassoc ninf nsz i1 %403, double %neg8.i.i, double %402
  %405 = tail call double @llvm.fabs.f64(double %400)
  %406 = tail call reassoc ninf nsz double @llvm.minnum.f64(double %405, double 5.000000e+00)
  %407 = fcmp reassoc ninf nsz olt double %400, 0.000000e+00
  %neg9.i.i = fneg reassoc ninf nsz double %406
  %408 = select reassoc ninf nsz i1 %407, double %neg9.i.i, double %406
  br label %function_body.exit.i

function_body.exit.i:                             ; preds = %__nv_pow.exit.i.i, %true_block4.i.i, %after_if.i.i
  %.03.i.i = phi double [ %206, %true_block4.i.i ], [ %404, %__nv_pow.exit.i.i ], [ 0.000000e+00, %after_if.i.i ]
  %.0.i.i = phi double [ %210, %true_block4.i.i ], [ %408, %__nv_pow.exit.i.i ], [ 0.000000e+00, %after_if.i.i ]
  %409 = bitcast i8* %scevgep37 to double*
  %410 = fadd reassoc ninf nsz double %200, %43
  %sunkaddr54 = getelementptr i8, i8* %scevgep37, i64 -13262976
  %411 = bitcast i8* %sunkaddr54 to double*
  store double %200, double* %411, align 8
  %sunkaddr55 = getelementptr i8, i8* %scevgep37, i64 -11605104
  %412 = bitcast i8* %sunkaddr55 to double*
  store double %.03.i.i, double* %412, align 8
  %sunkaddr56 = getelementptr i8, i8* %scevgep37, i64 -9947232
  %413 = bitcast i8* %sunkaddr56 to double*
  store double %.0.i.i, double* %413, align 8
  %scevgep36 = getelementptr double, double* %409, i64 -1036170
  store double %410, double* %scevgep36, align 8
  %414 = fmul reassoc ninf nsz double %.03.i.i, %.03.i.i
  %415 = fmul reassoc ninf nsz double %.0.i.i, %.0.i.i
  %416 = fadd reassoc ninf nsz double %415, %414
  %417 = tail call double @llvm.sqrt.f64(double %416)
  %scevgep33 = getelementptr double, double* %409, i64 -828936
  store double %417, double* %scevgep33, align 8
  %418 = add nuw nsw i32 %.07.i, %22
  %lsr.iv.next = add i32 %lsr.iv, %26
  %lsr.iv.next8 = add nuw i64 %lsr.iv7, %35
  %419 = icmp ult i32 %418, 207234
  br i1 %419, label %36, label %gpu_parallel_range_for.exit, !llvm.loop !19

gpu_parallel_range_for.exit:                      ; preds = %function_body.exit.i, %entry
  ret void
}

; Function Attrs: argmemonly nocallback nofree nounwind readonly
declare double @llvm.nvvm.ldg.global.f.f64.p0f64(double* nocapture, i32) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.minnum.f64(double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.maxnum.f64(double, double) #2

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

!nvvm.annotations = !{!0, !1, !2, !3, !4, !3, !5, !5, !5, !5, !6, !6, !5}
!llvm.ident = !{!7}
!nvvmir.version = !{!8}
!llvm.module.flags = !{!9, !10, !11, !12, !13, !14}

!0 = !{void (%struct.RuntimeContext.346*)* @update_cell_c82_0_kernel_0_range_for, !"kernel", i32 1}
!1 = !{void (%struct.RuntimeContext.346*)* @update_cell_c82_0_kernel_0_range_for, !"maxntidx", i32 128}
!2 = !{void (%struct.RuntimeContext.346*)* @update_cell_c82_0_kernel_0_range_for, !"minctasm", i32 2}
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
!18 = !{i32 1, i32 -2147483648}
!19 = distinct !{!19, !20}
!20 = !{!"llvm.loop.mustprogress"}
