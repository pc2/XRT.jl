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
if (NOT WIN32 AND NOT EXISTS ${LIB_UUID_DIR})
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

if (WIN32)
  # XRT's Windows headers (e.g. xrt_elf.h) carry inline definitions of functions
  # marked dllimport, which GCC rejects. XRT_API_SOURCE switches XRT's API macros
  # to their dllexport form, matching how XRT itself is compiled for Windows.
  target_compile_definitions(xrtwrap PRIVATE _WINDOWS XRT_API_SOURCE)
  target_compile_options(xrtwrap PRIVATE -fpermissive)
endif ()

# XRT >= 2.20 relocated its public headers from ${XILINX_XRT}/include/{experimental,
# version.h} down into ${XILINX_XRT}/include/xrt/. Keep the flat include root for
# older XRT and add the nested one for newer XRT; the layout that doesn't exist for
# a given XRT install just contributes nothing.
target_include_directories(xrtwrap PRIVATE ${XILINX_XRT}/include ${LIB_BOOST_DIR}/include)
if (EXISTS ${XILINX_XRT}/include/xrt)
  target_include_directories(xrtwrap PRIVATE ${XILINX_XRT}/include/xrt)
endif ()

# Newer XRT packages install the runtime libraries under lib64 rather than lib.
target_link_directories(xrtwrap PRIVATE ${XILINX_XRT}/lib ${LIB_BOOST_DIR}/lib)
if (EXISTS ${XILINX_XRT}/lib64)
  target_link_directories(xrtwrap PRIVATE ${XILINX_XRT}/lib64)
endif ()

# cxxwrap_julia_stl carries the jlcxx::stl wrappers (StlWrappers::instance et al.)
# that jlcxx/stl.hpp uses to wrap std::deque etc. Linux shared libs resolve it
# lazily at load time, but the Windows DLL link needs it named explicitly.
target_link_libraries(xrtwrap PRIVATE
  JlCxx::cxxwrap_julia
  JlCxx::cxxwrap_julia_stl
  xrt_coreutil
)

# libuuid is Linux-only: XRT's xrt_uuid.h pulls in <uuid/uuid.h> there, whereas on
# Windows XRT uses the OS RPC UUID facilities and no libuuid exists.
if (NOT WIN32)
  target_include_directories(xrtwrap PRIVATE ${LIB_UUID_DIR}/include)
  target_link_directories(xrtwrap PRIVATE ${LIB_UUID_DIR}/lib)
  target_link_libraries(xrtwrap PRIVATE uuid)
endif ()

set_property(TARGET xrtwrap PROPERTY POSITION_INDEPENDENT_CODE ON)
# On Linux, XRT.jl loads the wrapper by a versioned name (libxrtwrap.so.<ver>).
# On Windows, keep the native libxrtwrap.dll so the JLL's LibraryProduct finds it.
if (NOT WIN32)
  set_property(TARGET xrtwrap PROPERTY SUFFIX ".so.${XRT_VERSION_NUMBER}")
endif ()

install(TARGETS xrtwrap DESTINATION lib)
