execution_time = @elapsed begin
    using XRT

    # Load the xclbin file
    loadxclbin_time = @elapsed begin
        xclbin = XRT.Xclbin("/dev/shm/random_access_kernels_single.xclbin")
        uuid = load_xclbin!(xclbin; device=XRT.device(1))
    end

    # Create the kernel
    kernel_time = @elapsed begin
        num_cus = 32
        kernels = Vector{XRT.Kernel}()

        for i in 1:num_cus
            push!(kernels, XRT.Kernel(uuid, "accessMemory_0:{accessMemory_0_$(i)}"; device=XRT.device(1)))
        end
    end

    # Allocate buffers
    allocation_time = @elapsed begin
        m = 2^29
        chunk_size = 2^24
        
        data = zeros(UInt64, m)
        random_init = rand(UInt64, m)

        xdatas = Vector{XRT.BOArray}()
        xrandom_inits = Vector{XRT.BOArray}()
        for i in 1:num_cus
            xdata = XRT.BOArray{UInt64, 1}(chunk_size, group_id(kernels[i], 0); device=XRT.device(1))
            xdata[:] = data[(i-1)*chunk_size+1:(i-1)*chunk_size+chunk_size]
            xrandom_init = XRT.BOArray{UInt64, 1}(chunk_size, group_id(kernels[i], 1); device=XRT.device(1))
            xrandom_init[:] = random_init[(i-1)*chunk_size+1:(i-1)*chunk_size+chunk_size]

            push!(xdatas, xdata)
            push!(xrandom_inits, xrandom_init)
        end
    end

    # Sync input buffer to device
    syncto_time = @elapsed begin
        for i in 1:num_cus
            sync!(xdatas[i], XRT.TO_DEVICE)
            sync!(xrandom_inits[i], XRT.TO_DEVICE)
        end
    end

    # Execute the kernel
    run_time = @elapsed begin
        runs = Vector{XRT.Run}()
        for i in 1:num_cus
            push!(runs, XRT.Run(kernels[i], xdatas[i], xrandom_inits[i], m, m ÷ num_cus, UInt32(1), UInt32(i-1)))
        end
        for i in 1:num_cus
            wait(runs[i])
        end
    end

    # Sync output buffer to host
    syncfrom_time = @elapsed begin
        for i in 1:num_cus
            sync!(xdatas[i], XRT.FROM_DEVICE)
            data[(i-1)*chunk_size+1:(i-1)*chunk_size+chunk_size] = xdatas[i][:]
        end
    end

    # Verify the results. At least 95% of the values have to differ.
    verify_time = @elapsed begin
        @assert length(findall(x -> x == 0, data)) / length(data) < 0.05
    end
end

println(loadxclbin_time)
println(kernel_time)
println(allocation_time)
println(syncto_time)
println(run_time)
println(syncfrom_time)
println(verify_time)
println(execution_time)