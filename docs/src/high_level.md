# High Level Abstractions for Kernel Executions

Based on our [Custom XCLBIN Parser](@ref), XRT.jl provides a method to generate ready-to-use functions for
the execution of individual kernels in the bitstream: `prepare_bitstream(path; device)`.

This function will create a new module with a function for each kernel in the provided bitstream and load the bitstream on
an FPGA device.
Kernels can then be executed by calling the function with the required input parameters. If the input parameter is an `AbstractArray`,
it will be automatically copied to the FPGA memory before execution and back after execution.

See [Example: Auto-generated Kernel Interfaces](@ref) and [Example: STREAM Benchmark](@ref) for examples, how this approach can be
used to execute compute kernels on the FPGA.

