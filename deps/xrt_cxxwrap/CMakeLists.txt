cmake_minimum_required(VERSION 3.5)
project(XRTWrap)

find_package(JlCxx REQUIRED)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

# XRT
if (NOT EXISTS ${XILINX_XRT})
  message(FATAL_ERROR "Xilinx XRT not found, make sure to source setup.sh")
endif ()
if (NOT EXISTS ${LIB_UUID_DIR})
  message(FATAL_ERROR "No path to libuuid directory given!")
endif ()
if (NOT EXISTS ${LIB_BOOST_DIR})
  message(FATAL_ERROR "No path to boost directory given!")
endif ()

message(STATUS "Use XRT install in ${XILINX_XRT}")
message(STATUS "Use UUID libraries in ${LIB_UUID_DIR}")
message(STATUS "Use Boost libraries in ${LIB_BOOST_DIR}")

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH};${LIB_BOOST_DIR}/lib")

add_library(xrtwrap SHARED ${CMAKE_SOURCE_DIR}/src/xrtwrap.cpp)

target_include_directories(xrtwrap PRIVATE ${XILINX_XRT}/include ${LIB_UUID_DIR}/include ${LIB_BOOST_DIR}/include)

target_link_directories(xrtwrap PRIVATE ${XILINX_XRT}/lib ${LIB_UUID_DIR}/lib ${LIB_BOOST_DIR}/lib)

target_link_libraries(xrtwrap PRIVATE
  JlCxx::cxxwrap_julia
  uuid
  xrt_coreutil
)

set_property(TARGET xrtwrap PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET xrtwrap PROPERTY SUFFIX ".so.${XRT_VERSION_NUMBER}")

install(TARGETS xrtwrap DESTINATION lib)
