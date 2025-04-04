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

    if XRT.emulation_mode() == XRT.XRTWrap.TargetType.hw
        @devices_testset 1 "Xbutil" begin
            include("xbutil.jl")
        end
    end
    
    @devices_testset 1 "BOArray" begin
        include("boarray.jl")
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
