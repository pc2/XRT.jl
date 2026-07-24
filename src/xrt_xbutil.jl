"""
`xbutil program` has the same functionality as [`load_xclbin!`](@ref)
"""
const program! = load_xclbin!

module XbutilTest

using DocStringExtensions

"""
$(TYPEDEF)

Enum representing available preinstalled tests which can be run using [`XRT.validate!`](@ref).
"""
@enum Type::Int begin
    ALL
    AUX_CONNECTION
    PCIE_LINK
    SC_VERSION
    VERIFY
    DMA
    IOPS
    MEM_BW
    P2P
    M2M
    HOSTMEM_BW
    BIST
    VCU
    QUICK
    AIE_PL
end

end # XbutilTest

"""
```Julia
validate!(bdf::AbstractString, tests::Union{XRT.XbutilTest.Type, AbstractString}...; output) -> String
validate!(tests::Union{XRT.XbutilTest.Type, AbstractString}...; device, output) -> String

```

This function validates the selected device by running precompiled tests on it.
See [`XbutilTest.Type`](@ref) for available tests.

The following example will run two selected tests on the current active device.

```Julia
julia> XRT.validate!(XRT.XbutilTest.AUX_CONNECTION, XRT.XbuitlTest.PCIE_LINK)
```

**Keywords**

**`device`** A `XilinxDevice` to execute the tests on can be set. 
Alternatively, the bdf of a device can be specified as the first parameter.

**`output`** Output file for test results as JSON format.
"""
function validate!(bdf::AbstractString, tests::Vararg{Union{XbutilTest.Type, AbstractString}}; output=""::AbstractString)
    args = ["xbutil", "validate", "-d", "$(bdf)"]

    if length(tests) > 0
        push!(args, "-r")
        for test in tests
            push!(args, _XRTInternal.replace_underscore(test))
        end
    end

    if !isempty(output)
        push!(args, "-o")
        push!(args, output)
        push!(args, "-f")
        push!(args, "JSON")
    end

    _XRTInternal.call_utility(args...)
end

function validate!(tests::Vararg{Union{XbutilTest.Type, AbstractString}}; device::XilinxDevice=device(), output=""::AbstractString)
    bdf = device.bdf
    bdf === nothing && error("Device $(device.index) does not report a BDF")
    validate!(bdf, tests...; output=output)
end

"""
$(SIGNATURES)

Simply report the version of XRT and its drivers by calling `xbutil --version`.
"""
function version()
    _XRTInternal.call_utility("xbutil", "--version"; ignorestatus=true)
end

"""
$(TYPEDSIGNATURES)

Function for resetting a device.

**Caution:** Calling the function cann kill the current Julia instance, if different device allocations are present.
Make sure that all device allocations of the device to be reset are deallocated.
To do this, set all device allocations to nothing and call up the garbage collector.

```Julia
julia> d = XRT.XRTWrap.Device(0); d = nothing; GC.gc()
```
"""
function reset!(index::Integer)
    device = XRT.device(index)
    bdf = device.bdf
    bdf === nothing && error("Device $(index) does not report a BDF, so it cannot be reset")

    @warn "Deallocating devices. This function call can kill the Julia instance!"
    reset_active_device = XRT.device().index == index
    if reset_active_device
        _XRTInternal.state[].device = nothing
    end
    _XRTInternal.state[].available_devices[index] = nothing

    GC.gc()

    res = try
        _XRTInternal.call_utility("xbutil", "reset", "-d", "$(bdf)", "--force")
    catch
        # Leaving the slot empty would break every later device lookup.
        _XRTInternal.state[].available_devices[index] = device
        reset_active_device && (_XRTInternal.state[].device = device)
        rethrow()
    end
    @info "$(res)"

    sleep(0.5)
    xd = XilinxDevice(index)
    _XRTInternal.state[].available_devices[index] = xd
    if reset_active_device
        _XRTInternal.state[].device = xd
    end
    xd
end
