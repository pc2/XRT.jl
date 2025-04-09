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

a[:] .= rand(array_size)
b[:] .= rand(array_size)
c[:] .= 0

# Load the bitstream to the FPGA and generate functions 
# for each kernel
@info "Generate kernel functions"
module STREAMBitstream
    using XRT
    @prepare_bitstream("build_sw_emu/stream.xclbin")
end

# execute the stream kernel
@info "Execute kernel test run" 
STREAMBitstream.stream_calc!(a, b, c, 2.0, UInt32(4096), UInt32(0))
@info "Reset output buffer" 
c .= 0.0

@info "Execute full kernel run TRIAD" 
execution_time = @elapsed STREAMBitstream.stream_calc!(a, b, c, 2.0, UInt32(array_size), UInt32(1))

@info "Execution time: $execution_time seconds"
total_data_moved_fpga = 3 * array_size * sizeof(eltype(a))
total_data_moved_pcie = 6 * array_size * sizeof(eltype(a))
@info "Measured bandwidth: $((total_data_moved_fpga + total_data_moved_pcie) / execution_time * 1.0e-9) GB/s"

# validate the execution results
@info "Validate output"
@assert all(c .≈ (2 .* a .+ b))

@info "Done"
