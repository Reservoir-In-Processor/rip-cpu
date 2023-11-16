cmake_minimum_required(VERSION 3.14)
project(rip_cpu)

set(ALL_TESTS CACHE PATH "" FORCE)
add_subdirectory(test)
include(ProcessorCount)
ProcessorCount(N)
add_custom_target(test-all
  COMMAND ctest --test-dir ./test --output-on-failure -j ${N}
  DEPENDS test_all
)
# 