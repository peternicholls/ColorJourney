cmake_minimum_required(VERSION 3.16)

project(ColorJourney 
    VERSION 1.0.0
    DESCRIPTION "ColorJourney C Core Library - OKLab-based color generation"
    LANGUAGES C)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Build options
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(ENABLE_TESTING "Enable test suite" ON)

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Compiler flags for optimization and warnings
if(MSVC)
    add_compile_options(/W4 /O2)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -O2)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(-fomit-frame-pointer)
    endif()
endif()

# Main library target
add_library(colorjourney
    Sources/CColorJourney/ColorJourney.c
)

# Public headers
target_include_directories(colorjourney
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Sources/CColorJourney/include>
        $<INSTALL_INTERFACE:include>
)

# Platform-specific settings
if(APPLE OR UNIX)
    # macOS/Linux/Unix
    set_target_properties(colorjourney PROPERTIES
        SOVERSION 1
        VERSION 1.0.0
    )
elseif(MSVC)
    # Windows/MSVC
    set_target_properties(colorjourney PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif()

# Export library as static by default
set_target_properties(colorjourney PROPERTIES
    PREFIX lib
)

# Testing support
if(ENABLE_TESTING)
    enable_testing()
    
    # Add C test harness if it exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Tests/CColorJourneyTests/test_c_core.c")
        add_executable(colorjourney_tests
            Tests/CColorJourneyTests/test_c_core.c
        )
        
        target_link_libraries(colorjourney_tests
            PRIVATE colorjourney
        )
        
        target_include_directories(colorjourney_tests
            PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CColorJourney/include
        )
        
        add_test(
            NAME C_Core_Tests
            COMMAND colorjourney_tests
        )
    endif()
endif()

# Installation targets
install(TARGETS colorjourney
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES Sources/CColorJourney/include/ColorJourney.h
    DESTINATION include
)

# Package configuration for CMake consumers
include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/CMakeConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/ColorJourneyConfig.cmake"
    INSTALL_DESTINATION lib/cmake/ColorJourney
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/ColorJourneyConfig.cmake"
    DESTINATION lib/cmake/ColorJourney
)

# Summary
if(BUILD_SHARED_LIBS)
    set(LIB_TYPE "Shared")
else()
    set(LIB_TYPE "Static")
endif()

message(STATUS "ColorJourney C Library Configuration:")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Library Type: ${LIB_TYPE}")
message(STATUS "  Testing: ${ENABLE_TESTING}")
message(STATUS "  C Standard: C${CMAKE_C_STANDARD}")
