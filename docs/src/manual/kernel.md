# The `Kernel` Type

An [`XRT.Kernel`](@ref) object is required to execute a kernel that has previously been loaded onto a device (see [Loading an Xclbin onto a Device](@ref)).
Using the obtained `UUID` and the kernel name, a `Kernel` object can then be created for the device.
Again, the device can be manually set using the `device` keyword argument.

```Julia
julia> kernel = XRT.Kernel(xclbin_uuid, "kernel_name")
```

In addition, certain compute units can be specified on which the kernel is executed.
The compute units are specified in curly brackets:

```Julia
julia> kernel = XRT.Kernel(xclbin_uuid, "kernel_name:{cu1_name,cu2_name}")
```

As an alternative to the name, an [`XRT.XclbinKernel`](@ref) object can also be assigned.

## The `Run` Type

As in the XRT API, executing the kernel object is associated with an [`XRT.Run`](@ref) object.
This function takes the kernel object as well as all kernel arguments.

```Julia
julia> r = XRT.Run(kernel, args...)
```

Then, the kernel execution starts on the device asynchronously.
However, execution can be started manually by setting the `autostart` keyword argument to `false` and using the `XRT.start` function with the `Run` object.
To synchronize the kernel execution with the Julia program, the [`XRT.wait`](@ref) function is required.

```Julia
julia> wait(r)
```

Using the [`XRT.set_arg!`](@ref) and [`XRT.set_args!`](@ref) functions, the kernel arguments can be set for another kernel execution if needed.

## The `IP` Type

XRT.jl does also support creating [`XRT.IP`](@ref) objects, which have to be managed through the user by reading or writing registers.

See [User Managed Kernels](@ref) in the API references.