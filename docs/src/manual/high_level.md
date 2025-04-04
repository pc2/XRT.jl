# High Level Abstractions for Kernel Executions

Based on the [`XRT.Xclbin`](@ref) type and our [Custom XCLBIN Parser](@ref), XRT.jl provide a macro to generate ready-to-use functions for the execution of individual kernels in the bitstream:
[`@prepare_bitstream`](@ref)

This function will create several functions for each kernel in the provided bitstream.
In addition to the functions for the kernels, functions are also created for their compute units so that a CU can specifically be addressed.
For convenience, it is recommended to execute the macro in a new module.

```Julia
module KernelModule
    using XRT
    @prepare_bitstream("path/to/bitstream.xclbin")
end
```

Assume that our `bitstream.xclbin` does now contain one kernel `testkernel` with to compute units `cu1` and `cu2`.
The execution described above then generates the following functions:

- `KernelModule.testkernel!(...)`
- `KernelModule.testkernel__cu1!(...)`
- `KernelModule.testkernel__cu2!(...)`

As you can see, compute units can be addressed directly with double underscores.
Any function created includes type annotations, which ensures a correct execution.
The available kernels and their compute units can be analyzed by using the interface described in [The `Xclbin` Type](@ref) section.

Kernels can then be executed by calling the function with the required input parameters.
If the input parameter is an `AbstractArray`, it will be automatically copied to the FPGA memory before execution and back after execution.
For performance reasons, a specific synchronization direction can also be set for copying the arrays.
To achieve this, the array must be declared as a [`ToDeviceArray`](@ref) or a [`FromDeviceArray`](@ref), depending on whether it should be used as an input or output parameter.
These array types can be used like a conventional Julia array.

Further assume that our `testkernel` requires one input and one output array as first and second parameters, respectively.
The array types can be used for this:

```Julia
# Declare one array only for synchronisation to the device 
# and the other only for synchronisation to the host
input = ToDeviceArray{Float64}(MemAlign(4096), array_size)
output = FromDeviceArray{Float64}(MemAlign(4096), array_size)

# Initialize the arrays
input[:] .= rand(array_size)
output[:] .= 0

TestStreamModule.testkernel!(input, output)
```

All generated functions come with a keyword parameter `device` which can be used to specify the device the kernel should be executed on.
If the keyword parameter `device` is not set, the device currently set as active will be used.

```Julia
julia> TestStreamModule.testkernel!(input, output; device=XRT.device(2))
```

If the bitstream is not already programmed on the device, this will be done automatically before executing the kernel.

See [Example: Auto-generated Kernel Interfaces](@ref) and [Example: STREAM Benchmark](@ref) for examples of how this approach can be used to execute compute kernels on the FPGA.

## Type-Safe `Run` Objects

In general an [`XRT.Run`](@ref) element is used to execute kernels with given arguments.
A problem with this element is that it does not contain any type checks and thus no type safety.
XRT.jl provides the macro [`@prepare_run`](@ref) that creates kernel-adapted `Run` elements, which include the type signature for the arguments of a given kernel.

As with the other macro, it is advised to execute this macro in a separate module as a scope for the customized run function.
With its execution, the macro does return the [`XRT.Kernel`](@ref) and `XRT.UUID` objects, which are instantiated during the procedure.

```Julia
module RunModule
    using XRT
    kernel, uuid = @prepare_run("path/to/bitstream.xclbin", "testkernel")
end
```

This execution does now generate the following function:

- `RunModule.Run_testkernel(arg1::Arg1Type, arg2::Arg2Type...; autostart=true)`
- `RunModule.Run_testkernel__optional_cu(arg1::Arg1Type, arg2::Arg2Type...; autostart=true)` in the case that the compute unit was specified in the macro

Compared to the [`XRT.Run`](@ref) function, it is noticeable that the `kernel::XRT.Kernel` argument is missing, as it is already integrated in the new function.

See [Make it Type-Safe](@ref) for an example with practical application.

## Automatic Buffer Synchronization

Usually, when using the thin wrapper, all required buffer objects must be copied to or from the FPGA device.
This is done by manually calling the [`XRT.sync!`](@ref) function.
A feature that enables automatic buffer synchronization when using the functions provided by the thin wrapper and thus makes manual synchronization unnecessary, is the [`XRT.@sync_buffers`](@ref) macro.

The macro is called with an expression that contains at least one started [`XRT.Run`](@ref) object:

```Julia
julia> XRT.@sync_buffers XRT.Run(testkernel, xinput, xoutput)

# XRT.@sync_buffers macro analogously replaces the following code block
sync!(xinput, XRT.TO_DEVICE)
sync!(xoutput, XRT.TO_DEVICE)

r = XRT.Run(testkernel, xinput, xoutput)
wait(r)

sync!(xinput, XRT.FROM_DEVICE)
sync!(xoutput, XRT.FROM_DEVICE)
```

or with a block of expressions:

```Julia
julia> XRT.@sync_buffers begin 
    # ...some code
    XRT.Run(testkernel, xinput, xoutput)
    # ...more code
    begin
        # ...nested code
        r = XRT.Run(another_testkernel, another_xinput, another_xoutput)
    end
    # ...plenty code
    end
```

The macro will then search the expression for `XRT.Run` objects, if needed, adds a unique name to them, and then inserts [`XRT.wait`](@ref) calls after the expression.
In addition, the parameters of the `XRT.Run` function are evaluated, and `sync!` calls are inserted before and after the expression if a parameter contains an `XRT.AbstractBOArray`.

The synchronization direction can be defined as follows:

- To define a specific synchronization direction for the entire expression, set either `XRT.TO_DEVICE` or `XRT.FROM_DEVICE` as `direction` keyword argument before the expression. The not-selected synchronization direction must then be handled manually. **Note: In the latter case, the system does not automatically wait for the run objects to be completed.**

```Julia
julia> XRT.@sync_buffers direction=XRT.FROM_DEVICE XRT.Run(testkernel, xinput, xoutput)
```

- To select only a specific synchronization direction for individual `AbstractBOArrays`, [`XRT.ToDeviceBOArray`](@ref) and [`XRT.FromDeviceBOArray`](@ref) objects can be used. These can be handled like normal `XRT.BOArray` objects, but can only be synchronized in one direction. Alternatively, the `AbstractSyncDirectionWrapper` type can be used. See [Restricting Synchronization Direction](@ref) for a detailed insight.

See [Automatic buffer synchronization](@ref) and [Example: Automatic Buffer Synchronization](@ref) for practical examples.
