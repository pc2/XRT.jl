const path = "../examples/stream/build_$(XRT.emulation_mode())/stream.xclbin"

function comparekeys(dict1::LazyJSON.Object, dict2::LazyJSON.Object)
    !(0 in (keys(dict1) .== keys(dict2)))
end

comparekeys(::Nothing, ::Nothing) = true

# The suite targets Alveo; an NPU has no xbutil reset/validate, rejects NORMAL buffer
# objects and does not implement several device-info queries.
is_npu(device) = occursin(r"npu"i, something(device.name, ""))
is_npu() = any(is_npu, XRT.devices())

function get_xclbin_path()
    path = "../examples/stream/build_$(XRT.emulation_mode())/stream.xclbin"
    
    if isfile(path)
        return path
    else
        error("Stream xclbin file not present")
    end
end

macro xclbin_testset(description::AbstractString, expr::Expr)
    testset = esc(:(@testset $description $expr))
    quote
        if isfile(path)
            $testset
        else
            @warn "Stream xclbin file not available\nSkipping testset"
        end
    end
end

macro devices_testset(required::Int, description::AbstractString, expr::Expr)
    testset = esc(:(@testset $description $expr))
    quote
        if XRT.emulation_mode() == XRT.XRTWrap.TargetType.hw && length(XRT.devices()) < $required
            @warn "Test requires $($required) device(s). Not enough devices available\nSkipping testset"
        else
            $testset
        end
    end
end
