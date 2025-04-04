@test occursin(string(XRT.emulation_mode()), path)
@test !isabspath(path)
xclbin = XRT.Xclbin(path)

@testset "Xclbin Struct" begin
    @test_throws "Path 'foo' does not lead to a file" XRT.Xclbin("foo")

    @test typeof(xclbin.xclbin) == XRT.XRTWrap.XclbinAllocated
    @test isabspath(xclbin.path)

    @test length(xclbin.kernels) == 1
    @test length(xclbin.ips) == 34
    @test length(xclbin.mems) == 41

    @test xclbin.xsa_name == "xilinx_u280_gen3x16_xdma_1_202211_1" || xclbin.xsa_name == ""
    @test typeof(xclbin.uuid) == XRT.XRTWrap.UUIDAllocated

    @test xclbin.fpga_device_name == "virtexuplusHBM:xcu280:fsvh2892:-2L:e"
    @test xclbin.target_type == XRT.emulation_mode()

end

@testset "XclbinKernel Struct" begin
    kernel = xclbin.kernels[1]

    @test typeof(kernel.kernel) == XRT.XRTWrap.XclbinKernelDereferenced
    @test kernel.name == "stream_calc"
    @test length(kernel.cus) == 2
    @test typeof(kernel.cus[1]) == XRT.XclbinIP
    @test length(kernel.args) == kernel.num_args

end

@testset "XclbinIP Struct" begin
    ip = xclbin.ips[1]

    @test typeof(ip.ip) == XRT.XRTWrap.XclbinIPDereferenced
    @test ip.name == "stream_calc:k1"
    @test ip.type == XRT.XRTWrap.IPType.pl
    @test ip.control_type == XRT.XRTWrap.ControlType.chain
    @test length(ip.args) == ip.num_args
    @test ip.base_address == 8388608 || ip.base_address == 0
    @test ip.size == 4176

end

@testset "XclbinArg Struct" begin
    arg = xclbin.kernels[1].args[1]

    @test typeof(arg.arg) == XRT.XRTWrap.XclbinArgDereferenced
    @test arg.name == "in1"
    @test length(arg.mems) in 1:2
    @test arg.port == "M_AXI_GMEM"
    @test arg.size == 8
    @test arg.offset == 16
    @test arg.host_type == "void*"
    @test arg.index == 0

end

@testset "XclbinMem Struct" begin
    mem = xclbin.mems[1]

    @test typeof(mem.mem) == XRT.XRTWrap.XclbinMemDereferenced
    @test mem.tag == "HBM[0]" || mem.tag == "DDR[0]"
    @test mem.base_address == 0
    @test mem.size_kb == 262144 || mem.size_kb == 17179869184
    @test mem.type == XRT.XRTWrap.MemoryType.hbm || mem.type == XRT.XRTWrap.MemoryType.ddr4
    @test mem.index == 0

end

@testset "Custom Xclbin" begin
    @test XRT.get_kernel_info(path)[1]["name"] == xclbin.kernels[1].name
    @test length(XRT.get_system_info(path)[1]["compute_units"]) == length(xclbin.kernels[1].cus)

end

@testset "xclbinutil" begin
    @test XRT.info(xclbin)[1:3] == "XRT"
    @test_warn "stoi" XRT.migrate_forward(xclbin.path, "foo.xclbin")
end

@testset "CPP To Julia Types" begin
    XRT._XRTInternal.cpp_to_julia("int") == Int32
    XRT._XRTInternal.cpp_to_julia("unsigned int") == UInt32
    XRT._XRTInternal.cpp_to_julia("ulong") == UInt64
    XRT._XRTInternal.cpp_to_julia("uint") == UInt32
    XRT._XRTInternal.cpp_to_julia("std::string") == String
    XRT._XRTInternal.cpp_to_julia("half") == Float16
    XRT._XRTInternal.cpp_to_julia("void") == Any
    XRT._XRTInternal.cpp_to_julia("unknown") == Any
    XRT._XRTInternal.cpp_to_julia("char") == UInt8


    XRT._XRTInternal.cpp_to_julia("int*") == AbstractArray{Int32}
    XRT._XRTInternal.cpp_to_julia("float*") == AbstractArray{Float64}
    XRT._XRTInternal.cpp_to_julia("void*") == AbstractArray
    XRT._XRTInternal.cpp_to_julia("int*"; boarray=true) == XRT.AbstractBOArray{Int32}
    XRT._XRTInternal.cpp_to_julia("float*"; boarray=true) == XRT.AbstractBOArray{Float64}
    XRT._XRTInternal.cpp_to_julia("void*"; boarray=true) == XRT.AbstractBOArray
end
