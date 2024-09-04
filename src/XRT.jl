module XRT

using CxxWrap
using Scratch
using xrt_jll
using Logging
import ..Base: size, length, read, convert, wait


libname() = "libxrtwrap.so"

@wrapmodule(() -> joinpath(@get_scratch!("xrtwrap"),"lib", libname()))

function __init__()
    @initcxx
    if !("XILINX_XRT" in keys(ENV))
        @info "Use xrt_jll XRT libraries"
        ENV["XILINX_XRT"] = xrt_jll.artifact_dir
    else
        @info "Use native XRT libraries in $(ENV["XILINX_XRT"])"
    end
end

include("xrt_bo.jl")
include("xrt_kernel.jl")
include("custom_xclbin.jl")
include("hl_execution.jl")

export size, length, setindex!, getindex, convert, wait
export sync!, group_id, set_arg!, start, stop, load_xclbin!
export prepare_bitstream

end
