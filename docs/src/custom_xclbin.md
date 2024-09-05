# Custom XCLBIN Parser

XRT.jl comes with functions to parse the bitstream container format *xclbin*.
The most important functions provided are `get_kernel_info(path)` and `get_system_info(path)` which
both take as input a path to the bitstream. The functions extract the JSON data which is encoded in the
bitstream and return it as a `LazyJSON` data structure.

`get_kernel_info(path)` returns data about the implemented compute kernel, such as input parameters, compute
instances, memory addresses, and offest. `get_system_info(path)` returns information about resource utilization
of individual compute units and the available resources on the system.

## Example 

For our simple dummy kernel that is also used in the examples, we can get the resource utilization of the kernel like this:

```Julia
js = XRT.get_system_info("communication_PCIE.xclbin")
js[1]["compute_units"][1]
```

Results in the following LazyJSON object:

```
LazyJSON.Object{Nothing, String}(...):
  "id"               => "0"
  "kernel_name"      => "dummyKernel"
  "cu_name"          => "dummyKernel"
  "base_address"     => "0x800000"
  "actual_resources" => Any[Object{Nothing, String}("design_state"=>"routed", "LUT"=>"1328", "REG"=>"1439", "BRAM"=>"0", "DSP"=>"0", "URAM"=>"0"), Object{Nothing, String}("design_state"=>"synthesized", "LUT"=>"1497", "REG"=>"1586", "BRAM"=>"0", "DSP"=>"0", "URAM"=>"0…
  "clock_name"       => ""
  "clock_id"         => 0
  "clocks"           => Any[Object{Nothing, String}("port_name"=>"ap_clk", "id"=>"0", "requested_frequency"=>0, "achieved_frequency"=>0)]
  "reset_port_names" => Any["ap_rst_n"]
  "slr_resources"    => Any[Object{Nothing, String}("slr_name"=>"SLR0", "resource_utilization"=>Any[Object{Nothing, String}("resource_name"=>"LUT", "used"=>"1328", "available"=>"439680"), Object{Nothing, String}("resource_name"=>"LUTAsLogic", "used"=>"975", "availabl…

```