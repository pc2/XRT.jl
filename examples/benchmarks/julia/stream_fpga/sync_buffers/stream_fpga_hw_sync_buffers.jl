execution_time = @elapsed begin
    using XRT

    # Load the xclbin file
    loadxclbin_time = @elapsed begin
        xclbin = XRT.Xclbin("/dev/shm/stream.xclbin")
        uuid = load_xclbin!(xclbin; device=XRT.device(1))
    end

    # Create the kernel
    kernel_time = @elapsed begin
        kernel = XRT.Kernel(uuid, "stream_calc:{k1}"; device=XRT.device(1))
    end

    # Allocate buffers
    allocation_time = @elapsed begin
        array_size = 2^28

        a = Array{Float64}(MemAlign(4096), array_size)
        b = Array{Float64}(MemAlign(4096), array_size)
        c = Array{Float64}(MemAlign(4096), array_size)

        a[:] .= rand(array_size)
        b[:] .= rand(array_size)
        c[:] .= 0

        xa = XRT.BOArray(a, group_id(kernel, 0); device=XRT.device(1))
        xb = XRT.BOArray(b, group_id(kernel, 1); device=XRT.device(1))
        xc = XRT.BOArray(c, group_id(kernel, 2); device=XRT.device(1))
    end


    # Execute the kernel
    run_time = @elapsed begin
        @eval XRT.@sync_buffers XRT.Run(kernel, xa, xb, xc, 2.0, array_size, 1)
        c[:] .= xc[:]
    end

    # Verify results
    verify_time = @elapsed begin
        @assert all(c .≈ (2 .* a .+ b))
    end
end

println(loadxclbin_time)
println(kernel_time)
println(allocation_time)
println(run_time)
println(verify_time)
println(execution_time)
