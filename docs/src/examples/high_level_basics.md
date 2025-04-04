# Example: Auto-generated Kernel Interfaces

This example executes a kernel on the FPGA that takes one buffer as output and two scalar values as input.
The `@prepare_bitstream` macro can be used to generate Julia functions for all kernels implemented in the bitstream by parsing its metadata.
Buffer synchronization is handled automatically by XRT.jl.
For more information refer to [High Level Abstractions for Kernel Executions](@ref).

An example code for the execution of a kernel `dummyKernel` like this:

```C++
void dummyKernel(char* a, char validate, int count) {
    for (int i=0; i<count; i++) {
        a[i] = validate;
    }
}
```

The synthesized kernel can be executed on an FPGA like this:

```Julia
using XRT

# Allocate an output array
a = Array{UInt8}(MemAlign(4096), 1)

# Create a module that should contain the generated functions of the bitstream
module Bitstream
    using XRT
    @prepare_bitstream("path/to/communication_PCIE.xclbin")
end

# execute the dummyKernel kernel on the currently set device
Bitstream.dummyKernel!(a, UInt8(1), Int32(1))

# or instead execute the dummyKernel kernel on another detected device
# Bitstream.dummyKernel!(a, UInt8(1), Int32(1); device=XRT.device(3))

# validate the execution results
@assert all(a .== UInt8(1))
```

Optionally, a specific compute unit, also called `dummyKernel`, can be exeucuted instead:

```Julia
Bitstream.dummyKernel__dummyKernel!(a, UInt8(0), Int32(1))

@assert all(a .== UInt8(0))
```
