
"""
$(SIGNATURES)

 Parse a bitstream and generate functions for the included kernels.
 The functions will automatically copy all relevant buffers to the 
 FPGA memory, and execute the Kernel.

 It is recommended to generate the kernel functions in a separate module
 like this:

 ```Julia
 module DummyBitstream
    using XRT
    @prepare_bitstream("my_bitstream.xclbin")
 end
 ```

 Afterwards, you find the functions for each kernel in the module.
 To execute the kernel on a specific device, use the `device` keyword parameter:

 ```Julia
 DummyBitstream.kernel_name!(args...; device=XRT.Device(0))
 ```

"""
macro prepare_bitstream(path::String)
    j_data = XRT.get_kernel_info(path)
    mod_funcs = Expr[]
    for jk in j_data 
        args = [Symbol(a["name"]) for a in jk["arguments"]]
        arg_vector = [parse(Int, a["address_qualifier"]) == 1 for a in jk["arguments"]]
        arg_ids = [parse(Int, a["id"]) for a in jk["arguments"]] 
        fname = esc(Symbol(jk["name"],"!"))
        f = quote

            """
            ```Julia
            $($(jk["name"]))!($($(join([a["name"] for a in jk["arguments"]],", "))); device=XRT.Device(0))
            ```

            Execute a kernel on the FPGA using the provided arguments and HLS data types:

            $($([a["name"] * "::" * a["type"] * "\n\n" for a in jk["arguments"]]...)) 

            The provided data types are C data types. Matching Julia data types have to be used as inputs!
            """
            function $(fname)($([esc(a) for a in args]...); device=XRT.Device(0))
                uuid = load_xclbin!(device, $path)
                kernel = XRT.Kernel(device, uuid, $(String(jk["name"])))
                # Generate the code for buffer synchronization
                # and the actual kernel execution
                Expr(:block, $(begin                
                    final_args = []
                    exp = Expr[]

                    for (a, v, i) in zip(args, arg_vector, arg_ids)
                        if v
                            sym_bo = esc(Symbol("bo_array",i))
                            push!(exp, :($sym_bo =  XRT.BOArray(device, $a, XRT.group_id(kernel, $i))))
                            push!(exp, :(XRT.sync!($sym_bo, XRT.XCL_BO_SYNC_BO_TO_DEVICE)))
                            push!(final_args, sym_bo)
                        else
                            push!(final_args, a)
                        end
                    end
                    push!(exp, :(XRT.wait(XRT.Run(kernel, $(final_args...)))))
                    for (a, v, fa) in zip(args, arg_vector, final_args)
                        if v
                            push!(exp, :(XRT.sync!($fa, XRT.XCL_BO_SYNC_BO_FROM_DEVICE)))
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
    Expr(:block, mod_funcs...)
end

