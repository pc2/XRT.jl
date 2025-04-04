################################################################################
#                    Print functions for xrt_xclbin.jl                         #
################################################################################

Base.show(io::IO, ::MIME{Symbol("text/plain")}, xclbin::XRT.Xclbin) = xrtprint_xclbin(xclbin; io)

"""
$(TYPEDSIGNATURES)

Internal print function for [`XRT.Xclbin`](@ref) objects.
"""
function xrtprint_xclbin(xclbin::XRT.Xclbin; io::IO=stdout)
    # Xclbin metadata
    pretty_table(io, ["$(xclbin.target_type)" "$(xclbin.path)"];
        show_header = false,
        alignment = :c,
        highlighters = hl_col(1, crayon"bold"),
        columns_width = [6, 84]) 

    pretty_table(io, ["XSA Name" "$(xclbin.xsa_name)"
                      "FPGA Device Name" "$(xclbin.fpga_device_name)"
                      "UUID" "$(xclbin.uuid)"];
        show_header = false,
        alignment = [:r, :c],
        highlighters = hl_col(1, crayon"bold"),
        columns_width = [16, 74])

    # kernels
    data = []
    for (index, kernel) in enumerate(xclbin.kernels)
        arg_types = [arg.host_type for arg in kernel.args]
        arg_names = [arg.name for arg in kernel.args]
        args = ""
        for i in 1:kernel.num_args
            max_length = maximum(length.([arg_types[i], arg_names[i]]))
            args *= arg_types[i] * repeat(" ", max_length-length(arg_types[i])) * "   "
        end
        args = rstrip(args)
        args *= "\n"
        for i in 1:kernel.num_args
            max_length = maximum(length.([arg_types[i], arg_names[i]]))
            args *= arg_names[i] * repeat(" ", max_length-length(arg_names[i])) * "   "
        end
        args = rstrip(args)
        kernel_data = ["$index" "$(kernel.name)" "$(length(kernel.cus))" "$args"]
        if index == 1
            data = kernel_data
        else
            data = vcat(data, kernel_data)
        end
    end
    
    pretty_table(io, data;
        title = "Kernels:",
        header = ["Index", "Kernel Name", "No. CUs", "Arguments"],
        alignment = [:c, :c, :c, :l],
        highlighters = (hl_col(2, crayon"bold")),
        linebreaks = true,
        hlines = :all)
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, kernel::XRT.XclbinKernel) = xrtprint_xclbinkernel(kernel; io)

"""
$(TYPEDSIGNATURES)

Internal print function for [`XRT.XclbinKernel`](@ref) objects.
"""
function xrtprint_xclbinkernel(kernel::XRT.XclbinKernel; io::IO=stdout)
    xrtprint_simple_header(kernel.name; io)
    
    # cus
    data = []
    for (index, cu) in enumerate(kernel.cus)
        cu_data = ["$index" "$(cu.name)" "$(cu.type)" "$(cu.control_type)" "0x$(string(cu.base_address, base=16))" "$(if cu.size > 0 cu.size else "" end)" "$(cu.num_args)"]
        if index == 1
            data = cu_data
        else
            data = vcat(data, cu_data)
        end
    end
    pretty_table(io, data;
        title = "Compute Units:",
        header = ["Index", "CU Name", "Type", "Control Type", "Base Address", "Size", "No. Args"],
        highlighters = (hl_col(2, crayon"bold")),
        alignment = :c)

    xrtprint_argslist(kernel.args; io)
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, ip::XRT.XclbinIP) = xrtprint_xclbinip(ip; io)

"""
$(TYPEDSIGNATURES)

Internal print function for [`XRT.XclbinIP`](@ref) objects.
Does also print compute unit represantation of kernels.
"""
function xrtprint_xclbinip(ip::XRT.XclbinIP; io::IO=stdout)
    # name
    pretty_table(io, ["$(ip.name)"];
        show_header = false,
        highlighters = (hl_col(1, crayon"bold")),
        alignment = :c,
        columns_width = 33)
    
    # cus
    data = ["Type" "Control Protocol"
            "$(ip.type)" "$(ip.control_type)"
            "Size" "Base Address"
            "$(if ip.size > 0 ip.size else "" end)" "0x$(string(ip.base_address, base=16))"]
    pretty_table(io, data;
        show_header = false,
        highlighters = (hl_row(1, crayon"bold"), hl_row(3, crayon"bold")),
        body_hlines = [2],
        alignment = :c,
        columns_width = [10, 20])

    xrtprint_argslist(ip.args; io)
end

"""
$(TYPEDSIGNATURES)

Internal print function for a list of [`XRT.XclbinArg`](@ref) objects in a tabular form.
"""
function xrtprint_argslist(args::Vector{XRT.XclbinArg}; io::IO=stdout)
    # args
    if length(args) > 0
        data = []
        for (index, arg) in enumerate(args)
            arg_data = ["$(arg.index+1)" "$(arg.host_type)" "$(arg.name)" "$(arg.port)" "$(arg.size)" "$(arg.offset)" "$(join([mem.tag for mem in arg.mems], ", "))"]
            if index == 1
                data = arg_data
            else
                data = vcat(data, arg_data)
            end
        end
        pretty_table(io, data;
            title = "Arguments:",
            header = ["Index", "Host Type", "Name", "Port", "Size [Bytes]", "Offset", "Connected Memory Objects"],
            highlighters = (hl_col(3, crayon"bold")),
            alignment = :c)
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, arg::XRT.XclbinArg) = xrtprint_xclbinarg(arg; io)

"""
$(TYPEDSIGNATURES)

Internal print function for [`XRT.XclbinArg`](@ref) objects.
"""
function xrtprint_xclbinarg(arg::XRT.XclbinArg; io::IO=stdout)
    pretty_table(io, ["Index" "Host Type" "Name"
                      "$(arg.index)" "$(arg.host_type)" "$(arg.name)"
                      "Port" "Size [Bytes]" "Offset"
                      "$(arg.port)" "$(arg.size)" "$(arg.offset)"];
        show_header = false,
        highlighters = (hl_row(1, crayon"bold"), hl_row(3, crayon"bold")),
        body_hlines = [2],
        alignment = :c)

    if length(arg.mems) > 0
    pretty_table(io, [mem.tag for mem in arg.mems];
        title = "Connected Memory Objects",
        show_header = false) 
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, mem::XRT.XclbinMem) = xrtprint_xclbinmem(mem; io)

"""
$(TYPEDSIGNATURES)

Internal print function for [`XRT.XclbinMem`](@ref) objects.
"""
function xrtprint_xclbinmem(mem::XRT.XclbinMem; io::IO=stdout)
    pretty_table(io, ["Index" "Tag" "Type"
                      "$(mem.index)" "$(mem.tag)" "$(mem.type)"
                      "Base Address" "Size [Bytes]" "Used"
                      "0x$(string(mem.base_address, base=16))" "$(convert_bytes(mem.size_kb * 1024))" "$(mem.used)"];
        show_header = false,
        highlighters = (hl_row(1, crayon"bold"), hl_row(3, crayon"bold")),
        body_hlines = [2],
        alignment = :c)
end

################################################################################
#                    Print functions for xrt_device.jl                         #
################################################################################

Base.show(io::IO, ::MIME{Symbol("text/plain")}, device::XRT.XilinxDevice) = xrtprint_device(device; io)

"""
$(TYPEDSIGNATURES)

Internal print function for general XilinxDevice data.
"""
function xrtprint_device(device::XRT.XilinxDevice; io::IO=stdout)
    # Fetch device information
    index = device.index
    offline = device.offline
    max_clock_frequency_mhz = device.max_clock_frequency_mhz
    m2m = device.m2m
    nodma = device.nodma
    interface_uuid = device.interface_uuid
    kdma = device.kdma

    ready = offline == nothing ? "$nothing" : !offline

    # Device header
    data = [index string(device)]
    kwargs = Dict{Symbol, Any}(
        :show_header => false)
    if offline != nothing && offline
        _XRTInternal.highlight_offline_kwargs!(kwargs)
    end

    pretty_table(io, data;
        alignment=[:l, :c, :c],
        highlighters = hl_cell(1, 1, crayon"bold"),
        columns_width = [1, 68],
        kwargs...)

    # Static device information
    data = ["Max. Clock Frequency" "m2m" "NoDMA"
            "$(max_clock_frequency_mhz) MHz" "$(m2m)" "$(nodma)" 
            "Interface UUID" "No. of KDMA Engines" "Ready"
            "$(interface_uuid)" "$(kdma)" "$(ready)"]

    hl_m2m_title = hl_cell(1, 2, crayon"bold light_gray")
    hl_m2m = hl_cell(2, 2, crayon"light_gray")
    hl_nodma_title = hl_cell(1, 3, crayon"bold light_gray")
    hl_nodma = hl_cell(2, 3, crayon"light_gray")
    hl_offline_title = hl_cell(3, 3, crayon"bold light_gray")
    hl_offline = hl_cell(4, 3, crayon"light_gray")

    hls = (hl_row([1, 3], crayon"bold"), )
    if m2m != nothing && !m2m
        hls = (hl_m2m_title, hl_m2m, hls...)
    end
    if nodma != nothing && !nodma
        hls = (hl_nodma_title, hl_nodma, hls...)
    end
    if offline != nothing && offline
        hls = (hl_offline_title, hl_offline, hls...)
    end

    pretty_table(io, data; 
        body_hlines = [2],
        columns_width = [38, 19, 9],
        alignment = :c,
        highlighters = hls,
        kwargs...)

    # Available device reports
    data = [_XRTInternal.transform_header(string(field)) for field in fieldnames(XRT.XilinxDevice) 
            if fieldtype(XRT.XilinxDevice, field) == XRT.AbstractXilinxDeviceInformation &&
            getproperty(getproperty(XRT.device(), field), field) != nothing &&
            length(getproperty(getproperty(XRT.device(), field), field)) > 0]
    
    pretty_table(io, data;
        title = "Available Reports:",
        highlighters = (),
        alignment = :l,
        kwargs...)
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationMemory) = xrtprint_memory(report.memory; io)

"""
$(TYPEDSIGNATURES)

Internal print function for memory report.
"""
function xrtprint_memory(json::LazyJSON.Object; io::IO=stdout)
    for (key, object) in json
        if key == "board"
            if haskey(object, "memory")
                xrtprint_simple_header("Memory Topology"; io)
                for mem in object["memory"]["memories"]
                    kwargs = Dict()
                    if mem["enabled"] == "false"
                        _XRTInternal.highlight_offline_kwargs!(kwargs)
                    end
                    data = ["Type" "Allocated" "BO Count" "Base Address"  "Enabled"
                            mem["type"] "$(_XRTInternal.convert_bytes(parse(Int, mem["extended_info"]["usage"]["allocated_bytes"]))) / $(_XRTInternal.convert_bytes(parse(Int, mem["range_bytes"])))" mem["extended_info"]["usage"]["buffer_objects_count"] mem["base_address"] mem["enabled"]]

                    if haskey(mem["extended_info"], "temperature_C")
                        temp = ["Temp [C]"
                                mem["extended_info"]["temperature_C"]]
                        data = hcat(data, temp)
                    end
                    pretty_table(io, data;
                        show_header = false,
                        alignment = :c,
                        title = mem["tag"],
                        highlighters = hl_row(1, crayon"bold"),
                        kwargs...)
                end
                println(io)
            end
            
            if haskey(object, "direct_memory_accesses")
                xrtprint_simple_header(_XRTInternal.transform_header(object["direct_memory_accesses"]["type"]); io)
                if haskey(object["direct_memory_accesses"], "metrics")
                    for metric in object["direct_memory_accesses"]["metrics"]
                        data = ["Channel ID" "h2c [Bytes]" "c2h [Bytes]"
                                metric["channel_id"] _XRTInternal.convert_bytes(parse(Int, metric["host_to_card_bytes"])) _XRTInternal.convert_bytes(parse(Int, metric["card_to_host_bytes"]))]

                        pretty_table(io, data;
                            show_header = false,
                            alignment = :c,
                            highlighters = hl_row(1, crayon"bold"))
                    end
                end
            end
        end
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationDynamicRegions) = xrtprint_dynamic_regions(report.dynamic_regions; io)

struct PrintComputeUnit
    index::Integer
    name::LazyJSON.String
    base_address::LazyJSON.String
    usage::LazyJSON.String
    type::LazyJSON.String
    status::LazyJSON.String
end

"""
$(TYPEDSIGNATURES)

Internal print function for a single `PrintComputeUnit` object.
"""
function xrtprint_cu(cu::PrintComputeUnit; io::IO=stdout)
    data = ["Name" "Base Address" "Usage" "Status"
            cu.name cu.base_address cu.usage cu.status]
                
    pretty_table(io, data;
        show_header = false,
        title = "$(cu.index):",
        alignment = :c,
        highlighters = hl_row(1, crayon"bold"))
end

"""
$(TYPEDSIGNATURES)

Internal print function for dynamic-regions report.
"""
function xrtprint_dynamic_regions(json::LazyJSON.Object; io::IO=stdout)
    for (key, object) in json
        if key == "dynamic_regions"
            for item in object
                pretty_table(io, ["Xclbin UUID" "$(_XRTInternal.transform_header(item["xclbin_uuid"]))"];
                    show_header = false,
                    highlighters = hl_cell(1, 1, crayon"bold"))

                if haskey(item, "compute_units")
                    pls = Vector{PrintComputeUnit}()
                    pss = Vector{PrintComputeUnit}()
                    for (index, cu) in enumerate(item["compute_units"])
                        if cu["type"] == "PL"
                            push!(pls, PrintComputeUnit(index, cu["name"], cu["base_address"], cu["usage"], cu["type"], cu["status"]["bits_set"][1]))
                        else
                            push!(pss, PrintComputeUnit(index, cu["name"], cu["base_address"], cu["usage"], cu["type"], cu["status"]["bits_set"][1]))
                        end
                    end
                    if length(pls) > 0
                        xrtprint_simple_header("PL Compute Units"; io)
                        for _cu in pls
                            xrtprint_cu(_cu; io)
                        end
                    end
                    if length(pss) > 0
                        xrtprint_simple_header("PS Compute Units"; io)
                        for _cu in pss
                            xrtprint_cu(_cu; io)
                        end
                    end
                end
            end
        end
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationPlatform) = xrtprint_platform(report.platform; io)

"""
$(TYPEDSIGNATURES)

Internal print function for platform report.
"""
function xrtprint_platform(json::LazyJSON.Object; io::IO=stdout)
    for (key, object) in json
        if key == "platforms"
            for item in object
                data = Matrix{String}(undef, 0, 2)
                if haskey(item, "static_region")
                    data = vcat(data, hcat([[_XRTInternal.transform_header(key) for (key, value) in item["static_region"]],
                                        [value for (key, value) in item["static_region"]]]...))
                end
                if haskey(item, "off_chip_board_info")
                    data = vcat(data, hcat([[_XRTInternal.transform_header(key) for (key, value) in item["off_chip_board_info"]],
                                        [value for (key, value) in item["off_chip_board_info"]]]...))
                end
                if haskey(item, "status")
                    data = vcat(data, hcat([[_XRTInternal.transform_header(key) for (key, value) in item["status"]],
                                        [value for (key, value) in item["status"]]]...))
                end
                pretty_table(io, data;
                    show_header = false,
                    title = "Platform:",
                    highlighters = hl_col(1, crayon"bold"))
                println(io)
                
                if haskey(item, "clocks")
                    xrtprint_simple_header("Clocks"; io)
                    for clock in item["clocks"]
                        skip = ["description", "is_present"]
                        data = reshape([_XRTInternal.transform_header(key) for (key, value) in clock if !(key in skip)], 1, :)
                        data = vcat(data, reshape([value for (key, value) in clock if !(key in skip)], 1, :))
                        
                        pretty_table(io, data;
                            show_header = false,
                            title = "$(_XRTInternal.transform_header(clock["description"])):",
                            alignment = :c,
                            highlighters = hl_row(1, crayon"bold"))
                    end
                    println(io)
                end

                if haskey(item, "macs")
                    xrtprint_simple_header("Mac Addresses"; io)
                    for mac in item["macs"]
                        println(io, mac["address"])
                    end
                    println(io)
                end

                if haskey(item, "config")
                    xrtprint_simple_header("Config"; io)
                    for (key, value) in item["config"]
                        data = reshape([_XRTInternal.transform_header(key) for (key, value) in value], 1, :)
                        data = vcat(data, reshape([value for (key, value) in value], 1, :))
                        
                        pretty_table(io, data;
                            show_header = false,
                            title = "$(_XRTInternal.transform_header(key)):",
                            alignment = :c,
                            highlighters = hl_row(1, crayon"bold"))
                    end
                end
            end
        end
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationElectrical) = xrtprint_electrical(report.electrical; io)

"""
$(TYPEDSIGNATURES)

Internal print function for electrical report.
"""
function xrtprint_electrical(json::LazyJSON.Object; io::IO=stdout)
    # Power consumption
    data = ["Consumption [W]" "Max Consumption [W]" "Warning"
            json["power_consumption_watts"] json["power_consumption_max_watts"] json["power_consumption_warning"]]

    if json["power_consumption_warning"] == "true"
        hl_warning_title = hl_cell(1, 3, crayon"bold red")
        hl_warning = hl_cell(2, 3, crayon"red")
    else
        hl_warning_title = hl_cell(1, 3, crayon"bold light_gray")
        hl_warning = hl_cell(2, 3, crayon"light_gray")
    end
    
    pretty_table(io, data;
        show_header = false,
        title = "Power Consumption:",
        highlighters = (hl_warning, hl_warning_title, hl_row(1, crayon"bold")),
        alignment = :c)

    # Power rails
    if haskey(json, "power_rails")
        xrtprint_simple_header("Power Rails"; io)
        for item in json["power_rails"]
            data = ["ID"
                    item["id"]]

            available = false
            if item["voltage"]["is_present"] == "true"
                data = hcat(data, ["Voltage [V]"
                            item["voltage"]["volts"]])
                available = true
            end

            if item["current"]["is_present"] == "true"
                data = hcat(data, ["Current [A]"
                            item["current"]["amps"]])
                available = true
            end

            if !available
                continue
            end
            
            pretty_table(io, data;
                show_header = false,
                title = "$(item["description"]):",
                highlighters = (hl_row(1, crayon"bold")),
                alignment = :c)
        end
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationMechanical) = xrtprint_mechanical_thermal(report.mechanical; io)

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationThermal) = xrtprint_mechanical_thermal(report.thermal; io)

"""
$(TYPEDSIGNATURES)

Internal print function for mechanical and thermal reports.
"""
function xrtprint_mechanical_thermal(json::LazyJSON.Object; io::IO=stdout)
    for (key, object) in json
        if key == "fans" || key == "thermals"
            available = false
            for item in object 
                skip = ["description", "is_present"]
                data = reshape([_XRTInternal.transform_header(key) for (key, value) in item if !(key in skip)], 1, :)
                data = vcat(data, reshape([value for (key, value) in item if !(key in skip)], 1, :))
                
                kwargs = Dict()
                if item["is_present"] == "false"
                    continue
                    _XRTInternal.highlight_offline_kwargs!(kwargs)
                end
                available = true
                
                pretty_table(io, data;
                    show_header = false,
                    alignment = :c,
                    title = "$(uppercasefirst(item["description"])):",
                    highlighters = hl_row(1, crayon"bold"),
                    kwargs...)
            end
            if !available
                println(io, "No information available.")
            end
        end
    end
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationHost) = xrtprint_simple(report.host; io)

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationPcieInfo) = xrtprint_simple(report.pcie_info; io)

"""
$(TYPEDSIGNATURES)

Internal print function for reports which just contain strings as values.
"""
function xrtprint_simple(json::LazyJSON.Object; io::IO=stdout)
    data = [[_XRTInternal.transform_header(key) for (key, value) in json],
            [ value for (key, value) in json]]

    pretty_table(io, hcat(data...);
        show_header = false,
        highlighters = hl_col(1, crayon"bold"),
        alignment = [:r, :l],)
end

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationAie) = nothing

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationAieShim) = nothing

Base.show(io::IO, ::MIME{Symbol("text/plain")}, report::XRT._XRTDeviceInformation.XilinxDeviceInformationVmr) = nothing

################################################################################
#       Utilities that are used for prettyprinting Structures and JSON         #
################################################################################

"""
$(TYPEDSIGNATURES)

Internal print function for a section header.
"""
function xrtprint_simple_header(title::AbstractString; io::IO=stdout)
    pretty_table(io, ["$(title):"];
        show_header = false,
        highlighters = hl_cell(1, 1, crayon"bold"),
        tf = tf_simple)
    println(io)
end

"""
$(TYPEDSIGNATURES)

Takes a string or header obtained from JSON object that is in format "foo_bar".
Transforms it to a string as "Foo Bar" and applies some hardcoded exceptions for units and abbreviations.
"""
function transform_header(header::AbstractString)
    replaced_header = header
    replacements = Dict("gbit_sec" => "[GBit / s]", "pcie" => "PCIe", "idcode" => "IDCode", "mhz" => "MHz", "bar" => "BAR")
    for (key, value) in replacements 
        replaced_header = replace(replaced_header, key => value) 
    end
    words = split(replaced_header, r"[_ ]")
    capital = ["C", "rpm", "cpu", "dma", "id", "vbnv", "uuid", "fpga", "ddr", "jtag", "mig", "xdma"]
    words = Base.map(x -> if x in capital "$(uppercase(x))" else x end, words)
    exceptions = ["p2p"]
    words = Base.map(x -> if x in exceptions x else uppercasefirst(x) end, words)
    units = ["C", "RPM", "Bytes", "MHz"]
    words = Base.map(x -> if x in units "[$(x)]" else x end, words)
    return join(words, " ")
end

"""
$(TYPEDSIGNATURES)

Takes a dict of keyword arguments for the use with `pretty_table` function.
Makes the table outline dotted and greys the complete table.
"""
function highlight_offline_kwargs!(kwargs::Dict)
    kwargs[:border_crayon] = crayon"light_gray"
    kwargs[:header_crayon] = crayon"bold light_gray"
    kwargs[:title_crayon] = crayon"bold light_gray"
    kwargs[:highlighters] = Highlighter((data, i, j) -> true, crayon"light_gray")
    kwargs[:tf] = tf_ascii_dots
end

"""
$(TYPEDSIGNATURES)

This functions parses a (hexadecimal) string to an integer and transforms it to a human-readable format with Byte units.

```Julia
julia> _XRTInternal._XRTInternal.convert_bytes("0x10000040")
"256 MB"
```
"""
function convert_bytes(bytes::Union{AbstractString, Integer})
    if typeof(bytes) <: AbstractString
        bytes = parse(Int, bytes)
    end
    if bytes < 1024
        return "$bytes B"
    elseif bytes < 1024^2
        return "$(bytes ÷ 1024) KB"
    elseif bytes < 1024^3
        return "$(bytes ÷ 1024^2) MB"
    else
        return "$(bytes ÷ 1024^3) GB"
    end
end
