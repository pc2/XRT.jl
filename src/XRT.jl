module XRT
    using CxxWrap
    using Scratch
    import ..Base: size, length, read, convert, wait

    libname() = "libxrtwrap.so"

    @wrapmodule(() -> joinpath(@get_scratch!("lib"), libname()))

    function __init__()
        @initcxx
    end

    include("xrt_bo.jl")
    include("xrt_kernel.jl")
    include("custom_xclbin.jl")
    include("hl_execution.jl")

    export size, length, setindex!, getindex, convert, wait
    export sync!, group_id, set_arg!, start, stop, load_xclbin!
    export prepare_bitstream
end
