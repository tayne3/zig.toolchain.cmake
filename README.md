<div align="center">

![zig.toolchain.cmake](assets/logo.svg)

# zig.toolchain.cmake

[![Release](https://img.shields.io/github/v/release/tayne3/zig.toolchain.cmake?include_prereleases&label=release&logo=github&logoColor=white)](https://github.com/tayne3/zig.toolchain.cmake/releases)
[![Tag](https://img.shields.io/github/v/tag/tayne3/zig.toolchain.cmake?color=%23ff8936&style=flat-square&logo=git&logoColor=white)](https://github.com/tayne3/zig.toolchain.cmake/tags)
[![Tests](https://github.com/tayne3/zig.toolchain.cmake/actions/workflows/test.yml/badge.svg)](https://github.com/tayne3/zig.toolchain.cmake/actions/workflows/test.yml)
![CMake](https://img.shields.io/badge/CMake-3.14%2B-brightgreen?logo=cmake&logoColor=white)
![Zig](https://img.shields.io/badge/Zig-0.14.0%2B-blue?logo=zig&logoColor=white)

**English** | [中文](README_zh.md)

</div>

A lightweight CMake toolchain file that enables cross-compilation of C/C++ projects using Zig, eliminating the need to install platform-specific GCC toolchains.

## Usage

**Requirements**

- CMake 3.14+
- Zig Compiler

**Integration**

Download `zig.toolchain.cmake` to your project root or a `cmake/` subdirectory.

```bash
curl -o zig.toolchain.cmake https://github.com/tayne3/zig.toolchain.cmake/releases/download/v0.1.0/zig.toolchain.cmake
```

**Cross-Compilation**

Use standard CMake variables for common targets, or specify `ZIG_TARGET` directly when you need precise ABI control (e.g., `musl` vs `gnu`).

*Compile for Linux ARM64:*

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=zig.toolchain.cmake \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64

cmake --build build
```

*Compile for Windows x64:*

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=zig.toolchain.cmake \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=x86_64
```

*Compile for Linux x86_64 (Musl/Static):*

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=zig.toolchain.cmake \
  -DZIG_TARGET=x86_64-linux-musl
```
