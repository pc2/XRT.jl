using LazyJSON

@enum SectionType::Int begin
    BITSTREAM = 0
    CLEARING_BITSTREAM = 1
    EMBEDDED_METADATA = 2
    FIRMWARE = 3
    DEBUG_DATA = 4
    SCHED_FIRMWARE = 5
    MEM_TOPOLOGY = 6
    CONNECTIVITY = 7
    IP_LAYOUT = 8
    DEBUG_IP_LAYOUT = 9
    DESIGN_CHECK_POINT = 10
    CLOCK_FREQ_TOPOLOGY = 11
    MCS = 12
    BMC = 13
    BUILD_METADATA = 14
    KEYVALUE_METADATA = 15
    USER_METADATA = 16
    DNA_CERTIFICATE = 17
    PDI = 18
    BITSTREAM_PARTIAL_PDI = 19
    PARTITION_METADATA = 20
    EMULATION_DATA = 21
    SYSTEM_METADATA = 22
    SOFT_KERNEL = 23
    ASK_FLASH = 24
    AIE_METADATA = 25
    ASK_GROUP_TOPOLOGY = 26
    ASK_GROUP_CONNECTIVITY = 27
    SMARTNIC = 28
    AIE_RESOURCES = 29
    OVERLAY = 30
    VENDER_METADATA = 31
    AIE_PARTITION = 32
    IP_METADATA = 33
end

function get_meta(data)
    start_meta = last(findfirst("XCLBIN_MIRROR_DATA_START", data)) + 1
    end_meta = first(findfirst("XCLBIN_MIRROR_DATA_END", data)) - 1
    LazyJSON.parse(data[start_meta:end_meta])
end

"""
    get_section_string(xclbin_path::String, type::SectionType)

Get the specified raw section from the bitstream file xclbin_path.
"""
function get_section_string(xclbin_path::String, type::SectionType)
    data = read(xclbin_path, String)
    meta = get_meta(data)
    for (k, v) in meta
        if k == "section_header" && parse(Int, v["Kind"]) == Int(type)
            offset = parse(Int, v["Offset"])
            size = parse(Int, v["Size"])
            return data[offset+1:offset+size]
        end
    end
    nothing
end

"""
    get_kernel_info(xclbin_path::String)

Get information about contained kernels, instances, arguments and their register offsets...
"""
function get_kernel_info(xclbin_path::String)
    data = LazyJSON.parse(get_section_string(xclbin_path, BUILD_METADATA))
    data["build_metadata"]["xclbin"]["user_regions"][1]["kernels"]
end

"""
    get_system_info(xclbin_path::String)

Get information about resource utilization and connectivity
"""
function get_system_info(xclbin_path::String)
    data = LazyJSON.parse(get_section_string(xclbin_path, SYSTEM_METADATA))
    data["system_diagram_metadata"]["xclbin"]["user_regions"]
end