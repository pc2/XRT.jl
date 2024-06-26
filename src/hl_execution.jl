
"""

 prpeare_bitstream(path::String; device=XRT.Device(1))

 Load a bitstream to an FPGA and generate 
 interfaces for the included kernels.
 Returns a module with functions representing the 
 kernels of the bitstream.

 path: Path to the bitstream file (xclbin)
 device: XRT device to write the bitstream to

"""
function prepare_bitstream(path::String; device::XRT.Device=XRT.Device(1))
    uuid = load_xclbin!(device, path)
    j_data = XRT.get_kernel_info(path)
    return eval(:(
        module $(Symbol(first(split(basename(path),"."))))

        using XRT
        for jk in $j_data
            eval(quote

            args = [a["name"] for a in $(jk["arguments"])]
            arg_vector = [parse(Int, a["address_qualifier"]) == 1 for a in $(jk["arguments"])]
            arg_ids = [parse(Int, a["id"]) for a in $(jk["arguments"])]

            """
            $($(jk["name"]))($($(join([a["name"] for a in jk["arguments"]],", "))))

            Execute a kernel on the FPGA using the provided arguments and HLS data types:

            $($([a["name"] * "::" * a["type"] * "\n\n" for a in jk["arguments"]]...)) 

            The provided data types are C data types. Matching Julia data types have to be used as inputs!
            """
            function $(Symbol(jk["name"]))(args...)
                final_args = []

                kernel = XRT.Kernel($($device), $($uuid), $(String(jk["name"])), XRT.XRT_KERNEL_ACCESS_EXCLUSIVE)
                for (a, v, i) in zip(args, arg_vector, arg_ids)
                    if v
                        bo_array =  XRT.BOArray($($(device)), a, XRT.group_id(kernel, i))
                        XRT.sync!(bo_array, XRT.XCL_BO_SYNC_BO_TO_DEVICE) 
                        push!(final_args, bo_array)
                    else
                        push!(final_args, a)
                    end
                end
                XRT.wait(XRT.Run(kernel, final_args...))
                current_bo_id = 1
                for (a, v, fa) in zip(args, arg_vector, final_args)
                    if v
                        XRT.sync!(fa, XRT.XCL_BO_SYNC_BO_FROM_DEVICE) 
                        a[:] .= fa[:]
                    end
                end
            end
        end)
    end
end
    ))
end

