# Julia Wrapper for the XRT native C++ API

The [XRT.jl](https://github.com/pc2/XRT.jl) package allows user-friendly and interactive interaction with Xilinx FPGA accelerators.
The package allows the usage of the functions provided by the native XRT C++ API but also provides several abstraction layers, such as an automatic kernel detection or buffer synchronization.

[XRT](https://www.xilinx.com/products/design-tools/vitis/xrt.html#overview) is a runtime for Xilinx AI Engines and FPGA platforms.
It comes with native APIs for C++, C, Python and OpenCL.
This wrapper targets the C++ API to allow kernel scheduling, bitstream analysis, and more via XRT directly from Julia code.
[CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) is used to wrap the C++ library.

## Quick Start

The XRT.jl package comes with a built-in installation of XRT 2.17 using the [`xrt_jll`](https://github.com/JuliaBinaryWrappers/xrt_jll.jl) package.

```Julia
# install the package
using Pkg
Pkg.add("XRT")
```

Various tests can be performed to ensure the functionality of the package.

```Julia
# test the package
using Pkg
Pkg.test("XRT"; test_args=["--quick"])
```

For more details in the installation process, please see the [Installation](@ref) section.
In the following sections, the functionality of the interface is then presented.

### Executing a Kernel

After successful installation, a kernel can be executed as follows on the first available device.

```Julia
# Load the Bitstream on the device and create kernel instance
uuid = load_xclbin!("path/to/bitstream.xclbin")
kernel = XRT.Kernel(uuid, "kernel_name")

# Create buffer objects
a = Array{UInt8}(MemAlign(4096), 1)
xa = XRT.BOArray(a, group_id(kernel, 0))

# Load input data
sync!(xa, XRT.TO_DEVICE)

# Execute kernel and wait to complete execution
r = XRT.Run(kernel, xa, UInt8(1), 1)
wait(r)

# Read back output data
sync!(xa, XRT.FROM_DEVICE)
```

A more detailed view on the components needed for execution can as well as different abstraction layers can be found in the Manual.
Further examples can be found in the [Example: Wrapper for native XRT C++ API](@ref) section.
