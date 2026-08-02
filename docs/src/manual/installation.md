# Installation

**Note: Only Linux and Windows x86_64 systems are supported!**

The Julia XRT.jl package requires a functional installation of the XRT software stack.
However, a native installation of XRT is not necessary, as a built-in XRT installation is available in the `xrt_jll` package in version 2.26 (and 2.17).

## Package installation

The package can be installed through the package manager and added to your Julia environment:

```bash
pkg> add XRT
```

Or using the Julia `Pkg` package:

```bash
julia> using Pkg; Pkg.add("XRT")
```

Building the package can take some time, as the C++ library gets wrapped and a shared object file is generated during the building process.

## Switching `xrt_jll` version

The version of `xrt_jll` can be switched to v2.17.
Therefore, the following package needs to be added to Julia via the package manager and pinned to this version.

```
pkg> free xrt_jll

pkg> add xrt_jll@[2.17|2.26]

pkg> pin xrt_jll
```

Finally, restart Julia to use with XRT new `xrt_jll` version.


## Use native XRT installation

Instead of the built-in XRT installation, it is also possible to use XRT.jl with a native XRT installation as an option.
Versions from 2.14 onwards are supported.
Set the `XILINX_XRT` environment variable to the path of the local installation before importing the XRT.jl package:

```bash
export XILINX_XRT=/opt/software/FPGA/Xilinx/xrt/xrt_2.14
```

Alternatively, record the choice as a preference so it persists across sessions without an
environment variable:

```Julia
julia> using XRT; XRT.use_native_xrt("/opt/software/FPGA/Xilinx/xrt/xrt_2.14")
```

Either way, run `Pkg.build("XRT")` afterwards to compile `libxrtwrap` against that
installation, then restart Julia. `XRT.use_jll_xrt()` switches back to the `xrt_jll`
artifact.

After loading the package, the currently set version and other set environment variables can be verified.

```Julia
julia> using XRT

julia> XRT.versioninfo()
Xilinx Runtime library 2.14, native installation
Detected emulation mode: hw

Julia packages:
  XRT.jl: 0.1.4

Environment:
  XILINX_VIVADO = /opt/software/FPGA/Xilinx//Vivado/2022.2
  XILINX_VITIS = /opt/software/FPGA/Xilinx//Vitis/2022.2
  XILINX_HLS = /opt/software/FPGA/Xilinx//Vitis_HLS/2022.2
  XILINX_XRT = /opt/software/FPGA/Xilinx/xrt/xrt_2.14

3 devices:
  1: xilinx_u280_gen3x16_xdma_base_1, bdf=0000:a1:00.1
  2: xilinx_u280_gen3x16_xdma_base_1, bdf=0000:81:00.1
  3: xilinx_u280_gen3x16_xdma_base_1, bdf=0000:01:00.1
```

> It is possible to build a shared object file for every XRT version used. The files are named `libxrtwrap.so.2.xx` and can be found in the following directory: `.julia/scratchspaces/4d396880-2e3f-4be1-8c36-e87777010d00/xrtwrap/lib/`.
Versioned shared object files are removed and rebuilt when switching the version of the XRT installation.

## Emulation mode

You can instruct XRT to emulate FPGA devices by setting the `XCL_EMULATION_MODE` to either `hw_emu` or `sw_emu` before loading the package:

```bash
export XCL_EMULATION_MODE=sw_emu
```

In this case, the list of available devices should always just contain one single `XilinxDevice`.
So, the selection of an active device by an index always leads to the only available device.
Additionally, XRT.jl checks whether the Xclbin target type fits the set emulation mode (more on this in the chapter [The `Xclbin` Type](@ref)).

> This feature may only be functioning using a native XRT installation.

## Usage on HPC cluster

To use XRT.jl on an HPC cluster, like the [Noctua 2](https://pc2.uni-paderborn.de/systems-and-services/noctua-2) supercomputer, the following modules have to be loaded:

- For the use with a native XRT installation:

```bash
module load lang JuliaHPC fpga xilinx/xrt
```

- For the use with the built-in `xrt_jll` installation:

```bash
module load lang JuliaHPC fpga xilinx/vitis/24.1
```
