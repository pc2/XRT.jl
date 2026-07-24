import .XRTWrap: Kernel, Run, BO, group_id, offset, get_name, set_arg!, wait, start
using .XRTWrap.ComputeUnitAccessMode: SHARED, EXCLUSIVE, NONE

"""
$(TYPEDSIGNATURES)

Register `xclbin` with `device` and open a hardware context on it, returning the context
and the xclbin's uuid.

This is how an AIE device (an NPU) loads a design; [`load_xclbin!`](@ref) is the path for
Alveo cards. Pass the context to [`Kernel`](@ref) to address a kernel by name.
"""
function hw_context(xclbin::Xclbin; device::XilinxDevice=device())
    uuid = XRTWrap.register_xclbin(device.device, xclbin.xclbin)
    return XRTWrap.HwContext(device.device, uuid), uuid
end

"""
```Julia
Kernel(uuid::XRT.XRTWrap.UUID, name::AbstractString; device::XilinxDevice=device())
Kernel(uuid::XRT.XRTWrap.UUID, name::AbstractString, cus::Vararg{AbstractString}; device::XilinxDevice=device())
Kernel(uuid::XRT.XRTWrap.UUID, kernel::XclbinKernel, cus::Vararg{XclbinIP}; device::XilinxDevice=device())

```

Create a new kernel instance using a bitstream uuid and kernel name or [`XRT.XclbinKernel`](@ref) object.
Optionally, the compute units to be executed can also be specified.
To create the kernel on a device other than the current active device, use the `device` keyword parameter or set a wrapped device as first parameter.
"""
function Kernel(device::XRTWrap.Device, uuid::UUID, name::AbstractString; cu_access_mode::XRTWrap.ComputeUnitAccessMode.Type=SHARED)
    Kernel(device, uuid, name, cu_access_mode)
end

function Kernel(uuid::UUID, name::AbstractString; device::XilinxDevice=device(), cu_access_mode::XRTWrap.ComputeUnitAccessMode.Type=SHARED)
    Kernel(device.device, uuid, name; cu_access_mode)
end

function Kernel(uuid::UUID, name::AbstractString, cus::Vararg{AbstractString}; device::XilinxDevice=device(), cu_access_mode::XRTWrap.ComputeUnitAccessMode.Type=SHARED)
    Kernel(device.device, uuid, "$(name):{$(join(cus, ","))}"; cu_access_mode)
end

function Kernel(uuid::UUID, kernel::XclbinKernel, cus::Vararg{XclbinIP}; device::XilinxDevice=device(), cu_access_mode::XRTWrap.ComputeUnitAccessMode.Type=SHARED)
    name = kernel.name
    cus_to_add = Vector{String}()
    for cu in cus
        if split(cu.name, ":")[1] == kernel.name
            push!(cus_to_add, cu.cu_name)
        end
    end
    
    if length(cus_to_add) > 0
        name *= ":{" * join(cus_to_add, ",") * "}"
    end

    Kernel(device.device, uuid, name; cu_access_mode)
end

"""
$(TYPEDSIGNATURES)

Execute a kernel with the given arguments.
To automatically start the execution, set `autostart` to `true`.
Otherwise, the execution has to be explicitly started by calling `start(run::Run)`
"""
function Run(kernel::Kernel, arg1, args...; autostart=true)
    k = Run(kernel)
    for (i, a) in enumerate(vcat([arg1], args...))
        set_arg!(k, i-1, a)
    end
    if autostart
        start(k)
    end
    k
end

"""
$(TYPEDSIGNATURES)

Execute a kernel with the given arguments and blocks until kernel execution completes.
Returns used `XRT.Run` object.
"""
function call(kernel::Kernel, arg1, args...)
    k = Run(kernel, arg1, args...)
    wait(k)
    k
end

"""
```Julia
set_arg!(run::XRT.XRTWrap.Run, index, val)
set_arg!(run::XRT.XRTWrap.Run, index, val::XRT.AbstractBOArray)
set_arg!(run::XRT.XRTWrap.Run, index, val::XRT.XRTWrap.BO)

```

Set the argument for a kernel at the given index.
Note, that this is a thin wrapper to the C++ API,
so the indices start at 0!
"""
# A buffer object argument goes to the wrapper's own set_arg!(::Run, ::Integer, ::BO)
# overload, which passes the object itself rather than its address, as the AIE path needs.
# This scalar fallback matches that overload's `run` type (Run or a CxxRef to one) so it is
# not more specific there; the buffer overload then wins outright for a buffer object.
function set_arg!(run::Union{Run, XRTWrap.CxxWrap.CxxWrapCore.CxxRef{<:Run}}, index, val)
    val_array = [val]
    set_arg!(run, index, Base.unsafe_convert(Ptr{Nothing},val_array), sizeof(eltype(val)))
end

function set_arg!(run::Run, index, val::AbstractBOArray)
    set_arg!(run, index, val.bo)
end

function set_arg!(run::Run, index, val::AbstractSyncDirectionWrapper)
    set_arg!(run, index, val.object)
end

"""
$(TYPEDSIGNATURES)

Sets multiple arguments for a kernel beginning at the first argument.
A kernel argument remains untouched if the new arg at the index is `nothing`.
"""
function set_args!(run::Run, args...)
    for (idx, a) in enumerate(args)
        if a != nothing
            set_arg!(run, i-1, a)
        end
    end
end

"""
$(TYPEDSIGNATURES)

Wait for a given [`Run`](@ref) object to complete execution.
The method will return as soon as the execution is completed.
"""
function wait(run::Run)
    wait(run, 0)
end

@doc """
```Julia
group_id(kernel::XRT.XRTWrap.Kernel, argno::Integer)

```

Get the memory bank group id to use when allocating buffers of an kernel argument.
The kernel argument index starts at 0!
""" group_id

@doc """
```Julia
offset(kernel::XRT.XRTWrap.Kernel, argno::Integer)

```

Get the kernel register offset of kernel argument.
The kernel argument index starts at 0!
""" offset

@doc """
```Julia
get_name(kernel::XRT.XRTWrap.Kernel)

```

Returns the name of the kernel
""" get_name

"""
$(TYPEDSIGNATURES)

Returns an [`XRT.Xclbin`](@ref) object containing the kernel.
"""
function get_xclbin(kernel::XRT.XRTWrap.Kernel)
    xclbin = XRTWrap.get_xclbin(kernel)
    XRT.Xclbin(xclbin, get_name(kernel))
end