"""
$(TYPEDSIGNATURES)

Parse a bitstream and generate functions for the included kernels.
The functions will automatically copy all relevant buffers to the FPGA memory, and execute the Kernel.

It is recommended to generate the kernel functions in a separate module like this:

```Julia
module DummyBitstream
    using XRT
    @prepare_bitstream("my_bitstream.xclbin")
end
```

Afterwards, you find the functions for each kernel in the module.
To execute the kernel on a device other than the current active device, use the `device` keyword parameter:

```Julia
julia> DummyBitstream.kernel_name!(args...; device=XRT.device(2))
```

You can also directly execute a single specific compute unit of the kernel specified by '__':

```Julia
julia> DummyBitstream.kernel_name__cu_name!(args...)
```

"""
macro prepare_bitstream(path::String)
    xclbin = XRT.Xclbin(path)
    mod_funcs = Expr[]
    for kernel in xclbin.kernels
        names = Vector{AbstractString}()
        push!(names, kernel.name)
        fnames = [esc(Symbol(kernel.name, "!"))]
        arguments = kernel.args
        args = [Symbol(a.name) for a in arguments]
        arg_types = [a.julia_type for a in arguments]
        arg_vector = [size(a.mems, 1) >= 1 for a in arguments]
        arg_ids = [a.index for a in arguments] 

        if length(kernel.cus) > 1
            append!(names, [replace(cu.name, r"(:)(.*)" => s"\1{\2}") for cu in kernel.cus])
            append!(fnames, [esc(Symbol(replace(cu.name, ":" => "__"), "!")) for cu in kernel.cus])
        end

        for (i, name) in enumerate(names)
            f = quote
                """
                ```Julia
                $($(fnames[i]))($($(join([(a.name * "::" * string(a.julia_type)) for a in arguments],", "))); device=XRT.device())
                ```

                Execute a kernel on the FPGA using the provided arguments and HLS data types:

                $($(["`" * a.name * "::" * string(a.julia_type) * "`\n\n" for a in arguments]...))

                The provided data types are C data types converted to Julia types. Unknown types are converted as `Any` type.
                """
                function $(fnames[i])($([:($arg::$type) for (arg, type) in zip(args, arg_types)]...); device::XilinxDevice=XRT.device())
                    uuid = load_xclbin!($path; device=device)
                    kernel = XRT.Kernel(uuid, $name; device=device)
                    # Generate the code for buffer synchronization
                    # and the actual kernel execution
                    Expr(:block, $(begin                
                        final_args = []
                        exp = Expr[]

                        for (a, v, i) in zip(args, arg_vector, arg_ids)
                            if v
                                sym_bo = esc(Symbol("bo_array",i))
                                push!(exp,:(if $a isa ToDeviceWrapper{T} where T <: AbstractArray 
                                                $sym_bo =  XRT.ToDeviceWrapper(XRT.AbstractBOArray($a.object, XRT.group_id(kernel, $i); device=device))
                                            elseif $a isa FromDeviceWrapper{T} where T <: AbstractArray 
                                                $sym_bo =  XRT.FromDeviceWrapper(XRT.AbstractBOArray($a.object, XRT.group_id(kernel, $i); device=device))
                                            elseif $a isa AbstractArray
                                                $sym_bo =  XRT.AbstractBOArray($a, XRT.group_id(kernel, $i); device=device)
                                            else
                                                error("$a is neither an AbstractArray nor a wrapped AbstractArray")
                                            end  
                                ))
                                push!(exp, :(XRT.sync!($sym_bo, XRT.XRTWrap.BOSyncDirection.TO_DEVICE)))         
                                push!(final_args, sym_bo)
                            else
                                push!(final_args, a)
                            end
                        end
                        push!(exp, :(XRT.wait(XRT.Run(kernel, $(final_args...)))))
                        for (a, v, fa) in zip(args, arg_vector, final_args)
                            if v
                                push!(exp, :(XRT.sync!($fa, XRT.XRTWrap.BOSyncDirection.FROM_DEVICE)))
                                push!(exp, :($a[:] .= $fa[:]))
                            end
                        end
                        exp
                    end...))
                    nothing
                end 
            end
            push!(mod_funcs, f)
        end
    end
    Expr(:block, mod_funcs...)
end

"""
$(TYPEDSIGNATURES)

Synchronise relevant buffers to or from the FPGA device.
Therefore, the macro searches for calls of [`XRT.Run`](@ref) function and detects if its parameters are [`XRT.BOArray`](@ref) objects, which need to be synchronised.
If the buffer objects are to be synchronised back to the host, the completion of the `XRT.Run` function is also ensured after the expression. 

Note: The `XRT.Run` function requires the `autostart` keyword argument set to true or is manually started within the expression if the buffer objects should be synchronised back to the host.

**Keywords**

**`direction`** specifies the desired synchronisation direction.
The keyword argument can be set to either `XRT.TO_DEVICE` or `XRT.FROM_DEVICE`.
If the argument is omitted, synchronisation takes place in both directions.

For some exemplary applications of the `XRT.@sync_buffers` macro, an environment is first defined that corresponds to the usual kernel preparation:

```Julia
uuid = load_xclbin!("path/to/bitstream.xclbin")
kernel = XRT.Kernel(uuid, "kernel")

a = Array{Float64}(MemAlign(4096), 1024)
xa = XRT.BOArray(a, group_id(kernel, 0))
```

To subsequently execute the kernel without taking the buffer synchronisation into account, the macro can be used as follows:

```Julia
julia> XRT.@sync_buffers Run(kernel, xa)
```

The `XRT.BOArray` `xa` then contains the values returned by the kernel.
Optionally, the synchronisation for a single direction can be handled manually.
In the following case the termination of `Run` is not asured by the macro and has to be handled manually:

```Julia
julia> XRT.@sync_buffers direction=XRT.TO_DEVICE r = Run(kernel, xa)

julia> XRT.wait(r)

julia> sync!(xa, XRT.FROM_DEVICE)
```

In the opposite case, the termination of `wait` is handled after all:

```Julia
julia> sync!(xa, XRT.TO_DEVICE)

julia> XRT.@sync_buffers direction=XRT.FROM_DEVICE r = Run(kernel, xa)
```
"""
macro sync_buffers(ex::Vararg{Expr})
    expr = ex[end]
    kwargs = ex[1:end-1]

    sync_direction = nothing
    for kwarg in kwargs
        Meta.isexpr(kwarg, :(=)) || error("Invalid keyword argument $kwarg")
        key, value = kwarg.args
        if key == :direction
            value = eval(value)
            (value isa XRT.XRTWrap.BOSyncDirection.Type && (value == XRT.TO_DEVICE || value == XRT.FROM_DEVICE)) || 
                error("Invalid optional synchronisation direction. Must be either XRT.TO_DEVICE or XRT.FROM_DEVICE")
            sync_direction = value
        else
            error("Unknown keyword argument $kwarg")
        end
    end

    RUN = "Run" 
    run_names = Set{Symbol}()
    run_expr = Vector{Expr}()
    temp_expr_index = Vector{Int}()
    run_expr_index = Vector{Vector{Int}}()
    skip_expr_index = Set{Vector{Int}}()
    symbols = Set{Symbol}()
    
    function inspect_args(expr::Expr)
        if expr.head == :call && (expr.args[2] isa Expr && expr.args[2].head == :call &&
            ((expr.args[2].args[1] isa Symbol && startswith(string(expr.args[1]), RUN)) ||
            (expr.args[2].args[1] isa Expr && findfirst(obj -> hasfield(typeof(obj), :value) && startswith(string(obj.value), RUN), expr.args[2].args[1].args) != nothing)))
            # Run wrapped by wait or other function
            push!(skip_expr_index, [temp_expr_index..., 2])
        end
        
        if expr.head == :(=) && (expr.args[2] isa Expr && expr.args[2].head == :call &&
            ((expr.args[2].args[1] isa Symbol && startswith(string(expr.args[1]), RUN)) ||
            (expr.args[2].args[1] isa Expr && findfirst(obj -> hasfield(typeof(obj), :value) && startswith(string(obj.value), RUN), expr.args[2].args[1].args) != nothing)))
            # Run has named variable
            push!(run_names, expr.args[1])
            push!(skip_expr_index, [temp_expr_index..., 2])
        end
        
        if expr.head == :call && ((expr.args[1] isa Symbol && startswith(string(expr.args[1]), RUN)) ||
            (expr.args[1] isa Expr && findfirst(obj -> hasfield(typeof(obj), :value) && startswith(string(obj.value), RUN), expr.args[1].args) != nothing))
            push!(run_expr, expr)
            push!(run_expr_index, Base.copy(temp_expr_index))
            for arg in expr.args
                if typeof(arg) == Symbol
                    push!(symbols, arg)
                end
            end
        end
    end
    
    function traverse(expr::Expr)
        inspect_args(expr)
        for (index, arg) in enumerate(expr.args)
            if typeof(arg) == Expr
                if arg.head == :call || arg.head == :block || arg.head == :macrocall || arg.head == :(=)
                    push!(temp_expr_index, index)
                    traverse(arg)
                    pop!(temp_expr_index)
                end
            end
        end
    end

    traverse(expr)
    if sync_direction != XRT.TO_DEVICE
        if expr.head == :call && (startswith(string(expr.args[1]), RUN) ||
                (expr.args[1] isa Expr && findfirst(obj -> hasfield(typeof(obj), :value) && startswith(string(obj.value), RUN), expr.args[1].args) != nothing))
            expr = :(XRT.wait($expr))
        else
            for (i, single_run_expr_index) in enumerate(run_expr_index)
                if single_run_expr_index in skip_expr_index
                    continue
                end

                change_expr = expr
                while length(single_run_expr_index) > 1
                    change_expr = change_expr.args[popfirst!(single_run_expr_index)]
                end
                r = gensym("r")
                push!(run_names, r)
                change_expr.args[popfirst!(single_run_expr_index)] = :($r = $(run_expr[i]))
            end
        end
    end

    sync_to = Vector{Expr}()
    sync_from = Vector{Expr}()
    for arg in symbols
        push!(sync_to, :(if typeof($arg) <: XRT.AbstractBOArray || (typeof($arg) <: XRT.AbstractSyncDirectionWrapper{T} where T <: XRT.AbstractBOArray) sync!($arg, XRT.TO_DEVICE) end))
        push!(sync_from, :(if typeof($arg) <: XRT.AbstractBOArray || (typeof($arg) <: XRT.AbstractSyncDirectionWrapper{T} where T <: XRT.AbstractBOArray) sync!($arg, XRT.FROM_DEVICE) end))      
    end
    wait = Vector{Expr}()
    for run in run_names
        push!(wait, :(wait($run)))
    end

    quote
        @static if $sync_direction != XRT.FROM_DEVICE
            $(esc(Expr(:block, sync_to...)))
        end
        $(esc(expr))
        @static if $sync_direction != XRT.TO_DEVICE
            $(esc(Expr(:block, wait...)))
            $(esc(Expr(:block, sync_from...)))
        end
    end
end

"""
$(TYPEDSIGNATURES)

Parse a bitstream and generate adapted, typed XRT.Run function for a given kernel or compute unit.
Returns tuple of `XRT.Kernel` and `XRT.UUID` object for the specific kernel.

It is recommended to generate the function in a separate module like this:

```Julia
module DummyBitstream
    using XRT
    kernel, uuid = @prepare_run("my_bitstream.xclbin", "dummyKernel", device=device())
end
```

Afterwards, you find the function for the kernel object in the module.

```Julia
julia> DummyBitstream.Run_kernel_name(args...; autostart=true)
```

You can also directly execute a single specific compute unit of the kernel specified by '__':

```Julia
julia> DummyBitstream.Run_kernel_name__cu_name(args...; autostart=true)
```
"""
macro prepare_run(path::String, name::String, kwargs::Vararg{Expr})
    device = XRT.device()
    for kwarg in kwargs
        Meta.isexpr(kwarg, :(=)) || error("Invalid keyword argument $kwarg")
        key, value = kwarg.args
        if key == :device
            value = eval(value)
            value isa XRT.XilinxDevice || error("Invalid device value. Must be XRT.XilinxDevice.")
            device = value
        else
            error("Unknown keyword argument $kwarg")
        end
    end

    mod_funcs = Expr[]
    xclbin = XRT.Xclbin(path)
    kernel_cu = split(name, ":")
    cu_name = name
    
    xclbinkernel = nothing

    if length(kernel_cu) >= 1 && length(kernel_cu) <= 2
        i = findfirst(obj -> obj.name == kernel_cu[1], xclbin.kernels)
        if i == nothing
            error("No kernel '$(kernel_cu[1])' found.")
        end
        xclbinkernel = xclbin.kernels[i]
    else
        error("Invalid kernel name.")
    end
    if length(kernel_cu) == 2
        cu_name = replace(kernel_cu[2], r"^\{(.*)\}$" => s"\1") 
        i = findfirst(obj -> obj.cu_name == cu_name, xclbinkernel.cus)
        if i == nothing
            error("No cu '$(cu_name)' found.")
        end
        xclbinkernel = xclbinkernel.cus[i]
    end

    arguments = xclbinkernel.args
    args = [Symbol(a.name) for a in arguments]
    arg_types = [_XRTInternal.cpp_to_julia(a.host_type; boarray=true) for a in arguments]

    kernel_name = ""
    function_name = Symbol("Run")

    if length(kernel_cu) == 1
        kernel_name = String(kernel_cu[1])
        function_name = esc(Symbol("Run_", kernel_name))
    elseif length(kernel_cu) == 2 
        kernel_name = String(kernel_cu[1] * ":" * replace(kernel_cu[2], r"^(?!\{).*(?<!\})$" => s"{\0}"))
        function_name = esc(Symbol("Run_", kernel_cu[1], "__", cu_name))
    end

    f = quote
        uuid = load_xclbin!($path; device=$device)
        kernel = XRT.Kernel(uuid, $kernel_name; device=$device)

        """
        ```Julia
        $($(function_name))($($(join([a.name * "::" * string(_XRTInternal.cpp_to_julia(a.host_type; boarray=true)) for a in arguments],", "))); autostart=true)

        ```

        Function similar to the generic [`XRT.Run`](@ref), but with a fixed kernel object and type hints for the arguments.
        
        $($(["`" * a.name * "::" * string(_XRTInternal.cpp_to_julia(a.host_type; boarray=true)) * "`\n\n" for a in arguments]...))

        The provided data types are C data types converted to Julia types. Unknown types are converted as `Any` type.
        """
        function $(function_name)($([:($arg::$type) for (arg, type) in zip(args, arg_types)]...); autostart=true)
            XRT.Run(kernel, $(args...); autostart)
        end
        @info "Generated function $(@__MODULE__).$($(function_name))(...)"
        kernel, uuid
    end
    push!(mod_funcs, f)
    Expr(:block, mod_funcs...)
end
