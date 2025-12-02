include_guard(GLOBAL)

set(ZIG_TOOLCHAIN_VERSION "0.1.0")

if(CMAKE_GENERATOR MATCHES "Visual Studio")
  message(FATAL_ERROR "Zig Toolchain: Visual Studio generator is not supported. Please use '-G Ninja' or '-G MinGW Makefiles'.")
endif()

find_program(ZIG_COMPILER zig)
if(NOT ZIG_COMPILER)
  message(FATAL_ERROR "Zig Toolchain: Zig compiler not found. Please install Zig and ensure it is in your PATH.")
endif()

execute_process(
  COMMAND zig version
  OUTPUT_VARIABLE ZIG_COMPILER_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE ZIG_VERSION_RESULT
)
if(NOT ZIG_VERSION_RESULT EQUAL 0)
  message(FATAL_ERROR "Zig Toolchain: Zig compiler found but failed to get version.")
endif()

if(NOT ZIG_TARGET)
  if(NOT CMAKE_SYSTEM_NAME)
    set(CMAKE_SYSTEM_NAME "${CMAKE_HOST_SYSTEM_NAME}")
  endif()
  if(NOT CMAKE_SYSTEM_PROCESSOR)
    set(CMAKE_SYSTEM_PROCESSOR "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  endif()

  string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" Z_ARCH)
  if(Z_ARCH MATCHES "arm64|aarch64")
    set(Z_ARCH "aarch64")
  elseif(Z_ARCH MATCHES "x64|x86_64|amd64")
    set(Z_ARCH "x86_64")
  endif()

  string(TOLOWER "${CMAKE_SYSTEM_NAME}" Z_OS)
  set(Z_ABI "gnu")
  if(Z_OS MATCHES "darwin|macos")
    set(Z_OS "macos")
    set(Z_ABI "none")
  elseif(Z_OS MATCHES "windows")
    set(Z_OS "windows")
  elseif(Z_OS MATCHES "linux")
    set(Z_OS "linux")
  endif()

  set(ZIG_TARGET "${Z_ARCH}-${Z_OS}-${Z_ABI}")
endif()

if(ZIG_TARGET MATCHES "^-") 
  message(FATAL_ERROR "Zig Toolchain: ZIG_TARGET is not set. Please specify it manually using -DZIG_TARGET=...")
else()
  message(STATUS "Zig Toolchain: v${ZIG_COMPILER_VERSION} → ${ZIG_TARGET}")
endif()

if(ZIG_TARGET MATCHES "windows")
  set(CMAKE_SYSTEM_NAME Windows)
elseif(ZIG_TARGET MATCHES "linux")
  set(CMAKE_SYSTEM_NAME Linux)
elseif(ZIG_TARGET MATCHES "macos")
  set(CMAKE_SYSTEM_NAME Darwin)
endif()

set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR ${Z_ARCH})

option(ZIG_USE_CCACHE "Enable ccache optimization for Zig toolchain" OFF)
set(ZIG_CC_PREFIX "")
if(ZIG_USE_CCACHE)
  find_program(CCACHE_TOOL ccache)
  if(CCACHE_TOOL)
    set(ZIG_CC_PREFIX "${CCACHE_TOOL} ")
    message(STATUS "Zig Toolchain: ccache enabled at ${CCACHE_TOOL}")
  else()
    message(WARNING "Zig Toolchain: ZIG_USE_CCACHE is ON but 'ccache' was not found in PATH.")
  endif()
endif()

set(ZIG_SHIMS_DIR "${CMAKE_BINARY_DIR}/.zig-shims")
file(MAKE_DIRECTORY "${ZIG_SHIMS_DIR}")
if(CMAKE_HOST_WIN32)
  set(EXT ".cmd")
  set(HEADER "@echo off")
  set(ARGS "%*")
else()
  set(EXT "")
  set(HEADER "#!/bin/sh")
  set(ARGS "\"$@\"")
endif()

file(WRITE "${ZIG_SHIMS_DIR}/zig-cc${EXT}" "${HEADER}\n${ZIG_CC_PREFIX}zig cc -target ${ZIG_TARGET} ${ARGS}\n")
file(WRITE "${ZIG_SHIMS_DIR}/zig-c++${EXT}" "${HEADER}\n${ZIG_CC_PREFIX}zig c++ -target ${ZIG_TARGET} ${ARGS}\n")
file(WRITE "${ZIG_SHIMS_DIR}/zig-ar${EXT}" "${HEADER}\nzig ar ${ARGS}\n")
file(WRITE "${ZIG_SHIMS_DIR}/zig-rc${EXT}" "${HEADER}\nzig rc ${ARGS}\n")
file(WRITE "${ZIG_SHIMS_DIR}/zig-ranlib${EXT}" "${HEADER}\nzig ranlib ${ARGS}\n")
if(NOT CMAKE_HOST_WIN32)
  execute_process(COMMAND chmod +x 
    "${ZIG_SHIMS_DIR}/zig-cc" 
    "${ZIG_SHIMS_DIR}/zig-c++"
    "${ZIG_SHIMS_DIR}/zig-ar"
    "${ZIG_SHIMS_DIR}/zig-rc"
    "${ZIG_SHIMS_DIR}/zig-ranlib"
  )
endif()

set(CMAKE_C_COMPILER "${ZIG_SHIMS_DIR}/zig-cc${EXT}")
set(CMAKE_CXX_COMPILER "${ZIG_SHIMS_DIR}/zig-c++${EXT}")
set(CMAKE_AR "${ZIG_SHIMS_DIR}/zig-ar${EXT}" CACHE FILEPATH "Archiver" FORCE)
set(CMAKE_RANLIB "${ZIG_SHIMS_DIR}/zig-ranlib${EXT}" CACHE FILEPATH "Ranlib" FORCE)
if(CMAKE_SYSTEM_NAME MATCHES "Windows")
  set(CMAKE_RC_COMPILER "${ZIG_SHIMS_DIR}/zig-rc${EXT}" CACHE FILEPATH "Resource Compiler" FORCE)
endif()
