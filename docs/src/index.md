# XRT.jl

## Installation

**Note: Only Linux and Windows x86_64 systems are supported!**

The package is not registered. You can use
```
] add https://github.com/pc2/XRT.jl
```
to add the package to your Julia environment.

The following dependencies have to be installed to use XRT.jl:

- Xilinx Vitis for features like software or hardware emulation

XRT is contained in the `xrt_jll` package in version 2.17.
If a native installation of XRT should be used, set the `XILINX_XRT` environment variable to the path of the local installation.
XRT with the native C++ interface +2.14 are supported.

## Known Issues

- The build in XRT implementation is unable to find a device even when Vitis HLS is installed and the `XCL_EMULATION_MODE` variable is set.
