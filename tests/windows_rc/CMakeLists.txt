cmake_minimum_required(VERSION 3.14)
project(windows_rc_demo C)

if(WIN32)
    # Create a dummy icon file if it doesn't exist (for testing purposes)
    if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/icon.ico")
        file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/icon.ico" "")
    endif()
    
    add_executable(rc_app main.c resource.rc)
else()
    message(STATUS "Skipping Windows RC test on non-Windows target")
    add_executable(rc_app main.c)
endif()
