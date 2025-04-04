"""
$(TYPEDSIGNATURES)

Fetches the device information based on the given parameter.
It returns a value of the corresponding type or `nothing` if the parameter is not available.
"""
function get_info(device::XRTWrap.Device, param::XRTWrap.DeviceInformationParameters.Type)
    try
        if param == XRTWrap.DeviceInformationParameters.bdf
            XRTWrap.get_info_bdf(device)
        elseif param == XRTWrap.DeviceInformationParameters.interface_uuid
            XRTWrap.get_info_interface_uuid(device)
        elseif param == XRTWrap.DeviceInformationParameters.kdma
            XRTWrap.get_info_kdma(device)
        elseif param == XRTWrap.DeviceInformationParameters.max_clock_frequency_mhz
            XRTWrap.get_info_max_clock_frequency_mhz(device)
        elseif param == XRTWrap.DeviceInformationParameters.m2m
            XRTWrap.get_info_m2m(device)
        elseif param == XRTWrap.DeviceInformationParameters.name
            XRTWrap.get_info_name(device)
        elseif param == XRTWrap.DeviceInformationParameters.nodma
            XRTWrap.get_info_nodma(device)
        elseif param == XRTWrap.DeviceInformationParameters.offline
            XRTWrap.get_info_offline(device)
        elseif param == XRTWrap.DeviceInformationParameters.electrical
            LazyJSON.parse(XRTWrap.get_info_electrical(device))
        elseif param == XRTWrap.DeviceInformationParameters.thermal
            LazyJSON.parse(XRTWrap.get_info_thermal(device))
        elseif param == XRTWrap.DeviceInformationParameters.mechanical
            LazyJSON.parse(XRTWrap.get_info_mechanical(device))
        elseif param == XRTWrap.DeviceInformationParameters.memory
            LazyJSON.parse(XRTWrap.get_info_memory(device))
        elseif param == XRTWrap.DeviceInformationParameters.platform
            LazyJSON.parse(XRTWrap.get_info_platform(device))
        elseif param == XRTWrap.DeviceInformationParameters.pcie_info
            LazyJSON.parse(XRTWrap.get_info_pcie_info(device))
        elseif param == XRTWrap.DeviceInformationParameters.host
            LazyJSON.parse(XRTWrap.get_info_host(device))
        elseif param == XRTWrap.DeviceInformationParameters.aie
            LazyJSON.parse(XRTWrap.get_info_aie(device))
        elseif param == XRTWrap.DeviceInformationParameters.aie_shim
            LazyJSON.parse(XRTWrap.get_info_aie_shim(device))
        elseif param == XRTWrap.DeviceInformationParameters.dynamic_regions
            LazyJSON.parse(XRTWrap.get_info_dynamic_regions(device))
        elseif param == XRTWrap.DeviceInformationParameters.vmr
            LazyJSON.parse(XRTWrap.get_info_vmr(device))
        else
            throw(Exception())
        end
    catch e
        @warn "Failed fetching device info for param '$(param)': $(e)"
        return nothing
    end
end

"""
$(TYPEDSIGNATURES)

Fetches the device information based on the given parameter.
"""
function get_info(device::XRT.XilinxDevice, param::XRTWrap.DeviceInformationParameters.Type)
    get_info(device.device, param)
end
