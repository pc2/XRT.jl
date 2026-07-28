@devices_testset 1 "Internal" begin
    xd1 = XRT.device(1)
    @test typeof(xd1) == XRT.XilinxDevice
    @test typeof(xd1.device) == XRT.XRTWrap.DeviceAllocated

    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.bdf) == xd1.bdf
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.interface_uuid) == xd1.interface_uuid
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.kdma) == xd1.kdma
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.max_clock_frequency_mhz) == xd1.max_clock_frequency_mhz
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.m2m) == xd1.m2m
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.name) == xd1.name
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.nodma) == xd1.nodma
    @test XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.offline) == xd1.offline
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.electrical), xd1.electrical.electrical)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.thermal), xd1.thermal.thermal)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.mechanical), xd1.mechanical.mechanical)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.memory), xd1.memory.memory)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.platform), xd1.platform.platform)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.pcie_info), xd1.pcie_info.pcie_info)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.host), xd1.host.host)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.dynamic_regions), xd1.dynamic_regions.dynamic_regions)
    @test comparekeys(XRT._XRTInternal.get_info(xd1, XRT.XRTWrap.DeviceInformationParameters.vmr), xd1.vmr.vmr)

    xd2 = XRT.XilinxDevice(1)
    @test typeof(xd2) == XRT.XilinxDevice
    @test xd1.device != xd2.device
    @test xd1.bdf == xd2.bdf
    
end

@devices_testset 1 "Public" begin
    xd1 = XRT.device(1)

    @test xd1.max_clock_frequency_mhz === nothing || typeof(xd1.max_clock_frequency_mhz) == UInt64
    @test typeof(xd1.name) <: AbstractString
    @test xd1.nodma === nothing || typeof(xd1.nodma) == Bool
    @test typeof(xd1.electrical.electrical) <: LazyJSON.Object

    uuid = XRT.get_xclbin_uuid(; device=xd1)
    @test typeof(uuid) == XRT.XRTWrap.UUIDAllocated

end
