# Known Issues

## `xbutil`

- [`XRT.reset!`](@ref) can kill the active Julia instance or Jupyter kernel if there are user-defined device allocations present.

## AI Engines

XRT.jl does currently not support the usage of AIE.
Related types and functions are not covered by the wrapper, yet.

## xrt_jll

- xrt\_jll does currently not support emulation mode. Even if `XCL_EMULATION_MODE` is set and corresponding Xilinx Vitis version is installed.
- Calling `xbutil` is not fully supported. It is unable to run the built-in tests.