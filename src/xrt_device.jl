using .XRTWrap: get_xclbin_uuid
using .XRTWrap: UUID
import XRT: get_xclbin_uuid

abstract type AbstractXilinxDeviceInformation end

"""
$(TYPEDEF)

A `XilinxDevice` struct that allows direct access to the device parameters as fields.
The fields return always the up-to-date values.

**Fields**

**`device`** allows access to the `XRT.XRTWrap.Device` object if required.

**`index`** of the device as used by XRT.jl (starts at 1).

**`xclbin_uuid`** is a pointer to the last Xclbin UUID loaded onto the device.

**`bdf`** is the BDF for the device.

**`interface_uuid`** is the UUID when device is programmed with 2RP shell.

**`kdma`** is the number of KDMA engines.

**`max_clock_frequency_mhz`** is the maximum clock frequency.

**`m2m`** indicates whether the device contains m2m.

**`name`** is the device name.

**`nodma`** indicates whether the device is a NoDMA device.

**`offline`** indicates whether the device is offline.

**`electrical`** information about electrical and power sensors.
Returns as a `LazyJSON` object.

**`thermal`** information about thermal sensors.
Returns as a `LazyJSON` object.

**`mechanical`** information about mechanical sensors.
Returns as a `LazyJSON` object.

**`memory`** information about device memory.
Returns as a `LazyJSON` object.

**`platform`** is a `LazyJSON` object that contains information about platforms flashed on the device.

**`pcie_info`** information about PCIe.
Returns as a `LazyJSON` object.

**`host`** is host information.
Returns as a `LazyJSON` object.

**`aie`** information about AIE core of the device.
Returns as a `LazyJSON` object.

**`aie_shim`** information about AIE shim of the device.
Returns as a `LazyJSON` object.

**`dynamic_regions`** information about the xclbin on the device.
Returns as a `LazyJSON` object.

**`vmr`** information about vmr on the device.
Returns as a `LazyJSON` object.

**Note: The constructor should in general not be called directly! Use [`XRT.device`](@ref) or [`XRT.devices`](@ref) instead!**
"""
struct XilinxDevice
    device::XRTWrap.Device
    index::Integer
    xclbin_uuid::Ref{XRTWrap.UUID}

    electrical::AbstractXilinxDeviceInformation
    thermal::AbstractXilinxDeviceInformation
    mechanical::AbstractXilinxDeviceInformation
    memory::AbstractXilinxDeviceInformation
    platform::AbstractXilinxDeviceInformation
    pcie_info::AbstractXilinxDeviceInformation
    host::AbstractXilinxDeviceInformation
    aie::AbstractXilinxDeviceInformation
    aie_shim::AbstractXilinxDeviceInformation
    dynamic_regions::AbstractXilinxDeviceInformation
    vmr::AbstractXilinxDeviceInformation
    bdf::String
    interface_uuid::XRTWrap.UUID
    kdma::UInt32
    max_clock_frequency_mhz::UInt64
    m2m::Bool
    name::String
    nodma::Bool
    offline::Bool

    XilinxDevice(index::Integer) = new(XRTWrap.Device(index-1), index, Ref{XRTWrap.UUID}(XRTWrap.UUID()))
end

module _XRTDeviceInformation

using LazyJSON
import ..XRT

struct XilinxDeviceInformationElectrical <: XRT.AbstractXilinxDeviceInformation
    electrical::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationThermal <: XRT.AbstractXilinxDeviceInformation
    thermal::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationMechanical <: XRT.AbstractXilinxDeviceInformation
    mechanical::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationMemory <: XRT.AbstractXilinxDeviceInformation
    memory::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationPlatform <: XRT.AbstractXilinxDeviceInformation
    platform::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationPcieInfo <: XRT.AbstractXilinxDeviceInformation
    pcie_info::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationHost <: XRT.AbstractXilinxDeviceInformation
    host::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationAie <: XRT.AbstractXilinxDeviceInformation
    aie::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationAieShim <: XRT.AbstractXilinxDeviceInformation
    aie_shim::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationDynamicRegions <: XRT.AbstractXilinxDeviceInformation
    dynamic_regions::Union{LazyJSON.Object, Nothing}
end

struct XilinxDeviceInformationVmr <: XRT.AbstractXilinxDeviceInformation
    vmr::Union{LazyJSON.Object, Nothing}
end

end # _XRTDeviceInformation

Base.string(device::XilinxDevice) = "[$(device.bdf)] : $(device.name)"

Base.show(io::IO, device::XRT.XilinxDevice) = print(io, string(device))

function Base.getproperty(device::XilinxDevice, field::Symbol)
    if isdefined(XRTWrap.DeviceInformationParameters, field)
        try
            if fieldtype(XRT.XilinxDevice, field) == XRT.AbstractXilinxDeviceInformation
                param = getfield(XRTWrap.DeviceInformationParameters, field)
                json = _XRTInternal.get_info(device, param)
                subnames = split(string(field), "_")
                report_name = "XilinxDeviceInformation$(join([uppercasefirst(name) for name in subnames]))"
                report = @eval _XRTDeviceInformation.$(Symbol(report_name))
                return report(json)
            else
                throw(Exception())
            end
        catch ignore
            param = getfield(XRTWrap.DeviceInformationParameters, field)
            return _XRTInternal.get_info(device, param)
        end
    else 
        return getfield(device, field)
    end 
end

"""
```Julia
load_xclbin!(xclbin::XRT.Xclbin; device, force) -> XRT.UUID
load_xclbin!(path::String; device, force) -> XRT.UUID

```

Loads an [`XRT.Xclbin`](@ref) object on the current active device if it is not yet loaded onto it.
The function returns the UUID of the xclbin.
`XRT.program!` is an alias for `load_xclbin!`.

**Keywords**

**`device`** The target device can be changed by setting the `device` keyword parameter.

**`force`** Forces the Xclbin to be loaded onto the device.
"""
function load_xclbin!(xclbin::Xclbin; device::XilinxDevice=device(), force::Bool=false)
    if force || xclbin.uuid != device.xclbin_uuid[]
        uuid = XRTWrap.load_xclbin!(device.device, xclbin.path)
        device.xclbin_uuid[] = uuid
        return uuid;
    else
        return xclbin.uuid
    end
end

function load_xclbin!(path::String; device::XilinxDevice=device(), force::Bool=false)
    xclbin = Xclbin(path)
    load_xclbin!(xclbin; device=device, force)
end

"""
$(TYPEDSIGNATURES)

Returns the UUID of the xclbin image that is currently loaded on the active device.
The device can be changed by setting the `device` keyword parameter.
"""
function get_xclbin_uuid(; device::XilinxDevice=device())
    get_xclbin_uuid(device.device)
end
