cmake_minimum_required(VERSION 3.14)
project(shared_lib_demo C)

include_directories(include)

add_library(mylib SHARED lib.c)
add_executable(shared_app main.c)
target_link_libraries(shared_app mylib)
