"""
```Julia
device!(id::Int64) -> Union{Nothing, XRT.XilinxDevice}
device!(device::XRT.XilinxDevice) -> XRT.XilinxDevice

```

Sets the current active device by a id.
If emulation mode is set to `hw_emu` or `sw_emu`, the only available device is always selected.

The current active device can alternatively set by a `XilinxDevice`.
However, this is not recommended as it can lead to incorrect device allocations.
"""
function device!(id::Int)
    _XRTInternal.state[].device = _XRTInternal.state[].available_devices[id]
    _XRTInternal.state[].device
end

function device!(device::XilinxDevice)
    _XRTInternal.state[].device = device
    device
end

"""
```Julia
device() -> Union{Nothing, XRT.XilinxDevice}
devices(id::Int64) -> XRT.XilinxDevice

```

Returns the current active device or a available device with a given id.
Prefered over `devices()[id]` due to selection when emulation mode is active.
"""
device() = _XRTInternal.state[].device

device(id::Int) = _XRTInternal.state[].available_devices[id]

"""
$(TYPEDSIGNATURES)

Specifies a vector that contains all available devices.
"""
devices() = _XRTInternal.state[].available_devices.devices

"""
$(TYPEDSIGNATURES)

Returns the emulation mode.
It is set to either `hw`, `hw_emu`, or `sw_emu`.
To change this mode, export `XCL_EMULATION_MODE` environment variable before loading the package.
"""
emulation_mode() = _XRTInternal.state[].emulation_mode

"""
$(TYPEDSIGNATURES)

Prints information about XRT and package version, environment variables, and devices to the console.
"""
function versioninfo(io::IO=stdout)
    if !functional()
        println(io, "--- An error occurred while loading XRT ---")
    end
    print(io, "Xilinx Runtime library $(XRT.XRTWrap.XRT_VERSION_MAJOR).$(XRT.XRTWrap.XRT_VERSION_MINOR), ")
    if isdefined(XRTWrap, :xrt_jll)
        println(io, "built-in installation")
    else
        println(io, "native installation")
    end
    println(io, "Detected emulation mode: $(emulation_mode())")
    println(io)

    println(io, "Julia packages:")
    println(io, "  XRT.jl: $(PkgVersion.Version(XRT))")
    for name in [:xrt_jll]
        isdefined(XRTWrap, name) || continue
        mod = getfield(XRTWrap, name)
        println(io, "  $(name): $(PkgVersion.Version(mod))")
    end
    println(io)

    println(io, "Libraries:")
    println(io, "  xrtwrap: $(XRT.XRTWrap.libname())")
    println(io, "  XRT:")
    println(io, "    $(replace(chomp(XRT.version()), "\n" => "\n    ", r"(\ )+:" => ":"))")
    println(io)
    
    env = filter(var -> occursin("XRT", var) || occursin("XCL", var) || occursin("XILINX", var), keys(ENV))
    if !isempty(env)
        println(io, "Environment:")
        for var in env
            println(io, "  $(var) = $(ENV[var])")
        end
        println(io)
    end

    devs = devices()
    if isempty(devs)
        println(io, "No XRT-capable devices.")
    elseif length(devs) == 1
        println(io, "1 device:")
    else
        println(io, length(devs), " devices:")
    end
    for (i, dev) in enumerate(devs)
        println(io, "  $(dev.index): $(string(dev))")
    end
end

"""
$(TYPEDSIGNATURES)

Indicates whether XRTWrap was loaded successfully.
"""
functional() = XRTWrap._functional[] && return true