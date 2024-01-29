module XRT
    using CxxWrap
    using Scratch
    import ..Base: size

    libname() = "libxrtwrap.so"

    @wrapmodule(() -> joinpath(@get_scratch!("lib"), libname()))

    function __init__()
        @initcxx
    end

    include("xrt_bo.jl")
    include("xrt_kernel.jl")
    include("custom_xclbin.jl")

    export size, length, setindex!, getindex
end
