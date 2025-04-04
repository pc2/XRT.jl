execution_time = @elapsed begin
    using XRT

    # Load the xclbin file
    loadxclbin_time = @elapsed begin
        xclbin = XRT.Xclbin("/dev/shm/communication_PCIE.xclbin")
        uuid = load_xclbin!(xclbin; device=XRT.device(1))
    end

    # Create the kernel
    kernel_time = @elapsed begin
        kernel = XRT.Kernel(uuid, "dummyKernel"; device=XRT.device(1))
    end

    # Allocate buffers
    allocation_time = @elapsed begin
        array_size = 1

        a = Array{UInt8}(MemAlign(4096), array_size)
        a[:] .= UInt8(0)
        xa = XRT.BOArray(a, group_id(kernel, 0); device=XRT.device(1))
    end

    # Sync input buffer to device
    syncto_time = @elapsed begin
        sync!(xa, XRT.TO_DEVICE)
    end

    # Execute the kernel
    run_time = @elapsed wait(XRT.Run(kernel, xa, UInt8(1), array_size))

    # Sync output buffer to host
    syncfrom_time = @elapsed begin 
        sync!(xa, XRT.FROM_DEVICE)
        a[:] .= xa[:]
    end

    # Verify results
    verify_time = @elapsed begin
        @assert all(a .== UInt8(1))
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
