# Buffer Objects

In order to transfer data between host and devices, XRT primarily uses buffers in the form of `BO` (Buffer Object).
These `BO` need to be allocated on an available device's memory bank depending on the kernel argument.
Then, they can be synchronized to and from the device.

## The `BOArray` Type

XRT.jl offers an extended version of `BO`, the [`XRT.BOArray`](@ref), which additionally supports indexing and automatic alignment of the buffer as it must be aligned to 4K boundary.

The simplest way to create a `BOArray` object is to prepare an `AbstractArray` with the required user data and pass it to the `BOArray` constructor together with the desired memory bank index:

```Julia
julia> a = Array{Float64}(MemAlign(4096), array_size); a .= 1.0

julia> xa = XRT.BOArray(a, group_id(kernel, 0))
```

In this example the `Array` is optionally aligned using the `MemAlign` function from the [ArrayAllocators.jl](https://github.com/mkitti/ArrayAllocators.jl) package, which is reexported by XRT.jl.
The array can also be instantiated as usual.
Alignment is then performed by XRT.jl.

> It is important to correctly set the right memory bank index. This can be done via the `group_id` function that takes the kernel object and the kernel argument index starting at 0. Alternatively, a memory bank id, obtained by the `memory` report, can directly be specified.

To allocate the buffer on a device other than the one currently selected, the `device` keyword argument can be used.
It is also possible to set a `flag` as a keyword argument for creating special buffers (see [Official XRT Documentation](https://xilinx.github.io/XRT/master/html/xrt_native_apis.html#creating-special-buffers)).

The `BOArray` must then be transferred explicitly.
This is done with the [`XRT.sync!`](@ref) function and the corresponding synchronization direction, which can be found in the `XRT.BOSyncDirection` module:

```
julia> sync!(xa, XRT.TO_DEVICE)
```

## Restricting Synchronization Direction

Some functions used for [High Level Abstractions for Kernel Executions](@ref) handle the automatic synchronization of buffers.
However, this always happens in both directions, which can lead to unnecessary data transfers.
XRT.jl offers at least two options to avoid this.

### The `AbstractSyncDirectionArray` and the `AbstractBOArray` Type

In addition to the `BOArray` and `AbstractArray` types, there are also [`XRT.ToDeviceBOArray`](@ref)/[`XRT.FromDeviceBOArray`](@ref) or [`XRT.ToDeviceArray`](@ref)/[`XRT.FromDeviceArray`](@ref) types in XRT.jl.
A `BOArray`/`AbstractArray` can be instantiated as these types and thus restricts the respective synchronization direction of the user data.

In addition, a `BOArray` can also be converted as required:

```Julia
julia> todevice_xa = convert(XRT.ToDeviceBOArray, xa)
```

### The `AbstractSyncDirectionWrapper` Type

Another way to restrict the synchronization direction is to wrap the `AbstractArray` or the `BOArray` by either an [`XRT.ToDeviceWrapper`](@ref) object or an [`XRT.FromDeviceWrapper`](@ref).
These wrapper types guarantee that synchronization only happens in the specified direction:

```Julia
julia> XRT.Run(XRT.ToDeviceWrapper(input), XRT.FromDeviceWrapper(output),...)
```