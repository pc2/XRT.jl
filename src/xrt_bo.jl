using ArrayAllocators
import ..Base: size, length, getindex, setindex!, iterate
using .XRTWrap: BO, length, address, get_memory_group, get_flags, async!, sync!, map, read, write!, copy, XCL_BO_SYNC_BO_FROM_DEVICE, XCL_BO_SYNC_BO_TO_DEVICE
import XRT: write!, sync!

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


mutable struct BOArray{T,N}
    bo::BO
    data::Array{T,N}
end

function getindex(b::BOArray, inds...)
    b.data[inds...]
end

function setindex!(b::BOArray, X, inds...)
    b.data[inds...] = X
end

function size(b::BOArray, d::Integer)
    size(b.data, d)
end

function size(b::BOArray)
    size(b.data)
end

function length(b::BOArray)
    length(b.data)
end

function sync!(b::BOArray, direction::XRTWrap.xclBOSyncDirection)
    XRT.sync!(b.bo, direction)
end

function convert(::Type{BO}, boa::BOArray)
    boa.bo
end

iterate(b::BOArray) = iterate(b, 1)

function iterate(b::BOArray, state)
   if state <= length(b) 
        (b.data[state], state+1)
   else
        nothing
   end
end

"""
$(SIGNATURES)

Array data type usable with XRT. Can be used like BO but supports indexing and automatic
alignment of host buffers.
"""
function BOArray(device::Device, userdata::AbstractArray{T,N}, mem; flags::XRTWrap.BOFlags=XRTWrap.XRT_BO_FLAGS_NORMAL) where {T,N}
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

"""
$(SIGNATURES)

Array data type usable with XRT. Can be used like BO but supports indexing and automatic
alignment of host buffers.
"""
function BOArray{T,N}(device::Device, size, mem; flags::XRTWrap.BOFlags=XRTWrap.XRT_BO_FLAGS_NORMAL) where {T,N}
    aligned_buffer = Array{T,N}(MemAlign(4096), size)
    bo = BO(device, Base.unsafe_convert(Ptr{Nothing}, aligned_buffer), length(aligned_buffer) * sizeof(eltype(aligned_buffer)), flags, mem)
    BOArray(bo, aligned_buffer)
end


