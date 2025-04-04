@testset "Internal" begin
    @devices_testset 1 "XilinxDeviceArray" begin
        a = XRT._XRTInternal.XilinxDeviceArray()
        @test size(a.devices, 1) == 0
        @test size(a, 1) == 0
        @test length(a) == 0
        @test_warn "XilinxDevice with index 42 is not available" a[42]
        @test a[1] == nothing

        xd = XRT.device()
        push!(a.devices, xd)
        @test a[1] == xd
        @test size(a.devices, 1) == 1
        @test size(a, 1) == 1
        @test length(a) == 1
    end

end

@testset "Public" begin
    @devices_testset 2 "Devices" begin
        d = XRT.device(2)
        @test size(XRT.devices(), 1) == XRT.XRTWrap.enumerate_devices()
        @test XRT.devices() == XRT._XRTInternal.state[].available_devices.devices
        @test typeof(d) == XRT.XilinxDevice
        @test XRT.device(1) == XRT.devices()[1]

        XRT.device!(2)
        @test XRT.device() == d

        XRT.device!(d)
        @test XRT.device() == d

        XRT.device!(1)
        @test XRT.device() == XRT.device(1)
    end

    @testset "Emulation Mode" begin
        emu_mode = XRT.emulation_mode()
        @test typeof(emu_mode) == XRT.XRTWrap.TargetType.Type

        if ("XCL_EMULATION_MODE" in keys(ENV))
            @test string(emu_mode) == ENV["XCL_EMULATION_MODE"]
        else
            @test emu_mode == XRT.XRTWrap.TargetType.hw
        end
    end

end
