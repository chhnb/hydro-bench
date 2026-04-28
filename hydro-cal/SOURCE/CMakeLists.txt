cmake_minimum_required(VERSION 3.16)
project(hydro_cal LANGUAGES CXX CUDA)

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)

# ============================================================
# 1. 启用 CUDA 支持
# ============================================================
enable_language(CUDA)

# ============================================================
# CUDA 架构配置
# ============================================================
# 支持通过命令行指定架构，例如：
#   cmake -DCMAKE_CUDA_ARCHITECTURES="70;75;80;86" ..
# 或者使用 "native" 自动检测当前 GPU，或 "all" 支持所有架构
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    # 默认自动检测当前系统的 GPU 架构
    set(CMAKE_CUDA_ARCHITECTURES "native")
    message(STATUS "CUDA architectures not specified, using 'native' (auto-detect)")
else()
    message(STATUS "CUDA architectures specified: ${CMAKE_CUDA_ARCHITECTURES}")
endif()

# 常见架构参考：
# - 60: Pascal (P100)
# - 70: Volta (V100)
# - 75: Turing (T4, RTX 20xx)
# - 80: Ampere (A100)
# - 86: Ampere (RTX 30xx, A40)
# - 89: Ada Lovelace (RTX 40xx, L40)
# - 90: Hopper (H100)

message(STATUS "Found CUDA toolkit: ${CMAKE_CUDA_COMPILER_VERSION}")

# ============================================================
# 2. 搜索源文件（cpp + cu）
# ============================================================
file(GLOB SRC_FILES
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/*.cu"
)

# ============================================================
# 3. 编译可执行文件
# ============================================================
add_executable(hydro_cal ${SRC_FILES})

# ============================================================
# 4. 头文件目录
# ============================================================
target_include_directories(hydro_cal PRIVATE 
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
)

# ============================================================
# 5. CUDA 编译选项
# ============================================================
# C++ 编译选项
target_compile_options(hydro_cal PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-Wall -Wextra>
)

# CUDA 编译选项
set_property(TARGET hydro_cal PROPERTY CUDA_SEPARABLE_COMPILATION ON)
target_compile_options(hydro_cal PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler -fPIC>
)

# Debug 模式添加调试选项
if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RELWITHDEBINFO")
    target_compile_options(hydro_cal PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:-G -g>
    )
endif()

# ============================================================
# 6. 打印构建信息
# ============================================================
message(STATUS "CMake build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "CUDA version: ${CMAKE_CUDA_COMPILER_VERSION}")
message(STATUS "CUDA architectures: ${CMAKE_CUDA_ARCHITECTURES}")
