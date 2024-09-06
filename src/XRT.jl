module XRT

using DocStringExtensions

module XRTWrap

using CxxWrap
using Scratch
using Logging
import ..Base: size, length, read, convert, wait


if !("XILINX_XRT" in keys(ENV))
    @info "Use xrt_jll XRT libraries"
    using xrt_jll
    ENV["XILINX_XRT"] = xrt_jll.artifact_dir
else
    @info "Use native XRT libraries in $(ENV["XILINX_XRT"])"
end

libname() = "libxrtwrap.so"

@wrapmodule(() -> joinpath(@get_scratch!("xrtwrap"),"lib", libname()))

function __init__()
    @initcxx

end

end

include("xrt_device.jl")
include("xrt_bo.jl")
include("xrt_kernel.jl")
include("custom_xclbin.jl")
include("hl_execution.jl")

export size, length, setindex!, getindex, convert, wait
export sync!, group_id, set_arg!, start, stop, load_xclbin!
export @prepare_bitstream

end
