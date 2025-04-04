@testset "Reset" begin
    @test typeof(XRT.reset!(1)) == XRT.XilinxDevice
end

@testset "Version" begin
    @test occursin("$(XRT.XRTWrap.XRT_VERSION_MAJOR).$(XRT.XRTWrap.XRT_VERSION_MINOR)", XRT.version())

end

@xclbin_testset "Program" begin
    xclbin = XRT.Xclbin(path)
    @test XRT.XRTWrap.string(XRT.program!(xclbin)) == "9d1b0781-0c46-a128-c90c-d0448898c1c7"

end

@testset "Validate All" begin
    for device in XRT.devices()
        @test !occursin("FAILED", XRT.validate!(; device=device)) skip=quick
    end

end

@testset "Validate Quick" begin
    # This ensures that 'verify' will be loaded on device
    for device in XRT.devices()
        @test length(findall("PASSED", XRT.validate!(XRT.XbutilTest.AUX_CONNECTION; device=device))) == 1
        @test length(findall("PASSED", XRT.validate!(XRT.XbutilTest.QUICK; device=device))) == 4
    end

end
