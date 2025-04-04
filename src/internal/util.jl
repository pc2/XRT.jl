"""
$(TYPEDSIGNATURES)

Function used to call an XRT command-line tool from Julia.
It detects whether `xrt_jll` or a native installation is used.
"""
function call_utility(args::Vararg{AbstractString}; ignorestatus=false::Bool)
    args_array = Vector{String}([string(arg) for arg in args if !isempty(arg)])
    if isdefined(XRTWrap, :xrt_jll)
        if Symbol(args_array[1]) in names(XRTWrap.xrt_jll)
            read(Cmd(`$(getfield(XRTWrap, Symbol(args_array[1]))()) $(args_array[2:end])`; ignorestatus), String)
        else
            error("Unknown XRT utility $(args_array[1])")
        end
    else
        read(Cmd(Cmd(args_array); ignorestatus=ignorestatus), String)
    end
end

function replace_underscore(val::Union{XRT.XbutilTest.Type, AbstractString})
    output = replace(string(val), "_" => "-")
    output
end
