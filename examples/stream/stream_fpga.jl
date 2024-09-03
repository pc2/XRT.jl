using XRT
using ArrayAllocators

# Allocate an output array
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
bs = XRT.prepare_bitstream("build_sw_emu/stream.xclbin")

# execute the stream kernel
bs.stream_calc!(a, b, c, 2.0, 2^20, 1)

# validate the execution results
@assert all(c .== (2 .* a .+ b))