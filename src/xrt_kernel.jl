using .XRTWrap: Kernel, Run, BO, group_id, offset, get_name, set_arg!, wait, start, XRT_KERNEL_ACCESS_SHARED, XRT_KERNEL_ACCESS_EXCLUSIVE, XRT_KERNEL_ACCESS_NONE
import XRT: set_arg!, wait

"""
$(SIGNATURES)

Create a new kernel instance using a device, bitstream uuid, and kernel name.
"""
function Kernel(device::Device, uuid::UUID, name::String)
    Kernel(device, uuid, name, XRT_KERNEL_ACCESS_SHARED)
end

"""
$(SIGNATURES)

Execute a kernel with the given arguments.
To automatically start the execution, set `autostart` to `true`.
Otherwise, the execution has to be explicitly started by calling start(run::Run)
"""
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

"""
$(SIGNATURES)

Set the argument for a kernel at the given index.
Note, that this is a thin wrapper to the C++ API,
so the indices start at 0!
"""
function set_arg!(run::Run, index, val)
    val_array = [val]
    set_arg!(run, index, Base.unsafe_convert(Ptr{Nothing},val_array), sizeof(eltype(val)))
end

"""
$(SIGNATURES)

Set the argument for a kernel at the given index to a given BO.
Note, that this is a thin wrapper to the C++ API,
so the indices start at 0!
"""
function set_arg!(run::Run, index, val::BO)
    adr = address(val)
    set_arg!(run, index, adr)
end 

"""
$(SIGNATURES)

Set the argument for a kernel at the given index to a given BOArray.
Note, that this is a thin wrapper to the C++ API,
so the indices start at 0!
"""
function set_arg!(run::Run, index, val::BOArray)
    set_arg!(run, index, val.bo)
end

"""
$(SIGNATURES)

Wait for a given Run object to complete execution.
The method will return as soon as the execution is completed.
"""
function wait(run::Run)
    wait(run, 0)
end