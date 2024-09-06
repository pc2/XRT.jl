# High Level Abstractions for Kernel Executions

Based on our [Custom XCLBIN Parser](@ref), XRT.jl provides a macro to generate ready-to-use functions for
the execution of individual kernels in the bitstream: `@prepare_bitstream`.

This function will create a new module with a function for each kernel in the provided bitstream.
Kernels can then be executed by calling the function with the required input parameters. If the input parameter is an `AbstractArray`,
it will be automatically copied to the FPGA memory before execution and back after execution.
All generated function come with a keyworkd parameter `device` which can be used to specify the device the kernel should be executed on.
If the bitstream is not already programmed on the device, this will be done automatically before executing the kernel.

See [Example: Auto-generated Kernel Interfaces](@ref) and [Example: STREAM Benchmark](@ref) for examples, how this approach can be
used to execute compute kernels on the FPGA.

