# Julia Wrapper for the XRT native C++ API

[XRT](https://www.xilinx.com/products/design-tools/vitis/xrt.html#overview) is a runtime for Xilinx AI Engines and FPGA platforms. It comes with native APIs for C++, C, Python and OpenCL. This wrapper targets the
C++ API to allow kernel scheduling, bitstream analysis, and more via XRT directly from Julia code.
[CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) is used to wrap the C++ library.

## Example

This example executes a kernel on the FPGA that takes one buffer as output and
two scalar values as input.
The `prepare_bitstream` function can be used to generate Julia functions for all kernels implemented in the bitstream by parsing its meta data.
Buffer synchronization is handled automatically by XRT.jl.
An example code for the execution of a kernel `dummyKernel` in the bitstream is given below:

```Julia
using XRT
using ArrayAllocators

# Allocate an output array
a = Array{UInt8}(MemAlign(4096),1)

# Load the bitstream to the FPGA and generate functions 
# for each kernel
bs = XRT.prepare_bitstream("communication_PCIE.xclbin")

# execute the dummyKernel kernel
bs.dummyKernel!(a, UInt8(1),1)

# validate the execution results
@assert all(a .== UInt8(1))
```
The same execution can also be written on a lower level with direct control over buffer synchronization:

```Julia
using XRT
using ArrayAllocators
# Get a FPGA device
d = XRT.Device("0000:a1:00.1")
# Load the Bitstream on the device
uuid = load_xclbin!(d, "communication_PCIE.xclbin")
# Create a kernel instance for a kernel in the loaded bitstream
dummy = XRT.Kernel(d, uuid, "dummyKernel")

# Create device buffer and write data to buffer
# Use the memory bank of the selected kernel instance by calling
# group_id
a = Array{UInt8}(MemAlign(4096),1)
xa = XRT.BOArray(d, a, group_id(dummy, 0))
sync!(xa, XRT.XCL_BO_SYNC_BO_TO_DEVICE)

# Execute kernel
r = XRT.Run(dummy, xa, UInt8(1), 1)
# Wait kernel to complete execution
wait(r)
# Read back and validate output data
sync!(xa, XRT.XCL_BO_SYNC_BO_FROM_DEVICE)
@assert all(xa .== UInt8(1))
```

## Using the Package

The package is not in the official repositories. It can be istalled via

```Julia
using Pkg
Pkg.add("https://github.com/pc2/XRT.jl.git")
```

The following dependencies have to be installed to use XRT.jl:

- A C++ Compiler
- CMake +3.5
- Xilinx Vitis for features like software or hardware emulation

XRT is contained in the `xrt_jll` package in version 2.17.
If a native installation of XRT should be used, set the `XILINX_XRT` environment variable to the path of the local installation.
XRT with the native C++ interface +2.14 are supported.

Example for Noctua 2:

The following modules have to be loaded to use XRT.jl with the native XRT installation:

    module load lang JuliaHPC fpga xilinx/xrt devel CMake

or to use the build-in instalation:

    module load lang JuliaHPC fpga xilinx/vitis/24.1 devel CMake


