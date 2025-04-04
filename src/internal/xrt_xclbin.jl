abstract type AbstractGraphKernel end

abstract type AbstractGraphCU end

abstract type AbstractGraphMem end

mutable struct GraphKernel <: AbstractGraphKernel
    index::Int
    name::AbstractString
    mems::Vector{AbstractGraphMem}
    cus::Vector{AbstractGraphCU}
    kernels::Vector{AbstractGraphKernel}

    GraphKernel(index::Int, name::AbstractString) = new(index, name, Vector{AbstractGraphMem}(), Vector{AbstractGraphCU}(), Vector{AbstractGraphKernel}())
end

mutable struct GraphCU <: AbstractGraphCU
    index::Int
    name::AbstractString
    kernel::AbstractGraphKernel
    mems::Vector{AbstractGraphMem}
    cus::Vector{AbstractGraphCU}

    GraphCU(index::Int, name::AbstractString, kernel::AbstractGraphKernel) = new(index, name, kernel, Vector{AbstractGraphMem}(), Vector{AbstractGraphCU}())
end

mutable struct GraphMem <: AbstractGraphMem
    index::Int
    name::AbstractString
    kernel::AbstractGraphKernel
end

"""
$(TYPEDSIGNATURES)

See [`XRT.visualize_streams`](@ref).
"""
function draw_kernel_streams(xclbin::XRT.Xclbin, filter::AbstractString=""; io::IO=stdout, force_io::Bool=false)
    KERNEL_TITLE = "Kernel:"
    CU_TITLE = "Compute Unit:"
    MEM_TITLE = "Memory:"
    kernel_width = length(KERNEL_TITLE) + 2
    cu_width = length(CU_TITLE) + 2
    mem_width = length(MEM_TITLE) + 2

    system_metadata = LazyJSON.parse(XRT.get_section_string(xclbin.path, XRT.SectionType.SYSTEM_METADATA))
    all_kernels = Vector{GraphKernel}()
    
    for (idx, kernel) in enumerate(xclbin.kernels)
        kernel_width = max(kernel_width, length(kernel.name) + 2)
        tmp_kernel = GraphKernel(idx, kernel.name)

        # Add mems and cus
        for arg in kernel.args
            for mem in arg.mems
                mem_width = max(mem_width, length(mem.tag) + 2)
                if !any(obj -> obj.name == mem.tag, tmp_kernel.mems)
                    tmp_mem = GraphMem(length(tmp_kernel.mems) + 1, mem.tag, tmp_kernel)
                    push!(tmp_kernel.mems, tmp_mem)
                end
            end
        end
        for (jdx, cu) in enumerate(kernel.cus)
            cu_width = max(cu_width, length(cu.cu_name) + 2)
            tmp_cu = GraphCU(jdx, cu.cu_name, tmp_kernel)
            push!(tmp_kernel.cus, tmp_cu)
            
            for arg in cu.args
                for mem in arg.mems
                    mem_width = max(mem_width, length(mem.tag) + 2)
                    tmp_mem = nothing
                    if !any(obj -> obj.name == mem.tag, tmp_kernel.mems)
                        tmp_mem = GraphMem(length(tmp_kernel.mems) + 1, mem.tag, tmp_kernel)
                        push!(tmp_kernel.mems, tmp_mem)
                    else
                       tmp_mem = tmp_kernel.mems[findfirst(obj -> obj.name == mem.tag, tmp_kernel.mems)]
                    end

                    if !any(obj -> obj.name == mem.tag, tmp_cu.mems)
                        push!(tmp_cu.mems, tmp_mem)
                    end
                end
            end            
        end
        push!(all_kernels, tmp_kernel)
    end

    # CU CU connections
    for user_region in system_metadata["system_diagram_metadata"]["xclbin"]["user_regions"]
        for conn in user_region["connectivity"]
            if conn["node1"]["type"] == "compute_unit" &&
                conn["node2"]["type"] == "compute_unit"  &&
                !occursin("aie", conn["node1"]["arg_name"]) &&
                !occursin("aie", conn["node2"]["arg_name"])
                
                for kernel1 in all_kernels
                    cu1_index = findfirst(obj -> obj.name == conn["node1"]["name"], kernel1.cus)
                    if cu1_index != nothing
                        for kernel2 in all_kernels
                            cu2_index = findfirst(obj -> obj.name == conn["node2"]["name"], kernel2.cus)
                            if cu2_index != nothing
                                push!(kernel1.cus[cu1_index].cus, kernel2.cus[cu2_index])
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    # Kernel kernel connections
    for kernel in all_kernels
        for cu in kernel.cus
            for to_cu in cu.cus
                if to_cu.kernel.name != kernel.name && !any(obj -> obj.name == to_cu.kernel.name, kernel.kernels)
                    push!(kernel.kernels, to_cu.kernel)
                end
            end
        end
    end

    # Filter kernels / CUs / mems
    filter_type = nothing
    if length(filter) > 0
        for kernel in all_kernels
            if kernel.name == filter
                filter_type = :kernel
                break
            end
            for cu in kernel.cus
                if cu.name == filter
                    filter_type = :cu
                    break
                end
            end
        end
    end
    kernels = all_kernels
    if filter_type != nothing
        kernels = Vector{GraphKernel}()
        if filter_type == :kernel
            # Add filtered kernel
            filter_kernel = all_kernels[findfirst(obj -> obj.name == filter, all_kernels)]
            push!(kernels, filter_kernel)
            filter_kernel.index = 1
            for cu in filter_kernel.cus
                empty!(cu.cus)
            end

            # Add connected kernels
            for to_kernel in filter_kernel.kernels
                push!(kernels, to_kernel)
                to_kernel.index = length(kernels)
                empty!(to_kernel.cus)
                empty!(to_kernel.mems)
            end
        elseif filter_type == :cu
            cus = reduce(vcat, [kernel.cus for kernel in all_kernels])
            mems = reduce(vcat, [cu.mems for cu in cus])
            filter_cu = cus[findfirst(obj -> obj.name == filter, cus)]
            kernels = all_kernels

            # Remove unneeded cus
            for kernel in kernels
                if kernel.name == filter_cu.kernel.name
                    for i in length(kernel.cus):-1:1
                        if kernel.cus[i].name != filter_cu.name && !any(obj -> obj.name == kernel.cus[i].name, filter_cu.cus)
                            deleteat!(kernel.cus, i)
                        end
                    end
                else
                    for i in length(kernel.cus):-1:1
                        if !any(obj -> obj.name == kernel.cus[i].name, filter_cu.cus)
                            deleteat!(kernel.cus, i)
                        end
                    end
                end
            end


            # Remove unneeded kernels
            to_kernels = [cu.kernel for cu in filter_cu.cus]
            for i in length(kernels):-1:1
                if kernels[i].name != filter_cu.kernel.name && !any(obj -> obj.name == kernels[i].name, to_kernels)
                    deleteat!(kernels, i)
                end
            end

            # Remove unneeded mems
            new_cus = reduce(vcat, [kernel.cus for kernel in kernels])
            new_mems = reduce(vcat, [cu.mems for cu in new_cus])    
            for mem in mems
                if !any(obj -> obj.name == mem.name, new_mems)
                    for kernel in kernels
                        filter!(obj -> obj != mem, kernel.mems)
                        for cu in kernel.cus
                            filter!(obj -> obj != mem, cu.mems)
                        end
                    end
                end
            end

            # Repair index
            for (idx, kernel) in enumerate(kernels)
                kernel.index = idx
                for (jdx, mem) in enumerate(kernel.mems)
                    mem.index = jdx
                end
                for (jdx, cu) in enumerate(kernel.cus)
                    cu.index = jdx
                end
            end
        end
    end
    
    # Create graph as matrix
    required_height = fill(0, length(kernels))
    required_width = fill(0, length(kernels))
    required_cu_height = fill(0, length(kernels))
    required_cu_connection_width = fill(0, length(kernels)) 
    max_required_connection_width = 0
    kernel_connection_width = sum(map(obj -> length(obj.kernels), kernels)) == 0 ? 0 : sum(map(obj -> length(obj.kernels), kernels)) + 1

    for (idx, kernel) in enumerate(kernels)
        for cu in kernel.cus
            required_cu_connection_width[idx] += length(cu.cus)
        end
    end
    max_required_cu_connection_width = sum(required_cu_connection_width) > 0 ? sum(required_cu_connection_width) + 4 : 0
    
    for (idx, kernel) in enumerate(kernels)
        required_cu_height[idx] = 6 + 6 * length(kernel.cus) - 1
        required_mem_height = 6 + 6 * length(kernel.mems) - 1
        required_height[idx] = max(required_cu_height[idx], required_mem_height)

        required_connection_width = length(kernel.cus) * (length(kernel.mems) + 1) + 4 - 1
        max_required_connection_width = max(max_required_connection_width, required_connection_width)

        required_width[idx] = kernel_connection_width + kernel_width + max_required_cu_connection_width + cu_width + required_connection_width + mem_width + 10
    end

    max_required_width = maximum(required_width)
    graph = fill(' ', sum(required_height), max_required_width)
    
    y = 1
    for (idx, kernel) in enumerate(kernels)
        # Add Kernel
        draw_box!(graph, kernel_connection_width + 1, y, kernel_width, KERNEL_TITLE, kernel.name)

        # Add CUs
        for (jdx, cu) in enumerate(kernel.cus)
            draw_box!(graph, kernel_connection_width + kernel_width + 2 + max_required_cu_connection_width, y + (6 * jdx), cu_width, CU_TITLE, cu.name)
        end

        # Add Mems
        for (jdx, mem) in enumerate(kernel.mems)
            draw_box!(graph, required_width[idx] - mem_width - 6, y + (6 * jdx), mem_width, MEM_TITLE, mem.name)
        end

        # Connect Kernel and CUs
        draw_kernel_cu_connection!(graph, kernel_connection_width, y, kernel_width, max_required_cu_connection_width, required_cu_height[idx])

        # Connect Kernel and Mems
        if length(kernel.mems) > 0            
            graph[y+2, kernel_connection_width + kernel_width+2] = '├'
            graph[y+2, kernel_connection_width + kernel_width+3:required_width[idx]-1] .= '─'
            graph[y+2, required_width[idx]] = '┐'
        
            graph[y+3:y+3+6*length(kernel.mems)-2, required_width[idx]] .= '│'
        
            for mem in kernel.mems
                mem_y = y + 2 + 6 * mem.index
                if mem.index < length(kernel.mems)
                    graph[mem_y, required_width[idx]] = '┤'
                else
                    graph[y+2+6*length(kernel.mems), required_width[idx]] = '┘'
                end
                graph[mem_y, required_width[idx]-3:required_width[idx]-1] .= '─'
                graph[mem_y, required_width[idx]-5] = '├'
                graph[mem_y, required_width[idx]-4] = '◄'
            end
        end

        # Connect CU and Mems
        for (jdx, cu) in enumerate(kernel.cus)
            if length(cu.mems) > 0
                cu_y = y + 2 + 6 * jdx
                cu_x = kernel_connection_width + kernel_width + max_required_cu_connection_width + cu_width
                # Prepare CU connectors
                graph[cu_y-1, cu_x+3] = '├'
                graph[cu_y-1, cu_x+4] = '►'
                graph[cu_y-1, cu_x+5] = '─'
        
                max_current_connection_width = (length(kernel.cus) - jdx + 1) * (length(kernel.mems) + 1) - 1
                max_current_connection_x = kernel_width + cu_width + 6 + max_required_cu_connection_width + max_current_connection_width - 1
                graph[cu_y-1, cu_x+6:max_current_connection_x] .= '─'
        
                # Draw up down connections
                distances = map(abs, jdx .- map(obj -> obj.index, cu.mems))
                sorted_mems = map(obj -> obj.index, cu.mems)[sortperm(distances)]
                for (idx, j) in enumerate(sorted_mems)
                    x = kernel_connection_width + max_current_connection_x - idx + 1
                    if jdx <= j
                        # downwards
                        if idx == 1
                            graph[cu_y-1, x] = '┐'
                        else
                            graph[cu_y-1, x] = '┬'
                        end
                        distance = distances[findfirst(obj -> obj.index == j, cu.mems)] * 6
                        graph[cu_y:cu_y+distance, x] .= '│'
        
                        last_connection = true
                        for k in jdx+1:length(kernel.cus)
                            if j in map(obj -> obj.index, kernel.cus[k].mems)
                                last_connection = false
                                break
                            end
                        end
                        if last_connection
                            graph[cu_y+distance+1, x] = '└'
                        else
                            graph[cu_y+distance+1, x] = '┴'
                        end
                    else
                        # upwards
                        if idx == 1
                            graph[cu_y-1, x] = '┘'
                        else
                            graph[cu_y-1, x] = '┴'
                        end
                        distance = (distances[findfirst(obj -> obj.index == j, cu.mems)] - 1) * 6 + 2
                        graph[cu_y-distance-2:cu_y-2, x] .= '│'
        
                        last_connection = true
                        for k in jdx+1:length(kernel.cus)
                            if j in map(obj -> obj.index, kernel.cus[k].mems)
                                last_connection = false
                                break
                            end
                        end
                        if last_connection
                            graph[y+6*jdx-distance-1, x] = '┌'
                        else
                            graph[y+6*jdx-distance-1, x] = '┬'
                        end
                    end
                end
            end
        end
        
        # Prepare Mem connectors
        for (jdx, mem) in enumerate(kernel.mems)
            mem_y = y + 3 + 6 * jdx 
            graph[mem_y, required_width[idx]-mem_width-6] = '┤'
            graph[mem_y, required_width[idx]-mem_width-7] = '►'
            graph[mem_y, required_width[idx]-mem_width-8] = '─'
    
            tmp_connection_width = length(kernel.cus) * length(kernel.mems) + max_required_cu_connection_width
            for j in 1:tmp_connection_width
                if graph[mem_y, required_width[idx]-mem_width-8-j] == '┌' || graph[mem_y, required_width[idx]-mem_width-8-j] == '└'
                    break
                end 
                if graph[mem_y, required_width[idx]-mem_width-8-j] == ' '
                    graph[mem_y, required_width[idx]-mem_width-8-j] = '─'
                end
            end
        end
        y += required_height[idx]
    end

    # Connect CUs
    y = 1
    cu_index = 1
    for (idx, kernel) in enumerate(kernels)
        for (jdx, cu) in enumerate(kernel.cus)
            if length(cu.cus) > 0        
                cu_y = y + 3 + 6 * cu.index
                cu_x = kernel_connection_width + kernel_width + 2 + max_required_cu_connection_width

                for (kdx, to_cu) in enumerate(cu.cus)                                  
                    if kdx == length(cu.cus)
                        if to_cu.kernel.index > cu.kernel.index
                            graph[cu_y, cu_x-2-cu_index] = '┌'
                        elseif to_cu.kernel.index < cu.kernel.index
                            graph[cu_y, cu_x-2-cu_index] = '└'
                        else
                            if to_cu.index > cu.index
                                graph[cu_y, cu_x-2-cu_index] = '┌'
                            elseif to_cu.index < cu.index
                                graph[cu_y, cu_x-2-cu_index] = '└'
                            end
                        end
                    else
                        if to_cu.kernel.index > cu.kernel.index || (to_cu.kernel.index == cu.kernel.index && to_cu.index > cu.index)
                            graph[cu_y, cu_x-2-cu_index] = '┬'
                        elseif to_cu.kernel.index < cu.kernel.index || (to_cu.kernel.index == cu.kernel.index && to_cu.index < cu.index)
                            graph[cu_y, cu_x-2-cu_index] = '┴'
                        end
                    end

                    to_cu_y = sum(required_height[1:to_cu.kernel.index-1]) + 6 + 6 * (to_cu.index - 1) + 1
                    
                    if to_cu.kernel.index > cu.kernel.index || (to_cu.kernel.index == cu.kernel.index && to_cu.index > cu.index)
                        graph[cu_y+1:to_cu_y, cu_x-2-cu_index] .= '│'
                        if to_cu.name in map(obj -> obj.name, to_cu.kernel.cus)
                            graph[to_cu_y+1, cu_x-2-cu_index] = '┴'
                        else
                            graph[to_cu_y+1, cu_x-2-cu_index] = '└'
                        end
                    elseif to_cu.kernel.index < cu.kernel.index || (to_cu.kernel.index == cu.kernel.index && to_cu.index < cu.index)
                        graph[to_cu_y:cu_y-1, cu_x-2-cu_index] .= '│'
                        if to_cu.name in map(obj -> obj.name, to_cu.kernel.cus)
                            graph[to_cu_y-1, cu_x-2-cu_index] = '┬'
                        else
                            graph[to_cu_y-1, cu_x-2-cu_index] = '┌'
                        end
                    end
                end

                graph[cu_y, cu_x] = '┤'
                graph[cu_y, cu_x-1] = '◄'
                tmp_connection_width = length(kernel.cus) * length(kernel.mems) + max_required_cu_connection_width
                for j in 1:tmp_connection_width
                    if graph[cu_y, cu_x-1-j] == '┌' || graph[cu_y, cu_x-1-j] == '└'
                        break
                    end 
                    if graph[cu_y, cu_x-1-j] == ' '
                        graph[cu_y, cu_x-1-j] = '─'
                    end
                end
                
                cu_index += 1
            end
        end
        y += required_height[kernel.index]
    end

    # Connect kernels
    kernel_connection = 1
    for kernel in kernels
        if length(kernel.kernels) > 0
            kernel_y = sum(required_height[1:kernel.index-1]) + 4
            kernel_x = kernel_connection_width

            graph[kernel_y, kernel_x+1] = '┤'
            graph[kernel_y, kernel_x] = '◄'
            
            for (idx, to_kernel) in enumerate(kernel.kernels)
                to_kernel_y = sum(required_height[1:to_kernel.index-1]) + 2
                graph[to_kernel_y, kernel_x+1] = '┤'
                graph[to_kernel_y, kernel_x] = '►'

                if kernel.index < to_kernel.index
                    if idx == length(kernel.kernels)
                        graph[kernel_y, kernel_x-kernel_connection] = '┌'
                    else
                        graph[kernel_y, kernel_x-kernel_connection] = '┬'
                    end
                    graph[kernel_y+1:to_kernel_y-1, kernel_x-kernel_connection] .= '│'
                    graph[to_kernel_y, kernel_x-kernel_connection] = '└'
                elseif kernel.index > to_kernel.index
                    if idx == length(kernel.kernels)
                        graph[kernel_y, kernel_x-kernel_connection] = '└'
                    else
                        graph[kernel_y, kernel_x-kernel_connection] = '┴'
                    end
                    graph[to_kernel_y+1:kernel_y-1, kernel_x-kernel_connection] .= '│'
                    graph[to_kernel_y, kernel_x-kernel_connection] = '┌'
                end
                
                for i in 1:kernel_connection
                    if graph[to_kernel_y, kernel_x-kernel_connection+i] == ' '
                        graph[to_kernel_y, kernel_x-kernel_connection+i] = '─'
                    elseif graph[to_kernel_y, kernel_x-kernel_connection+i] == '└'
                        graph[to_kernel_y, kernel_x-kernel_connection+i] = '┴'
                    elseif graph[to_kernel_y, kernel_x-kernel_connection+i] == '┌'
                        graph[to_kernel_y, kernel_x-kernel_connection+i] = '┬'
                    end
                end
                
                kernel_connection += 1
            end
        end
    end

    # Print graph
    rows, cols = Base.displaysize(io)
    if max_required_width > cols && !force_io
        temp_path, temp_file = mktemp("."; cleanup=false)
        for row in eachrow(graph)
            write(temp_file, "$(join(row))\n")
        end        
        close(temp_file)
        new_path = joinpath(dirname(temp_path), "xrtjl_" * basename(temp_path) * ".txt")
        mv(temp_path, new_path)
        @warn "Terminal size to small. Writing output to file $new_path"
    else
        for row in eachrow(graph)
            println(io, join(row))
        end
    end
    nothing
end

"""
$(TYPEDSIGNATURES)

Internal function that draws connecting arrows from the kernel box to its corresponding cu boxes.
"""
@inline function draw_kernel_cu_connection!(graph::Matrix{Char}, x::Int, y::Int, kernel_width::Int, cu_connection_width::Int, required_cu_height::Int)
    new_x = kernel_width ÷ 2 + 1 + x
    max_y = y + required_cu_height - 4
    if max_y >= y + 4
        graph[y+4, new_x] = '┬'
        graph[y+5:max_y, new_x] .= '│'
        graph[y+7:6:max_y, new_x] .= '├'
        graph[y+7:6:max_y+1, new_x+1:x+kernel_width+cu_connection_width] .= '─'
        graph[y+7:6:max_y+1, x+kernel_width+cu_connection_width+1] .= '►'
        graph[y+7:6:max_y+1, x+kernel_width+cu_connection_width+2] .= '┤'
        graph[max_y, new_x] = '└'
    end
end

"""
$(TYPEDSIGNATURES)

Internal function that draws a five rows high box with a title and an input string to given coordinates of a char matrix.
The function throws an exception if the box does not fit the matrix.
The output looks like following:

```
┌──────────────┐
│    title     │
│              │
│ input string │
└──────────────┘
```
"""
@inline function draw_box!(graph::Matrix{Char}, x::Int, y::Int, width::Int, title::AbstractString, input::AbstractString)
    @assert width >= length(title) && width >= length(input)
    @assert x + width + 1 <= size(graph, 2)
    @assert y + 4 <= size(graph, 1)

    max_x = x + width + 1
    max_y = y + 4
    
    # Draw outline
    graph[y, x] = '┌'
    graph[y, x+1:max_x-1] .= '─'
    graph[y, max_x] = '┐'
    graph[y+1:max_y-1, x] .= '│'
    graph[y+1:max_y-1, max_x] .= '│'
    graph[max_y, x] = '└'
    graph[max_y, x+1:max_x-1] .= '─'
    graph[max_y, max_x] = '┘'

    # Fill title  
    space = (width - length(title) + 1) ÷ 2
    for i in 1:length(title)
        graph[y+1, x+space+i] = collect(title)[i]
    end

    # Fill input
    space = (width - length(input) + 1) ÷ 2
    for i in 1:length(input)
        graph[max_y-1, x+space+i] = collect(input)[i]
    end
end

function cpp_to_julia(cpp_type::AbstractString; boarray=false)
    types_map = Dict(
            "int" => Int32,
            "unsigned int" => UInt32,
            "uint" => UInt32,
            "long" => Int64,
            "unsigned long" => UInt64,
            "ulong" => UInt64,
            "half" => Float16,
            "float" => Float32,
            "double" => Float64,
            "char" => UInt8,
            "bool" => Bool,
            "std::string" => String
        )

    is_array = false

    if cpp_type[end] == '*'
        is_array = true
    end
        
    if is_array
        type = get(types_map, cpp_type[1:end-1], Any)
        if boarray
            if type == Any
                return Union{XRT.AbstractBOArray,
                    XRT.AbstractSyncDirectionWrapper}
            else
                return Union{XRT.AbstractBOArray{type},
                    XRT.AbstractSyncDirectionWrapper}
            end
        else
            if type == Any
                return Union{AbstractArray,
                    XRT.AbstractSyncDirectionWrapper}
            else
                return Union{AbstractArray{type},
                    XRT.AbstractSyncDirectionWrapper}
            end
        end
    else
        return get(types_map, cpp_type, Any)
    end
end
