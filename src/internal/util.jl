"""
$(TYPEDSIGNATURES)

Function used to call an XRT command-line tool from Julia.
It detects whether `xrt_jll` or a native installation is used.
"""
# XRT 2.19 renamed `xbutil` to `xrt-smi`; try the names an installation may carry.
const UTILITY_ALIASES = Dict("xbutil" => ("xrt-smi", "xbutil"))

function utility_cmd(name::AbstractString)
    candidates = get(UTILITY_ALIASES, name, (name,))
    native = XRTWrap.native_xrt()
    if native !== nothing
        for candidate in candidates
            path = joinpath(native, "bin", candidate)
            isfile(path) && return Cmd([path])
            path = Sys.which(candidate)
            path === nothing || return Cmd([path])
        end
    elseif isdefined(XRTWrap, :xrt_jll)
        for candidate in candidates
            product = Symbol(replace(candidate, "-" => "_"))
            isdefined(XRTWrap.xrt_jll, product) && return getfield(XRTWrap.xrt_jll, product)()
        end
    end
    error("Unknown XRT utility $(name)")
end

function call_utility(args::Vararg{AbstractString}; ignorestatus=false::Bool)
    args_array = Vector{String}([string(arg) for arg in args if !isempty(arg)])
    read(Cmd(`$(utility_cmd(args_array[1])) $(args_array[2:end])`; ignorestatus), String)
end

function replace_underscore(val::Union{XRT.XbutilTest.Type, AbstractString})
    output = replace(string(val), "_" => "-")
    output
end
