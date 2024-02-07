


function Run(kernel::Kernel, arg1, args...; autostart=true)
    k = Run(kernel)
    for (i, a) in enumerate(vcat([arg1], args...))
        set_arg!(k, i-1, a)
    end
    if autostart
        start(k)
    end
    k
end

function set_arg!(run::Run, index, val)
    val_array = [val]
    set_arg!(run, index, Base.unsafe_convert(Ptr{Nothing},val_array), sizeof(eltype(val)))
end

function set_arg!(run::Run, index, val::BO)
    adr = address(val)
    set_arg!(run, index, adr)
end 

function set_arg!(run::Run, index, val::BOArray)
    set_arg!(run, index, val.bo)
end

function wait(run::Run)
    wait(run, 0)
end