<div align="center">
    <img width="150px" src="./docs/src/assets/logo_default.svg" alt="XRT Logo">
    <h1><b>XRT.jl</b></h1>
    <p><i>Julia Wrapper for the XRT native C++ API</i></p>
</div>

<br>

[XRT](https://www.xilinx.com/products/design-tools/vitis/xrt.html#overview) is a runtime for Xilinx AI Engines and FPGA platforms.
It comes with native APIs for C, C++, Python, and OpenCL.
This wrapper targets the native C++ API to allow kernel scheduling, bitstream analysis, and more via XRT directly from Julia code.
[CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) is used to wrap the C++ library.

## Installation

**Prerequisites** for the use of XRT.jl:

- [Xilinx Vitis](https://www.xilinx.com/support/download.html) for features such as software or hardware emulation
- XRT is contained in the [`xrt_jll.jl`](https://github.com/JuliaBinaryWrappers/xrt_jll.jl) package in version 2.17.
A version with XRT v2.16 is available in [this](https://github.com/DO6LTM/xrt_jll.jl) repository.
Both versions allow the execution of kernels but they are still not fully functional.
It is therefore recommended to use a native XRT installation.
To do so, the environment variable `XILINX_XRT` must be set to the path of the local installation.
XRT with the native C++ interface +2.14 is supported.

XRT.jl can be installed via the Julia package manager:

```
] add XRT
```

### Usage on HPC cluster

To use XRT.jl on an HPC cluster, like the [Noctua 2](https://pc2.uni-paderborn.de/systems-and-services/noctua-2) supercomputer, following modules have to be loaded:

- For the use with a native XRT installation:

```bash
module load lang JuliaHPC fpga xilinx/xrt
```

- For the use with the built-in `xrt_jll` installation:

```bash
module load lang JuliaHPC fpga xilinx/vitis/24.1
```

## Example

This example executes a kernel on the FPGA that takes one buffer as output and two scalar values as input.
The `@prepare_bitstream` macro can be used to generate Julia functions for all kernels implemented in the bitstream by parsing its meta data.
Buffer synchronisation is handled automatically by XRT.jl.
An example code for the execution of a kernel `dummyKernel` in the bitstream is given below:

```Julia
using XRT

# Allocate an output array
a = Array{UInt8}(MemAlign(4096), 1)

# Generate functions for each kernel in the bitstream. 
# Do this in a separate module for convenience
module Bitstream
    using XRT
    @prepare_bitstream("communication_PCIE.xclbin")
end

# Program the bitstream to the active device and execute the kernel
Bitstream.dummyKernel!(a, UInt8(1), 1)

# validate the execution results
@assert all(a .== UInt8(1))
```
The same execution can also be written on a lower level with direct control over buffer synchronisation:

```Julia
using XRT
# Set a active FPGA device (default 1) 
XRT.device!(1)

# Load the Bitstream on the device
uuid = load_xclbin!("communication_PCIE.xclbin")
# Create a kernel instance for a kernel in the loaded bitstream
dummy = XRT.Kernel(uuid, "dummyKernel")

# Create device buffer and write data to buffer
# Use the memory bank of the selected kernel instance by calling group_id
a = Array{UInt8}(MemAlign(4096), 1)
xa = XRT.BOArray(a, group_id(dummy, 0))
sync!(xa, XRT.TO_DEVICE)

# Execute kernel
r = XRT.Run(dummy, xa, UInt8(1), 1)
# Wait kernel to complete execution
wait(r)

# Read back and validate output data
sync!(xa, XRT.FROM_DEVICE)
@assert all(xa .== UInt8(1))
```

## Documentation

More information on the installation, the usage of XRT.jl, and further examples can be found in the [documentation](https://pc2.github.io/XRT.jl).
