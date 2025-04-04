using .XRTWrap.TargetType
using .XRTWrap.MemoryType
using .XRTWrap.ControlType
using .XRTWrap.IPType
using .XRTWrap.DeviceInformationParameters
using .XRTWrap.BOFlags
using .XRTWrap.ErtCmdState
using .XRTWrap.BOSyncDirection
using .XRTWrap.CVStatus
using .XRTWrap.ComputeUnitAccessMode
using .XRTWrap.LogLevel
using .XRTWrap.KernelType

function Base.show(io::IO, val::Union{
    XRTWrap.TargetType.Type,
    XRTWrap.MemoryType.Type,
    XRTWrap.ControlType.Type,
    XRTWrap.IPType.Type,
    XRTWrap.DeviceInformationParameters.Type,
    XRTWrap.BOFlags.Type,
    XRTWrap.ErtCmdState.Type,
    XRTWrap.BOSyncDirection.Type,
    XRTWrap.CVStatus.Type,
    XRTWrap.ComputeUnitAccessMode.Type,
    XRTWrap.LogLevel.Type,
    XRTWrap.KernelType.Type
    })
    print(io, "$(string(val))")
end

function Base.string(val::Union{
    XRTWrap.TargetType.Type,
    XRTWrap.MemoryType.Type,
    XRTWrap.ControlType.Type,
    XRTWrap.IPType.Type,
    XRTWrap.DeviceInformationParameters.Type,
    XRTWrap.BOFlags.Type,
    XRTWrap.ErtCmdState.Type,
    XRTWrap.BOSyncDirection.Type,
    XRTWrap.CVStatus.Type,
    XRTWrap.ComputeUnitAccessMode.Type,
    XRTWrap.LogLevel.Type,
    XRTWrap.KernelType.Type
    })
    mod = parentmodule(typeof(val))
    for n in names(mod; all=true, imported=false)
        if getproperty(mod, n) === val
            return string(n)
        end
    end
end