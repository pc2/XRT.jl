# Julia Wrapper for the XRT native C++ API

[XRT](https://www.xilinx.com/products/design-tools/vitis/xrt.html#overview) comes with native APIs for C++, C, Python and OpenCL. This wrapper targets the
C++ API to allow kernel scheduling via XRT directly from Julia code.
[CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) is used to wrap the C++ library.

## WIP

Currently, the wrapper does not contain the whole API!
It is possible to get a device, create kernels, custom IPs and XRT buffers, and execute
kernels. However, this should be sufficient for most tasks.

## Example

This example executes a kernel on the FPGA that takes one buffer as output and
two scalar values as input:

```Julia
using XRT
using ArrayAllocators
# Get a FPGA device
d = XRT.Device()
# Load the Bitstream on the device
uuid = load_xclbin(d, "communication_PCIE.xclbin")
# Create a kernel instance for a kernel in the loaded bitstream
dummy = XRT.Kernel(d, uuid, "dummyKernel")

# Create device buffer and write data to buffer
# Use the memory bank of the selected kernel instance by calling
# group_id
a = Array{UInt8}(MemAlign(4096),1)
xa = XRT.BOArray(d, a, group_id(dummy, 0))
sync(xa, XRT.XCL_BO_SYNC_BO_TO_DEVICE)

# Execute kernel
r = XRT.Run(dummy, xa, UInt8(1), Int(1))
# Wait kernel to complete execution
wait(r)
# Read back and validate output data
sync(xa, XRT.XCL_BO_SYNC_BO_FROM_DEVICE)
@assert all(xa .== UInt8(1))
```

