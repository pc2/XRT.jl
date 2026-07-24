module XRT

using Reexport
using LazyJSON
using DocStringExtensions
using PkgVersion

@reexport using ArrayAllocators 

module XRTWrap

using CxxWrap
using Scratch
using Logging
import ..Base: size, length, read, convert, wait

get_version(version_output) = VersionNumber(match(r"Version\s+:\s+(\d+\.\d+\.\d+)", version_output)[1])

"""
Path of a native XRT installation selected through `XILINX_XRT`, or `nothing` when the
`xrt_jll` artifact is used. An `XILINX_XRT` inside a depot is one we set ourselves.
"""
function native_xrt()
    path = get(ENV, "XILINX_XRT", "")
    isempty(path) && return nothing
    any(depot -> occursin(depot, path), DEPOT_PATH) && return nothing
    return path
end

# Loading these dlopens their XRT libraries, which would then satisfy libxrtwrap's
# DT_NEEDED and shadow a native installation, so only load them when we use them.
if native_xrt() === nothing
    import xrt_jll
    import xrt_cxxwrap_jll
end

"""
Path of the `libxrtwrap` CxxWrap shim. `xrt_cxxwrap_jll` ships one built against
`xrt_jll`; a native XRT needs one built against its own headers, which `Pkg.build("XRT")`
puts in the scratch space. `JULIA_XRTWRAP_LIBRARY` overrides both.
"""
function libpath()
    override = get(ENV, "JULIA_XRTWRAP_LIBRARY", "")
    isempty(override) || return override
    isdefined(@__MODULE__, :xrt_cxxwrap_jll) && return xrt_cxxwrap_jll.libxrtwrap

    scratch = @get_scratch!("xrtwrap")
    for dir in (joinpath(scratch, "lib"), joinpath(scratch, "bin"))
        isdir(dir) || continue
        for file in readdir(dir; join=true)
            startswith(basename(file), "libxrtwrap.") && return file
        end
    end
    error("""XILINX_XRT points at a native XRT installation in $(native_xrt()), but no \
             libxrtwrap has been built against it. Run `Pkg.build("XRT")`.""")
end

const _functional = Ref{Bool}(true)

module DeviceInformationParameters
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_device_info_params)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # DeviceInformationParameters

module BOFlags
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_bo_flags)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # BOFlags

module ErtCmdState
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_ert_cmd_state)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # ErtCmdState

module BOSyncDirection
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_xcl_bo_sync_direction)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # BOSyncDirection

module CVStatus
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_cv_status)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # CVStatus

module ComputeUnitAccessMode
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_cu_access_mode)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # ComputeUnitAccessMode

module TargetType
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_target_type)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # TargetType

module ControlType
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_control_type)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # ControlType

module MemoryType
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_memory_type)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # MemoryType

module KernelType
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_kernel_type)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end  # KernelType

module IPType
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_ip_type)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # IPType

module LogLevel
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(XRTWrap.libpath, :define_module_verbosity_level)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # LogLevel

@wrapmodule(libpath, :define_module_xrtwrap)

function __init__()
    try
        @initcxx
    catch ignore
        _functional[] = false
    end

    # Which XRT we bound to was settled while precompiling; check before we set
    # XILINX_XRT ourselves below, which would change the answer.
    stale = (native_xrt() === nothing) != isdefined(@__MODULE__, :xrt_cxxwrap_jll)

    if isdefined(@__MODULE__, :xrt_jll)
        # XRT locates its configuration and driver plugins relative to XILINX_XRT.
        ENV["XILINX_XRT"] = xrt_jll.artifact_dir
    end

    if stale
        @warn "XRT.jl was precompiled against a different XRT than XILINX_XRT selects now. Recompiling..."
        Base.compilecache(Base.identify_package("XRT"))
        @warn "Recompiling done. Please restart Julia to load the new version."
    end
end

end # XRTWrap

include("custom_xclbin.jl")
include("xrt_xclbin.jl")
include("xrt_device.jl")
include("xrt_xbutil.jl")
include("internal/_XRTInternal.jl")
include("xrt_bo.jl")
include("xrt_kernel.jl")
include("hl_execution.jl")
include("state.jl")
include("xrt_enum.jl")
include("xrt_ini.jl")
include("xrt_uuid.jl")
include("xrt_ip.jl")

function __init__()
    shim_version = VersionNumber(XRTWrap.XRT_VERSION_MAJOR, XRTWrap.XRT_VERSION_MINOR)
    xrt_version = try
        XRTWrap.get_version(version())
    catch
        nothing
    end

    if xrt_version !== nothing &&
       (xrt_version.major != shim_version.major || xrt_version.minor != shim_version.minor)
        @warn """libxrtwrap is built against XRT v$(shim_version), but XRT \
                 v$(xrt_version.major).$(xrt_version.minor) is installed. For a native \
                 installation, run `Pkg.build("XRT")` to rebuild it."""
    end

    if haskey(ENV, "XRT_INI_PATH")
        @info "XRT_INI_PATH is set to '$(ENV["XRT_INI_PATH"])'"
    end

    if functional()
        _XRTInternal.construct()
        if length(devices()) > 0
            @info "XRT.jl loaded with active device $(string(device()))"
        else
            @warn "No XRT-capable devices found"
        end
    else
        error("An error occured while initializing XRT.\n
        Maybe the installed XRT does not support features of the currently loaded libxrtwrap v$(shim_version) version.\n
        Calling an XRTWrap function causes the Julia kernel to crash.")
    end
end

export size, length, setindex!, getindex, wait
export sync!, group_id, set_arg!, start, stop, load_xclbin!, get_xclbin_uuid, Xclbin
export @prepare_bitstream, @prepare_run
export ToDeviceArray, FromDeviceArray

end
