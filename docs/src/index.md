# XRT.jl

## Installation

**Note: Only Linux and Windows x86_64 systems are supported!**

The package is not registered. You can use
```
] add https://github.com/pc2/XRT.jl
```
to add the package to your Julia environment.

The following dependencies have to be installed to use XRT.jl:

- A C++ Compiler
- CMake +3.5
- Xilinx Vitis for features like software or hardware emulation

XRT is contained in the `xrt_jll` package in version 2.17.
If a native installation of XRT should be used, set the `XILINX_XRT` environment variable to the path of the local installation.
XRT with the native C++ interface +2.14 are supported.