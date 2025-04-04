const path = "../examples/stream/build_$(XRT.emulation_mode())/stream.xclbin"

function comparekeys(dict1::LazyJSON.Object, dict2::LazyJSON.Object)
    !(0 in (keys(dict1) .== keys(dict2)))
end

comparekeys(::Nothing, ::Nothing) = true

function get_xclbin_path()
    path = "../examples/stream/build_$(XRT.emulation_mode())/stream.xclbin"
    
    if isfile(path)
        return path
    else
        error("Stream xclbin file not present")
    end
end

macro xclbin_testset(description::AbstractString, expr::Expr)
    quote 
        if !isfile(path)
            @warn "Stream xclbin file not available\nSkipping testset"
            return nothing
        end

        @testset $description begin
            esc($expr)
        end
    end
end

macro devices_testset(required::Int, description::AbstractString, expr::Expr)
    quote 
        if XRT.emulation_mode() == XRT.XRTWrap.TargetType.hw && length(XRT.devices()) < $required
            @warn "Test requires $($required) device(s). Not enough devices available\nSkipping testset"
            return nothing
        end

        @testset $description begin
            esc($expr)
        end
    end
end
