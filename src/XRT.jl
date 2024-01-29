module XRT
    using CxxWrap
    using Scratch
    using Pkg

    libname() = "libxrtwrap.so"

    @wrapmodule(() -> joinpath(@get_scratch!("lib"), libname()))

    function __init__()
        @initcxx
    end

    function set_arg(run::Run, index, val)
        set_arg(run, index, val[], sizeof(val))
    end

    function write!(bo::BO, data)
        write(bo, Base.unsafe_convert(Ptr{Nothing}, data))
    end

    function write!(bo::BO, data::Array, length; offset=0)
        val_size = sizeof(eltype(data))
        write(bo, Base.unsafe_convert(Ptr{Nothing}, data), length * val_size, offset * val_size)
    end

    function read!(bo::BO, data)
        read(bo, Base.unsafe_convert(Ptr{Nothing}, data))
    end

    function read!(bo::BO, data::Array, length; offset=0)
        val_size = sizeof(eltype(data))
        read(bo, Base.unsafe_convert(Ptr{Nothing}, data), length * val_size, offset * val_size)
    end
end
