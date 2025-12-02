cmake_minimum_required(VERSION 3.14)
project(test_fixture C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_library(c_shared_lib SHARED src/shared_lib.c)
target_include_directories(c_shared_lib PUBLIC include)
target_compile_definitions(c_shared_lib PRIVATE shared_lib_EXPORTS)

add_library(c_static_lib STATIC src/static_lib.c)
target_include_directories(c_static_lib PUBLIC include)

add_library(cxx_shared_lib SHARED src/shared_lib.cpp)
target_include_directories(cxx_shared_lib PUBLIC include)
target_compile_definitions(cxx_shared_lib PRIVATE shared_lib_EXPORTS)

add_library(cxx_static_lib STATIC src/static_lib.cpp)
target_include_directories(cxx_static_lib PUBLIC include)

add_executable(c_app src/main.c)
target_link_libraries(c_app c_shared_lib c_static_lib)
add_executable(cxx_app src/main.cpp)
target_link_libraries(cxx_app c_shared_lib c_static_lib cxx_shared_lib cxx_static_lib)

if(WIN32)
  target_sources(c_app PRIVATE resource.rc)
  target_sources(cxx_app PRIVATE resource.rc)
endif()
