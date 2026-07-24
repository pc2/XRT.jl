"""
$(TYPEDEF)

A `XilinxDeviceArray` behaves like a normal Julia `Vector{XRT.XilinxDevice}`.
The difference is, that it always points to the first element, when emulation mode is set.
"""
struct XilinxDeviceArray
    devices::Vector{Union{XRT.XilinxDevice, Nothing}}

    """
    $(TYPEDSIGNATURES)

    Constructs an empty `XilinxDeviceArray` of length `size`.
    """
    XilinxDeviceArray() = new(Vector{Union{XRT.XilinxDevice, Nothing}}())
end

function Base.getindex(arr::_XRTInternal.XilinxDeviceArray, index::Integer)
    if haskey(ENV, "XCL_EMULATION_MODE") && (ENV["XCL_EMULATION_MODE"] == "sw_emu" || ENV["XCL_EMULATION_MODE"] == "hw_emu")
        try
            return arr.devices[1]
        catch e
            @warn "XilinxDevice with index $(index) is not available"
            return nothing
        end
    else 
        for d in arr.devices
            d === nothing && continue
            if d.index == index
                return d
            end
        end
        @warn "XilinxDevice with index $(index) is not available"
        return nothing
    end
end

function Base.setindex!(arr::_XRTInternal.XilinxDeviceArray, device::Union{XRT.XilinxDevice, Nothing}, index::Integer)
    arr.devices[index] = device
end

Base.size(arr::_XRTInternal.XilinxDeviceArray) = Base.size(arr.devices)

Base.size(arr::_XRTInternal.XilinxDeviceArray, d::Integer) = Base.size(arr.devices, d)

Base.length(arr::_XRTInternal.XilinxDeviceArray) = Base.length(arr.devices)

function first(arr::_XRTInternal.XilinxDeviceArray)
    for d in arr.devices
        return d
    end
end

Base.iterate(arr::_XRTInternal.XilinxDeviceArray) = Base.iterate(arr.devices)

"""
$(TYPEDEF)

`State` is a singleton object that stores global parameters, like devices and emulation mode.
"""
mutable struct State
    device::Union{XRT.XilinxDevice, Nothing}
    available_devices::XilinxDeviceArray
    emulation_mode::XRTWrap.TargetType.Type
end

const state = Base.RefValue{State}()

"""
$(TYPEDSIGNATURES)

Constructs and initialises a singleton object of type [`XRT._XRTInternal.State`](@ref).
It checks for a set emulation mode, and detects and registers available devices.
"""
function construct()
    global state
    if !isassigned(state)
        if haskey(ENV, "XCL_EMULATION_MODE") && (ENV["XCL_EMULATION_MODE"] == "sw_emu" || ENV["XCL_EMULATION_MODE"] == "hw_emu")
            emulation_mode = getproperty(XRTWrap.TargetType, Symbol(ENV["XCL_EMULATION_MODE"]))
            @info "XCL_EMULATION_MODE variable is set to '$(emulation_mode)'"
        else
            emulation_mode = XRTWrap.TargetType.hw
        end

        enumerate_devices = XRTWrap.enumerate_devices()
        if (enumerate_devices > 0)
            available_devices_indices = Vector{Integer}()
            for i = 1:enumerate_devices
                try 
                    XRTWrap.Device(i-1)
                    push!(available_devices_indices, i)
                catch ignore
                    @warn "XilinxDevice with index $(i) is not available"
                    # Ignore device just as the C++ API does
                end
            end
            xilinx_devices = XilinxDeviceArray()
            for i in available_devices_indices
                push!(xilinx_devices.devices, XRT.XilinxDevice(i))
            end

            s = State(first(xilinx_devices), xilinx_devices, emulation_mode)
        else   
            s = State(nothing, XilinxDeviceArray(), emulation_mode)
        end
        state[] = s
    end
    return nothing
end
