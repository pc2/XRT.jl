using XRT
using ArrayAllocators
using Logging

array_size = 2^20

if !("XCL_EMULATION_MODE" in keys(ENV))
    # Hardware execution. Increase array array_size
    array_size = 2^28
end

# Allocate an output array
@info "Allocate and initialize arrays"
a = Array{Float64}(MemAlign(4096),array_size)
b = Array{Float64}(MemAlign(4096),array_size)
c = Array{Float64}(MemAlign(4096),array_size)

for i in 1:array_size
    a[i] = rand()
    b[i] = rand()
    c[i] = 0
end

# Load the bitstream to the FPGA and generate functions 
# for each kernel
@info "Upload bitstream and generate kernel functions"
bs = XRT.prepare_bitstream("build_sw_emu/stream.xclbin")

# execute the stream kernel
@info "Execute kernel test run" 
bs.stream_calc!(a, b, c, 2.0, 16, 1)
c .= 0.0

@info "Execute full kernel run TRIAD" 
execution_time = @elapsed bs.stream_calc!(a, b, c, 2.0, array_size, 1)

@info "Execution time: $execution_time seconds"
@info "Measured bandwidth: $((3 * array_size * sizeof(eltype(a))) / execution_time * 1.0e-9) GB/s"

# validate the execution results
@info "Validate output"
@assert all(c .== (2 .* a .+ b))

@info "Done"