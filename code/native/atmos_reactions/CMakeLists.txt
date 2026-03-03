cmake_minimum_required(VERSION 3.10)
project(atmos_reactions CXX)

set(CMAKE_CXX_STANDARD 17)

add_library(atmos_reactions STATIC
  reactions.cpp
)
target_include_directories(atmos_reactions PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# Optional: build standalone test executable
option(ATMOS_REACTIONS_BUILD_TEST "Build test executable" OFF)
if(ATMOS_REACTIONS_BUILD_TEST)
  add_executable(atmos_reactions_test test_runner.cpp)
  target_link_libraries(atmos_reactions_test PRIVATE atmos_reactions)
  target_include_directories(atmos_reactions_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
endif()
