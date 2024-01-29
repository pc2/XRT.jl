
function Run(kernel::Kernel, args...; autostart=true)
    k = Run(kernel)
    for (i, a) in enumerate(args)
        set_arg(k, i, a)
    end
    if autostart
        start(k)
    end
    k
end

function set_arg!(run::Run, index, val)
    set_arg!(run, index, val[], sizeof(val))
end

function set_arg!(run::Run, index, val::BOArray)
    set_arg!(run, index, val.bo)
end
