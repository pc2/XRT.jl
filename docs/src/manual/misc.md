# Miscellaneous

> Although the XRT.jl package offers many simplifying functions and types, all types and functions provided by the native C++ API are available in the `XRT.XRTWrap` submodule.

## Configuration file

XRT allows the user to set several parameters to control logging, execution flow and debugging.
Therefore, an `xrt.ini` file will be detected, just as the native C++ API does.
In addition, the interface offers a function with which these parameters can be set at runtime, as long as they have not yet been used during the execution of a kernel.
The `XRTConfiguration` module provides a list of available parameter keys, which can be given into the `XRT.set!` function:

```Julia
julia> XRT.set!(XRT.XRTConfiguration.RUNTIME_LOG, "foo.log")
```

More about this in section [Configuration File xrt.ini](@ref).

## Enum types

XRTs native C++ API uses some enum types as flags for functions and structs, such as device information, synchronization directions, etc.
To maintain these enums and keep them organized, each is housed in its own submodule.
The values of an enum are always of type `XRT.[submodule].Type`, where `[submodule]` is one of: 

- `DeviceInformationParameters`
- `BOFlags`
- `ErtCmdState`
- `BOSyncDirection`
- `CVStatus`
- `LogLevel`

And especially for `Xclbin` type relevant:

- `ComputeUnitAccessMode`, 
- `TargetType`
- `ControlType`
- `MemoryType`
- `IPType`

As an example:

```
julia> typeof(XRT.BOSyncDirection.FROM_DEVICE)
XRT.BOSyncDirection.Type

julia> XRT.BOSyncDirection.FROM_DEVICE
FROM_DEVICE
```