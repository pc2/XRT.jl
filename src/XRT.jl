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

get_version(xbutil_version) = VersionNumber(match(r"Version\s+:\s+(\d+\.\d+\.\d+)", xbutil_version)[1])
xbutil_version = VersionNumber("1")

if !(haskey(ENV, "XILINX_XRT"))
    @info "Use xrt_jll artifacts"
    using xrt_jll
    ENV["XILINX_XRT"] = xrt_jll.artifact_dir
    xbutil_version = get_version(read(`$(xrt_jll.xbutil()) --version`, String))
else
    @info "Use native XRT libraries in $(ENV["XILINX_XRT"])"
    xbutil_version = get_version(read(`xbutil --version`, String))
end

libname() = "libxrtwrap.so.$(xbutil_version.major).$(xbutil_version.minor)"
libpath = joinpath(@get_scratch!("xrtwrap"), "lib", libname())

if !isfile(libpath)
    @info "No shared object library v$(xbutil_version.major).$(xbutil_version.minor) found. Building..."
    include("../deps/build.jl")
    @info "Done"
end

const _functional = Ref{Bool}(true)

module DeviceInformationParameters
    using ..XRTWrap
    using CxxWrap
    @wrapmodule(() -> XRTWrap.libpath, :define_module_device_info_params)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_bo_flags)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_ert_cmd_state)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_xcl_bo_sync_direction)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_cv_status)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_cu_access_mode)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_target_type)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_control_type)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_memory_type)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_kernel_type)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_ip_type)

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
    @wrapmodule(() -> XRTWrap.libpath, :define_module_verbosity_level)

    function __init__()
        try
            @initcxx
        catch ignore
            XRTWrap._functional[] = false
        end
    end
end # LogLevel

@wrapmodule(() -> libpath, :define_module_xrtwrap)

function __init__()
    try
        @initcxx
    catch ignore
        _functional[] = false
    end

    if haskey(ENV, "XILINX_XRT")
        if isdefined(XRTWrap, :xrt_jll) || any(path -> occursin(path, ENV["XILINX_XRT"]), DEPOT_PATH)
            @info "XRT.jl precompiled with xrt_jll, but XILINX_XRT is set. Recompiling..."
            Base.compilecache(Base.identify_package("XRT"))
            @warn "Recompiling Done. Please restart Julia to load the new version."
        else
            @info "Using native XRT libraries in $(ENV["XILINX_XRT"])"
        end
    else
        if isdefined(XRTWrap, :xrt_jll)
            @info "Using xrt_jll artifacts"
            ENV["XILINX_XRT"] = xrt_jll.artifact_dir
        else
            @info "XRT.jl not precompiled with xrt_jll. Recompiling..."
            Base.compilecache(Base.identify_package("XRT"))
            @info "Recompiling Done. Please restart Julia to load the new version."
        end
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
    xrt_version = XRTWrap.get_version(version())

    if xrt_version.major != XRTWrap.XRT_VERSION_MAJOR || xrt_version.minor != XRTWrap.XRT_VERSION_MINOR
        @info "Version libxrtwrap.so.$(XRTWrap.XRT_VERSION_MAJOR).$(XRTWrap.XRT_VERSION_MINOR) loaded, but XRT v$(xrt_version.major).$(xrt_version.minor) found. Recompiling..."
        Base.compilecache(Base.identify_package("XRT"))
        @warn "Recompiling Done. Please restart Julia to load the new version."
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
        Maybe XRT v$(xrt_version.major).$(xrt_version.minor) does not support features of the currently loaded libxrtwrap.so.$(XRTWrap.XRT_VERSION_MAJOR).$(XRTWrap.XRT_VERSION_MINOR) version.\n
        Calling an XRTWrap function causes the Julia kernel to crash.")
    end
end

export size, length, setindex!, getindex, wait
export sync!, group_id, set_arg!, start, stop, load_xclbin!, get_xclbin_uuid, Xclbin
export @prepare_bitstream, @prepare_run
export ToDeviceArray, FromDeviceArray

end
