<div align="center">

![zig.toolchain.cmake](assets/logo.svg)

# zig.toolchain.cmake

[![Release](https://img.shields.io/github/v/release/tayne3/zig.toolchain.cmake?include_prereleases&label=release&logo=github&logoColor=white)](https://github.com/tayne3/zig.toolchain.cmake/releases)
[![Tag](https://img.shields.io/github/v/tag/tayne3/zig.toolchain.cmake?color=%23ff8936&style=flat-square&logo=git&logoColor=white)](https://github.com/tayne3/zig.toolchain.cmake/tags)
[![Tests](https://github.com/tayne3/zig.toolchain.cmake/actions/workflows/test.yml/badge.svg)](https://github.com/tayne3/zig.toolchain.cmake/actions/workflows/test.yml)
![CMake](https://img.shields.io/badge/CMake-3.14%2B-brightgreen?logo=cmake&logoColor=white)

[English](README.md) | **中文**

</div>

一个轻量级的 CMake 工具链文件,利用 Zig 实现 C/C++ 项目的交叉编译,无需安装各平台的 GCC 工具链。

## 使用方法

**前置条件**

- CMake 3.14+
- Zig 编译器

**集成**

将 `zig.toolchain.cmake` 下载到你的项目根目录或 `cmake/` 子目录中。

```bash
curl -o zig.toolchain.cmake https://github.com/tayne3/zig.toolchain.cmake/releases/download/v0.1.1/zig.toolchain.cmake
```

**交叉编译**

使用标准 CMake 变量即可满足常见需求,如需精确控制 ABI（如 `musl` vs `gnu`）可直接指定 `ZIG_TARGET`。

*编译 Linux ARM64:*

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=zig.toolchain.cmake \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64

cmake --build build
```

*编译 Windows x64:*

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=zig.toolchain.cmake \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=x86_64
```

*编译 Linux x86_64 (Musl/Static):*

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=zig.toolchain.cmake \
  -DZIG_TARGET=x86_64-linux-musl
```
