# Troubleshooting

### Building the libxrtwrap.so remains at `[50%] Building CXX object CMakeFiles/xrtwrap.dir/src/xrtwrap.cpp.o`

At least 2 GB of memory are required for building the `libxrtwrap.so` file.

### `No xclbin with uuid 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx': Invalid argument`

This error appears if a kernel of a bitstream is executed on a device other than the one on which this bitstream was previously loaded.
This is also the case if a `XilinxDevice` has been instantiated and allocated several times, even with the same index.
Be sure to choose the devices provided by the `XRT.devices()` function.

### Version of native XRT installation has been updated, but it had no effect on XRT.jl

Try rebuilding the package.
In the building process, the currently selected XRT library is wrapped and a new shared object file is created.

```Julia
julia> using Pkg; Pkg.build("XRT")
```

### Macro throws `LoadError: UndefVarError: XRT not defined`

Try to evaluate the macro at run time instead of parse time.

```Julia
julia> @eval XRT.@sync_buffers begin ...
```

### `XRT.IP` instantiation throws `LoadError: failed to open cu context: Invalid argument`

The IP object was already created at some point before and is still in memory.
Setting the old IP object to `nothing` and explicitly calling the garbage collector using `GC.gc()` should make the IP available again.

### XRT.jl is unable to detect a device correctly `[nothing] : nothing` and cannot upload a bitstream onto a device

XRT 2.17 is not compatible with the installed Xilinx FPGAs or drivers, as it comes with extensive changes according to device communication.
Use an XRT installation ≤ 2.16 instead.

### C++ exception while wrapping module XRTWrap: invalid subtyping in definition of Autostart with supertype Any

The shared library `libxrtwrap.so` has been built with an older version of Julia.
Delete the file to rebuild it.