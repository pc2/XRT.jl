# XRT.jl Public API

Documentation of the public functions provided by the XRT.jl package.
Some functions, which are directly wrapped from the native C++ API, might not be listed.

## Contents

```@contents
Pages = ["api.md"]
Depth = 2:3
```

## Index

```@index
Pages   = ["api.md"]
Order   = [:type, :function]
```

## References

### Devices

```@autodocs
Modules = [XRT]
Pages   = ["xrt_device.jl"]
```

### Xclbin File

The following data types and functions are used for the inspection of the bitstream and metadata of Xclbin files.
It contains the wrapped functions provided by the native C++ API, as well as the [Custom XCLBIN Parser](@ref) and function provided by `xclbinutil`.

```@autodocs
Modules = [XRT]
Pages   = ["xrt_xclbin.jl", "custom_xclbin.jl"]
```

### Kernels

```@autodocs
Modules = [XRT]
Pages   = ["xrt_kernel.jl"]
```

#### User Managed Kernels

```@autodocs
Modules = [XRT]
Pages   = ["xrt_ip.jl"]
```

### Buffer Objects

The following data type `BOArray` can be used as an XRT `BO`, but additionally allows indexing and automatic alignment of the host buffer.

```@autodocs
Modules = [XRT]
Pages   = ["xrt_bo.jl"]
```

### High-Level Execution

```@autodocs
Modules = [XRT]
Pages   = ["hl_execution.jl"]
```

### xbutil

XRT.jl offers the possibility to call the `xbutil` program provided by XRT directly from Julia in order to check the XRT installation and available devices.

```@autodocs
Modules = [XRT, XRT.XbutilTest]
Pages   = ["xrt_xbutil.jl"]
```

### Utilities

Utility functions for global parameters, such as active device configuration, or package information:

```@autodocs
Modules = [XRT]
Pages   = ["state.jl", "prettyprinting.jl"]
```

```@autodocs
Modules = [XRT]
Pages   = ["xrt_ini.jl"]
Filter  = func -> startswith(string(func), "log")
```
