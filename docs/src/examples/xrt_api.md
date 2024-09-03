# Wrapper for native XRT C++ API

This module consists of a thin wrapper around the [XRT native C++ API](https://xilinx.github.io/XRT/master/html/xrt_native_apis.html).
Assume we have a synthesized bitstream with the following kernel:

```C++
void dummyKernel(char* a, char validate, int count) {
    for (int i=0; i<count; i++) {
        a[i] = validate;
    }
}
```

The kernel can be executed as follows:

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