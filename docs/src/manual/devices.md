# The `XilinxDevice` Type

With the import and loading of XRT.jl, the interface automatically detects and allocates all available Xilinx FPGA devices.
The `XRT.devices()` function can be used to list all of these recognized devices.
One device is thereby represented by its provided name and its BDF identifier:

```Julia
julia> XRT.devices()
3-element Vector{XRT.XilinxDevice}:
 xilinx_u280_gen3x16_xdma_base_1, bdf=0000:a1:00.1
 xilinx_u280_gen3x16_xdma_base_1, bdf=0000:81:00.1
 xilinx_u280_gen3x16_xdma_base_1, bdf=0000:01:00.1
```

The `XRT.device!` function can then be used to globally set a specific device as the active device to be used:

```
julia> d = XRT.device!(3)
┌───┬──────────────────────────────────────────────────────────────────────┐
│ 3 │           [0000:01:00.1] : xilinx_u280_gen3x16_xdma_base_1           │
└───┴──────────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────┬─────────────────────┬───────────┐
│          Max. Clock Frequency          │         m2m         │   NoDMA   │
│                500 MHz                 │        false        │   false   │
├────────────────────────────────────────┼─────────────────────┼───────────┤
│             Interface UUID             │ No. of KDMA Engines │   Ready   │
│  fb2b2c5a-19ed-6359-3fea-95f51fbc8eb9  │          0          │   true    │
└────────────────────────────────────────┴─────────────────────┴───────────┘
Available Reports:
┌─────────────────┐
│ Electrical      │
│ Thermal         │
│ Mechanical      │
│ Memory          │
│ Platform        │
│ PCIe Info       │
│ Host            │
│ Aie             │
│ Aie Shim        │
│ Dynamic Regions │
└─────────────────┘
```

The successful setting can then be verified using the `XRT.device()` function.
This device will then be used for most functions that require a device as an argument.
Alternatively, it can temporarily be changed by setting the `device` keyword argument on the specific function.

> It is recommended not to call the `XilinxDevice` constructor explicitly, as otherwise problems may occur during kernel execution due to incorrect device allocations.

A `XilinxDevice` offers many fields that can be used to query the current device parameters provided by the API.
Calling up the device's show function does also present an overview of the device's data and its available reports.
The request for such a field returns the corresponding value or a human-readable illustration of a generated report object:

```
julia> d.max_clock_frequency_mhz
0x00000000000001f4

julia> d.memory
====================
  Memory Topology: 
====================

HBM[0]
┌─────────┬──────────────┬──────────┬──────────────┬─────────┬──────────┐
│  Type   │  Allocated   │ BO Count │ Base Address │ Enabled │ Temp [C] │
│ MEM_HBM │ 0 B / 256 MB │    0     │     0x0      │  true   │    31    │
└─────────┴──────────────┴──────────┴──────────────┴─────────┴──────────┘
HBM[1]
┌──────────┬──────────────┬──────────┬──────────────┬─────────┬──────────┐
│   Type   │  Allocated   │ BO Count │ Base Address │ Enabled │ Temp [C] │
│ MEM_DRAM │ 0 B / 256 MB │    0     │  0x10000000  │  true   │    31    │
└──────────┴──────────────┴──────────┴──────────────┴─────────┴──────────┘
...
```

If the report name is applied to a report object a second time, the corresponding `LazyJSON` object is returned.

```Julia
julia> d.memory.memory
LazyJSON.Object{Nothing, String}(...):
  "board" => Object{Nothing, String}("direct_memory_accesses"=>Object{Nothing, …
```

Using the `device` field, you can always access the wrapped device data type.
