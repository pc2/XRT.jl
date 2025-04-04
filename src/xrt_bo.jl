import ..Base: size, length, getindex, setindex!, iterate
using .XRTWrap: BO, length, address, get_memory_group, get_flags, async!, sync!, map, read, write!, copy
using .XRTWrap.BOSyncDirection: FROM_DEVICE, TO_DEVICE
import XRT: write!, sync!, address, get_memory_group, get_flags

function write!(bo::BO, data)
    write!(bo, Base.unsafe_convert(Ptr{Nothing}, data))
end

function write!(bo::BO, data::Array, length; offset=0)
    val_size = sizeof(eltype(data))
    write!(bo, Base.unsafe_convert(Ptr{Nothing}, data), length * val_size, offset * val_size)
end

function read!(bo::BO, data)
    read!(bo, Base.unsafe_convert(Ptr{Nothing}, data))
end

function read!(bo::BO, data::Array, length; offset=0)
    val_size = sizeof(eltype(data))
    read!(bo, Base.unsafe_convert(Ptr{Nothing}, data), length * val_size, offset * val_size)
end

################################################################################
#                                    BOArray                                   #
################################################################################

abstract type AbstractBOArray{T,N} end

mutable struct BOArray{T,N} <: AbstractBOArray{T,N}
    bo::BO
    data::Array{T,N}
end

mutable struct ToDeviceBOArray{T,N} <: AbstractBOArray{T,N}
    bo::BO
    data::Array{T,N}
end

mutable struct FromDeviceBOArray{T,N} <: AbstractBOArray{T,N}
    bo::BO
    data::Array{T,N}
end

function getindex(b::AbstractBOArray, inds...)
    b.data[inds...]
end

function setindex!(b::AbstractBOArray, X, inds...)
    b.data[inds...] = X
end

function size(b::AbstractBOArray, d::Integer)
    size(b.data, d)
end

function size(b::AbstractBOArray)
    size(b.data)
end

function Base.length(b::AbstractBOArray)
    length(b.data)
end

"""
```Julia
sync!(b::AbstractBOArray, direction::XRTWrap.BOSyncDirection.Type)
sync!(w::AbstractSyncDirectionWrapper, direction::XRTWrap.BOSyncDirection.Type)

```

Synchronise buffer content in specified direction.
Use `BOArray` or `Array` with sync direction in type to prohibit a specific sync direction.
"""
function sync!(b::AbstractBOArray, direction::XRTWrap.BOSyncDirection.Type)
    XRT.sync!(b.bo, direction)
end

function sync!(b::ToDeviceBOArray, direction::XRTWrap.BOSyncDirection.Type)
    if direction == XRTWrap.BOSyncDirection.TO_DEVICE
        XRT.sync!(b.bo, direction)
    end
end

function sync!(b::FromDeviceBOArray, direction::XRTWrap.BOSyncDirection.Type)
    if direction == XRTWrap.BOSyncDirection.FROM_DEVICE
        XRT.sync!(b.bo, direction)
    end
end

function Base.convert(::Type{BO}, boa::AbstractBOArray)
    boa.bo
end

function Base.convert(::Type{T}, b::AbstractBOArray) where {T <: AbstractBOArray}
    T(b.bo, b.data)::T
end

iterate(b::AbstractBOArray) = iterate(b, 1)

function iterate(b::AbstractBOArray, state)
   if state <= length(b) 
        (b.data[state], state+1)
   else
        nothing
   end
end

function Base.lastindex(b::AbstractBOArray)
    Base.lastindex(b.data)
end

"""
$(TYPEDSIGNATURES)

Returns the device address of this buffer.
"""
function address(b::AbstractBOArray)
    XRTWrap.address(b.bo)
end

"""
$(TYPEDSIGNATURES)

Returns the memory group in which this buffer is allocated
"""
function get_memory_group(b::AbstractBOArray)
    XRTWrap.get_memory_group(b.bo)
end

"""
$(TYPEDSIGNATURES)

Returns the `XRT.XRTWrap.BOFlags` with which this buffer was constructed.
""" 
function get_flags(b::AbstractBOArray)
    XRTWrap.get_flags(b.bo)
end

"""
```Julia
AbstractBOArray(userdata::AbstractArray{T, N}, mem; device, flags)
AbstractBOArray(device::XRT.XRTWrap.Device, userdata::AbstractArray{T, N}, mem; flags)

```

See [`XRT.BOArray`](@ref).  
It can return [`XRT.ToDeviceBOArray`](@ref) or [`XRT.FromDeviceBOArray`](@ref), depending on whether `userdata` is of Type [`XRT.ToDeviceArray`](@ref) or [`XRT.FromDeviceArray`](@ref).
"""
function AbstractBOArray(userdata::AbstractArray{T,N}, mem; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    AbstractBOArray(device.device, userdata, mem; flags=flags)
end

function AbstractBOArray(device::XRTWrap.Device, userdata::AbstractArray{T,N}, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    if UInt64(pointer(userdata)) % 4096 != 0
        @warn "User buffer not aligned. Create aligned copy!"
        aligned_buffer = Array{T,N}(MemAlign(4096), size(userdata))
        aligned_buffer .= userdata
    else
        if typeof(userdata) <: AbstractSyncDirectionArray
            aligned_buffer = userdata.data
        else
            aligned_buffer = userdata
        end
    end
    bo = BO(device, Base.unsafe_convert(Ptr{Nothing}, aligned_buffer), sizeof(aligned_buffer), flags, mem)
    if typeof(userdata) <: XRT.ToDeviceArray
        ToDeviceBOArray(bo, aligned_buffer)
    elseif typeof(userdata) <: XRT.FromDeviceArray
        FromDeviceBOArray(bo, aligned_buffer)
    else
        BOArray(bo, aligned_buffer)
    end
end

"""
```Julia
BOArray(userdata::AbstractArray{T, N}, mem; device, flags) -> XRT.BOArray
BOArray(device::XRT.XRTWrap.Device, userdata::AbstractArray{T, N}, mem; flags) -> XRT.BOArray
BOArray{T,N}(size, mem::Integer; device, flags) -> XRT.BOArray
BOArray{T,N}(device::XRT.XRTWrap.Device, size, mem; flags) -> XRT.BOArray

```

Array data type usable with XRT.
Can be used like `BO` but supports indexing and automatic alignment of host buffers.

**Keywords**

**`device`** [`XilinxDevice`](@ref) to allocate buffer on.
Default is the current active device.

**`flags`** Flags are provided in the `XRT.XRTWrap.BOFlags` module.
Default is `XRT.XRTWrap.BOFlags.NORMAL`
"""
function BOArray(userdata::AbstractArray{T,N}, mem; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    BOArray(device.device, userdata, mem; flags=flags)
end

function BOArray(device::XRTWrap.Device, userdata::AbstractArray{T,N}, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    if UInt64(pointer(userdata)) % 4096 != 0
        @warn "User buffer not aligned. Create aligned copy!"
        aligned_buffer = Array{T,N}(MemAlign(4096), size(userdata))
        aligned_buffer .= userdata
    else
        aligned_buffer = userdata
    end
    bo = BO(device, Base.unsafe_convert(Ptr{Nothing}, aligned_buffer), sizeof(aligned_buffer), flags, mem)
    BOArray(bo, aligned_buffer)
end

function BOArray{T,N}(size, mem::Integer; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    BOArray{T,N}(device.device, size, mem; flags=flags)
end

function BOArray{T,N}(device::XRTWrap.Device, size, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    aligned_buffer = Array{T,N}(MemAlign(4096), size)
    bo = BO(device, Base.unsafe_convert(Ptr{Nothing}, aligned_buffer), length(aligned_buffer) * sizeof(eltype(aligned_buffer)), flags, mem)
    BOArray(bo, aligned_buffer)
end

"""
```Julia
ToDeviceBOArray(userdata::AbstractArray{T, N}, mem; device, flags) -> XRT.ToDeviceBOArray
ToDeviceBOArray(device::XRT.XRTWrap.Device, userdata::AbstractArray{T, N}, mem; flags) -> XRT.ToDeviceBOArray
ToDeviceBOArray{T,N}(size, mem::Integer; device, flags) -> XRT.ToDeviceBOArray
ToDeviceBOArray{T,N}(device::XRT.XRTWrap.Device, size, mem; flags) -> XRT.ToDeviceBOArray

```

See [`XRT.BOArray`](@ref).
Synchronisation only takes place in direction **from host to the device**.
If a different synchronisation direction than `XRT.TO_DEVICE` is specified, synchronisation does not take place.
This data structure can be used to avoid unnecessary synchronisation during high-level use.
"""
function ToDeviceBOArray(userdata::AbstractArray{T,N}, mem; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    ToDeviceBOArray(device.device, userdata, mem; flags=flags)
end

function ToDeviceBOArray(device::XRTWrap.Device, userdata::AbstractArray{T,N}, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    boarray = BOArray(device, userdata, mem; flags=flags)
    ToDeviceBOArray(boarray.bo, boarray.data)
end

function ToDeviceBOArray{T,N}(size, mem::Integer; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    ToDeviceBOArray{T,N}(device.device, size, mem; flags=flags)
end

function ToDeviceBOArray{T,N}(device::XRTWrap.Device, size, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    boarray = BOArray(device, size, mem; flags=flags)
    ToDeviceBOArray(boarray.bo, boarray.data)
end

"""
```Julia
FromDeviceBOArray(userdata::AbstractArray{T, N}, mem; device, flags) -> XRT.FromDeviceBOArray
FromDeviceBOArray(device::XRT.XRTWrap.Device, userdata::AbstractArray{T, N}, mem; flags) -> XRT.FromDeviceBOArray
FromDeviceBOArray{T,N}(size, mem::Integer; device, flags) -> XRT.FromDeviceBOArray
FromDeviceBOArray{T,N}(device::XRT.XRTWrap.Device, size, mem; flags) -> XRT.FromDeviceBOArray

```

See [`XRT.BOArray`](@ref).
Synchronisation only takes place in direction **from device to host**.
If a different synchronisation direction than `XRT.FROM_DEVICE` is specified, synchronisation does not take place.
This data structure can be used to avoid unnecessary synchronisation during high-level use.
"""
function FromDeviceBOArray(userdata::AbstractArray{T,N}, mem; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    FromDeviceBOArray(device.device, userdata, mem; flags=flags)
end

function FromDeviceBOArray(device::XRTWrap.Device, userdata::AbstractArray{T,N}, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    boarray = BOArray(device, userdata, mem; flags=flags)
    FromDeviceBOArray(boarray.bo, boarray.data)
end

function FromDeviceBOArray{T,N}(size, mem::Integer; device::XilinxDevice=XRT.device(), flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    FromDeviceBOArray{T,N}(device.device, size, mem; flags=flags)
end

function FromDeviceBOArray{T,N}(device::XRTWrap.Device, size, mem; flags::XRTWrap.BOFlags.Type=XRTWrap.BOFlags.NORMAL) where {T,N}
    boarray = BOArray(device, size, mem; flags=flags)
    FromDeviceBOArray(boarray.bo, boarray.data)
end

################################################################################
#                           Arrays with sync direction                         #
################################################################################

abstract type AbstractSyncDirectionArray{T} <: AbstractArray{T,1} end

"""
$(TYPEDEF)

A data type that wraps an `Array` in order to prohibit a single synchronisation direction when calling [`XRT.sync!`](@ref) function.
Can be used in functions created by [`@prepare_bitstream`](@ref) macro.
Alternatively, use [`XRT.ToDeviceWrapper`](@ref) or [`XRT.FromDeviceWrapper`](@ref).
"""
struct ToDeviceArray{T} <: AbstractSyncDirectionArray{T}
    data::Vector{T}
end

"""
$(TYPEDEF)

See [`ToDeviceArray`](@ref).
"""
struct FromDeviceArray{T} <: AbstractSyncDirectionArray{T}
    data::Vector{T}
end

Base.show(io::IO, a::AbstractSyncDirectionArray) = show(io, a.data)

Base.show(io::IO, ::MIME{Symbol("text/plain")}, a::AbstractSyncDirectionArray) = show(io, a.data)

function getindex(a::AbstractSyncDirectionArray, inds...)
    a.data[inds...]
end

function setindex!(a::AbstractSyncDirectionArray, X, inds...)
    a.data[inds...] = X
end

function size(a::AbstractSyncDirectionArray, d::Integer)
    size(a.data, d)
end

function size(a::AbstractSyncDirectionArray)
    size(a.data)
end

function Base.length(a::AbstractSyncDirectionArray)
    length(a.data)
end

function iterate(a::AbstractSyncDirectionArray, state...) 
    iterate(a.data, state...)
end

function broadcast(::typeof(==), a::AbstractSyncDirectionArray, value)
    return map(x -> x == value, a.data)
end

Base.unsafe_convert(::Type{Ptr{T}}, a::XRT.AbstractSyncDirectionArray{T}) where {T} = pointer(a.data)

function Base.unsafe_wrap(::Type{XRT.ToDeviceArray{T}}, ptr::Ptr{T}, dims::Int64; own::Bool=false) where {T}
    data = unsafe_wrap(Array{T}, ptr, (dims,); own=own)
    XRT.ToDeviceArray{T}(reshape(data, dims))
end

function Base.unsafe_wrap(::Type{XRT.FromDeviceArray{T}}, ptr::Ptr{T}, dims::Int64; own::Bool=false) where {T} 
    data = unsafe_wrap(Array{T}, ptr, (dims,); own=own)
    XRT.FromDeviceArray{T}(reshape(data, dims))
end

function ArrayAllocators.allocate(::Type{ToDeviceArray{T}}, dims::Dims{N}) where {T,N}
    data = ArrayAllocators.allocate(Array{T}, dims)
    return ToDeviceArray{T}(data)
end

function ArrayAllocators.allocate(::Type{FromDeviceArray{T}}, dims::Dims{N}) where {T,N}
    data = ArrayAllocators.allocate(Array{T}, dims)
    return FromDeviceArray{T}(data)
end

################################################################################
#                         Sync direction wrapper types                         #
################################################################################

abstract type AbstractSyncDirectionWrapper{T} end

"""
$(TYPEDEF)

This wrapper can alternatively used to set a single synchronisation direction to a `BOArray` or `Array`.
E.g. can be used within the [`@prepare_bitstream`] macro:

```Julia
a = Array{Float64}(MemAlign(4096),array_size)
b = Array{Float64}(MemAlign(4096),array_size)
c = Array{Float64}(MemAlign(4096),array_size)
		
a[:] .= rand(array_size)
b[:] .= rand(array_size)
c[:] .= 0
		
kernel_function!(XRT.ToDeviceWrapper(a), XRT.ToDeviceWrapper(b), XRT.FromDeviceWrapper(c), 2.0, array_size, 1)
```
"""
struct ToDeviceWrapper{T} <: AbstractSyncDirectionWrapper{T}
    object::T
end

"""
$(TYPEDEF)

See [`XRT.ToDeviceWrapper`](@ref).
"""
struct FromDeviceWrapper{T} <: AbstractSyncDirectionWrapper{T}
    object::T
end

function sync!(w::ToDeviceWrapper, direction::XRTWrap.BOSyncDirection.Type)
    if direction == XRTWrap.BOSyncDirection.TO_DEVICE
        XRT.sync!(w.object, direction)
    end
end

function sync!(w::FromDeviceWrapper, direction::XRTWrap.BOSyncDirection.Type)
    if direction == XRTWrap.BOSyncDirection.FROM_DEVICE
        XRT.sync!(w.object, direction)
    end
end

function getindex(a::AbstractSyncDirectionWrapper, inds...)
    a.object[inds...]
end

function setindex!(a::AbstractSyncDirectionWrapper, X, inds...)
    a.object[inds...] = X
end

function size(a::AbstractSyncDirectionWrapper, d::Integer)
    size(a.object, d)
end

function size(a::AbstractSyncDirectionWrapper)
    size(a.object)
end

function Base.length(a::AbstractSyncDirectionWrapper)
    length(a.object)
end

function iterate(a::AbstractSyncDirectionWrapper, state...) 
    iterate(a.object, state...)
end

function Base.convert(::Type{T}, a::AbstractSyncDirectionWrapper) where {T <: AbstractSyncDirectionWrapper}
    T(a.object)::T
end
