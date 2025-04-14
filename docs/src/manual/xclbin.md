# The `Xclbin` Type

Another important element of the package is the [`XRT.Xclbin`](@ref) type, as it wraps the native `xrt::xclbin` class and allows access to metadata, such as kernel or memory information of the bitstream container file.
To create an Xclbin object, the path to a valid Xclbin container file must be specified.
When loading, the package checks whether the bitstream is compatible with the current system configuration and potentially issues a warning.

```Julia
julia> xclbin = XRT.Xclbin("path/to/communication_PCIE_emulate.xclbin")
┌ Warning: xclbin target type 'sw_emu' does not match the currently set value 'hw'
└ This can lead to incorrect execution
/pc2/users/l/user/path/to/communication_PCIE_emulate.xclbin
```

All attributes can easily be read using fields and chained vector accesses, instead of the native APIs getter functions.
To obtain the C++ class object from an `Xclbin` struct, just call `.xclbin`, `.kernel`, `.arg`, or `.mem` depending on the respective type.
Thus, the following two calls are equivalent:

```Julia
julia> xclbin.kernels[1].args[1].mems[1].type
ddr4

julia> XRT.XRTWrap.get_type(XRT.XRTWrap.get_mems(XRT.XRTWrap.get_args(XRT.XRTWrap.get_kernels(xclbin.xclbin)[1])[1])[1])
ddr4
```

Similar to the [`XRT.XilinxDevice`](@ref) type, the information provided by the `XRT.Xclbin` object can be printed in a human-readable way by calling the show function:

```
julia> xclbin = XRT.Xclbin("path/to/communication_PCIE.xclbin")
┌────────┬──────────────────────────────────────────────────────────────────────────────────────┐
│   hw   │                     /absolute/path/to/communication_PCIE.xclbin                      │
└────────┴──────────────────────────────────────────────────────────────────────────────────────┘
┌──────────────────┬────────────────────────────────────────────────────────────────────────────┐
│         XSA Name │                    xilinx_u280_gen3x16_xdma_1_202211_1                     │
│ FPGA Device Name │                    virtexuplusHBM:xcu280:fsvh2892:-2L:e                    │
│             UUID │                    0c0b1f4c-9b50-464d-bc14-1b34dea8fdb2                    │
└──────────────────┴────────────────────────────────────────────────────────────────────────────┘
Kernels:
┌───────┬─────────────┬─────────┬───────────────────────────────────────┐
│ Index │ Kernel Name │ No. CUs │ Arguments                             │
├───────┼─────────────┼─────────┼───────────────────────────────────────┤
│   1   │ dummyKernel │    1    │ char*      char           int         │
│       │             │         │ output_r   verification   messageSize │
└───────┴─────────────┴─────────┴───────────────────────────────────────┘

julia> xclbin.kernels[1]
================
  dummyKernel: 
================

Compute Units:
┌───────┬─────────────────────────┬──────┬──────────────┬──────────────┬──────┬──────────┐
│ Index │         CU Name         │ Type │ Control Type │ Base Address │ Size │ No. Args │
├───────┼─────────────────────────┼──────┼──────────────┼──────────────┼──────┼──────────┤
│   1   │ dummyKernel:dummyKernel │  pl  │    chain     │   0x800000   │  44  │    3     │
└───────┴─────────────────────────┴──────┴──────────────┴──────────────┴──────┴──────────┘
Arguments:
┌───────┬───────────┬──────────────┬───────────────┬──────────────┬────────┬──────────────────────────┐
│ Index │ Host Type │     Name     │     Port      │ Size [Bytes] │ Offset │ Connected Memory Objects │
├───────┼───────────┼──────────────┼───────────────┼──────────────┼────────┼──────────────────────────┤
│   1   │   char*   │   output_r   │  M_AXI_GMEM   │      8       │   16   │          bank0           │
│   2   │   char    │ verification │ S_AXI_CONTROL │      4       │   28   │                          │
│   3   │    int    │ messageSize  │ S_AXI_CONTROL │      4       │   36   │                          │
└───────┴───────────┴──────────────┴───────────────┴──────────────┴────────┴──────────────────────────┘

```

## Visualize XCLBIN Streams

To simplify the analysis of Xclbin files, kernels, compute units, memory objects and their connections to each other can be written to the console using XRT.jl.
Therefore, the information of the [`XRT.Xclbin`](@ref) type, and our [Custom XCLBIN Parser](@ref) can be printed in a human-readable way, using the [`XRT.visualize_streams`](@ref) 
function.

The following code snippet shows an example of a single plotted graph:

```Julia
julia> XRT.visualize_streams(XRT.Xclbin("path/to/communication_PCIE.xclbin"))
┌─────────────┐                                     
│   Kernel:   │                                     
│             ├────────────────────────────────────┐
│ dummyKernel │                                    │
└─────┬───────┘                                    │
      │                                            │
      │       ┌───────────────┐     ┌─────────┐    │
      └──────►┤ Compute Unit: ├►─┐  │ Memory: │    │
              │               │  │  │         ├◄───┘
              │  dummyKernel  │  └─►┤  bank0  │     
              └───────────────┘     └─────────┘     
```

As the graphs created can very quickly become too large and confusing when the bitstream becomes more complex, it is possible to filter out only a single kernel or compute unit by its name:

```Julia
julia> XRT.visualize_streams(XRT.Xclbin("path/to/stream.xclbin"), "k1")
┌─────────────┐                                     
│   Kernel:   │                                     
│             ├────────────────────────────────────┐
│ stream_calc │                                    │
└─────┬───────┘                                    │
      │                                            │
      │       ┌───────────────┐     ┌─────────┐    │
      └──────►┤ Compute Unit: ├►─┐  │ Memory: │    │
              │               │  │  │         ├◄───┘
              │       k1      │  └─►┤  DDR[0] │     
              └───────────────┘     └─────────┘     
```

## Custom XCLBIN Parser

In addition to the `XRT.Xclbin` type, XRT.jl comes with a custom parser for the Xclbin bitstream container format, since the native API does not provide the entire intended range of functions.
This parser allows extended user-defined inspection of Xclbin files.

The most important functions provided are `get_kernel_info(path)` and `get_system_info(path)` which both take as input a path to the bitstream file.
The functions extract the JSON data that is encoded in the bitstream and return it as a `LazyJSON` data structure.

`get_kernel_info(path)` returns data about the implemented compute kernel, such as input parameters, compute instances, memory addresses, and offset.
`get_system_info(path)` returns information about resource utilization of individual compute units and the available resources on the system.

### Example 

For our simple dummy kernel that is also used in the examples, we can get the resource utilization of the kernel like this:

```Julia
julia> js = XRT.get_system_info("path/to/communication_PCIE.xclbin")
1-element LazyJSON.Array{Nothing, String}:
 LazyJSON.Object{Nothing, String}("name" => ...

julia> js[1]["compute_units"][1]
LazyJSON.Object{Nothing, String}(...):
  "id"               => "0"
  "kernel_name"      => "dummyKernel"
  "cu_name"          => "dummyKernel"
  "base_address"     => "0x800000"
  "actual_resources" => Any[Object{Nothing, String}("design_state"=>"routed", "…
  "clock_name"       => ""
  "clock_id"         => 0
  "clocks"           => Any[Object{Nothing, String}("port_name"=>"ap_clk", "id"…
  "reset_port_names" => Any["ap_rst_n"]
  "slr_resources"    => Any[Object{Nothing, String}("slr_name"=>"SLR0", "resour…
```

## Loading an Xclbin onto a Device

In order to execute the kernels stored in one Xclbin file, they first need to be loaded onto an available device.
This can be done using the [`XRT.load_xclbin!`](@ref) function:

```Julia
julia> xclbin_uuid = load_xclbin!(xclbin)
```

The function returns the `UUID` of the Xclbin file.
It is also possible to set the device manually using the `device` keyword argument.
The loading process is skipped, when the Xclbin is already on the device by comparing the [`XRT.get_xclbin_uuid`](@ref) return value.
However, it can be forced by setting the `force` keyword argument.
