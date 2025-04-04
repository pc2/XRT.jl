execution_time = @elapsed begin
    using XRT

    # Call @prepare_bitstream
    prepare_time = @elapsed @eval @prepare_bitstream("/dev/shm/stream.xclbin")

    # Allocate buffers
    allocation_time = @elapsed begin
        array_size = 2^28

        a = Array{Float64}(MemAlign(4096), array_size)
        b = Array{Float64}(MemAlign(4096), array_size)
        c = Array{Float64}(MemAlign(4096), array_size)

        a[:] .= rand(array_size)
        b[:] .= rand(array_size)
        c[:] .= 0
    end

    # Execute the kernel
    run_time = @elapsed stream_calc__k1!(a, b, c, 2.0, UInt32(array_size), UInt32(1))

    # Verify results
    verify_time = @elapsed begin
        @assert all(c .≈ (2 .* a .+ b))
    end
end

println(prepare_time)
println(allocation_time)
println(run_time)
println(verify_time)
println(execution_time)
