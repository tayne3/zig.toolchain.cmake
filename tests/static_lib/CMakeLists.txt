cmake_minimum_required(VERSION 3.14)
project(static_lib_demo C)

include_directories(include)

add_library(mylib STATIC lib.c)
add_executable(static_app main.c)
target_link_libraries(static_app mylib)
