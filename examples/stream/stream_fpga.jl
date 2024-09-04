using XRT
using ArrayAllocators
using Logging

# Allocate an output array
@info "Allocate and initialize arrays"
a = Array{Float64}(MemAlign(4096),2^20)
b = Array{Float64}(MemAlign(4096),2^20)
c = Array{Float64}(MemAlign(4096),2^20)

for i in 1:2^20
    a[i] = rand()
    b[i] = rand()
    c[i] = 0
end

# Load the bitstream to the FPGA and generate functions 
# for each kernel
@info "Upload bitstream and generate kernel functions"
bs = XRT.prepare_bitstream("build_sw_emu/stream.xclbin")

# execute the stream kernel
@info "Execute kernel" 
bs.stream_calc!(a, b, c, 2.0, 2^20, 1)

# validate the execution results
@info "Validate output"
@assert all(c .== (2 .* a .+ b))

@info "Done"