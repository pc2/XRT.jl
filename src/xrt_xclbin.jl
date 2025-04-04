struct XclbinMem
    mem::XRTWrap.XclbinMem
    tag::AbstractString
    base_address::UInt64
    size_kb::UInt64
    used::Bool
    type::XRTWrap.MemoryType.Type
    index::Int32
end

"""
$(TYPEDSIGNATURES)

Memory data type that represents a physical device memory bank.
It treats the attributes of the APIs mem class as fields.

**Fields**

**`mem`** allows access to the `XRT.XRTWrap.XclbinMem` object if required.

**`tag`** is the memory tag name.

**`base_address`** is the base adress of the memory bank.

**`size_kb`** is the size of the memory in KB.

**`used`** is the status of the memory, whether it is used by kernels in the xclbin file.

**`type`** is the memory type.

**`index`** is the index of the memory within the memory topology.
"""
function XclbinMem(mem::XRTWrap.XclbinMem)
    tag = XRTWrap.get_tag(mem)
    base_address = XRTWrap.get_base_address(mem)
    size_kb = XRTWrap.get_size_kb(mem)
    used = XRTWrap.get_used(mem)
    type = XRTWrap.get_type(mem)
    index = XRTWrap.get_index(mem)
    return XclbinMem(mem, tag, base_address, size_kb, used, type, index)
end

Base.string(mem::XclbinMem) = "$(mem.tag)"

Base.show(io::IO, mem::XclbinMem) = print(io, string(mem))

struct XclbinArg
    arg::XRTWrap.XclbinArg
    name::AbstractString
    mems::AbstractVector{XclbinMem}
    port::AbstractString
    size::UInt64
    offset::UInt64
    host_type::AbstractString
    julia_type::Type
    index::Int
end

"""
$(TYPEDSIGNATURES)

XclbinArg data type that represents a compute unit argument.
It treats the attributes of the APIs arg class as fields.

**Fields**

**`arg`** allows access to the `XRT.XRTWrap.XclbinArg` object if required.

**`name`** is the argument name.

**`mems`** specifies a vector of [`XRT.XclbinMem`](@ref) type objects.
This vector represents memory objects to which the argument is connected.

**`port`** is the port name of the argument.

**`size`** is the argument size in bytes.

**`offset`** is the argument offset.

**`host_type`** is the argument host type.

**`julia_type`** is the host types corresponding Julia type.

**`index`** is the index of the argument.
"""
function XclbinArg(arg::XRTWrap.XclbinArg)
    name = XRTWrap.get_name(arg)

    wrapped_mems = XRTWrap.get_mems(arg)
    mems = Base.map(XclbinMem, wrapped_mems)

    port = XRTWrap.get_port(arg)
    size = XRTWrap.get_size(arg)
    offset = XRTWrap.get_offset(arg)
    host_type = XRTWrap.get_host_type(arg)
    julia_type = _XRTInternal.cpp_to_julia(host_type)
    index = XRTWrap.get_index(arg)
    return XclbinArg(arg, name, mems, port, size, offset, host_type, julia_type, index)
end

Base.string(arg::XclbinArg) = "$(arg.name)"

Base.show(io::IO, arg::XclbinArg) = print(io, string(arg))

struct XclbinIP
    ip::XRTWrap.XclbinIP
    name::AbstractString
    cu_name::AbstractString
    type::XRTWrap.IPType.Type
    control_type::XRTWrap.ControlType.Type
    num_args::Int
    args::AbstractVector{XclbinArg}
    base_address::UInt64
    size::Int
end

"""
$(TYPEDSIGNATURES)

XclbinIP data type that represents a IP_LAYOUT section of an Xclbin.
It treats the attributes of the APIs ip class as fields.

**Fields**

**`ip`** allows access to the `XRT.XRTWrap.XclbinIP` object if required.

**`name`** is the IP name.

**`cu_name`** if the IP is a CU it stores the CUs name after the colon.

**`type`** is the IP type.
It is either set to `pl` or `ps`.

**`control_type`** is IP control type.
It is set to one of `hs`, `chain`, `none`, or `fa`.

**`num_args`** is the number of arguments for the IP per CONNECTIVITY section.

**`args`** specifies a vector of [`XRT.XclbinArg`](@ref) type objects.
This vector represents the arguments of the kernel sorted by indices.

**`base_address`** is the base address of the compute unit.

**`size`** is the address range size of the IP.
"""
function XclbinIP(ip::XRTWrap.XclbinIP)
    name = XRTWrap.get_name(ip)
    cu_name = split(name, ":")[end]
    type = XRTWrap.get_type(ip)
    control_type = XRTWrap.get_control_type(ip)
    num_args = XRTWrap.get_num_args(ip)

    wrapped_args = XRTWrap.get_args(ip)
    args = Base.map(XclbinArg, wrapped_args)

    base_address = XRTWrap.get_base_address(ip)
    size = XRTWrap.get_size(ip)
    return XclbinIP(ip, name, cu_name, type, control_type, num_args, args, base_address, size)
end

Base.string(ip::XclbinIP) = "$(ip.name)"

Base.show(io::IO, ip::XclbinIP) = print(io, string(ip))

struct XclbinKernel
    kernel::XRTWrap.XclbinKernel
    name::AbstractString
    type::Union{XRTWrap.KernelType.Type, Nothing}
    cus::AbstractVector{XclbinIP}
    num_args::Int
    args::AbstractVector{XclbinArg}
end

"""
$(TYPEDSIGNATURES)

Kernel data type that represents a kernel of an Xclbin.
It treats the attributes of the APIs kernel class as fields.

**Fields**

**`kernel`** allows access to the `XRT.XRTWrap.XclbinKernel` object if required.

**`name`** is the kernel name.

**`type`** is the type of the kernel.
Only available for XRT ≥ 2.16.

**`cus`** specifies a vector of [`XRT.XclbinIP`](@ref) type objects.
These elements represent the compute units for the kernel object.

**`num_args`** is the number of arguments for the kernel.

**`args`** specifies a vector of [`XRT.XclbinArg`](@ref) type objects.
This vector represents the arguments of the kernel sorted by indices.

**Note: XRT version 2.16 or newer supports the `type` field.
However, this has yet not been implemented in XRT.jl.**
"""
function XclbinKernel(kernel::XRTWrap.XclbinKernel)
    name = XRTWrap.get_name(kernel)
    type = XRTWrap.get_type(kernel)

    wrapped_cus = XRTWrap.get_cus(kernel)
    cus = Base.map(XclbinIP, wrapped_cus)

    num_args = XRTWrap.get_num_args(kernel)

    wrapped_args = XRTWrap.get_args(kernel)
    args = Base.map(XclbinArg, wrapped_args)

    return XclbinKernel(kernel, name, type, cus, num_args, args)
end

Base.string(kernel::XclbinKernel) = "$(kernel.name)"

Base.show(io::IO, kernel::XclbinKernel) = print(io, string(kernel))

struct Xclbin
    xclbin::XRTWrap.Xclbin
    path::AbstractString
    filename::AbstractString

    kernels::AbstractVector{XclbinKernel}
    ips::AbstractVector{XclbinIP}
    mems::AbstractVector{XclbinMem}
    xsa_name::AbstractString
    uuid::XRTWrap.UUID
    fpga_device_name::AbstractString
    target_type::XRTWrap.TargetType.Type
    interface_uuid::Union{XRTWrap.UUID, Nothing}
end

"""
$(TYPEDSIGNATURES)

Structure that allows a more convenient access to parameters provided `XRTWrap.Xclbin` type.
Nevertheless, this type can be called with the field `xclbin` if required.
With the instantiation of an `Xclbin` object several checks, such as the path or the target type are performed.

**Fields**

**`xclbin`** allows access to the `XRT.XRTWrap.Xclbin` object if required.

**`path`** is the absolute path that leads to the xclbin file.

**`filename`** is the file name of the xclbin file including the file extension.

**`kernels`** specifies a vector of [`XRT.XclbinKernel`](@ref) type objects.
These elements provide information of all kernels given in the metadata.

**`ips`** specifies a vector of [`XRT.XclbinIP`](@ref) type objects.
These elements represent the IP_LAYOUT section of the xclbin file.

**`mems`** specifies a vector of [`XRT.XclbinMem`](@ref) type objects.

**`xsa_name`** is the Xilinx Support Archive name of the xclbin file.

**`uuid`** is the UUID of the xclbin file.

**`fpga_device_name`** is the name of the FPGA device according to the metadata.

**`target_type`** is the type of the xlbin file.
It is either set to `hw`, `hw_emu`, or `sw_emu`.

**`interface_uuid`** is the interface UUID when device is programmed with 2RP shell.
Only available for XRT ≥ 2.16.
"""
function Xclbin(path::AbstractString)
    if !isfile(path)
        error("Path '$(path)' does not lead to a file")
        return nothing
    end
    wrapped_xclbin = XRTWrap.Xclbin(path)
    Xclbin(wrapped_xclbin, path)
end

function Xclbin(wrapped_xclbin::XRTWrap.Xclbin, path::AbstractString)
    filename = basename(path)

    wrapped_kernels = XRTWrap.get_kernels(wrapped_xclbin)
    kernels = Base.map(XclbinKernel, wrapped_kernels)

    wrapped_ips = XRTWrap.get_ips(wrapped_xclbin)
    ips = Base.map(XclbinIP, wrapped_ips)

    wrapped_mems = XRTWrap.get_mems(wrapped_xclbin)
    mems = Base.map(XclbinMem, wrapped_mems)

    xsa_name = XRTWrap.get_xsa_name(wrapped_xclbin)
    uuid = XRTWrap.get_uuid(wrapped_xclbin)
    fpga_device_name = XRTWrap.get_fpga_device_name(wrapped_xclbin)
    target_type = XRTWrap.get_target_type(wrapped_xclbin)
    interface_uuid = XRTWrap.get_interface_uuid(wrapped_xclbin)

    xclbin = Xclbin(wrapped_xclbin, abspath(path), filename, kernels, ips, mems, xsa_name, uuid, fpga_device_name, target_type, interface_uuid)

    # Check xclbin file with target type
    xclbin_target_type = XRTWrap.get_target_type(xclbin.xclbin)
    if xclbin_target_type !== emulation_mode()
        @warn "xclbin target type '$(xclbin_target_type)' does not match the currently set value '$(emulation_mode())'\nThis can lead to incorrect execution"
    end

    return xclbin
end

Base.string(x::Xclbin) = "$(x.path)"

Base.show(io::IO, xclbin::Xclbin) = print(io, string(xclbin))

"""
$(TYPEDSIGNATURES)

This function calls `xclbinutil` with the `--info` flag in order to obtain information provided by the xclbin data type.
The optional keyword parameter `output` allows the output to be written to a file.
"""
function info(xclbin::AbstractString; output=""::AbstractString)
    _XRTInternal.call_utility("xclbinutil", "-i", "$xclbin", "--info", "$output")
end

function info(xclbin::Xclbin; output=""::AbstractString)
    info(xclbin.path; output=output)
end

"""
$(TYPEDSIGNATURES)

This function calls `xclbinutil` with the `--migrate-forward` flag in order to migrate an old xclbin format to the new AXLF based format.
The migrated file will be returned as Xclbin type.
"""
function migrate_forward(xclbin::AbstractString, output::AbstractString)
    _XRTInternal.call_utility("xclbinutil", "--migrate-forward", "-i", "$xclbin", "-o", "$output"; ignorestatus=true)
    if isfile(output)
        return Xclbin(output)
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

This function calls `xclbinutil` with the `--dump-section` flag in order to extract a section from the xclbin file.
The section will be written to file `file`.
The function provides similar functionality as the custom xclbin parser.
It can be called either directly with the path to xclbin file or with an [`XRT.Xclbin`](@ref) object.

```Julia
julia> XRT.dump_section("path/to/file.xclbin", XRT.SectionType.BUILD_METADATA, "JSON", "out.json")
```
"""
function dump_section(xclbin::AbstractString, section::SectionType.Type, format::AbstractString, file::AbstractString)
    _XRTInternal.call_utility("xclbinutil", "--dump-section", "$(string(section)):$(format):$(file)", "-i", "$(xclbin)")
    nothing
end

function dump_section(xclbin::Xclbin, section::SectionType.Type, format::AbstractString, file::AbstractString)
    dump_section(xclbin.path, section, format, file)
end

"""
    $(TYPEDSIGNATURES)

This function analyses the streams between kernels, compute units and memory banks of an [`XRT.Xclbin`](@ref) object.
It prints the resulting graph to the specified io.
If the width of the terminal window is not sufficient for proper printing, the graph is printed in a temporary file.
This can be prevented with the `force_io` keyword.

The function also allows the printing of only one single kernel/compute unit of an Xclbin file together with its corresponding streams.
This is primarily required to analyse bitstreams with numerous compute units.

For example, a bitstream with a kernel `FooKernel` consisting of two compute units: `FooKernel:BarCU` and `FooKernel:BazCU`.
To print only the first compute, `filter="BarCU"` can be set to the name of the kernel or the compute unit only.

**Keywords**

**`io`** specifies the output to print to.

**`force_io`** ensures usage of specified `io`.
"""
function visualize_streams(xclbin::XRT.Xclbin, filter::AbstractString=""; io::IO=stdout, force_io::Bool=false)
    _XRTInternal.draw_kernel_streams(xclbin, filter; io, force_io)
end
