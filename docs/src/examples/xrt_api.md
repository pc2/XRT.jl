# Example: Wrapper for native XRT C++ API

This module consists of a thin wrapper around the [XRT native C++ API](https://xilinx.github.io/XRT/master/html/xrt_native_apis.html).
Assume we have a synthesized bitstream with the following kernel:

```C++
void dummyKernel(char* a, char validate, int count) {
    for (int i=0; i<count; i++) {
        a[i] = validate;
    }
}
```

The kernel can be executed as follows using the one-to-one wrapped functions from the native C++ API:

```Julia
using XRT
# Get a FPGA device by index
d = XRT.XRTWrap.Device(1)
# Load the Bitstream on the device
uuid = load_xclbin!(d, "path/to/communication_PCIE.xclbin")
# Create a kernel instance for a kernel in the loaded bitstream
dummy = XRT.Kernel(d, uuid, "dummyKernel")

# Create device buffer and write data to buffer
# Use the memory bank of the selected kernel instance by calling group_id
a = Array{UInt8}(MemAlign(4096), 1)
xa = XRT.BOArray(d, a, group_id(dummy, 0))
sync!(xa, XRT.TO_DEVICE)

# Execute kernel
r = XRT.Run(dummy, xa, UInt8(1), 1)
# Wait kernel to complete execution
wait(r)
# Read back and validate output data
sync!(xa, XRT.FROM_DEVICE)
@assert all(xa .== UInt8(1))
```

**Note: Indexing of devices using the wrapped `XRT.XRTWrap.Device` constructor starts at 0!**

## Automatic use of the active device

To make this execution procedure a little more convenient, the device set globally as active can be used.
At first, it must be set at the beginning.
If no device has been set, the first device detected by XRT.jl is implicitly used.
In the following example the kernel will be executed on the same device as in the previous example.
The function uses a Julia-typical count starting at 1:

```Julia
using XRT
# Globally set an active FPGA device
XRT.device!(2)

# Load the Bitstream on the device
uuid = load_xclbin!("path/to/communication_PCIE.xclbin")
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

## Automatic buffer synchronization

To simplify this procedure even further, the synchronization of the buffer objects can be arranged automatically.

```Julia
using XRT
# Globally set an active FPGA device
XRT.device!(2)

# Load the Bitstream on the device
uuid = load_xclbin!("path/to/communication_PCIE.xclbin")
# Create a kernel instance for a kernel in the loaded bitstream
dummy = XRT.Kernel(uuid, "dummyKernel")

# Create device buffer and write data to buffer
# Use the memory bank of the selected kernel instance by calling group_id
a = Array{UInt8}(MemAlign(4096), 1)
xa = XRT.BOArray(a, group_id(dummy, 0))

# Execute kernel
XRT.@sync_buffers XRT.Run(dummy, xa, UInt8(1), 1)

# Validate output data
@assert all(xa .== UInt8(1))
```

## Make it Type-Safe

As another step the kernel loading process can be replaced.
This does also create a type-safe Run function for the `dummyKernel`.

**Note: The macro was not executed in a separate module due to its compactness!**

```Julia
using XRT
# Globally set an active FPGA device
XRT.device!(2)

# Loading the bitstream and generating kernel-adapted Run function
dummy, _ = @prepare_run("path/to/communication_PCIE.xclbin", "dummyKernel")

# Create device buffer and write data to buffer
# Use the memory bank of the selected kernel instance by calling group_id
a = Array{UInt8}(MemAlign(4096), 1)
xa = XRT.BOArray(a, group_id(dummy, 0))

# Execute kernel
XRT.@sync_buffers Run_dummyKernel(xa, UInt8(1), Int32(1))

# Validate output data
@assert all(xa .== UInt8(1))
```

As one can see, `UInt32(1)` is required as the execution without this cast throws the following exception:

```Julia
julia> XRT.@sync_buffers Run_dummyKernel(xa, UInt8(1), 1)
MethodError: no method matching Run_dummyKernel(::XRT.BOArray{UInt8, 1}, ::UInt8, ::UInt32)

Closest candidates are:
  Run_dummyKernel(::Union{XRT.AbstractBOArray{UInt8}, XRT.AbstractSyncDirectionWrapper}, ::UInt8, ::Int32; autostart)
  ...
```
