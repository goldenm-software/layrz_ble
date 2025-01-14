cmake_minimum_required(VERSION 3.10)

# Set the project name
project(LayrzBlePlugin)

# Add the source file
set(SOURCES LayrzBlePlugin.cpp)

# Add the executable
add_library(LayrzBlePlugin SHARED ${SOURCES})

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Link libraries (if any)
# target_link_libraries(LayrzBlePlugin <library_name>)

# Set output directory for the DLL
set_target_properties(LayrzBlePlugin PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
)