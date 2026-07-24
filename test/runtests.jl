using Test
using XRT
using ArrayAllocators
using LazyJSON
using Logging

include("utilities.jl")

if "--help" in ARGS
    println("""
        Usage: runtests.jl [--help] [--quick] [--verbose]

               --help             Show this text.
               --quick            Skip long tests.
               --verbose          Print more information during testing.""")
    exit(0)
end

const quick = "--quick" in ARGS
const verbose = "--verbose" in ARGS

@testset verbose=verbose "XRT.jl" begin

    # Reaches the XRT command-line tools, which needs no device.
    @testset "Version" begin
        @test occursin("$(XRT.XRTWrap.XRT_VERSION_MAJOR).$(XRT.XRTWrap.XRT_VERSION_MINOR)", XRT.version())
    end

    # reset/validate address a device by BDF, and on an NPU xrt-smi has neither.
    if XRT.emulation_mode() == XRT.XRTWrap.TargetType.hw
        if any(device -> device.bdf === nothing, XRT.devices())
            @warn "Not every device reports a BDF\nSkipping testset"
        elseif is_npu()
            @warn "xbutil reset/validate are not available on an NPU\nSkipping testset"
        else
            @devices_testset 1 "Xbutil" begin
                include("xbutil.jl")
            end
        end
    end

    # BOArray allocates NORMAL buffer objects, which an NPU rejects (ENOTSUP).
    if is_npu()
        @warn "BOArray uses NORMAL buffer objects, unsupported on an NPU\nSkipping testset"
    else
        @devices_testset 1 "BOArray" begin
            include("boarray.jl")
        end
    end

    @testset "State" begin
        include("state.jl")
    end

    @testset "Device" begin
        include("device.jl")
    end

    @xclbin_testset "Xclbin" begin
        include("xclbin.jl")
    end

    @devices_testset 1 "Stream Example" begin
        include("stream.jl")
    end

end
